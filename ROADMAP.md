# Roadmap

This plan covers Espal 0.1. It sets the scope and the order of work, and it shows how two example apps exercise each piece. It also describes how we benchmark and lists the guarantees we can claim. For each guarantee it states what the guarantee assumes and how it can break. The decisions made so far, and any still open, sit at the end.

## Goal

Espal is a batteries-included web framework for Lean 4, in the manner of Rails or Phoenix, built from packages that also work alone. It aims to be easy to use and fast enough for production APIs and server-rendered pages. Its guarantees set it apart, and the compiler or CI checks each one:

1. The server and the client agree on routes, request bodies and responses.
2. Queries carry no injected SQL, touch only the current tenant's rows, and stay within a budget per request.
3. App processes keep no state between requests, so the app scales by running more of them.

The first production app grades QTI assessments and stores its data in Postgres.

## Scope

Version 0.1 includes:

- A JSON API with typed endpoints, and a generated TypeScript client.
- Server-rendered pages in a JSX-like syntax, with forms and partial page updates in the style of htmx. The server sends HTML fragments that replace parts of the page, and it keeps no page state.
- Models declared with an attribute on ordinary Lean structures, with migrations, seed data and test fixtures generated from them.
- A query layer with a builder, query syntax in `do` notation, and statement budgets. The [database API design note](docs/design/database-api.md) compares the options we prototyped.
- Streaming request and response bodies, with typed JSON checked one element at a time.
- The defaults below, and a report for every route that shows which guarantees hold and how.
- Sign-in with sessions, passwords and OpenID Connect, plus roles and a permission check on every endpoint.
- Background jobs and scheduled tasks in a queue stored in the database, and outgoing mail sent through that queue.
- An `espal` command that creates projects, endpoints, models and migrations.

Three batteries come after 0.1. They are file uploads to S3-compatible storage, OpenTelemetry traces, metrics and logs, and HTTP caching. Caches and rate limits stay outside the app process.

Espal won't offer GraphQL, because typed REST endpoints and the generated client cover the need. It also leaves out a generated admin UI. Live views that hold page state on the server stay out too, since they would tie each browser to one process.

### Databases

Postgres comes first, and 0.1 supports only Postgres. Later adapters let apps use existing MySQL, MariaDB or SQL Server databases, and SQLite serves apps that run on it. MySQL and MariaDB go through MariaDB Connector/C, and SQL Server goes through FreeTDS. Both are LGPL, and Espal links them as shared libraries. Espal avoids libmysqlclient. Its license is GPLv2 with an exception for open-source software, and the exception doesn't cover closed-source apps.

Unit tests run on the Lean evaluator, not SQLite, so they use the same rules as the proofs. Integration tests run on each real database. The prototype had a bug in its SQL that SQLite let through and Postgres caught.

### Packages

Each battery is its own Lake package in this repository, and each works without the others. An app can take the query layer without the HTTP server, or the router without the models. The `espal` package at the root depends on all of them and sets the defaults, so most apps need one dependency.

| Package | Contents |
|---|---|
| `espal-core` | Limits, the route report, problem details, shared types |
| `espal-route` | Typed routes and links |
| `espal-json` | Lawful and streaming JSON codecs |
| `espal-http` | The server, request limits, admission control |
| `espal-query` | The query layer, budgets, the evaluator, dialects |
| `espal-model` | The model attribute, migrations, fixtures |
| `espal-page` | JSX pages, forms, partial updates |
| `espal-auth` | Sessions, passwords, OpenID Connect, permissions |
| `espal-jobs` | The job queue, scheduled tasks, mail |
| `espal-client` | The OpenAPI description and the TypeScript client |
| `espal-cli` | The `espal` command |

Package names follow `espal-<area>`, and each package's modules live under `Espal.<Area>`, such as `Espal.Query`. No package depends on one listed below it. An app that wants a single package names it with `subDir` in its `[[require]]` entry. Reservoir lists only packages at a repository root, so only `espal` appears there.

### Building on other projects

Espal prefers depending on existing Lean libraries to writing its own, and it may adapt code from permissively licensed projects when it keeps their notices. What exists today doesn't limit what Espal attempts. Where a library falls short, Espal replaces it. Going without dependencies may become a goal later. The [spikes](#spikes-and-a-baseline) evaluate four candidates.

## Defaults

