# Roadmap

This plan covers Espal 0.1. It sets the order of work, shows how two example apps exercise each piece, describes how we benchmark, and lists the guarantees we can claim. For each guarantee it states what the guarantee assumes and how it can break. Items marked **Open** are not settled; each one carries a proposed default.

## Goal

Espal is an HTTP framework for Lean 4 that is easy to use and fast enough for production APIs and server-rendered pages. Its guarantees set it apart, and the compiler or CI checks each one:

1. The server and the client agree on routes, request bodies and responses.
2. Queries carry no injected SQL, touch only the current tenant's rows, and stay within a budget per request.
3. App processes keep no state between requests, so the app scales by running more of them.

Version 0.1 covers a JSON API, server-rendered pages in a JSX-like syntax, and a generated TypeScript client. The first production app grades QTI assessments and stores its data in Postgres.

## Where the claims run ahead of the plan

The README and the pitch promise more than this plan delivers. We fix these before 0.1.

The README says an endpoint declares how much work it may spend, and that code over budget fails to compile. Only statement budgets exist, and only in the prototype. Lean has no CPU or memory limit per task, and nothing can stop a pure computation once it runs. Static bounds on pure code form a research track below.

The README also says the compiler checks how the app behaves under load. The compiler can check statement counts and row bounds, which shape load behavior. The behavior itself we measure.

"Stateless" holds for app processes, while Postgres holds all the state. Adding app processes moves the bottleneck to the database. Row and query-plan budgets matter for that reason as much as statement budgets do.

Proposed README bullet: "**Query budgets.** Each endpoint declares how many statements it sends and how many rows each may return. A handler that sends a query per row, or a query without a row bound, fails to compile."

## Kinds of evidence

Each property below carries one of these labels. Only the first two come from the compiler. A label gives the target for 0.1, and each property says which parts the prototype already proves.

- **Proved.** Lean's kernel checks a theorem about Lean definitions. The theorem reaches the running program only through the trusted base below.
- **Typed.** Code that breaks the rule fails to compile. Each typed rule gets a `#guard_msgs` test that shows the rejection and its message.
- **Checked at startup.** The app refuses to start when the rule fails, for example when the database schema differs from the declared one.
- **Linted.** A CI check reads compiled declarations, as `scripts/Lint.lean` does.
- **Tested.** Conformance, differential or fuzz tests give evidence. They prove nothing.
- **Measured.** Benchmarks report numbers on stated hardware.
- **Enforced.** A runtime limit covers every line of code and proves nothing.

### Trusted base

Every proved claim relies on these parts:

- Lean's kernel, plus Lean's compiler and runtime. The compiler turns the definitions we reason about into machine code, and nobody has verified it.
- Code behind `@[extern]` and `@[implemented_by]`. A `@[csimp]` swap comes with a proof; an `implemented_by` swap does not.
- The C libraries Espal links, which are libuv, OpenSSL, and libpq if we choose it.
- Postgres, the reverse proxy, the operating system and the network.

## Properties

### P1. Route round trip (Proved)

For every route value, `ofPath (toPath r) = some r`. `Espal.Route` proves this for the decimal codec today.

The converse is missing. The parser accepts leading zeros, so `/users/007` and `/users/7` reach the same route, and one resource has two URLs. Cache keys and path-based rules can then disagree. We prove that `toPath` inverts `ofPath` on canonical paths, and answer other paths with a redirect or a 404.

The proof assumes the HTTP layer passes the path through unchanged. Percent-decoding, `..`, doubled or trailing slashes, and a proxy that rewrites paths all happen outside it. A test sends each of these cases through the real server.

### P2. Every endpoint is reachable (Proved at compile time)

The `api` macro proves that each endpoint's requests reach that endpoint and no earlier one. A shadowed endpoint fails to compile with "endpoint … is unreachable".

Each endpoint's proof steps through every earlier endpoint, so total proof time grows with the square of the endpoint count. Nobody has timed an API with 200 endpoints. Compile-time benchmarks with 10, 50 and 200 generated endpoints run in CI against a budget.

