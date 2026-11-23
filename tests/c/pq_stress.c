// Drives the libpq binding in `packages/espal-postgres/c/pq.c` from several threads, as Lean
// does: one thread waits in espal_pq_next while others call espal_pq_send. `tests/sanitize.sh`
// builds it with AddressSanitizer, UndefinedBehaviorSanitizer and ThreadSanitizer.
//
// It checks that every statement gets exactly one answer, that a session ended by the server
// fails the reader without a crash, and that a close wakes an idle reader.
#include <lean/lean.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern void lean_initialize_runtime_module(void);
extern void lean_initialize_thread(void);
extern void lean_finalize_thread(void);
extern lean_obj_res espal_pq_connect(b_lean_obj_arg conninfo, uint8_t read_only, uint32_t timeout);
extern lean_obj_res espal_pq_send(b_lean_obj_arg conn, b_lean_obj_arg sql, b_lean_obj_arg name,
                                   uint8_t prepare, b_lean_obj_arg params);
extern lean_obj_res espal_pq_next(b_lean_obj_arg conn);
extern lean_obj_res espal_pq_close(b_lean_obj_arg conn);

#define SENDERS 4
#define PER_SENDER 500
#define TOTAL (SENDERS * PER_SENDER)

static const char *conninfo;

static void die(const char *what) {
  fprintf(stderr, "pq_stress: %s\n", what);
  exit(1);
}

// Takes the value of an IO result, or returns NULL and frees the error.
static lean_object *take(lean_obj_res result) {
  if (lean_io_result_is_ok(result)) return lean_io_result_take_value(result);
  lean_dec(result);
  return NULL;
}

static lean_object *connect_or_die(void) {
  lean_object *info = lean_mk_string(conninfo);
  lean_object *conn = take(espal_pq_connect(info, 0, 0));
  lean_dec(info);
  if (conn == NULL) die("could not connect");
  return conn;
}

// Sends `sql` with one text parameter, by the prepared statement `name` unless it is empty.
// `prepare` prepares that statement first. Returns whether the send succeeded.
static int send_named(lean_object *conn, const char *sql, const char *name, int prepare,
                      const char *param) {
  lean_object *text = lean_mk_string(sql);
  lean_object *stmt = lean_mk_string(name);
  lean_object *params = lean_mk_empty_array();
  if (param) params = lean_array_push(params, lean_mk_string(param));
  lean_object *unit = take(espal_pq_send(conn, text, stmt, (uint8_t)prepare, params));
  lean_dec(text);
  lean_dec(stmt);
  lean_dec(params);
  return unit != NULL;
}

// Sends `sql` with one text parameter, parsed for this one use.
static int send_one(lean_object *conn, const char *sql, const char *param) {
  return send_named(conn, sql, "", 0, param);
}

typedef struct {
  lean_object *conn;
  int first;
} sender_arg;

static void *sender(void *p) {
  sender_arg *arg = (sender_arg *)p;
  lean_initialize_thread();
  for (int i = 0; i < PER_SENDER; i++) {
    char number[16];
    snprintf(number, sizeof number, "%d", arg->first + i);
    // Half run the statement the main thread prepared, and half send the text each time.
    int sent = i % 2 == 0 ? send_named(arg->conn, "select $1::int", "stress", 0, number)
                          : send_one(arg->conn, "select $1::int", number);
    if (!sent) die("a send failed");
  }
  lean_finalize_thread();
  return NULL;
}

typedef struct {
  lean_object *conn;
  int wanted;
  int answered;
  int failed;
  unsigned char seen[TOTAL];
} reader_arg;

