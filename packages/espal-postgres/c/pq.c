// libpq in pipeline mode. One Lean task per connection blocks in espal_pq_next and returns the
// result of each statement in the order they were sent. Request handlers call espal_pq_send.
//
// libpq allows one thread at a time on a PGconn, so a mutex guards every libpq call. The reader
// waits in poll() without the mutex, on the socket and on an eventfd. A sender and a close write
// to the eventfd to wake it. The reader also waits on the socket while no statement is in flight,
// so it notices a connection that the server closed before a handler tries to use it.
#include <lean/lean.h>
#include <libpq-fe.h>
#include <poll.h>
#include <pthread.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/eventfd.h>
#include <unistd.h>

typedef struct {
  PGconn *conn;
  pthread_mutex_t mu;
  int wake;
  int inflight;
  int closed;
} pq_t;

static void pq_finalize(void *p) {
  pq_t *pq = (pq_t *)p;
  if (pq->conn) PQfinish(pq->conn);
  close(pq->wake);
  pthread_mutex_destroy(&pq->mu);
  free(pq);
}

static void pq_foreach(void *p, b_lean_obj_arg f) {
  (void)p;
  (void)f;
}

static lean_external_class *pq_class = NULL;
static pthread_once_t pq_class_once = PTHREAD_ONCE_INIT;

static void pq_register(void) { pq_class = lean_register_external_class(pq_finalize, pq_foreach); }

static lean_obj_res io_error(const char *msg) {
  return lean_io_result_mk_error(lean_mk_io_user_error(lean_mk_string(msg)));
}

static pq_t *pq_of(b_lean_obj_arg obj) { return (pq_t *)lean_get_external_data(obj); }

// Wakes the reader from its wait.
static void pq_wake(pq_t *pq) {
  uint64_t one = 1;
  ssize_t ignored = write(pq->wake, &one, sizeof one);
  (void)ignored;
}

// Connects, optionally makes the session read-only, and enters pipeline mode.
LEAN_EXPORT lean_obj_res espal_pq_connect(b_lean_obj_arg conninfo, uint8_t read_only) {
  pthread_once(&pq_class_once, pq_register);
  PGconn *conn = PQconnectdb(lean_string_cstr(conninfo));
  if (PQstatus(conn) != CONNECTION_OK) {
    lean_obj_res e = io_error(PQerrorMessage(conn));
    PQfinish(conn);
    return e;
  }
  if (read_only) {
    PGresult *r = PQexec(conn, "SET default_transaction_read_only = on");
    if (PQresultStatus(r) != PGRES_COMMAND_OK) {
      lean_obj_res e = io_error(PQerrorMessage(conn));
      PQclear(r);
      PQfinish(conn);
      return e;
    }
    PQclear(r);
  }
  if (!PQenterPipelineMode(conn) || PQsetnonblocking(conn, 1) != 0) {
    lean_obj_res e = io_error(PQerrorMessage(conn));
    PQfinish(conn);
    return e;
  }
  pq_t *pq = (pq_t *)malloc(sizeof(pq_t));
  if (pq == NULL) {
    PQfinish(conn);
    return io_error("out of memory");
  }
  pq->wake = eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
  if (pq->wake < 0) {
    free(pq);
    PQfinish(conn);
    return io_error("no file descriptor is left for the connection");
  }
  pq->conn = conn;
  pq->inflight = 0;
  pq->closed = 0;
  pthread_mutex_init(&pq->mu, NULL);
  return lean_io_result_mk_ok(lean_alloc_external(pq_class, pq));
}

// Sends one statement with text parameters, followed by a sync, and flushes it.
LEAN_EXPORT lean_obj_res espal_pq_send(b_lean_obj_arg obj, b_lean_obj_arg sql,
                                       b_lean_obj_arg params) {
  pq_t *pq = pq_of(obj);
  size_t n = lean_array_size(params);
  if (n > 65535) return io_error("a statement takes at most 65535 parameters");
  const char **values = NULL;
  if (n > 0) {
    values = (const char **)malloc(n * sizeof(char *));
    if (values == NULL) return io_error("out of memory");
    for (size_t i = 0; i < n; i++) values[i] = lean_string_cstr(lean_array_get_core(params, i));
  }
  pthread_mutex_lock(&pq->mu);
  if (pq->closed) {
    pthread_mutex_unlock(&pq->mu);
    free(values);
    return io_error("the connection is closed");
  }
  int ok = PQsendQueryParams(pq->conn, lean_string_cstr(sql), (int)n, NULL, values, NULL, NULL, 0) &&
           PQpipelineSync(pq->conn);
  free(values);
  if (!ok) {
    lean_obj_res e = io_error(PQerrorMessage(pq->conn));
    pthread_mutex_unlock(&pq->mu);
    return e;
  }
  pq->inflight++;
  int f;
  while ((f = PQflush(pq->conn)) == 1) {
    // The server may wait for us to read before it reads more, so take input while flushing.
    struct pollfd p = {PQsocket(pq->conn), POLLIN | POLLOUT, 0};
    if (poll(&p, 1, -1) < 0) continue;
    if ((p.revents & POLLIN) && !PQconsumeInput(pq->conn)) {
      f = -1;
      break;
    }
  }
  lean_obj_res result =
      f < 0 ? io_error(PQerrorMessage(pq->conn)) : lean_io_result_mk_ok(lean_box(0));
  pq_wake(pq);
  pthread_mutex_unlock(&pq->mu);
  return result;
}