### P3. Client and server agree (Proved for the Lean client, Tested for TypeScript)

The prototype proves two theorems. `dispatch_request` shows that a request built by the client reaches the intended handler with the same parameters and body. `decode_respond` shows that the client decodes a response to the value the handler returned.

Both need a `LawfulJson` instance for every body type, meaning `fromJson? (toJson a) = .ok a`. Lean's derived `ToJson` and `FromJson` instances come without that proof. Espal needs a deriving handler that generates it.

The guarantee breaks in four places:

- JSON has no NaN or infinity, so `Float` has no lawful codec. API types reject `Float`.
- The generated TypeScript is a second implementation outside Lean. JavaScript numbers lose precision above 2^53 − 1. Following the OpenAPI int64 guidance and ProtoJSON, 64-bit and unbounded integers travel as decimal strings.
- `Option` needs one encoding. JSON has `null` and a missing key, and TypeScript adds `undefined`.
- During a rolling deploy, a browser tab running last week's client calls this week's server. The theorem covers a single version.

CI generates the client and compiles it with `tsc --strict`. A test sends random values from TypeScript through the Lean server and back. CI also compares the API description with the last release and fails on a breaking change.

### P4. No SQL injection (Proved)

`sqlText_eraseParams` shows that the SQL text depends on no parameter value. Values travel only as bind parameters.

The guarantee breaks in these cases:

- An escape hatch accepts raw SQL.
- A dynamic identifier, such as a sort column the user picks, enters the text. Identifiers come from the schema, so a sort column is an enumeration.
- A user's `%` or `_` reaches a `LIKE` pattern. That is a matching bug rather than injection, and the query layer escapes both characters.
- A batch lookup exceeds the protocol's limit of 65,535 bind parameters. The prototype's `byAnyOf` uses one parameter per key and fails on long lists. `col = ANY($1)` with one array parameter avoids the limit.

### P5. The query model matches Postgres (Tested)

We prove facts about queries with a small evaluator written in Lean. Those facts hold in Postgres only where Postgres gives the same answers.

The two disagree on integer overflow, where Postgres raises an error and Lean's `Int` grows. They also differ on three-valued `NULL` logic, collation, floating point, time zones, and `char(n)` padding. We model only the fragment where they agree. `NULL` becomes an explicit `Option`, and each Lean type maps to a Postgres type with a checked range.

Differential tests generate schemas, rows and queries. They run each query through the evaluator and through Postgres and compare the results. CI runs them against each supported Postgres release.

### P6. Tenant isolation (Proved over the model, Enforced by Postgres)

The prototype proves that a scoped select returns only the scope's rows (`scopedSelect_tenant`). It also proves that scoped updates and deletes leave other tenants' rows unchanged (`scopedUpdate_isolation`, `scopedDelete_isolation`). These results reach Postgres only through P5.

As a second layer, Espal generates Postgres row-level security policies for each tenanted table. A raw query or a gap in the model then still can't cross tenants.

The guarantee breaks in these cases:

- Handler code builds a `Scope` from a request field instead of the signed-in session. The `Scope` constructor stays private to the authentication module.
- A join scopes one side only.
- A background job runs without a scope.
- A pooled connection keeps the previous request's tenant setting. Espal sets it with `SET LOCAL` inside each transaction, and a plain `SET` stays out of the code.

Every fault test in M4 also counts cross-tenant reads. The target is zero.

### P7. The database matches the declared schema (Checked at startup)

At startup the app compares the declared tables with the Postgres catalog and refuses to start on a mismatch.

The check breaks when another service changes the schema while the app runs. It also breaks when a rolling deploy runs old and new code against one schema. Migrations therefore expand first and contract later: add the new shape, deploy, then drop the old one.

### P8. Statement budget (Proved, Typed per endpoint)

`runCounting_count` shows that a `DbM n` program sends `n` statements against any database. A query per row fails to type-check, because its count depends on data.

The current form has three gaps:

