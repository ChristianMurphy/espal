// A bare libpq client: CONNS threads, each with its own connection in pipeline mode, keeping DEPTH
// single-row lookups in flight. It sets the ceiling a Lean client is measured against.
#include <libpq-fe.h>
#include <arpa/inet.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static const char *conninfo = "host=127.0.0.1 port=5432 user=benchmarkdbuser password=benchmarkdbpass dbname=hello_world";
static int depth, seconds;

static double now(void) {
  struct timespec t;
  clock_gettime(CLOCK_MONOTONIC, &t);
  return t.tv_sec + t.tv_nsec / 1e9;
}

static void *run(void *arg) {
  long *count = arg;
  PGconn *c = PQconnectdb(conninfo);
  if (PQstatus(c) != CONNECTION_OK) { fprintf(stderr, "%s", PQerrorMessage(c)); exit(1); }
  Oid types[1] = {23};
  PQclear(PQprepare(c, "w", "SELECT id, randomnumber FROM world WHERE id = $1", 1, types));
  PQenterPipelineMode(c);
  uint32_t x = (uint32_t)(uintptr_t)count | 1;
  int inflight = 0;
  double end = now() + seconds;
  while (now() < end || inflight > 0) {
    while (inflight < depth && now() < end) {
      x ^= x << 13; x ^= x >> 17; x ^= x << 5;
      uint32_t be = htonl(x % 10000 + 1);
      const char *v[1] = {(const char *)&be};
      int len[1] = {4}, fmt[1] = {1};
      PQsendQueryPrepared(c, "w", 1, v, len, fmt, 1);
      PQpipelineSync(c);
      inflight++;
    }
    PQflush(c);
    PGresult *r;
    while ((r = PQgetResult(c)) != NULL || inflight > 0) {
      if (r == NULL) continue;
      ExecStatusType st = PQresultStatus(r);
      PQclear(r);
      if (st == PGRES_PIPELINE_SYNC) { inflight--; (*count)++; break; }
    }
  }
  PQfinish(c);
  return NULL;
}

int main(int argc, char **argv) {
  int conns = argc > 1 ? atoi(argv[1]) : 1;
  depth = argc > 2 ? atoi(argv[2]) : 1;
  seconds = argc > 3 ? atoi(argv[3]) : 5;
  pthread_t th[64];
  long counts[64] = {0};
  double t0 = now();
  for (int i = 0; i < conns; i++) pthread_create(&th[i], NULL, run, &counts[i]);
  long total = 0;
  for (int i = 0; i < conns; i++) { pthread_join(th[i], NULL); total += counts[i]; }
  double secs = now() - t0;
  printf("bare-libpq conns=%d depth=%d: %ld queries in %.2fs = %.0f q/s\n", conns, depth, total, secs, total / secs);
  return 0;
}