// The rows of a result as `Array (Array (Option String))`.
static lean_obj_res rows_of(const PGresult *r) {
  int rows = PQntuples(r), cols = PQnfields(r);
  lean_object *out = lean_mk_empty_array_with_capacity(lean_box(rows));
  for (int i = 0; i < rows; i++) {
    lean_object *row = lean_mk_empty_array_with_capacity(lean_box(cols));
    for (int j = 0; j < cols; j++) {
      lean_object *cell;
      if (PQgetisnull(r, i, j)) {
        cell = lean_box(0);
      } else {
        cell = lean_alloc_ctor(1, 1, 0);
        lean_ctor_set(cell, 0, lean_mk_string_from_bytes(PQgetvalue(r, i, j), PQgetlength(r, i, j)));
      }
      row = lean_array_push(row, cell);
    }
    out = lean_array_push(out, row);
  }
  return out;
}

// `Except.error (sqlstate, message)` for a statement the server refused.
static lean_obj_res refused_of(const PGresult *r) {
  const char *state = PQresultErrorField(r, PG_DIAG_SQLSTATE);
  const char *message = PQresultErrorField(r, PG_DIAG_MESSAGE_PRIMARY);
  lean_object *pair = lean_alloc_ctor(0, 2, 0);
  lean_ctor_set(pair, 0, lean_mk_string(state ? state : ""));
  lean_ctor_set(pair, 1, lean_mk_string(message ? message : PQresultErrorMessage(r)));
  lean_object *error = lean_alloc_ctor(0, 1, 0);
  lean_ctor_set(error, 0, pair);
  return error;
}

// Blocks until the next statement's result is complete, and returns it as
// `Except (String × String) Rows`. A lost connection is an IO error.
LEAN_EXPORT lean_obj_res espal_pq_next(b_lean_obj_arg obj) {
  pq_t *pq = pq_of(obj);
  lean_object *answer = NULL;
  pthread_mutex_lock(&pq->mu);
  for (;;) {
    if (pq->closed) {
      pthread_mutex_unlock(&pq->mu);
      if (answer) lean_dec(answer);
      return io_error("the connection is closed");
    }
    if (!PQconsumeInput(pq->conn)) {
      lean_obj_res e = io_error(PQerrorMessage(pq->conn));
      pthread_mutex_unlock(&pq->mu);
      if (answer) lean_dec(answer);
      return e;
    }
    int ends = 0;
    while (pq->inflight > 0 && !PQisBusy(pq->conn)) {
      PGresult *r = PQgetResult(pq->conn);
      if (r == NULL) {
        // One NULL ends a statement's results, and the sync's own result follows. A second
        // NULL in a row means nothing more has arrived yet.
        if (++ends >= 2) break;
        continue;
      }
      ends = 0;
      ExecStatusType st = PQresultStatus(r);
      if (st == PGRES_PIPELINE_SYNC) {
        PQclear(r);
        pq->inflight--;
        pthread_mutex_unlock(&pq->mu);
        if (answer == NULL) return io_error("the server sent no result for a statement");
        return lean_io_result_mk_ok(answer);
      }
      if (answer == NULL) {
        if (st == PGRES_TUPLES_OK || st == PGRES_COMMAND_OK) {
          answer = lean_alloc_ctor(1, 1, 0);
          lean_ctor_set(answer, 0, rows_of(r));
        } else if (st == PGRES_FATAL_ERROR && PQstatus(pq->conn) == CONNECTION_OK) {
          answer = refused_of(r);
        } else {
          lean_obj_res e = io_error(PQresultErrorMessage(r));
          PQclear(r);
          pthread_mutex_unlock(&pq->mu);
          return e;
        }
      }
      PQclear(r);
    }
    struct pollfd fds[2] = {{PQsocket(pq->conn), POLLIN, 0}, {pq->wake, POLLIN, 0}};
    pthread_mutex_unlock(&pq->mu);
    poll(fds, 2, -1);
    if (fds[1].revents & POLLIN) {
      uint64_t count;
      ssize_t ignored = read(pq->wake, &count, sizeof count);
      (void)ignored;
    }
    pthread_mutex_lock(&pq->mu);
  }
}

// Marks the connection closed and wakes its reader. The finalizer frees the connection.
LEAN_EXPORT lean_obj_res espal_pq_close(b_lean_obj_arg obj) {
  pq_t *pq = pq_of(obj);
  pthread_mutex_lock(&pq->mu);
  pq->closed = 1;
  pq_wake(pq);
  pthread_mutex_unlock(&pq->mu);
  return lean_io_result_mk_ok(lean_box(0));
}