- Because the index is exact, both branches of an `if` must send the same number of statements. Real handlers need an upper bound instead.
- The count covers statements the app writes. `BEGIN`, `COMMIT`, statement preparation, retries and pool health checks fall outside it, and the docs say so.
- Pipelining sends several statements per round trip, so round trips can only fall below the count. The count says nothing about what one statement costs; P9 covers that.

### P9. Row bounds and query cost (Typed, then Tested)

Every select carries a `LIMIT` or a predicate on a unique key. Each join follows a foreign key to a unique key, so a row matches at most one row on the other side. The result then holds no more rows than the limit, and no query returns an unbounded cartesian product. We can prove that bound over the model.

Rows scanned depend on indexes and the planner, which the compiler can't see. CI runs `EXPLAIN` for each declared query on a seeded database. It fails on a sequential scan of a large table or an estimate over a threshold.

The CI check misses cases where production differs. The planner may choose another plan with production data, estimates may be wrong, or an index may exist in CI and not in production. Postgres may also switch a prepared statement to a generic plan. In production, `pg_stat_statements` and a slow-query log per endpoint record the real cost.

### P10. Cost of pure code (Research track)

CSLib's `TimeM` shows the technique. A monad adds up costs in `bind`, and proofs bound the total in counted steps. It covers only code written in that style, and it counts steps rather than time.

Lean's runtime can change the real cost. `Array.set` updates in place only when nothing else refers to the array. A second reference turns an O(1) update into an O(n) copy, and the proof model can't see reference counts.

For 0.1 we ship a deadline per request, checked at every effect step (Enforced), and benchmarks for hot paths (Measured). The research track aims at a cost monad and proved bounds for the tenant app's grading functions. It succeeds only if those proofs stay short enough for app authors to write.

### P11. Stateless handlers (Typed, Proved over the interpreter, Linted)

A handler returns its effects as data instead of running them, and it has no `IO` access. Espal's interpreter runs the effects. Between requests it keeps only connection pools. Nothing here exists yet. We plan to prove over a model of the interpreter that the response depends on three inputs. They are the request, the database state, and what the declared effects return. Send the same request to another process with the same inputs, and it returns the same response.

App code can still reach process-global state. An `initialize` declaration can hold an `IO.Ref`, and `unsafeBaseIO`, `@[extern]` and `implemented_by` open other paths. An in-process cache, rate limiter or session store breaks the property too. The app audit (M2) lists every such declaration that a handler can reach.

Time, randomness and logging are effects the interpreter supplies, so they count among the request's inputs. Caches and rate limits move to Postgres or to a declared external store.

### P12. Safe HTML (Proved and Typed)

Escaped text contains no `<`, `>`, `"` or `'` (`escape_safe`). A rendered page contains one `<` per element (`renderL_countLt`), so text can't open a tag. Type classes check element nesting.

The proofs assume the prototype's closed set of attributes. They also assume that links come only from routes, which rules out `javascript:` URLs.

Some attributes and elements need their own escaping or validation and their own proof. These include external URLs, `style`, `on*` handlers, `srcdoc`, and the bodies of `<script>` and `<style>`. Our nesting rules can also disagree with the HTML5 parser, which closes or moves elements, for example inside tables. A test renders random trees, parses them with an HTML5 parser, and compares the result with the model's tree.

### P13. HTTP framing (Tested)

Std.Http rejects duplicate `Content-Length`, `Transfer-Encoding` together with `Content-Length`, repeated `Transfer-Encoding`, and `Transfer-Encoding` on HTTP/1.0. It also rejects framing fields in trailers and line endings other than CRLF. Lean's own tests cover RFC compliance, body framing and random input.

Most request smuggling comes from two parsers that disagree, such as a proxy and the server behind it. No proof about our parser covers the proxy. We turn the known smuggling cases into tests. They include conflicting `Content-Length` and `Transfer-Encoding`, obfuscated `Transfer-Encoding`, whitespace before the colon, folded header lines, bare CR, and odd chunk extensions. HTTP Garden runs against Espal behind each proxy the docs recommend. HTTP Garden is GPL-3.0, so it runs as a separate tool and stays out of Espal's releases.