// Reads answers until `wanted` have arrived or the connection fails.
static void *reader(void *p) {
  reader_arg *arg = (reader_arg *)p;
  lean_initialize_thread();
  while (arg->answered < arg->wanted) {
    lean_object *answer = take(espal_pq_next(arg->conn));
    if (answer == NULL) {
      arg->failed = 1;
      break;
    }
    // `Except.ok rows` has tag 1. The one cell holds the number that was sent.
    if (lean_obj_tag(answer) == 1) {
      lean_object *rows = lean_ctor_get(answer, 0);
      if (lean_array_size(rows) == 1) {
        lean_object *cell = lean_array_get_core(lean_array_get_core(rows, 0), 0);
        if (!lean_is_scalar(cell)) {
          int n = atoi(lean_string_cstr(lean_ctor_get(cell, 0)));
          if (n >= 0 && n < TOTAL) arg->seen[n]++;
        }
      }
    }
    lean_dec(answer);
    arg->answered++;
  }
  lean_finalize_thread();
  return NULL;
}

// Every statement from several senders gets exactly one answer.
static void many_senders(void) {
  lean_object *conn = connect_or_die();
  reader_arg *r = calloc(1, sizeof *r);
  r->conn = conn;
  r->wanted = TOTAL + 1;
  pthread_t reading, sending[SENDERS];
  // Prepares the statement the senders run by name. Its answer is one more for the reader, and
  // the value 0 it carries is also sent once by a sender.
  if (!send_named(conn, "select $1::int", "stress", 1, "0")) die("a prepare failed");
  sender_arg args[SENDERS];
  pthread_create(&reading, NULL, reader, r);
  for (int i = 0; i < SENDERS; i++) {
    args[i].conn = conn;
    args[i].first = i * PER_SENDER;
    pthread_create(&sending[i], NULL, sender, &args[i]);
  }
  for (int i = 0; i < SENDERS; i++) pthread_join(sending[i], NULL);
  pthread_join(reading, NULL);
  if (r->failed || r->answered != TOTAL + 1) die("the reader lost answers");
  for (int i = 0; i < TOTAL; i++)
    if (r->seen[i] != (i == 0 ? 2 : 1)) die("a statement did not get exactly one answer");
  free(r);
  lean_dec(conn);
}

// A session that the server ends fails its reader, and later sends fail or go unanswered.
static void ended_session(void) {
  lean_object *conn = connect_or_die();
  lean_object *other = connect_or_die();
  reader_arg *r = calloc(1, sizeof *r);
  r->conn = conn;
  r->wanted = 2;
  pthread_t reading;
  if (!send_one(conn, "select pg_sleep(30)", NULL)) die("a send failed");
  pthread_create(&reading, NULL, reader, r);
  // The second connection ends every other session of this role.
  if (!send_one(other,
                "select pg_terminate_backend(pid) from pg_stat_activity "
                "where usename = current_user and pid <> pg_backend_pid()",
                NULL))
    die("a send failed");
  lean_object *answer = take(espal_pq_next(other));
  if (answer == NULL) die("the ending connection failed");
  lean_dec(answer);
  pthread_join(reading, NULL);
  if (!r->failed) die("a reader survived the end of its session");
  send_one(conn, "select 1", NULL);
  free(r);
  lean_dec(conn);
  lean_dec(other);
}

// A close wakes a reader that waits on an idle connection.
static void close_while_idle(void) {
  lean_object *conn = connect_or_die();
  reader_arg *r = calloc(1, sizeof *r);
  r->conn = conn;
  r->wanted = 1;
  pthread_t reading;
  pthread_create(&reading, NULL, reader, r);
  lean_object *unit = take(espal_pq_close(conn));
  if (unit == NULL) die("a close failed");
  pthread_join(reading, NULL);
  if (!r->failed) die("a reader survived a close");
  if (send_one(conn, "select 1", NULL)) die("a closed connection took a statement");
  free(r);
  lean_dec(conn);
}

int main(void) {
  conninfo = getenv("ESPAL_TEST_DATABASE");
  if (conninfo == NULL) die("set ESPAL_TEST_DATABASE to a libpq connection string");
  lean_initialize_runtime_module();
  for (int round = 0; round < 5; round++) {
    many_senders();
    ended_session();
    close_while_idle();
  }
  puts("pq_stress: every check passed");
  return 0;
}