Every app gets these unless it opts out. The numbers are starting points, and [load testing](#load-testing-and-behavior-under-faults) checks them.

- **Limits.** Request bodies up to 1 MiB, at most 1,000 rows per query, at most 10 statements per request, and a 5-second deadline. An app changes them in one place, and a route can override them.
- **Collections.** Lists use keyset pagination, with 25 items by default and 100 at most. Espal signs each cursor and ties it to the filters and the tenant, and responses carry `Link` headers (RFC 8288). Filtering and sorting accept only fields the route declares. Every sort ends on a unique key, so pages never overlap. Keyset pages don't form a snapshot, so rows written between requests can appear or vanish.
- **Errors.** Errors follow RFC 9457 problem details, and a validation error names the field that failed.
- **Safe writes.** Updates check `ETag` against `If-Match` and answer `412` on a mismatch, as RFC 9110 allows. Writes accept idempotency keys, using the header from the IETF draft, which expired in April 2026 without becoming an RFC. Each type declares which fields a request can write and which a response can show.
- **API description.** Espal generates an OpenAPI 3.2.1 description from the routes, and the TypeScript client comes from that description.

Three entries on the OWASP API Security Top 10 (2023) map onto these defaults:

- API1, broken object level authorization, meets scoped queries and permission checks.
- API3, broken object property level authorization, meets the declared readable and writable fields.
- API4, unrestricted resource consumption, meets the limits and budgets.

## Releases and versions

- **Versions.** All packages share one version number and release together, following Semantic Versioning. Before 1.0, a minor release such as 0.2 may break APIs and a patch release may not. Release notes list every break and how to migrate.
- **Lean.** Each release pins one stable Lean version in `lean-toolchain`. A move to a newer Lean ships as a minor release of its own, and the nightly canary job warns of breakage ahead of time. The canary also builds every dependency on the newest Lean release candidate, so a dependency that breaks shows up before Espal moves.
- **Security.** Reports go through GitHub's private vulnerability reporting, as [SECURITY.md](SECURITY.md) describes. Fixes go to the latest release. Before 0.1, only `main` gets fixes.
- **Documentation.** The documentation site uses [Verso](https://verso.lean-lang.org/doc/latest), the Lean FRO's documentation tool, under Apache 2.0. GitHub Pages serves it at `christianmurphy.github.io/espal`. Verso elaborates the Lean code in a document as it builds, which keeps examples from going stale. Its SubVerso library lets the documents use a different Lean version from the packages. The site uses the logo and favicon in `docs/brand`.
- **Name.** A check in October 2026 found `espal` free on npm, crates.io and PyPI, and found no owner for `espal.dev`. Others hold `espal.com`, `espal.org` and `espal.net`. Reservoir names each package by its owner, so `@ChristianMurphy/espal` can't collide with another. The TypeScript client needs its npm name, `espal` or a scope such as `@espal`, claimed before work on the [TypeScript client](#typescript-client) starts. MIT's Software Design Group has a research system named Espalier, a spreadsheet with database queries, in a different field.

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
- The C libraries Espal links, which are libuv, OpenSSL, libpq, MariaDB Connector/C and FreeTDS.
- The databases, the reverse proxy, the operating system and the network.

### Route report and escape hatches

An audit command prints a report for every route. It marks each guarantee listed under Properties as proved, typed, enforced at runtime, assumed, or bypassed. It also lists what the route's dependencies assume.

Escape hatches live under one name, `Espal.escape`, because Lean already uses `unsafe` for something else. Each one takes a reason and lists the guarantees it voids. Raw SQL, for example, voids [injection safety](#no-sql-injection) and the [statement](#statement-budget) and [row](#row-bounds-and-query-cost) budgets for that route, but its body limit still holds. A strict profile rejects every escape hatch in CI.

## Properties

Each property names the evidence behind it, using the kinds above.

| Property | Evidence |
|---|---|
| [Route round trip](#route-round-trip) | Proved, with one URL per resource Enforced |
| [Every endpoint is reachable](#every-endpoint-is-reachable) | Proved at compile time |
| [Client and server agree](#client-and-server-agree) | Proved for the Lean client, Tested for TypeScript |
| [No SQL injection](#no-sql-injection) | Proved |
| [The query model matches each database](#the-query-model-matches-each-database) | Tested |
| [Tenant isolation](#tenant-isolation) | Proved over the model, Enforced by Postgres and SQL Server |
| [The database matches the declared schema](#the-database-matches-the-declared-schema) | Checked at startup |
| [Statement budget](#statement-budget) | Proved, Typed per endpoint |
| [Row bounds and query cost](#row-bounds-and-query-cost) | Typed, then Tested |
| [Time and space cost of pure code](#time-and-space-cost-of-pure-code) | Research track |
| [Stateless handlers](#stateless-handlers) | Typed, Proved over the interpreter, Linted |
| [Safe HTML](#safe-html) | Proved and Typed |
| [HTTP framing](#http-framing) | Tested |
| [Framework totality](#framework-totality) | Linted |
| [Overload and runtime limits](#overload-and-runtime-limits) | Enforced, Measured |
| [Retries don't duplicate writes](#retries-dont-duplicate-writes) | Proved over the model, Tested |
| [Every endpoint checks permission](#every-endpoint-checks-permission) | Typed |
| [Background jobs run at least once](#background-jobs-run-at-least-once) | Tested |
| [Generated code passes every check](#generated-code-passes-every-check) | Tested |
| [Partial updates reach the right place](#partial-updates-reach-the-right-place) | Typed, design idea |
| [Memory per request stays within a declared bound](#memory-per-request-stays-within-a-declared-bound) | Typed, Proved over a model, Enforced |
| [Streaming decoders agree with whole-body decoders](#streaming-decoders-agree-with-whole-body-decoders) | Proved |
| [Route contracts](#route-contracts) | Proved, prototype first |

### Route round trip

A link built from a route's parameters dispatches back to that route with the same parameters. The theorem covers the path as segments, and [client and server agreement](#client-and-server-agree) uses it as a lemma. Espal proves it over lean-routing's `dispatch` and `linkFor`. A prototype of the proof took about 90 lines, with `Nat.toNat?_repr` from Lean's standard library.

Each resource gets one URL. lean-routing reaches user 42 at `/users/042`, `/users/4_2` and `/users/%34%32` as well as `/users/42`. Espal rebuilds the link from the captured values, compares it with the request's encoded path, and redirects when they differ. That check at run time also covers percent-encoding, which a proof about the parser can't reach.

The proof assumes the HTTP layer passes the path through unchanged. Percent-decoding, `..`, doubled or trailing slashes, and a proxy that rewrites paths all happen outside it. A test sends each of these cases through the real server.

### Every endpoint is reachable

The `api` macro proves that each endpoint's requests reach that endpoint and no earlier one. A shadowed endpoint fails to compile with "endpoint … is unreachable".

Each endpoint's proof steps through every earlier endpoint, so total proof time grows with the square of the endpoint count. Nobody has timed an API with 200 endpoints. Compile-time benchmarks with 10, 50 and 200 generated endpoints run in CI against a budget.

### Client and server agree

The prototype proves two theorems. `dispatch_request` shows that a request built by the client reaches the intended handler with the same parameters and body. `decode_respond` shows that the client decodes a response to the value the handler returned.

Both need a `LawfulJson` instance for every body type, meaning `fromJson? (toJson a) = .ok a`. The derived `ToJson` and `FromJson` instances of Lean and of lean-json come without that proof. Espal needs a deriving handler that generates it. The [lean-json note](docs/design/lean-json.md) states the classes and the theorem for the full trip through text.

The guarantee breaks in four places:

- JSON has no NaN or infinity, so `Float` has no lawful codec. API types reject `Float`.
- The generated TypeScript is a second implementation outside Lean. JavaScript numbers lose precision above 2^53 − 1. Following the OpenAPI int64 guidance and ProtoJSON, 64-bit and unbounded integers travel as decimal strings.
- `Option` needs one encoding. JSON has `null` and a missing key, and TypeScript adds `undefined`.
- During a rolling deploy, a browser tab running last week's client calls this week's server. The theorem covers a single version.

CI generates the client and compiles it with `tsc --strict`. A test sends random values from TypeScript through the Lean server and back. CI also compares the API description with the last release and fails on a breaking change.

### No SQL injection

`sqlText_eraseParams` shows that the SQL text depends on no parameter value. Values travel only as bind parameters.

The guarantee breaks in these cases:

- An escape hatch accepts raw SQL.
- A dynamic identifier, such as a sort column the user picks, enters the text. Identifiers come from the schema, so a sort column is an enumeration.
- A user's `%` or `_` reaches a `LIKE` pattern. That is a matching bug rather than injection, and the query layer escapes both characters.
- A batch lookup exceeds the database's limit on bind parameters. Postgres and MySQL allow 65,535 per statement, SQLite 32,766, and SQL Server 2,100. The prototypes send one parameter per key and fail on long lists. Postgres can take one array parameter with `col = ANY($1)`. The other databases need JSON table functions or, on SQL Server, table-valued parameters.
- SQL Server's `sp_executesql` accepts a whole batch of statements. Espal renders one statement per text, so the proof still holds, but the SQL Server adapter must never join texts.

### The query model matches each database

We prove facts about queries with a small evaluator written in Lean. Those facts hold in a database only where it gives the same answers.

Postgres and the evaluator disagree on integer overflow, where Postgres raises an error and Lean's `Int` grows. They also differ on three-valued `NULL` logic, collation, floating point, time zones, and `char(n)` padding. We model only the fragment where they agree. `NULL` becomes an explicit `Option`, and each Lean type maps to a database type with a checked range.

The other databases add their own gaps:

- MySQL, MariaDB and SQL Server compare text without regard to case by default, so an exact match on `ada` also finds `Ada`. Generated tables declare a case-sensitive collation.
- SQLite switches integer arithmetic to floating point on overflow, and ordinary SQLite tables accept any value in any column. Generated tables use SQLite's `STRICT` mode.
- MySQL outside strict mode, and SQL Server with `ANSI_WARNINGS OFF`, clip or truncate bad values instead of failing. Each adapter sets the session options Espal relies on when it connects.

Differential tests generate tables, rows and queries. Each query runs on the evaluator and on every database, and the test compares the rows. CI runs this for every supported release. In the prototype, the test matched SQLite and Postgres on 13 queries. It also caught Postgres sorting names its own way under an ICU English collation.

### Tenant isolation

The prototype proves that a scoped select returns only the scope's rows (`scopedSelect_tenant`). It also proves that scoped updates and deletes leave other tenants' rows unchanged (`scopedUpdate_isolation`, `scopedDelete_isolation`). These results hold in Postgres only where [the query model matches it](#the-query-model-matches-each-database).

As a second layer, Espal generates row-level security policies for each tenanted table on Postgres and SQL Server. A raw query or a gap in the model then still can't cross tenants. MySQL, MariaDB and SQLite have no row-level security, so on them tenant isolation rests on the proofs and the differential tests alone.

The guarantee breaks in these cases:

- Handler code builds a `Scope` from a request field instead of the signed-in session. The `Scope` constructor stays private to the authentication module.
- A join scopes one side only.
- A background job runs without a scope.
- A pooled connection keeps the previous request's tenant setting. On Postgres, Espal sets it with `SET LOCAL` inside each transaction, and a plain `SET` stays out of the code. SQL Server needs its own reset rule.

Every fault test in [load testing](#load-testing-and-behavior-under-faults) also counts cross-tenant reads. The target is zero.

### The database matches the declared schema

Migrations come from the models. At startup the app compares the declared tables with the database catalog and refuses to start on a mismatch.

The check breaks when another service changes the schema while the app runs. It also breaks when a rolling deploy runs old and new code against one schema. Migrations therefore expand first and contract later: add the new shape, deploy, then drop the old one.

### Statement budget

`runCounting_count` shows that a `DbM n` program sends `n` statements against any database. A query per row fails to type-check, because its count depends on data.

The current form has three gaps:

- Because the index is exact, both branches of an `if` must send the same number of statements. Real handlers need an upper bound instead.
- The count covers statements the app writes. `BEGIN`, `COMMIT`, statement preparation, retries and pool health checks fall outside it, and the docs say so.
- Pipelining sends several statements per round trip, so round trips can only fall below the count. The count says nothing about what one statement costs; [row bounds and query cost](#row-bounds-and-query-cost) covers that.

The prototype found two more problems. A budgeted program isn't a monad, so code chains `.bind` calls instead of using `do` notation. A query per row fails with `failed to synthesize instance of type class Monad (DbM 1)`, which never mentions the loop. Before 0.1, budgets need a `do`-notation form and a custom error message.

### Row bounds and query cost

Every select carries a `LIMIT` or a predicate on a unique key. Each join follows a foreign key to a unique key, so a row matches at most one row on the other side. The result then holds no more rows than the limit, and no query returns an unbounded cartesian product. We can prove that bound over the model.

Rows scanned depend on indexes and the planner, which the compiler can't see. CI runs `EXPLAIN` for each declared query on a seeded database. It fails on a sequential scan of a large table or an estimate over a threshold. Each database reports plans in its own format, so the check needs a reader for each.

The CI check misses cases where production differs. The planner may choose another plan with production data, estimates may be wrong, or an index may exist in CI and not in production. Postgres may also switch a prepared statement to a generic plan. In production, `pg_stat_statements` and a slow-query log per endpoint record the real cost.

### Time and space cost of pure code

CSLib's `TimeM` shows the technique. A monad adds up costs in `bind`, and proofs bound the total in counted steps. It covers only code written in that style, and it counts steps rather than time. CSLib trusts its cost annotations instead of checking them.

The same technique can count space. A route states its bound as a declaration, for example linear in the number of items. An app can raise or lower it without touching the proof. We found no Lean library with a space cost model today, so this is new work.

Lean's runtime can change the real cost. It reuses the memory of a value that nothing else refers to, as the paper "Counting Immutable Beans" (IFL 2019) describes. So `Array.set` updates in place only when the array has one reference. A second reference turns an O(1) update into an O(n) copy, and the proof model can't see reference counts.

For 0.1 we ship a deadline per request, checked at every effect step (Enforced). We also ship [memory bounds per request](#memory-per-request-stays-within-a-declared-bound) and benchmarks for hot paths (Measured). The research track aims at proved time and space bounds for the tenant app's grading functions. It succeeds only if those proofs stay short enough for app authors to write.

### Stateless handlers

A handler returns its effects as data instead of running them, and it has no `IO` access. Espal's interpreter runs the effects. Between requests it keeps only connection pools. Nothing here exists yet. We plan to prove over a model of the interpreter that the response depends on three inputs. They are the request, the database state, and what the declared effects return. Send the same request to another process with the same inputs, and it returns the same response.

App code can still reach process-global state. An `initialize` declaration can hold an `IO.Ref`, and `unsafeBaseIO`, `@[extern]` and `implemented_by` open other paths. An in-process cache, rate limiter or session store breaks the property too. The [route report](#route-report-and-escape-hatches) lists every such declaration that a handler can reach.

Time, randomness and logging are effects the interpreter supplies, so they count among the request's inputs. Caches and rate limits move to Postgres or to a declared external store.

### Safe HTML

Escaped text contains no `<`, `>`, `"` or `'` (`escape_safe`). A rendered page contains one `<` per element (`renderL_countLt`), so text can't open a tag. Type classes check element nesting.

The proofs assume the prototype's closed set of attributes. They also assume that links come only from routes, which rules out `javascript:` URLs.

Some attributes and elements need their own escaping or validation and their own proof. These include external URLs, `style`, `on*` handlers, `srcdoc`, and the bodies of `<script>` and `<style>`. Our nesting rules can also disagree with the HTML5 parser, which closes or moves elements, for example inside tables. A test renders random trees, parses them with an HTML5 parser, and compares the result with the model's tree.

### HTTP framing

Std.Http rejects duplicate `Content-Length`, `Transfer-Encoding` together with `Content-Length`, repeated `Transfer-Encoding`, and `Transfer-Encoding` on HTTP/1.0. It also rejects framing fields in trailers and line endings other than CRLF. Lean's own tests cover RFC compliance, body framing and random input.

Most request smuggling comes from two parsers that disagree, such as a proxy and the server behind it. No proof about our parser covers the proxy. We turn the known smuggling cases into tests. They include conflicting `Content-Length` and `Transfer-Encoding`, obfuscated `Transfer-Encoding`, whitespace before the colon, folded header lines, bare CR, and odd chunk extensions. HTTP Garden runs against Espal behind each proxy the docs recommend. HTTP Garden is GPL-3.0, so it runs as a separate tool and stays out of Espal's releases.

If we write our own parser, we prove a round trip between its printer and parser and keep the same rejection list.

### Framework totality

Espal's library contains no `partial`, `unsafe`, `panic!` or `!` calls, and no axioms beyond the standard three.

A total function can still run for hours or exhaust memory. Deep recursion that isn't in tail position overflows the stack, and Lean then aborts the whole process. Body size limits and tail-recursive parsers keep request handling from recursing on input size.

### Overload and runtime limits

Espal detects overload from the time requests wait in its admission queue. When the shortest wait over a window stays above a target, Espal lowers its concurrency limit. New requests then get `503` with `Retry-After`. CoDel uses the same signal for packet queues.

Lean supports deadlines on I/O and cooperative cancellation. `IO.cancel` sets a flag that code must poll. There is no CPU or memory cap per task, so a hard cap needs a separate process and a supervisor.

The single libuv loop thread may saturate before the handlers do. Accepting and parsing requests then becomes the bottleneck, and shedding can't relieve it. [Load testing](#load-testing-and-behavior-under-faults) measures where saturation starts. In the [HTTP spike](bench/results/http/2026-10-18-cloud-4vcpu/README.md), Std.Http spent about 540 µs of CPU on each `/plaintext` request, mostly on handoffs between threads. A `503` takes the same path, so at twice peak load the proxy sheds the excess.

### Retries don't duplicate writes

We plan to prove that a write carrying an idempotency key runs at most once per key. The key and the write commit in one transaction under a unique constraint.

The guarantee breaks when the key commits outside the write's transaction. It also breaks for effects outside Postgres, such as an email or a webhook, which need a transactional outbox.

A fault test kills processes under load while clients retry, then counts rows.

### Every endpoint checks permission

Each endpoint declares the permission it needs, and the `api` macro rejects an endpoint that declares none. A public endpoint says so explicitly. The handler receives a value that only the permission check can construct, so a handler that skips the check fails to compile.

The [spikes](#spikes-and-a-baseline) try cedar-lean as the permission engine. Cedar's Lean model proves three things. It denies a request unless a policy permits it. A forbid policy beats any permit. Its policy validator is sound. Cedar checks its Rust engine against that model with differential tests.

The guarantee breaks in these cases:

- The permission rules themselves are wrong. The rules are the specification, so tests check them against examples.
- A permission depends on data, such as a teacher seeing only their own classes. That needs query scoping in the manner of [tenant isolation](#tenant-isolation), not only a check at the door.
- Sign-in can fail in its own ways. Tests cover password hashing, session key rotation, token checks for OpenID Connect, and limits on sign-in attempts, which live outside the process.

### Background jobs run at least once

A job enters the queue in the same transaction as the write that caused it. Workers claim jobs with row locks that skip rows already locked, so two workers never take the same job. A worker that dies mid-job leaves it to run again. Jobs therefore run at least once and must tolerate a repeat; the [idempotency keys](#retries-dont-duplicate-writes) apply. Statement budgets cover jobs as they cover requests.

Mail goes through the queue. A worker that crashes after the mail provider accepts a message, but before the job finishes, sends it twice. Providers that accept an idempotency key prevent the duplicate.

The claim breaks on SQLite, which allows one writer at a time and has no row locks, so SQLite apps run one worker. A fault test kills workers mid-job and counts how often each job ran and each message went out.

Veil, a Lean framework for transition systems (Apache 2.0, CAV 2025), could prove the claim protocol safe across every interleaving of workers. It covers safety properties only, and its 2.0 release is still a pre-release, so this stays a research track.

### Generated code passes every check

CI runs the `espal` generators to create a project with an endpoint, a model and a migration. It then builds that project with `--wfail`, checks its route report, and runs its tests. The job fails as soon as the generators fall behind the library.

### Partial updates reach the right place

A fragment endpoint returns HTML for a named target on a page. If pages name targets with typed references instead of CSS selectors, the compiler can check that the target exists on the page. It can also check that the target's content model accepts the fragment, for example that a table row goes into a table body. Nobody has prototyped this yet.

The check can't see changes that client scripts make after the page loads, or a target chosen at runtime.

### Memory per request stays within a declared bound

Each route's limits give it a memory bound that grows at most linearly in them. The limits are body bytes, [rows per query](#row-bounds-and-query-cost), streamed array elements, and response bytes. An app sets them once, and a route can override them. Over a cost model of Espal's own buffers, we plan to prove that decoding, reading rows and rendering stay within the bound.

Before running a request, Espal reserves its bound from a fixed memory pool. A request that doesn't fit waits in the [admission queue](#overload-and-runtime-limits), and it gets `503` once the queue is full. The edge cases have fixed answers:

- A body whose `Content-Length` exceeds the limit gets `413` before Espal reads it. Espal counts a chunked body as it arrives and cuts it off with `413` at the limit.
- A route whose bound exceeds the whole pool is a configuration error, and the app refuses to start.
- When a handler reads a streamed body slowly, Espal stops reading from the socket, so unread input waits in the kernel's socket buffer.

The guarantee breaks in these cases:

- Handler code allocates outside Espal's buffers, for example by building a large list. Espal counts only code written in the [cost style for pure code](#time-and-space-cost-of-pure-code).
- C libraries allocate on their own. libpq holds a whole result in C memory unless the client uses single-row mode.
- Lean's runtime can't attribute memory to a request. Heartbeats count small allocations per thread rather than bytes, they miss large objects, and requests move between threads. Enforcement therefore counts the bytes Espal buffers, not every allocation.

Tests run each route alone at its limits and compare the process's peak memory with the bound. Until [load testing](#load-testing-and-behavior-under-faults) calibrates the model, an overrun shows up in the route report. After that milestone, it fails CI. A process-level limit in production catches what the model misses.

### Streaming decoders agree with whole-body decoders

Decoders derived from types read JSON as it arrives and check each element on arrival. A handler can then take a large array one element at a time. We plan to prove that any split of the input into chunks gives the same result as decoding the whole body. We also plan to prove that a malformed element fails the request before the decoder reads past it.

Nesting depth gets its own limit, because a deeply nested body would otherwise recurse on input size, which [framework totality](#framework-totality) rules out. Duplicate object keys and numbers too large for the target type are errors. MessagePack follows after 0.1. Its length prefixes let a decoder skip parts a handler doesn't need without parsing them.

### Route contracts

A route may state a postcondition, such as "the response belongs to the requested student". Lean's `vcgen` tactic, built on the `Std.WP` library, turns a program and its postcondition into proof goals, and it handles embedded languages as well as monads. It first shipped in Lean 4.33, and the 4.35 release notes present it as the successor to `mvcgen`. It still needs `set_option experimental.vcgen true`, and its interface is moving again on Lean's main branch. The [query layer milestone](#query-layer-models-and-postgres) tries one contract on a tenant-app route before 0.1 commits to the feature.

### Claims Espal will not make

- Any proof about latency or throughput, or about the process's real memory use.
- Any proof about a database, the proxy, or the TypeScript runtime.
- Correctness of the generated TypeScript client beyond what tests show.
- Bounded running time for total code.
- Jobs or mail delivered once and only once.
- Unlimited scaling for stateless processes. The database sets the limit.

## Example apps

Both apps live in `examples/` as separate Lake packages that depend on Espal by path. CI builds and tests them on every change, so they stay in step with the library.

### Benchmark app

The benchmark app follows the TechEmpower test rules. Its numbers then line up with published results for other frameworks. TechEmpower stopped after Round 23 and archived its repository in March 2026. We reuse the rules but can't submit.

| Endpoint | Added in |
|---|---|
| `/plaintext`, `/json` | [Spikes](#spikes-and-a-baseline) on raw Std.Http, [packages and JSON API](#packages-endpoints-and-the-json-api) through Espal |
| `/db`, `/queries?n=`, `/updates?n=` | [Query layer](#query-layer-models-and-postgres) |
| `/fortunes` (escaped list page) | [Pages](#server-rendered-pages) |

TechEmpower's rules keep the comparison fair. Every response carries `Server` and `Date` headers, and query counts stay between 1 and 500. For `/fortunes`, the app adds a row at request time and sorts in application code. One row contains `<script>`, and the output is UTF-8.

### Tenant app

The tenant app grades assessments shaped like the QTI domain, without QTI XML import at first. Schools are tenants, and assessments, items, submissions and grading rules live in Postgres. The app grows with each milestone.

| Milestone | What the app adds |
|---|---|
| [Packages and JSON API](#packages-endpoints-and-the-json-api) | Pure grading endpoints, such as `POST /grade`, with proofs that scores stay between zero and the item's maximum |
| [Query layer](#query-layer-models-and-postgres) | Schools, assessments, items and submissions in Postgres, scoped by tenant, with statement and row budgets |
| [Load testing](#load-testing-and-behavior-under-faults) | The exam-end burst from the performance targets: 100,000 submissions in one minute |
| [TypeScript client](#typescript-client) | A small TypeScript test runner built on the generated client |
| [Pages](#server-rendered-pages) | Teacher pages listing assessments and results |
| [Sign-in](#sign-in-and-permissions) | Sign-in for teachers and students, with teachers seeing only their own classes |
| [Jobs and mail](#background-jobs-and-mail) | Regrading an assessment as a background job, with results sent by mail |
| Later | QTI XML import through our own structured XML parser, which rejects DTDs and entities |

## Milestones

Milestones are outcomes without dates. They run in the order below, which keeps the agreed sequence of macro, then load test, then TypeScript client.

### Foundations

We finished this milestone. The repository exists, and CI runs the build, tests, lint, a second kernel check, an axiom audit, formatting checks, and a workflow audit. `Espal.Route` provides typed routes with a round-trip proof.

CI also runs `lake check`, which builds the project in a bubblewrap sandbox, replays every declaration through the kernel, and rejects axioms beyond the standard ones. A weekly job runs `lake check --paranoid`, which adds nanoda and the other checkers that Lean bundles.

### Spikes and a baseline

Here we pick the HTTP layer, the Postgres client and the libraries we keep. We also fix the numbers in the performance targets.

- **Toolchain.** Lean 4.35.0 has two server bugs that later releases fix. Each socket read blocks a pool thread, fixed by [lean4#15174](https://github.com/leanprover/lean4/pull/15174). The `Date` header reads the time zone database on every response. In a container without one, the server sends no response at all ([lean4#15442](https://github.com/leanprover/lean4/issues/15442), fixed by #15443 and #15469). Both fixes are in v4.36.0-rc1, released October 14. We spike on 4.35.0 and 4.36.0-rc1 and move to 4.36.0 when it ships.
- **HTTP spike (done).** We served `/plaintext` and `/json` on Std.Http, a bare Std.Async loop and Go `net/http`, on Lean 4.35.0 and 4.36.0-rc1. The [results](bench/results/http/2026-10-18-cloud-4vcpu/README.md) come from a shared 4-vCPU cloud VM with shortened runs, so they guide the choice and stay out of published claims.
  - On 4.36.0-rc1, Std.Http served about 4,300 requests per second on two CPUs, 4.6 percent of Go. On 4.35.0 it served about 900.
  - Std.Http spent ten times the CPU per request of the bare loop. The bare loop reached 29 percent of Go, so a server of our own has room to grow but stays well behind Go.
  - Two processes pinned to one CPU each, behind haproxy, served 2.8 times as much as one process on both CPUs. The proxy itself cost almost nothing.
  - A profile put 42 percent of Std.Http's time in the kernel scheduler, at 26 context switches per request. Mutexes took about 2 percent. The cost comes from handing each async step to another thread, which [lean4#13469](https://github.com/leanprover/lean4/issues/13469) also describes.
  - `Lean.Data.Json` made the server binary 120 MB, against 7.7 MB with a small encoder.
- **Postgres spike (done).** We built two clients far enough to serve `/db`, both on Lean 4.36.0-rc1. The [results](bench/results/postgres/2026-10-18-cloud-4vcpu/README.md) come from the same cloud VM as the HTTP spike, with Postgres on one CPU.
  - The libpq client is 160 lines of C around libpq in pipeline mode. Lean doesn't let a C binding wait on a socket inside its event loop, so each connection has its own thread. With four connections it reached 48,062 queries per second, the Postgres core's limit, at 34 µs of client CPU per query.
  - The wire client is pure Lean, with SCRAM-SHA-256 sign-in and pipelining. It stopped at 23,955 queries per second at 61 µs per query, because all its I/O shares Lean's one event loop. It has no TLS, and nobody has reviewed its hashing code.
  - Over HTTP, Std.Http set the limit for both. `/db` served 3,741 requests per second with libpq and 3,283 with the wire client. The same server served 4,383 for `/plaintext`, and Go with pgx served 21,602 for `/db`.
  - Both recovered on their own when Postgres killed their connections or restarted, in about 0.1 and 2.3 seconds, with no hung requests.
  - The libpq server links 24 shared libraries at run time, among them OpenSSL, Kerberos and LDAP.
- **Dependency spikes.** We build each candidate on Espal's toolchain, measure it against what Espal needs, and write down whether we keep or replace it. The candidates pin Lean versions from 4.33 to 4.35 today.
  - lean-linq (MIT) as the query layer (done). Espal builds on its core with its own Postgres client, and sends changes upstream first. It passed its tests on Lean 4.35.0 and 4.36.0-rc1, and its budgets close most gaps in the [statement budget](#statement-budget). A module can't import it yet, its warnings fail `--wfail`, and its build needs all four client libraries. Moving its MySQL driver to MariaDB Connector/C took four changed lines. The [decision note](docs/design/lean-linq.md) lists what has to change upstream.
  - lean-routing (Apache 2.0) as the router (done). Espal builds its routes on it as it is. On Lean 4.35.0 and 4.36.0-rc1 it built with no warnings and passed its tests. Espal adds the link round-trip proof, a reachability check, and a redirect to each resource's one URL. The [decision note](docs/design/lean-routing.md) has the details.
  - LeanIO (MIT) for streamed multipart uploads, ranges and ETags (done). Espal writes its own after 0.1 ships, when uploads and HTTP caching arrive. LeanIO's multipart parser loses the start of a field that spans two chunks, and its executables are 120 MB. The [decision note](docs/design/leanio.md) has the details.
  - cedar-lean (Apache 2.0) as the permission engine (done). Espal checks permissions with its authorizer and sends changes upstream first. Its proofs cover [every endpoint checks permission](#every-endpoint-checks-permission), and a check took 6.7 µs. A program that uses it is 119 MB until Batteries and cedar-lean keep the Lean package out of their run-time imports. The [decision note](docs/design/cedar-lean.md) has the details.
- **Exit.** Numbers in `bench/results/` with the hardware recorded, a written decision for HTTP, Postgres and each dependency, and fixed targets in the table below.
- **Failure.** The spike may show that no Lean server on this runtime gets near the throughput target. We then write our own server, which adds to the work in [packages, endpoints and the JSON API](#packages-endpoints-and-the-json-api), or restate the target. Several processes per machine stay part of the design either way, and statelessness makes them cheap.



### Packages, endpoints and the JSON API

- Split the repository into the packages listed under Scope, with the `espal` package at the root.
- Build the `api` macro on [lean-routing](docs/design/lean-routing.md)'s routes, with the reachability check on top. The route codec moves to bytes, and helpers become private.
- An endpoint declares its method, path, parameters, body, response, typed errors, permission and statement budget.
- JSON on [lean-json](docs/design/lean-json.md), which imports only `Std`. `Lean.Data.Json` makes a server binary 120 MB, well over the 10 MB target. A `LawfulJson` deriving handler generates the round-trip proof that [client and server agreement](#client-and-server-agree) needs, and [streaming decoders](#streaming-decoders-agree-with-whole-body-decoders) come with the chunk-split proof.
- Errors use problem details. A decode failure returns `400` and names the field.
- The default limits, memory bounds per request, `413` for oversized bodies, and the [memory pool](#memory-per-request-stays-within-a-declared-bound). Espal raises Std.Http's limit of 100 requests per keep-alive connection, which forces a proxy to reconnect often.
- The route report and `Espal.escape`. The report includes what the earlier app audit found: `unsafe`, `extern`, `implemented_by`, `initialize` and extra axioms that handlers can reach, as [stateless handlers](#stateless-handlers) describes.
- The OpenAPI 3.2.1 description.
- **Tests.** A `#guard_msgs` test with the exact message for each rejection: shadowed route, unreachable endpoint, missing handler, wrong body type. Compile-time benchmarks as described under [every endpoint is reachable](#every-endpoint-is-reachable).
- **Failure.** Errors may surface as unification failures that app authors can't read, and Lean's monthly releases break macros. We test error text, pin the toolchain, and run a non-blocking CI job against Lean nightly to catch breakage early. The same job builds each dependency on the newest Lean release candidate.

### Query layer, models and Postgres

- The query core from [lean-linq](docs/design/lean-linq.md), with table variables that the interpreter supplies. Models declared with an attribute, the builder, and query syntax in `do` notation sit on top.
- Statement budgets with upper bounds and `do` notation. The proofs for [injection](#no-sql-injection), [tenant isolation](#tenant-isolation), [statement budgets](#statement-budget) and [row bounds](#row-bounds-and-query-cost) carry over, with batch lookups through `= ANY($1)`.
- Collections and safe writes from the defaults.
- The libpq client behind Espal's own client interface, with pipelining, transactions, prepared statements, and single-row mode for streamed results. Its pool waits for a reconnecting connection, where the spike's pool failed requests at once.
- Migrations, seed data and fixtures generated from the models, and the [schema check at startup](#the-database-matches-the-declared-schema).
- [Row-level security](#tenant-isolation) policies for each tenanted table.
- The [differential tests](#the-query-model-matches-each-database) and [`EXPLAIN` checks](#row-bounds-and-query-cost) in CI.
- One [route contract](#route-contracts) on a tenant-app route, checked with `vcgen`.

### Load testing and behavior under faults

- Benchmark scripts in `bench/` that follow the method below, and a regression job.
- [Admission control](#overload-and-runtime-limits), deadlines per request, and `503` with `Retry-After`.
- Several processes behind a proxy, with health endpoints. On `SIGTERM` a process stops accepting, finishes requests in flight, then exits.
- [Idempotency keys](#retries-dont-duplicate-writes).
- Fault runs under load. We stop a process with `SIGTERM`, kill one with `SIGKILL`, stop the database primary, and cut the network to Postgres. Each run reports errors, recovery time and cross-tenant reads.
- An hour-long soak run that tracks memory growth.
- A check of the default limits under load. We also measure each example route's peak memory at its limits, as [memory per request](#memory-per-request-stays-within-a-declared-bound) describes.

### TypeScript client

- Generate the TypeScript client from the OpenAPI description. Errors become discriminated unions. 64-bit integers become strings, with `bigint` as an option.
- The tests from [client and server agreement](#client-and-server-agree), plus a compatibility check against the previous release.

### Server-rendered pages

- Port the JSX syntax and content model. Add `/fortunes` to the benchmark app and teacher pages to the tenant app.
- Partial page updates, with fragment routes typed like pages. The [target check](#partial-updates-reach-the-right-place) comes in if a prototype shows it works.
- Forms with typed decoding. Form posts with cookies need CSRF protection through `SameSite` cookies and a token per session.
- The HTML5 parser comparison from [safe HTML](#safe-html).

### Sign-in and permissions

- Sessions, passwords, OpenID Connect and roles.
- A [permission check on every endpoint](#every-endpoint-checks-permission), built on cedar-lean's authorizer.
- Limits on sign-in attempts, stored outside the process.

### Background jobs and mail

- A job queue in the database, scheduled tasks, and mail sent through the queue. Jobs [run at least once](#background-jobs-run-at-least-once).
- Fault tests that kill workers mid-job.

### CLI and generators

- The `espal` command, which creates projects, endpoints, models and migrations.
- The CI job that checks [generated code](#generated-code-passes-every-check).

### Release 0.1

- The Verso documentation site, with a tutorial that builds one endpoint, one query and one page.
- Release binaries without GMP by default, with shared GMP as an option. They link libpq built without Kerberos and LDAP, or ship it beside the binary. Lean links against an old glibc for portability, so a release with shared GMP needs its own GMP build.
- A Reservoir listing for the `espal` package, which needs at least two stars and an OSI license.

### Other databases

0.1 supports only Postgres. The [query layer](#query-layer-models-and-postgres) work sets the shape each new database plugs into.

- SQLite through leansqlite, the Lean FRO's binding under Apache 2.0. MySQL and MariaDB through MariaDB Connector/C, and SQL Server through FreeTDS.
- Dialect features gated by type classes, with differential tests and an `EXPLAIN` reader for each database.

### Research tracks

None of these block 0.1.

- [Time and space cost of pure code](#time-and-space-cost-of-pure-code).
- Our own HTTP/1.1 server on Std.Async. The HTTP spike found room for up to six times Std.Http's throughput on the same runtime.
- Upstream fixes to Std.Http and Std.Async, such as fewer thread handoffs per request (lean4#13469). C bindings also need a way to wait on a socket inside the event loop. After a [question on Zulip](https://leanprover.zulipchat.com/#narrow/channel/270676-lean4/topic/Waiting.20on.20a.20C.20library.27s.20socket.20in.20Std.2EAsync/with/632829791), [lean4#15769](https://github.com/leanprover/lean4/issues/15769) proposes a way to do that.
- A Postgres client in pure Lean, grown from the spike's wire client, once Lean has TLS and a faster event loop.
- A proof of the [job claim protocol](#background-jobs-run-at-least-once) in Veil.
- MessagePack, after the [streaming decoders](#streaming-decoders-agree-with-whole-body-decoders) for JSON.
- Fewer dependencies, once Espal knows which ones it keeps.

## Performance targets

These targets come from the earlier proposal, and we fixed their figures after the [spikes](#spikes-and-a-baseline). The database failover row waits for the Postgres client to hold requests while it reconnects.

| Target | Status |
|---|---|
| Comparison with Go and Axum | Reported, with no promised ratio. The exam-end burst below is the throughput goal. In our [HTTP spike](bench/results/http/2026-10-18-cloud-4vcpu/README.md), Std.Http on Lean 4.36.0-rc1 served 4.6 percent of Go's rate on the same two CPUs. That gap is about 22×. An earlier third-party test on an Apple M3 found about 17×. |
| With one Postgres read, at least 80% of a bare libpq client | Agreed. In the [Postgres spike](bench/results/postgres/2026-10-18-cloud-4vcpu/README.md), the libpq client matched a bare C client, as both reached the Postgres core's limit. |
| At 70% of peak load, p99 under 15 ms and p99.9 under 50 ms | Agreed. Measured on the benchmark app on reference hardware, by the method below. The [HTTP spike](bench/results/http/2026-10-18-cloud-4vcpu/README.md) ran on a shared VM. On that VM, Std.Http reached a p99 of 9.7 to 11.6 ms and a p99.9 of 17 to 25 ms. |
| At twice peak load, the proxy answers excess requests with `503` within 5 ms | Agreed. The proxy holds a connection limit for each process and a short queue timeout. Espal's [admission queue](#overload-and-runtime-limits) limits the requests that get through. |
| Three nodes reach at least 2.7× the throughput of one | Agreed. Holds until Postgres saturates. We report it with the database on its own machine. |
| Losing a node causes under 0.1% errors, all from requests in flight on that node | Agreed. Counted over a 60-second run at the exam-end rate of 1,700 requests per second, killing the node at 30 s. Depends on proxy health checks and retries of idempotent requests. |
| Stopping a process with `SIGTERM` causes no errors | Agreed. The process stops accepting, finishes the requests in flight, then exits. |
| After a database failover, writes resume within 30 s with no duplicates | Proposed. The Postgres setup controls failover time. Espal's part is reconnecting and idempotency keys. In the [Postgres spike](bench/results/postgres/2026-10-18-cloud-4vcpu/README.md), the pool failed requests that landed on a reconnecting connection. |
| Zero cross-tenant reads during every fault test | Agreed |
| At the end of an exam, 100,000 submissions arrive within one minute, about 1,700 per second. Espal stores all of them, loses none and stores none twice. | Agreed. A second run sends half of them in the last ten seconds, about 5,000 per second, to test the admission queue. |
| Binary under 10 MB, start-up under 100 ms | Agreed. CI checks binary size for both example apps. |

Third parties have published figures from laptops. Std.Http served about 1,600 to 2,400 req/s before the fix and 5,400 to 9,800 after it. A bare Std.Async loop served about 46,000 ([LeanAPI](https://github.com/theoriclabs/leanapi/issues/3), [lean-http-bench](https://github.com/keithadler/lean-http-bench)). These figures motivate the [spikes](#spikes-and-a-baseline) and don't replace them.

## Benchmark method

A framework's latency depends on the app. Every figure therefore names the workload (an endpoint of the benchmark app), the hardware and the settings.

- **Open-loop load.** A closed-loop tool waits for each response before it sends the next request. A stalled server then slows the load as well, and the stall drops out of the percentiles. Benchmarkers call this coordinated omission. We drive load at a fixed arrival rate instead. [oha](https://github.com/hatoo/oha) (MIT) with `-q` and `--latency-correction` is the main tool. [wrk2](https://github.com/giltene/wrk2) (Apache 2.0, unmaintained since 2019) gives a second opinion.
- **Tool check.** Before we trust a tool, we pause the server with `SIGSTOP` for one second during a run. The reported p99.9 must show the pause.
- **Procedure.** A short sweep finds the peak rate. We then run at 25, 50, 70, 90 and 200% of peak, each for 60 seconds after a warm-up, five times. Reports plot latency against arrival rate. They give the median and spread of p50, p99, p99.9 and maximum latency. They also give the error rate, CPU time per request and memory.
- **Hardware.** GitHub-hosted runners measure compile time, binary size and instruction counts, which stay stable on shared machines. Espal publishes no absolute latency or throughput figures until a dedicated machine with a fixed CPU frequency runs them. That machine arrives by the end of [load testing](#load-testing-and-behavior-under-faults) at the latest. The load generator runs on separate cores or a separate machine.
- **Comparisons.** Go `net/http`, Axum and FastAPI run the same workloads on the same machine, each written as its documentation recommends. We publish their code and settings and invite fixes, because a comparison against a badly tuned baseline tells nobody anything.
- **Regressions.** CI compares instruction counts and compile times with the main branch and fails on a large regression.

## Project risks

- **Lean's HTTP ceiling.** In the [HTTP spike](bench/results/http/2026-10-18-cloud-4vcpu/README.md), Std.Http used ten times the CPU per request of a bare Std.Async loop. Most of it went to handoffs between threads (lean4#13469). We answer with one process per core, upstream fixes, and our own server as a fallback.
- **Proofs about the wrong thing.** Each proof covers a model: the query evaluator, the HTML tree, the Lean client, the memory model of Espal's buffers. Each proved claim therefore gets a test against the real system. The sections on [client and server agreement](#client-and-server-agree), [the query model](#the-query-model-matches-each-database), [safe HTML](#safe-html) and [memory per request](#memory-per-request-stays-within-a-declared-bound) describe those tests.
- **Escape hatches.** Apps that use raw SQL or global state lose guarantees. The route report names every escape hatch and what it voids, and the strict profile rejects them. Row-level security backs up tenant isolation on Postgres and SQL Server.
- **Proof burden on app authors.** If ordinary endpoints need hand-written proofs, few people will use Espal. The target is zero hand-written proofs in the benchmark app, and proofs in the tenant app only for grading rules.
- **Compile time.** Macros and proof automation slow builds. Compile-time benchmarks run in CI against a budget.
- **Toolchain churn.** Lean ships monthly releases that break metaprograms. We pin the toolchain, bump it on purpose, and keep a nightly canary job.
- **Dependencies.** A build compiles every package with a single Lean version, and `lake update` raises it to the newest that a direct dependency pins. Each library moves at its own pace, so a Lean upgrade waits until all of them compile on the new version. The canary job finds that breakage early. Fixes go upstream first, like the lean-linq pull request that replaces `String.data`, which Lean 4.36 removed. Espal's lint doesn't cover dependencies, so the route report lists their axioms and their `partial` and `unsafe` declarations.
- **Experimental proof tools.** `vcgen` is experimental in Lean 4.35, and its interface is moving again on Lean's main branch. [Route contracts](#route-contracts) wait on a prototype in the [query layer milestone](#query-layer-models-and-postgres).
- **FFI crashes.** A crash in C code kills the process and every request in flight, and C bugs bypass every proof. We keep the C small, fuzz it, and run it under AddressSanitizer in CI. Espal links four C client libraries once every database adapter exists.
- **More databases, more testing.** Each database needs its SQL tested against a real server in CI. Each also departs from the evaluator in its own ways, as [the query model](#the-query-model-matches-each-database) describes.
- **Scope.** 0.1 carries four batteries on top of the core: models and migrations, sign-in and permissions, jobs and mail, and the CLI. With one maintainer, that pushes 0.1 well out. Our own HTTP server, a Postgres client, cost proofs for pure code and an XML parser would each be a project of their own too. Each sits behind a decision point with a fallback, and the packages can ship one at a time.
- **Fooling ourselves with benchmarks.** Coordinated omission, noisy runners, code paths tuned for the benchmark, and untuned baselines all distort results. The benchmark method addresses each one.
- **Security surface.** A web framework owns cookies, sessions and CSRF protection. The milestone for [server-rendered pages](#server-rendered-pages) covers CSRF, and the one for [sign-in](#sign-in-and-permissions) covers sign-in.
- **Licenses.** Adapted code keeps its license notice, and LGPL libraries stay shared. GPL-licensed tools such as HTTP Garden run outside the repository.
- **One maintainer.** Each milestone ships something usable on its own, and research tracks never block a release.

## Assumptions

Each of these could prove wrong. The second sentence of each says how we would find out or what would change.

- Deployments put a reverse proxy in front of Espal for TLS and to spread load over processes. Std.Http has no TLS, so a deployment without a proxy would need TLS inside Espal.
- Tenants share tables with a tenant column, as in the prototype. Schools with data residency rules might need a database per tenant, which changes [tenant isolation](#tenant-isolation).
- Production runs on Linux, on x86-64 and arm64, and development also runs on macOS. A request for another platform would add a CI target.
- App authors accept Lean's toolchain and its build times. Compile-time budgets and feedback on the tutorial will show whether they do.
- Espal supports the Postgres releases still maintained upstream. Pipeline mode needs libpq 14 or later, so an older client library rules out pipelining.
- Apps on MySQL, MariaDB or SQLite accept tenant isolation without a layer the database enforces. If schools require one, those adapters need another mechanism, such as a database per tenant.

## Decisions so far

These came out of the planning discussion in October 2026.

- **Scope.** Batteries included, built from packages in one repository that also work alone.
- **Example apps.** A benchmark app and a realistic multi-tenant app.
- **HTTP layer.** Std.Http from Lean 4.36, run as one process per core behind a proxy. A server of our own stays a research track.
- **Postgres client.** libpq in pipeline mode, behind Espal's own client interface. The pure-Lean wire client stays a research track.
- **Budgets.** Statements, rows and query cost, and the cost of pure code, with runtime limits as a backstop. Proofs come first.
- **Memory.** A bound per request from declared limits, streaming by default with each element checked on arrival, and declarative space bounds for pure code.
- **Reuse.** Prefer existing libraries, and keep the notices of any adapted code. What exists today doesn't limit what Espal attempts.
- **GMP.** A shared library or none.
- **Left out.** GraphQL, a generated admin UI, and live views.
- **Databases.** Postgres first, then SQLite, MySQL, MariaDB and SQL Server through adapters after 0.1, with LGPL client libraries linked as shared libraries.
- **Query layer.** Models through an attribute and the builder first, query syntax in `do` notation, and a core whose table variables the interpreter supplies.
- **Tests.** Unit tests on the Lean evaluator, integration tests on real databases.
- **Pages.** Partial updates in the style of htmx.
- **Defaults.** Collections, problem details, safe writes, and an OpenAPI 3.2.1 description.
- **Streaming.** Typed JSON in 0.1, MessagePack later.
- **Route report.** One per route, with named escape hatches and a strict profile.
- **Contracts.** One prototype with `vcgen` in the query layer milestone before committing.
- **Candidate dependencies.** lean-linq, lean-routing, LeanIO and cedar-lean, each evaluated during the spikes, and lean-json after them.
- **Query core.** lean-linq's core, run by Espal's own Postgres client. Changes go upstream first, and a copy with its MIT notice is the fallback.
- **Router.** lean-routing as it is, with Espal's endpoints, reachability check and canonical-path redirect on top. A copy with its Apache 2.0 notice is the fallback.
- **Permission engine.** cedar-lean's authorizer, with changes upstream first. A copy of `Cedar.Spec` with its Apache 2.0 notice is the fallback.
- **Uploads, ranges and ETags.** Espal's own, with a chunk-split proof for the multipart parser. LeanIO stays out.
- **JSON.** lean-json, with a round-trip class whose instances a deriving handler proves. Changes go upstream first, and a copy with its Apache 2.0 notice is the fallback.
- **Tenant app.** A QTI-shaped grading app, without XML import at first.
- **Load target.** 100,000 submissions within one minute at the end of an exam.
- **Databases in 0.1.** Postgres only.
- **Benchmark hardware.** GitHub runners for regression checks now, and a dedicated machine for published latency figures by the end of load testing.
- **Throughput goal.** The exam-end burst. Comparisons with Go and Axum get reported without a promised ratio.
- **Where the plan lives.** This file, with a [GitHub milestone](https://github.com/ChristianMurphy/espal/milestones) and issues for each roadmap milestone.
- **Dates.** None. A milestone ends when its exit criteria pass.
- **Contributors.** You and Claude until 0.1. Outside pull requests open after the first release.
- **Memory in CI.** Overruns get reported until load testing calibrates the model, and fail CI after that.
- **Package names.** `espal-<area>`, with modules under `Espal.<Area>`.
- **SQLite binding.** leansqlite, when SQLite support arrives after 0.1.
- **Versions.** One version for all packages, following Semantic Versioning.
- **Lean versions.** One stable Lean version per release.
- **Security reports.** GitHub's private vulnerability reporting.
- **Documentation.** A Verso site on GitHub Pages.
- **Order of the spikes.** Open the issues, then run the HTTP spike first.

## Open decisions

None right now. The library trials settle which dependencies Espal keeps.