If we write our own parser, we prove a round trip between its printer and parser and keep the same rejection list.

### P14. Framework totality (Linted)

Espal's library contains no `partial`, `unsafe`, `panic!` or `!` calls, and no axioms beyond the standard three.

A total function can still run for hours or exhaust memory. Deep recursion that isn't in tail position overflows the stack, and Lean then aborts the whole process. Body size limits and tail-recursive parsers keep request handling from recursing on input size.

### P15. Overload and runtime limits (Enforced, Measured)

Espal detects overload from the time requests wait in its admission queue. When the shortest wait over a window stays above a target, Espal lowers its concurrency limit. New requests then get `503` with `Retry-After`. CoDel uses the same signal for packet queues.

Lean supports deadlines on I/O and cooperative cancellation. `IO.cancel` sets a flag that code must poll. There is no CPU or memory cap per task, so a hard cap needs a separate process and a supervisor.

The single libuv loop thread may saturate before the handlers do. Accepting and parsing requests then becomes the bottleneck, and shedding can't relieve it. M4 measures where saturation starts.

### P16. Retries don't duplicate writes (Proved over the model, Tested)

We plan to prove that a write carrying an idempotency key runs at most once per key. The key and the write commit in one transaction under a unique constraint.

The guarantee breaks when the key commits outside the write's transaction. It also breaks for effects outside Postgres, such as an email or a webhook, which need a transactional outbox.

A fault test kills processes under load while clients retry, then counts rows.

### Claims Espal will not make

- Any proof about latency, throughput or memory use.
- Any proof about Postgres, the proxy, or the TypeScript runtime.
- Correctness of the generated TypeScript client beyond what tests show.
- Bounded running time for total code.
- Unlimited scaling for stateless processes. The database sets the limit.

## Example apps

Both apps live in `examples/` as separate Lake packages that depend on Espal by path. CI builds and tests them on every change, so they stay in step with the library.

### Benchmark app

The benchmark app follows the TechEmpower test rules. Its numbers then line up with published results for other frameworks. TechEmpower stopped after Round 23 and archived its repository in March 2026. We reuse the rules but can't submit.

| Endpoint | Added in |
|---|---|
| `/plaintext`, `/json` | M1 on raw Std.Http, M2 through Espal |
| `/db`, `/queries?n=`, `/updates?n=` | M3 |
| `/fortunes` (escaped list page) | M6 |

TechEmpower's rules keep the comparison fair. Every response carries `Server` and `Date` headers, and query counts stay between 1 and 500. For `/fortunes`, the app adds a row at request time and sorts in application code. One row contains `<script>`, and the output is UTF-8.

### Tenant app

**Open.** Which realistic app to build. The proposed default is a grading app shaped like the QTI domain, without QTI XML import at first. Schools are tenants, and assessments, items, submissions and grading rules live in Postgres. The app grows with each milestone.

| Milestone | What the app adds |
|---|---|
| M2 | Pure grading endpoints, such as `POST /grade`, with proofs that scores stay between zero and the item's maximum |
| M3 | Schools, assessments, items and submissions in Postgres, scoped by tenant, with statement and row budgets |
| M4 | A load profile of many students submitting at the end of an exam |
| M5 | A small TypeScript test runner built on the generated client |
| M6 | Teacher pages listing assessments and results |
| Later | QTI XML import through our own structured XML parser, which rejects DTDs and entities |

## Milestones

Milestones are outcomes without dates (**Open**). M2, M4 and M5 follow the order already agreed: macro, then load test, then TypeScript client.

### M0. Foundations (done)

The repository exists, and CI runs the build, tests, lint, a second kernel check, an axiom audit, formatting checks, and a workflow audit. `Espal.Route` provides typed routes with a round-trip proof.

### M1. Spikes and a baseline

M1 picks the HTTP layer and the Postgres client, and fixes the performance targets.

