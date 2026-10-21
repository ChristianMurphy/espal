// libpq in pipeline mode for the Postgres spike. One Lean task per connection blocks in
// espal_pq_next, which polls the socket; request handlers call espal_pq_send. A mutex keeps the
// two from using the PGconn at the same time, since libpq connections are not thread-safe.
#include <lean/lean.h>
#include <libpq-fe.h>
#include <arpa/inet.h>
#include <errno.h>
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
  int wake; // eventfd: tells the reader that input arrived while a sender held the lock
  int inflight;
  int ok;
  uint64_t value;
  char err[256];
} pq_t;

static void pq_finalize(void *p) {
  pq_t *pq = (pq_t *)p;
  if (pq->conn) PQfinish(pq->conn);
  close(pq->wake);
  pthread_mutex_destroy(&pq->mu);
  free(pq);
}

static void pq_foreach(void *p, b_lean_obj_arg f) { (void)p; (void)f; }

static lean_external_class *pq_class = NULL;

static lean_obj_res io_error(const char *msg) {
  return lean_io_result_mk_error(lean_mk_io_user_error(lean_mk_string(msg)));
}

LEAN_EXPORT lean_obj_res espal_pq_connect(b_lean_obj_arg conninfo, b_lean_obj_arg sql) {
  if (pq_class == NULL) pq_class = lean_register_external_class(pq_finalize, pq_foreach);
  PGconn *conn = PQconnectdb(lean_string_cstr(conninfo));
  if (PQstatus(conn) != CONNECTION_OK) {
    lean_obj_res e = io_error(PQerrorMessage(conn));
    PQfinish(conn);
    return e;
  }
  Oid types[1] = {23};
  PGresult *r = PQprepare(conn, "w", lean_string_cstr(sql), 1, types);
  if (PQresultStatus(r) != PGRES_COMMAND_OK) {
    lean_obj_res e = io_error(PQerrorMessage(conn));
    PQclear(r);
    PQfinish(conn);
    return e;
  }
  PQclear(r);
  if (!PQenterPipelineMode(conn) || PQsetnonblocking(conn, 1) != 0) {
    lean_obj_res e = io_error(PQerrorMessage(conn));
    PQfinish(conn);
    return e;
  }
  pq_t *pq = calloc(1, sizeof(pq_t));
  pq->conn = conn;
  pthread_mutex_init(&pq->mu, NULL);
  pq->wake = eventfd(0, EFD_NONBLOCK);
  return lean_io_result_mk_ok(lean_alloc_external(pq_class, pq));
}

LEAN_EXPORT lean_obj_res espal_pq_send(b_lean_obj_arg obj, uint32_t id) {
  pq_t *pq = (pq_t *)lean_get_external_data(obj);
  uint32_t be = htonl(id);
  const char *values[1] = {(const char *)&be};
  int lengths[1] = {4};
  int formats[1] = {1};
  int consumed = 0;
  pthread_mutex_lock(&pq->mu);
  if (!PQsendQueryPrepared(pq->conn, "w", 1, values, lengths, formats, 1) ||
      !PQpipelineSync(pq->conn)) {
    lean_obj_res e = io_error(PQerrorMessage(pq->conn));
    pthread_mutex_unlock(&pq->mu);
    return e;
  }
  pq->inflight++;
  int f;
  while ((f = PQflush(pq->conn)) == 1) {
    struct pollfd p = {PQsocket(pq->conn), POLLIN | POLLOUT, 0};
    poll(&p, 1, -1);
    if (p.revents & POLLIN) {
      PQconsumeInput(pq->conn);
      consumed = 1;
    }
  }
  pthread_mutex_unlock(&pq->mu);
  if (f < 0) return io_error(PQerrorMessage(pq->conn));
  if (consumed) {
    uint64_t one = 1;
    (void)!write(pq->wake, &one, sizeof one);
  }
  return lean_io_result_mk_ok(lean_box(0));
}

static uint32_t be32(const char *p) {
  uint32_t v;
  memcpy(&v, p, 4);
  return ntohl(v);
}

// Reads column `col` of the first row as a binary int4. Fails on NULL, text format or any other
// length, since the server decides what each column holds.
static int int4_at(const PGresult *r, int col, uint32_t *out) {
  if (PQgetisnull(r, 0, col) || PQfformat(r, col) != 1 || PQgetlength(r, 0, col) != 4) return 0;
  *out = be32(PQgetvalue(r, 0, col));
  return 1;
}

// Blocks until the next query in flight finishes. Returns (id << 32 | randomnumber).
LEAN_EXPORT lean_obj_res espal_pq_next(b_lean_obj_arg obj) {
  pq_t *pq = (pq_t *)lean_get_external_data(obj);
  for (;;) {
    pthread_mutex_lock(&pq->mu);
    if (!PQconsumeInput(pq->conn)) {
      lean_obj_res e = io_error(PQerrorMessage(pq->conn));
      pthread_mutex_unlock(&pq->mu);
      return e;
    }
    while (pq->inflight > 0 && !PQisBusy(pq->conn)) {
      PGresult *r = PQgetResult(pq->conn);
      if (r == NULL) continue;
      ExecStatusType st = PQresultStatus(r);
      if (st == PGRES_TUPLES_OK) {
        uint32_t id, number;
        if (PQntuples(r) == 1 && PQnfields(r) == 2 && int4_at(r, 0, &id) && int4_at(r, 1, &number)) {
          pq->value = ((uint64_t)id << 32) | number;
          pq->ok = 1;
        } else {
          pq->ok = 0;
          strcpy(pq->err, "expected one row with two binary int4 columns");
        }
      } else if (st == PGRES_PIPELINE_SYNC) {
        pq->inflight--;
        int ok = pq->ok;
        uint64_t value = pq->value;
        char err[256];
        strcpy(err, pq->err);
        pq->ok = 0;
        pq->err[0] = 0;
        PQclear(r);
        pthread_mutex_unlock(&pq->mu);
        if (ok) return lean_io_result_mk_ok(lean_box_uint64(value));
        return io_error(err[0] ? err : "query failed");
      } else {
        pq->ok = 0;
        strncpy(pq->err, PQresultErrorMessage(r), sizeof pq->err - 1);
      }
      PQclear(r);
    }
    int sock = PQsocket(pq->conn);
    pthread_mutex_unlock(&pq->mu);
    if (sock < 0) return io_error("libpq connection has no socket");
    struct pollfd fds[2] = {{sock, POLLIN, 0}, {pq->wake, POLLIN, 0}};
    if (poll(fds, 2, -1) < 0 && errno != EINTR) return io_error("poll failed");
    if (fds[1].revents & POLLIN) {
      uint64_t n;
      (void)!read(pq->wake, &n, sizeof n);
    }
  }
}
