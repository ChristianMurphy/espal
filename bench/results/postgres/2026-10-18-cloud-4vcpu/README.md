# Postgres spike results, 18 October 2026

These numbers come from the Postgres spike in the [spikes and a baseline](../../../../ROADMAP.md#spikes-and-a-baseline) milestone. The clients, servers and scripts live in `explorations/postgres` on the `explore/postgres` branch.

## Setup

The run used the same shared 4-vCPU cloud VM as the [HTTP spike](../../http/2026-10-18-cloud-4vcpu/README.md). Postgres 16.15 ran pinned to CPU 2 with its default settings and SCRAM-SHA-256 sign-in. The `world` table held 10,000 rows, and each query looked up one row by primary key, as TechEmpower's `/db` test does. All Lean code used Lean `4.36.0-rc1`.

## The two clients

- **The wire client.** Pure Lean over Std.Async TCP, with no C. It signs in with SCRAM-SHA-256, using SHA-256, HMAC, PBKDF2 and Base64 written in Lean and checked against Python's `hashlib`. It prepares statements and sends `Bind`, `Execute` and `Sync` for each query, so many queries share a connection in flight. A reader task matches replies to queries in order. It is about 400 lines of Lean.
- **The libpq client.** 160 lines of C around libpq in pipeline mode, plus about 50 lines of Lean. Lean doesn't let a C binding wait on a socket inside its event loop. So each connection has a dedicated Lean task that waits on libpq's socket and resolves queries in order. A C mutex keeps that task and the request handlers from using a connection at the same time.

## Queries per second, without HTTP

These runs call each client directly from CPUs 0 and 1. A bare C client using libpq marks the ceiling.

| Client | One query in flight | One connection, many in flight | Four connections | Client CPU per query, four connections |
|---|---|---|---|---|
| Bare C libpq | 15,627 | 38,143 | 43,712 | 13 µs |
| Lean libpq client | 7,871 | 20,259 | 48,062 | 34 µs |
| Lean wire client | 4,449 | 20,336 | 23,955 | 61 µs |

`direct-clients.md` lists the exact settings. With four connections, the libpq client reaches the limit of one Postgres core. The wire client stops at half of that, because all of its reads and writes pass through Lean's single event loop. With one query in flight, the wire client spends 274 µs of CPU per query, against 102 µs for the libpq client. Most of that goes to handing work between threads, as in the HTTP spike.

## `/db` over HTTP

Each server ran on CPUs 0 and 1, with oha on CPU 3 and 64 connections. The method matches the HTTP spike. A closed-loop run found the peak, then open-loop runs measured 25, 50, 70, 90 and 200 percent of it, three times each. `raw/` has every run.

| Server | Peak req/s | Server CPU per request at peak | Postgres CPU per request at peak |
|---|---|---|---|
| Go `net/http` with pgx | 21,602 | 59 µs | 37 µs |
| Std.Http with the libpq client | 3,741 | 449 µs | 67 µs |
| Std.Http with the wire client | 3,283 | 492 µs | 61 µs |
| Std.Http `/plaintext`, same setup | 4,383 | 370 µs | none |

- Std.Http limits both Lean servers. `/db` reaches 75 to 85 percent of `/plaintext` on the same server, and the two clients differ by 14 percent.
- Go serves 5.8 times as many `/db` requests as the faster Lean server. For `/plaintext` the HTTP spike measured 22 times.
- At light load the Lean servers spend more CPU per request. They used about 1.3 ms per request at 25 percent of peak, and 0.45 ms at peak. Go's cost per request changes much less.
- With oha on a single CPU, p99 latency at 70 percent of peak was about 30 ms for the Lean servers. Go's was 11 ms. The Lean `/plaintext` server showed 37 ms in this run, against 10 ms in the HTTP spike with oha on two CPUs. So these latencies say more about the load generator than the clients.
- No server returned an error status in any run.

## Dropped connections

`faults.json` holds runs at a steady 1,000 requests per second for 20 seconds. Five seconds in, the run either killed every backend serving the app with `pg_terminate_backend` or restarted Postgres. A probe then measured how long `/db` took to answer again. Both Lean servers used a pool that replaces a broken connection on its next use. While it reconnects, other requests on that connection get `503`.

| Server | Recovery after killing backends | Failed requests | Recovery after a restart | Failed requests |
|---|---|---|---|---|
| Go with pgx | 0.18 s | 16 | 2.47 s | 242 |
| Lean wire client | 0.16 s | 78 | 2.42 s | 346 |
| Lean libpq client | 0.10 s | 28 | 2.31 s | 155 |

Every server recovered without a restart, and no request hung. The slowest single request took 496 ms. The Lean servers fail more requests than they need to. A request that lands on a reconnecting connection fails at once instead of waiting for it.

## Other findings

- Lean links executables against an older glibc that ships with the toolchain. Adding the system library directory to find libpq pulled in the system glibc and broke the link. The spike links libpq from a directory that holds only that library.
- The server that uses libpq links 24 shared libraries at run time, among them OpenSSL, Kerberos and LDAP. A release binary would need libpq built without the optional parts, or shipped beside it.
- Dedicated tasks blocked in `poll` keep a Lean process alive after `main` returns, so the libpq programs exit explicitly.
- The libpq library uses the PostgreSQL License, which is permissive.
- Lean's runtime offers no TLS. Managed Postgres requires TLS, so the wire client would need a binding to a TLS library before production use. The libpq client gets TLS from libpq.