- **Toolchain.** Lean 4.35.0 has two server bugs that later releases fix. Each socket read blocks a pool thread, fixed by [lean4#15174](https://github.com/leanprover/lean4/pull/15174). The `Date` header reads the time zone database on every response. In a container without one, the server sends no response at all ([lean4#15442](https://github.com/leanprover/lean4/issues/15442), fixed by #15443 and #15469). Both fixes are in v4.36.0-rc1, released October 14. We spike on 4.35.0 and 4.36.0-rc1 and move to 4.36.0 when it ships.
- **HTTP spike.** We serve `/plaintext` and `/json` on Std.Http and measure them by the method below. First one process, then N processes on separate ports behind a proxy. Std.Http runs one libuv loop behind one lock and has no `SO_REUSEPORT` binding, so N processes are how a machine's cores get used. A bare Std.Async loop sets the ceiling for any Lean server on this runtime, and Go `net/http` on the same machine sets a reference point. We also profile the lock contention reported in [lean4#13469](https://github.com/leanprover/lean4/issues/13469).
- **Postgres spike.** We build both candidates far enough to serve `/db`.
  - libpq over FFI in non-blocking mode, with `uv_poll` on `PQsocket`. This needs a new C binding that runs under the event loop's lock.
  - A wire-protocol client in Lean with startup, SCRAM-SHA-256 sign-in, extended queries and pipelining. Managed Postgres requires TLS. Lean's runtime exposes nothing from OpenSSL beyond a version number. This path therefore also needs a TLS binding, plus the SHA-256, HMAC and PBKDF2 that SCRAM uses.
  - The comparison covers query latency, pipelined throughput, lines of C, what each lets us prove, and recovery when a connection drops mid-pipeline.
- **Exit.** Numbers in `bench/results/` with the hardware recorded, a written decision for HTTP and for Postgres, and fixed targets in the table below.
- **Failure.** The spike may show that no Lean server on this runtime gets near the throughput target. We then write our own server, which enlarges M2, or restate the target. Several processes per machine stay part of the design either way, and statelessness makes them cheap.

### M2. Endpoint macro and JSON API

- Port the prototype's `route_type` and `api` macros. The route codec moves to bytes, and helpers become private.
- An endpoint declares its method, path, parameters, body, response, typed errors and statement budget.
- A `LawfulJson` deriving handler generates the round-trip proof (P3).
- Typed errors map to status codes. A decode failure returns `400` with a machine-readable body.
- An app audit, run as a Lake script, applies `scripts/Lint.lean` to an app's modules. It lists `unsafe`, `extern`, `implemented_by`, `initialize` and extra axioms that handlers can reach (P11).
- **Tests.** A `#guard_msgs` test with the exact message for each rejection: shadowed route, unreachable endpoint, missing handler, wrong body type. Compile-time benchmarks as in P2.
- **Failure.** Errors may surface as unification failures that app authors can't read, and Lean's monthly releases break macros. We test error text, pin the toolchain, and run a non-blocking CI job against Lean nightly to catch breakage early.

### M3. Postgres and query budgets

- A typed schema; select, insert, update and delete with joins along foreign keys; the reference evaluator.
- P4, P6 and P8 ported, with upper-bound budgets. Batch lookups through `= ANY($1)`, and row bounds (P9).
- The client chosen in M1, with a connection pool, transactions and prepared statements.
- The schema check at startup (P7). **Open.** Whether Espal generates migrations from the Lean schema, or authors write them and Espal checks them against it.
- Row-level security policies for each tenanted table (P6).
- The differential tests (P5) and `EXPLAIN` checks in CI (P9).

### M4. Load testing and behavior under faults

- Benchmark scripts in `bench/` that follow the method below, and a regression job.
- Admission control (P15), deadlines per request, and `503` with `Retry-After`.
- Several processes behind a proxy, with health endpoints. On `SIGTERM` a process stops accepting, finishes requests in flight, then exits.
- Idempotency keys (P16).
- Fault runs under load. We kill a process with `SIGKILL`, stop the database primary, and cut the network to Postgres. Each run reports errors, recovery time and cross-tenant reads.
- An hour-long soak run that tracks memory growth.

### M5. TypeScript client

- Generate TypeScript types and a `fetch` client from the API description. Errors become discriminated unions. 64-bit integers become strings, with `bigint` as an option.
- **Open.** Whether to emit OpenAPI 3.1 as an intermediate format. It brings other tools along but adds a second mapping to test.
- Tests as in P3, plus a compatibility check against the previous release.

### M6. Server-rendered pages

- Port the JSX syntax and content model. Add `/fortunes` to the benchmark app and teacher pages to the tenant app.
- Forms with typed decoding. Form posts with cookies need CSRF protection through `SameSite` cookies and a token per session.
- The HTML5 parser comparison (P12).

### M7. Release 0.1

- Documentation, and a tutorial that builds one endpoint, one query and one page.
- Release binaries without GMP by default, with shared GMP as an option. Lean links against an old glibc for portability, so a release with shared GMP needs its own GMP build.
- Turn nanoda back on once lean-action can find Espal's root module, or run it in a custom step.
- A Reservoir listing, which needs at least two stars and an OSI license.

### Research tracks

None of these block 0.1.

- Cost bounds for pure code (P10).
- Our own HTTP/1.1 server, if M1 calls for it.
- Upstream fixes to Std.Http and Std.Async, such as the mutexes per request described in lean4#13469.

## Performance targets

These targets come from the earlier proposal. Agreed figures stand; we fix the rest at the end of M1.

| Target | Status |
|---|---|
| Throughput without a database within 2× of Axum and Go | **At risk.** One test ran both on the same machine (Apple M3, 64 connections). Std.Http with the lean4#15174 fix served 9,827 req/s, and Go served 170,865. That is a gap of about 17×. We restate this after M1. |
| With one Postgres read, at least 80% of a bare libpq client | Agreed |
| At 70% of peak load, p99 under 10 ms and p99.9 under 50 ms | Proposed. Measured on the benchmark app on reference hardware, by the method below. |
| At twice peak load, excess requests get a `503` within 5 ms | Proposed. Detection as in P15. |
| Three nodes reach at least 2.7× the throughput of one | Agreed. Holds until Postgres saturates. We report it with the database on its own machine. |
| Losing a node causes under 0.1% errors, all from requests in flight on that node | Proposed. Depends on proxy health checks, draining and retries of idempotent requests. |
| After a database failover, writes resume within 30 s with no duplicates | Proposed. The Postgres setup controls failover time. Espal's part is reconnecting and idempotency keys. |
| Zero cross-tenant reads during every fault test | Agreed |
| Binary under 10 MB, start-up under 100 ms | Agreed. CI checks binary size for both example apps. |

Third parties have published figures from laptops. Std.Http served about 1,600 to 2,400 req/s before the fix and 5,400 to 9,800 after it. A bare Std.Async loop served about 46,000 ([LeanAPI](https://github.com/theoriclabs/leanapi/issues/3), [lean-http-bench](https://github.com/keithadler/lean-http-bench)). These figures motivate M1 and don't replace it.

## Benchmark method

A framework's latency depends on the app. Every figure therefore names the workload (an endpoint of the benchmark app), the hardware and the settings.

- **Open-loop load.** A closed-loop tool waits for each response before it sends the next request. A stalled server then slows the load as well, and the stall drops out of the percentiles. Benchmarkers call this coordinated omission. We drive load at a fixed arrival rate instead. [oha](https://github.com/hatoo/oha) (MIT) with `-q` and `--latency-correction` is the main tool. [wrk2](https://github.com/giltene/wrk2) (Apache 2.0, unmaintained since 2019) gives a second opinion.
- **Tool check.** Before we trust a tool, we pause the server with `SIGSTOP` for one second during a run. The reported p99.9 must show the pause.
- **Procedure.** A short sweep finds the peak rate. We then run at 25, 50, 70, 90 and 200% of peak, each for 60 seconds after a warm-up, five times. Reports plot latency against arrival rate. They give the median and spread of p50, p99, p99.9 and maximum latency. They also give the error rate, CPU time per request and memory.
- **Hardware (Open).** The proposed default uses GitHub-hosted runners for compile time, binary size and instruction counts, which stay stable on shared machines. Throughput and latency runs use a dedicated machine with a fixed CPU frequency. The load generator runs on separate cores or a separate machine.
- **Comparisons.** Go `net/http`, Axum and FastAPI run the same workloads on the same machine, each written as its documentation recommends. We publish their code and settings and invite fixes, because a comparison against a badly tuned baseline tells nobody anything.
- **Regressions.** CI compares instruction counts and compile times with the main branch and fails on a large regression.

## Project risks

- **Lean's HTTP ceiling.** One libuv loop sits behind one lock. Std.Http uses about five times the CPU per request of a bare Std.Async loop (lean4#13469). We answer with several processes per machine, upstream fixes, and our own server as a fallback.
- **Proofs about the wrong thing.** Each proof covers a model: the query evaluator, the HTML tree, the Lean client. Each proved claim therefore gets a test against the real system (P3, P5, P12).
- **Escape hatches.** Apps that use raw SQL or global state lose the guarantees without any warning. The app audit lists every such spot, and row-level security backs up tenant isolation.
- **Proof burden on app authors.** If ordinary endpoints need hand-written proofs, few people will use Espal. The target is zero hand-written proofs in the benchmark app, and proofs in the tenant app only for grading rules.
- **Compile time.** Macros and proof automation slow builds. Compile-time benchmarks run in CI against a budget.
- **Toolchain churn.** Lean ships monthly releases that break metaprograms. We pin the toolchain, bump it on purpose, and keep a nightly canary job.
- **FFI crashes.** A crash in C code kills the process and every request in flight, and C bugs bypass every proof. We keep the C small, fuzz it, and run it under AddressSanitizer in CI.
- **Scope.** Our own HTTP server, our own Postgres client, cost proofs for pure code and an XML parser are each a project of their own. Each sits behind a decision point with a fallback.
- **Fooling ourselves with benchmarks.** Coordinated omission, noisy runners, code paths tuned for the benchmark, and untuned baselines all distort results. The benchmark method addresses each one.
- **Security surface.** A web framework owns cookies, sessions and CSRF protection. M6 covers CSRF, and authentication remains an open decision.
- **Licenses.** We read other projects' code to learn from it, then write our own. GPL-licensed tools such as HTTP Garden run outside the repository.
- **One maintainer.** Each milestone ships something usable on its own, and research tracks never block a release.

## Assumptions

Each of these could prove wrong. The second sentence of each says how we would find out or what would change.

- Deployments put a reverse proxy in front of Espal for TLS and to spread load over processes. Std.Http has no TLS, so a deployment without a proxy would need TLS inside Espal.
- Tenants share tables with a tenant column, as in the prototype. Schools with data residency rules might need a database per tenant, which changes P6.
- Production runs on Linux, on x86-64 and arm64, and development also runs on macOS. A request for another platform would add a CI target.
- App authors accept Lean's toolchain and its build times. Compile-time budgets and feedback on the tutorial will show whether they do.
- Espal supports the Postgres releases still maintained upstream. Pipeline mode needs libpq 14 or later, so an older client library rules out pipelining.

## Open decisions

Each has a proposed default. You haven't confirmed any of them.

1. **Where the plan lives.** This file, with GitHub milestones and issues once M1 starts.
2. **Benchmark hardware.** As in the benchmark method.
3. **Dates and contributors.** Outcome milestones without dates.
4. **Escape hatches for app authors** (raw SQL, process state, C code). Allowed, and listed by the app audit.
5. **The tenant app.** A QTI-shaped grading app without XML import at first.
6. **Sign-in for 0.1.** Built-in sessions, or an external identity provider through OpenID Connect. Schools often connect tools through LTI 1.3, which builds on OpenID Connect.
7. **Expected traffic for the QTI app.** Peak submissions per second at the end of an exam would set the first real target.
8. **The throughput target.** We restate "within 2× of Axum and Go" after M1.
9. **HTTP server and Postgres client.** The M1 spikes decide.
10. **Migrations.** Generated from the Lean schema, or written by hand and checked against it.
