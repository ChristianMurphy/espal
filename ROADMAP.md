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

Espal prefers depending on existing Lean libraries to writing its own, and it may adapt code from permissively licensed projects when it keeps their notices. What exists today doesn't limit what Espal attempts. Where a library falls short, Espal replaces it. Going without dependencies may become a goal later. M1 evaluates four candidates.

## Defaults

Every app gets these unless it opts out. The numbers are starting points that M4 checks under load.

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
- **Lean.** Each release pins one stable Lean version in `lean-toolchain`. A move to a newer Lean ships as a minor release of its own, and the nightly canary job warns of breakage ahead of time.
- **Security.** Reports go through GitHub's private vulnerability reporting, as [SECURITY.md](SECURITY.md) describes. Fixes go to the latest release. Before 0.1, only `main` gets fixes.
- **Documentation.** The documentation site uses [Verso](https://verso.lean-lang.org/doc/latest), the Lean FRO's documentation tool, under Apache 2.0. GitHub Pages serves it at `christianmurphy.github.io/espal`. Verso elaborates the Lean code in a document as it builds, which keeps examples from going stale. Its SubVerso library lets the documents use a different Lean version from the packages. The site uses the logo and favicon in `docs/brand`.
- **Name.** A check in October 2026 found `espal` free on npm, crates.io and PyPI, and found no owner for `espal.dev`. Others hold `espal.com`, `espal.org` and `espal.net`. Reservoir names each package by its owner, so `@ChristianMurphy/espal` can't collide with another. The TypeScript client needs its npm name, `espal` or a scope such as `@espal`, claimed before M5. MIT's Software Design Group has a research system named Espalier, a spreadsheet with database queries, in a different field.

## Where the claims run ahead of the plan

The README and the pitch promise more than this plan delivers. We fix these before 0.1.

The README says an endpoint declares how much work it may spend, and that code over budget fails to compile. Only statement budgets exist, and only in the prototype. Lean has no CPU or memory limit per task, and nothing can stop a pure computation once it runs. Static bounds on pure code form a research track below.

The README also says the compiler checks how the app behaves under load. The compiler can check statement counts and row bounds, which shape load behavior. The behavior itself we measure.

"Stateless" holds for app processes, while the database holds all the state. Adding app processes moves the bottleneck to the database. Row and query-plan budgets matter for that reason as much as statement budgets do.

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
- The C libraries Espal links, which are libuv, OpenSSL, libpq if we choose it, MariaDB Connector/C and FreeTDS.
- The databases, the reverse proxy, the operating system and the network.

### Route report and escape hatches

An audit command prints a report for every route. It marks each guarantee listed under Properties as proved, typed, enforced at runtime, assumed, or bypassed. It also lists what the route's dependencies assume.

Escape hatches live under one name, `Espal.escape`, because Lean already uses `unsafe` for something else. Each one takes a reason and lists the guarantees it voids. Raw SQL, for example, voids injection safety (P4) and the budgets (P8, P9) for that route, but its body limit still holds. A strict profile rejects every escape hatch in CI.

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
- A batch lookup exceeds the database's limit on bind parameters. Postgres and MySQL allow 65,535 per statement, SQLite 32,766, and SQL Server 2,100. The prototypes send one parameter per key and fail on long lists. Postgres can take one array parameter with `col = ANY($1)`. The other databases need JSON table functions or, on SQL Server, table-valued parameters.
- SQL Server's `sp_executesql` accepts a whole batch of statements. Espal renders one statement per text, so the proof still holds, but the SQL Server adapter must never join texts.

### P5. The query model matches each database (Tested)

We prove facts about queries with a small evaluator written in Lean. Those facts hold in a database only where it gives the same answers.

Postgres and the evaluator disagree on integer overflow, where Postgres raises an error and Lean's `Int` grows. They also differ on three-valued `NULL` logic, collation, floating point, time zones, and `char(n)` padding. We model only the fragment where they agree. `NULL` becomes an explicit `Option`, and each Lean type maps to a database type with a checked range.

The other databases add their own gaps:

- MySQL, MariaDB and SQL Server compare text without regard to case by default, so an exact match on `ada` also finds `Ada`. Generated tables declare a case-sensitive collation.
- SQLite switches integer arithmetic to floating point on overflow, and ordinary SQLite tables accept any value in any column. Generated tables use SQLite's `STRICT` mode.
- MySQL outside strict mode, and SQL Server with `ANSI_WARNINGS OFF`, clip or truncate bad values instead of failing. Each adapter sets the session options Espal relies on when it connects.

Differential tests generate tables, rows and queries. Each query runs on the evaluator and on every database, and the test compares the rows. CI runs this for every supported release. In the prototype, the test matched SQLite and Postgres on 13 queries. It also caught Postgres sorting names its own way under an ICU English collation.

### P6. Tenant isolation (Proved over the model, Enforced by Postgres and SQL Server)

The prototype proves that a scoped select returns only the scope's rows (`scopedSelect_tenant`). It also proves that scoped updates and deletes leave other tenants' rows unchanged (`scopedUpdate_isolation`, `scopedDelete_isolation`). These results reach Postgres only through P5.

As a second layer, Espal generates row-level security policies for each tenanted table on Postgres and SQL Server. A raw query or a gap in the model then still can't cross tenants. MySQL, MariaDB and SQLite have no row-level security, so on them tenant isolation rests on the proofs and the differential tests alone.

The guarantee breaks in these cases:

- Handler code builds a `Scope` from a request field instead of the signed-in session. The `Scope` constructor stays private to the authentication module.
- A join scopes one side only.
- A background job runs without a scope.
- A pooled connection keeps the previous request's tenant setting. On Postgres, Espal sets it with `SET LOCAL` inside each transaction, and a plain `SET` stays out of the code. SQL Server needs its own reset rule.

Every fault test in M4 also counts cross-tenant reads. The target is zero.

### P7. The database matches the declared schema (Checked at startup)

Migrations come from the models. At startup the app compares the declared tables with the database catalog and refuses to start on a mismatch.

The check breaks when another service changes the schema while the app runs. It also breaks when a rolling deploy runs old and new code against one schema. Migrations therefore expand first and contract later: add the new shape, deploy, then drop the old one.

### P8. Statement budget (Proved, Typed per endpoint)

`runCounting_count` shows that a `DbM n` program sends `n` statements against any database. A query per row fails to type-check, because its count depends on data.

The current form has three gaps:

- Because the index is exact, both branches of an `if` must send the same number of statements. Real handlers need an upper bound instead.
- The count covers statements the app writes. `BEGIN`, `COMMIT`, statement preparation, retries and pool health checks fall outside it, and the docs say so.
- Pipelining sends several statements per round trip, so round trips can only fall below the count. The count says nothing about what one statement costs; P9 covers that.

The prototype found two more problems. A budgeted program isn't a monad, so code chains `.bind` calls instead of using `do` notation. A query per row fails with `failed to synthesize instance of type class Monad (DbM 1)`, which never mentions the loop. Before 0.1, budgets need a `do`-notation form and a custom error message.

### P9. Row bounds and query cost (Typed, then Tested)

Every select carries a `LIMIT` or a predicate on a unique key. Each join follows a foreign key to a unique key, so a row matches at most one row on the other side. The result then holds no more rows than the limit, and no query returns an unbounded cartesian product. We can prove that bound over the model.

Rows scanned depend on indexes and the planner, which the compiler can't see. CI runs `EXPLAIN` for each declared query on a seeded database. It fails on a sequential scan of a large table or an estimate over a threshold. Each database reports plans in its own format, so the check needs a reader for each.

The CI check misses cases where production differs. The planner may choose another plan with production data, estimates may be wrong, or an index may exist in CI and not in production. Postgres may also switch a prepared statement to a generic plan. In production, `pg_stat_statements` and a slow-query log per endpoint record the real cost.

### P10. Time and space cost of pure code (Research track)

CSLib's `TimeM` shows the technique. A monad adds up costs in `bind`, and proofs bound the total in counted steps. It covers only code written in that style, and it counts steps rather than time. CSLib trusts its cost annotations instead of checking them.

The same technique can count space. A route states its bound as a declaration, for example linear in the number of items. An app can raise or lower it without touching the proof. We found no Lean library with a space cost model today, so this is new work.

Lean's runtime can change the real cost. It reuses the memory of a value that nothing else refers to, as the paper "Counting Immutable Beans" (IFL 2019) describes. So `Array.set` updates in place only when the array has one reference. A second reference turns an O(1) update into an O(n) copy, and the proof model can't see reference counts.

For 0.1 we ship a deadline per request, checked at every effect step (Enforced). We also ship memory bounds per request (P21) and benchmarks for hot paths (Measured). The research track aims at proved time and space bounds for the tenant app's grading functions. It succeeds only if those proofs stay short enough for app authors to write.

### P11. Stateless handlers (Typed, Proved over the interpreter, Linted)

A handler returns its effects as data instead of running them, and it has no `IO` access. Espal's interpreter runs the effects. Between requests it keeps only connection pools. Nothing here exists yet. We plan to prove over a model of the interpreter that the response depends on three inputs. They are the request, the database state, and what the declared effects return. Send the same request to another process with the same inputs, and it returns the same response.

App code can still reach process-global state. An `initialize` declaration can hold an `IO.Ref`, and `unsafeBaseIO`, `@[extern]` and `implemented_by` open other paths. An in-process cache, rate limiter or session store breaks the property too. The route report (M2) lists every such declaration that a handler can reach.

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

### P17. Every endpoint checks permission (Typed)

Each endpoint declares the permission it needs, and the `api` macro rejects an endpoint that declares none. A public endpoint says so explicitly. The handler receives a value that only the permission check can construct, so a handler that skips the check fails to compile.

M1 evaluates cedar-lean as the permission engine. Cedar's Lean model proves three things. It denies a request unless a policy permits it. A forbid policy beats any permit. Its policy validator is sound. Cedar checks its Rust engine against that model with differential tests.

The guarantee breaks in these cases:

- The permission rules themselves are wrong. The rules are the specification, so tests check them against examples.
- A permission depends on data, such as a teacher seeing only their own classes. That needs query scoping in the manner of tenants (P6), not only a check at the door.
- Sign-in can fail in its own ways. Tests cover password hashing, session key rotation, token checks for OpenID Connect, and limits on sign-in attempts, which live outside the process.

### P18. Background jobs run at least once (Tested)

A job enters the queue in the same transaction as the write that caused it. Workers claim jobs with row locks that skip rows already locked, so two workers never take the same job. A worker that dies mid-job leaves it to run again. Jobs therefore run at least once and must tolerate a repeat; the keys from P16 apply. Statement budgets cover jobs as they cover requests.

Mail goes through the queue. A worker that crashes after the mail provider accepts a message, but before the job finishes, sends it twice. Providers that accept an idempotency key prevent the duplicate.

The claim breaks on SQLite, which allows one writer at a time and has no row locks, so SQLite apps run one worker. A fault test kills workers mid-job and counts how often each job ran and each message went out.

Veil, a Lean framework for transition systems (Apache 2.0, CAV 2025), could prove the claim protocol safe across every interleaving of workers. It covers safety properties only, and its 2.0 release is still a pre-release, so this stays a research track.

### P19. Generated code passes every check (Tested)

CI runs the `espal` generators to create a project with an endpoint, a model and a migration. It then builds that project with `--wfail`, checks its route report, and runs its tests. The job fails as soon as the generators fall behind the library.

### P20. Partial updates reach the right place (Typed, design idea)

A fragment endpoint returns HTML for a named target on a page. If pages name targets with typed references instead of CSS selectors, the compiler can check that the target exists on the page. It can also check that the target's content model accepts the fragment, for example that a table row goes into a table body. Nobody has prototyped this yet.

The check can't see changes that client scripts make after the page loads, or a target chosen at runtime.

### P21. Memory per request stays within a declared bound (Typed, Proved over a model, Enforced)

Each route's limits give it a memory bound that grows at most linearly in them. The limits are body bytes, rows per query (P9), streamed array elements, and response bytes. An app sets them once, and a route can override them. Over a cost model of Espal's own buffers, we plan to prove that decoding, reading rows and rendering stay within the bound.

Before running a request, Espal reserves its bound from a fixed memory pool. A request that doesn't fit waits in the admission queue (P15), and it gets `503` once the queue is full. The edge cases have fixed answers:

- A body whose `Content-Length` exceeds the limit gets `413` before Espal reads it. Espal counts a chunked body as it arrives and cuts it off with `413` at the limit.
- A route whose bound exceeds the whole pool is a configuration error, and the app refuses to start.
- When a handler reads a streamed body slowly, Espal stops reading from the socket, so unread input waits in the kernel's socket buffer.

The guarantee breaks in these cases:

- Handler code allocates outside Espal's buffers, for example by building a large list. Espal counts only code written in the cost style of P10.
- C libraries allocate on their own. libpq holds a whole result in C memory unless the client uses single-row mode.
- Lean's runtime can't attribute memory to a request. Heartbeats count small allocations per thread rather than bytes, they miss large objects, and requests move between threads. Enforcement therefore counts the bytes Espal buffers, not every allocation.

Tests run each route alone at its limits and compare the process's peak memory with the bound. Until M4 calibrates the model, an overrun shows up in the route report. After M4, it fails CI. A process-level limit in production catches what the model misses.

### P22. Streaming decoders agree with whole-body decoders (Proved)

Decoders derived from types read JSON as it arrives and check each element on arrival. A handler can then take a large array one element at a time. We plan to prove that any split of the input into chunks gives the same result as decoding the whole body. We also plan to prove that a malformed element fails the request before the decoder reads past it.

Nesting depth gets its own limit, because a deeply nested body would otherwise recurse on input size (P14). Duplicate object keys and numbers too large for the target type are errors. MessagePack follows after 0.1. Its length prefixes let a decoder skip parts a handler doesn't need without parsing them.

### P23. Route contracts (Proved, prototype first)

A route may state a postcondition, such as "the response belongs to the requested student". Lean's `vcgen` tactic, built on the `Std.WP` library, turns a program and its postcondition into proof goals, and it handles embedded languages as well as monads. It first shipped in Lean 4.33, and the 4.35 release notes present it as the successor to `mvcgen`. It still needs `set_option experimental.vcgen true`, and its interface is moving again on Lean's main branch. M3 tries one contract on a tenant-app route before 0.1 commits to the feature.

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
| `/plaintext`, `/json` | M1 on raw Std.Http, M2 through Espal |
| `/db`, `/queries?n=`, `/updates?n=` | M3 |
| `/fortunes` (escaped list page) | M6 |

TechEmpower's rules keep the comparison fair. Every response carries `Server` and `Date` headers, and query counts stay between 1 and 500. For `/fortunes`, the app adds a row at request time and sorts in application code. One row contains `<script>`, and the output is UTF-8.

### Tenant app

The tenant app grades assessments shaped like the QTI domain, without QTI XML import at first. Schools are tenants, and assessments, items, submissions and grading rules live in Postgres. The app grows with each milestone.

| Milestone | What the app adds |
|---|---|
| M2 | Pure grading endpoints, such as `POST /grade`, with proofs that scores stay between zero and the item's maximum |
| M3 | Schools, assessments, items and submissions in Postgres, scoped by tenant, with statement and row budgets |
| M4 | The exam-end burst from the performance targets: 100,000 submissions in one minute |
| M5 | A small TypeScript test runner built on the generated client |
| M6 | Teacher pages listing assessments and results |
| M7 | Sign-in for teachers and students, with teachers seeing only their own classes |
| M8 | Regrading an assessment as a background job, with results sent by mail |
| Later | QTI XML import through our own structured XML parser, which rejects DTDs and entities |

## Milestones

Milestones are outcomes without dates. M2, M4 and M5 follow the order already agreed: macro, then load test, then TypeScript client.

### M0. Foundations (done)

The repository exists, and CI runs the build, tests, lint, a second kernel check, an axiom audit, formatting checks, and a workflow audit. `Espal.Route` provides typed routes with a round-trip proof.

One follow-up remains. Lean 4.35 added `lake check`, which builds the project, replays every declaration through the kernel, and rejects axioms beyond the standard ones. With `--paranoid` it also runs nanoda and other independent checkers, which would bring nanoda back. It needs bubblewrap, so we first confirm that GitHub's runners allow it.

### M1. Spikes and a baseline

M1 picks the HTTP layer, the Postgres client and the dependencies, and fixes the performance targets.

- **Toolchain.** Lean 4.35.0 has two server bugs that later releases fix. Each socket read blocks a pool thread, fixed by [lean4#15174](https://github.com/leanprover/lean4/pull/15174). The `Date` header reads the time zone database on every response. In a container without one, the server sends no response at all ([lean4#15442](https://github.com/leanprover/lean4/issues/15442), fixed by #15443 and #15469). Both fixes are in v4.36.0-rc1, released October 14. We spike on 4.35.0 and 4.36.0-rc1 and move to 4.36.0 when it ships.
- **HTTP spike.** We serve `/plaintext` and `/json` on Std.Http and measure them by the method below. First one process, then N processes on separate ports behind a proxy. Std.Http runs one libuv loop behind one lock and has no `SO_REUSEPORT` binding, so N processes are how a machine's cores get used. A bare Std.Async loop sets the ceiling for any Lean server on this runtime, and Go `net/http` on the same machine sets a reference point. We also profile the lock contention reported in [lean4#13469](https://github.com/leanprover/lean4/issues/13469).
- **Postgres spike.** We build both candidates far enough to serve `/db`.
  - libpq over FFI in non-blocking mode, with `uv_poll` on `PQsocket`. This needs a new C binding that runs under the event loop's lock.
  - A wire-protocol client in Lean with startup, SCRAM-SHA-256 sign-in, extended queries and pipelining. Managed Postgres requires TLS. Lean's runtime exposes nothing from OpenSSL beyond a version number. This path therefore also needs a TLS binding, plus the SHA-256, HMAC and PBKDF2 that SCRAM uses.
  - The comparison covers query latency, pipelined throughput, lines of C, what each lets us prove, and recovery when a connection drops mid-pipeline.
- **Dependency spikes.** We build each candidate on Espal's toolchain, measure it against what Espal needs, and write down whether we keep or replace it. The candidates pin Lean versions from 4.33 to 4.35 today.
  - lean-linq (MIT) as the query layer. It uses the representation we chose for the core, and it has budgets in `do` notation and drivers for four databases. Its MySQL driver links libmysqlclient, which Espal would swap for MariaDB Connector/C.
  - lean-routing (Apache 2.0) as the router. It derives handler types from route patterns and proves that patterns round-trip. It tests the link round trip, which Espal's own codec proves.
  - LeanIO (MIT) for typed extractors, streamed multipart uploads, ranges and ETags. It has almost no proofs and uses `partial def`, so it would sit outside the totality lint, and the route report would say so.
  - cedar-lean (Apache 2.0) as the permission engine, with the proofs described in P17.
- **Exit.** Numbers in `bench/results/` with the hardware recorded, a written decision for HTTP, Postgres and each dependency, and fixed targets in the table below.
- **Failure.** The spike may show that no Lean server on this runtime gets near the throughput target. We then write our own server, which enlarges M2, or restate the target. Several processes per machine stay part of the design either way, and statelessness makes them cheap.



### M2. Packages, endpoints and the JSON API

- Split the repository into the packages listed under Scope, with the `espal` package at the root.
- Port the prototype's `route_type` and `api` macros, or build them on lean-routing if M1 keeps it. The route codec moves to bytes, and helpers become private.
- An endpoint declares its method, path, parameters, body, response, typed errors, permission and statement budget.
- A `LawfulJson` deriving handler generates the round-trip proof (P3), and streaming decoders come with the chunk-split proof (P22).
- Errors use problem details. A decode failure returns `400` and names the field.
- The default limits, memory bounds per request, `413` for oversized bodies, and the memory pool (P21).
- The route report and `Espal.escape`. The report includes what the earlier app audit found: `unsafe`, `extern`, `implemented_by`, `initialize` and extra axioms that handlers can reach (P11).
- The OpenAPI 3.2.1 description.
- **Tests.** A `#guard_msgs` test with the exact message for each rejection: shadowed route, unreachable endpoint, missing handler, wrong body type. Compile-time benchmarks as in P2.
- **Failure.** Errors may surface as unification failures that app authors can't read, and Lean's monthly releases break macros. We test error text, pin the toolchain, and run a non-blocking CI job against Lean nightly to catch breakage early.

### M3. Query layer, models and Postgres

- The query core, with table variables that the interpreter supplies. It comes from lean-linq if M1 keeps it, and from our own code otherwise. Models declared with an attribute, the builder, and query syntax in `do` notation sit on top.
- Statement budgets with upper bounds and `do` notation. P4, P6, P8 and P9 ported, with batch lookups through `= ANY($1)`.
- Collections and safe writes from the defaults.
- The client chosen in M1, with a connection pool, transactions, prepared statements, and single-row mode for streamed results.
- Migrations, seed data and fixtures generated from the models, and the schema check at startup (P7).
- Row-level security policies for each tenanted table (P6).
- The differential tests (P5) and `EXPLAIN` checks in CI (P9).
- One route contract on a tenant-app route, checked with `vcgen` (P23).

### M4. Load testing and behavior under faults

- Benchmark scripts in `bench/` that follow the method below, and a regression job.
- Admission control (P15), deadlines per request, and `503` with `Retry-After`.
- Several processes behind a proxy, with health endpoints. On `SIGTERM` a process stops accepting, finishes requests in flight, then exits.
- Idempotency keys (P16).
- Fault runs under load. We kill a process with `SIGKILL`, stop the database primary, and cut the network to Postgres. Each run reports errors, recovery time and cross-tenant reads.
- An hour-long soak run that tracks memory growth.
- A check of the default limits under load, and a measurement of each example route's peak memory at its limits (P21).

### M5. TypeScript client

- Generate the TypeScript client from the OpenAPI description. Errors become discriminated unions. 64-bit integers become strings, with `bigint` as an option.
- Tests as in P3, plus a compatibility check against the previous release.

### M6. Server-rendered pages

- Port the JSX syntax and content model. Add `/fortunes` to the benchmark app and teacher pages to the tenant app.
- Partial page updates, with fragment routes typed like pages. The target check from P20 comes in if a prototype shows it works.
- Forms with typed decoding. Form posts with cookies need CSRF protection through `SameSite` cookies and a token per session.
- The HTML5 parser comparison (P12).

### M7. Sign-in and permissions

- Sessions, passwords, OpenID Connect and roles.
- A permission check on every endpoint (P17), built on cedar-lean if M1 keeps it.
- Limits on sign-in attempts, stored outside the process.

### M8. Background jobs and mail

- A job queue in the database, scheduled tasks, and mail sent through the queue (P18).
- Fault tests that kill workers mid-job.

### M9. CLI and generators

- The `espal` command, which creates projects, endpoints, models and migrations.
- The CI job from P19.

### M10. Release 0.1

- The Verso documentation site, with a tutorial that builds one endpoint, one query and one page.
- Release binaries without GMP by default, with shared GMP as an option. Lean links against an old glibc for portability, so a release with shared GMP needs its own GMP build.
- A Reservoir listing for the `espal` package, which needs at least two stars and an OSI license.

### M11. Other databases (after 0.1)

0.1 supports Postgres only. M3 designs the dialect interface so the others can follow.

- SQLite through leansqlite, the Lean FRO's binding under Apache 2.0. MySQL and MariaDB through MariaDB Connector/C, and SQL Server through FreeTDS.
- Dialect features gated by type classes, with differential tests and an `EXPLAIN` reader for each database.

### Research tracks

None of these block 0.1.

- Time and space cost of pure code (P10).
- Our own HTTP/1.1 server, if M1 calls for it.
- Upstream fixes to Std.Http and Std.Async, such as the mutexes per request described in lean4#13469.
- A proof of the job claim protocol in Veil (P18).
- MessagePack (P22).
- Fewer dependencies, once Espal knows which ones it keeps.

## Performance targets

These targets come from the earlier proposal. Agreed figures stand; we fix the rest at the end of M1.

| Target | Status |
|---|---|
| Comparison with Go and Axum | Reported, with no promised ratio. The exam-end burst below is the throughput goal. We found one test that ran both on the same machine (Apple M3, 64 connections). Std.Http with the lean4#15174 fix served 9,827 req/s and Go served 170,865, a gap of about 17×. |
| With one Postgres read, at least 80% of a bare libpq client | Agreed |
| At 70% of peak load, p99 under 10 ms and p99.9 under 50 ms | Proposed. Measured on the benchmark app on reference hardware, by the method below. |
| At twice peak load, excess requests get a `503` within 5 ms | Proposed. Detection as in P15. |
| Three nodes reach at least 2.7× the throughput of one | Agreed. Holds until Postgres saturates. We report it with the database on its own machine. |
| Losing a node causes under 0.1% errors, all from requests in flight on that node | Proposed. Depends on proxy health checks, draining and retries of idempotent requests. |
| After a database failover, writes resume within 30 s with no duplicates | Proposed. The Postgres setup controls failover time. Espal's part is reconnecting and idempotency keys. |
| Zero cross-tenant reads during every fault test | Agreed |
| At the end of an exam, 100,000 submissions arrive within one minute, about 1,700 per second. Espal stores all of them, loses none and stores none twice. | Agreed. A second run sends half of them in the last ten seconds, about 5,000 per second, to test the admission queue. |
| Binary under 10 MB, start-up under 100 ms | Agreed. CI checks binary size for both example apps. |

Third parties have published figures from laptops. Std.Http served about 1,600 to 2,400 req/s before the fix and 5,400 to 9,800 after it. A bare Std.Async loop served about 46,000 ([LeanAPI](https://github.com/theoriclabs/leanapi/issues/3), [lean-http-bench](https://github.com/keithadler/lean-http-bench)). These figures motivate M1 and don't replace it.

## Benchmark method

A framework's latency depends on the app. Every figure therefore names the workload (an endpoint of the benchmark app), the hardware and the settings.

- **Open-loop load.** A closed-loop tool waits for each response before it sends the next request. A stalled server then slows the load as well, and the stall drops out of the percentiles. Benchmarkers call this coordinated omission. We drive load at a fixed arrival rate instead. [oha](https://github.com/hatoo/oha) (MIT) with `-q` and `--latency-correction` is the main tool. [wrk2](https://github.com/giltene/wrk2) (Apache 2.0, unmaintained since 2019) gives a second opinion.
- **Tool check.** Before we trust a tool, we pause the server with `SIGSTOP` for one second during a run. The reported p99.9 must show the pause.
- **Procedure.** A short sweep finds the peak rate. We then run at 25, 50, 70, 90 and 200% of peak, each for 60 seconds after a warm-up, five times. Reports plot latency against arrival rate. They give the median and spread of p50, p99, p99.9 and maximum latency. They also give the error rate, CPU time per request and memory.
- **Hardware.** GitHub-hosted runners measure compile time, binary size and instruction counts, which stay stable on shared machines. Espal publishes no absolute latency or throughput figures until a dedicated machine with a fixed CPU frequency runs them, by M4 at the latest. The load generator runs on separate cores or a separate machine.
- **Comparisons.** Go `net/http`, Axum and FastAPI run the same workloads on the same machine, each written as its documentation recommends. We publish their code and settings and invite fixes, because a comparison against a badly tuned baseline tells nobody anything.
- **Regressions.** CI compares instruction counts and compile times with the main branch and fails on a large regression.

## Project risks

- **Lean's HTTP ceiling.** One libuv loop sits behind one lock. Std.Http uses about five times the CPU per request of a bare Std.Async loop (lean4#13469). We answer with several processes per machine, upstream fixes, and our own server as a fallback.
- **Proofs about the wrong thing.** Each proof covers a model: the query evaluator, the HTML tree, the Lean client, the memory model of Espal's buffers. Each proved claim therefore gets a test against the real system (P3, P5, P12, P21).
- **Escape hatches.** Apps that use raw SQL or global state lose guarantees. The route report names every escape hatch and what it voids, and the strict profile rejects them. Row-level security backs up tenant isolation on Postgres and SQL Server.
- **Proof burden on app authors.** If ordinary endpoints need hand-written proofs, few people will use Espal. The target is zero hand-written proofs in the benchmark app, and proofs in the tenant app only for grading rules.
- **Compile time.** Macros and proof automation slow builds. Compile-time benchmarks run in CI against a budget.
- **Toolchain churn.** Lean ships monthly releases that break metaprograms. We pin the toolchain, bump it on purpose, and keep a nightly canary job.
- **Dependencies.** Each library Espal depends on pins its own Lean version and moves at its own pace, so a Lean upgrade waits for all of them. Espal's lint doesn't cover them, so the route report lists their axioms and their `partial` and `unsafe` declarations.
- **Experimental proof tools.** `vcgen` is experimental in Lean 4.35, and its interface is moving again on Lean's main branch. Route contracts wait on the M3 spike.
- **FFI crashes.** A crash in C code kills the process and every request in flight, and C bugs bypass every proof. We keep the C small, fuzz it, and run it under AddressSanitizer in CI. Espal links four C client libraries once every database adapter exists.
- **More databases, more testing.** Each database needs its SQL tested against a real server in CI, and each departs from the evaluator in its own ways (P5).
- **Scope.** 0.1 carries four batteries on top of the core: models and migrations, sign-in and permissions, jobs and mail, and the CLI. With one maintainer, that pushes 0.1 well out. Our own HTTP server, a Postgres client, cost proofs for pure code and an XML parser would each be a project of their own too. Each sits behind a decision point with a fallback, and the packages can ship one at a time.
- **Fooling ourselves with benchmarks.** Coordinated omission, noisy runners, code paths tuned for the benchmark, and untuned baselines all distort results. The benchmark method addresses each one.
- **Security surface.** A web framework owns cookies, sessions and CSRF protection. M6 covers CSRF, and M7 covers sign-in.
- **Licenses.** Adapted code keeps its license notice, and LGPL libraries stay shared. GPL-licensed tools such as HTTP Garden run outside the repository.
- **One maintainer.** Each milestone ships something usable on its own, and research tracks never block a release.

## Assumptions

Each of these could prove wrong. The second sentence of each says how we would find out or what would change.

- Deployments put a reverse proxy in front of Espal for TLS and to spread load over processes. Std.Http has no TLS, so a deployment without a proxy would need TLS inside Espal.
- Tenants share tables with a tenant column, as in the prototype. Schools with data residency rules might need a database per tenant, which changes P6.
- Production runs on Linux, on x86-64 and arm64, and development also runs on macOS. A request for another platform would add a CI target.
- App authors accept Lean's toolchain and its build times. Compile-time budgets and feedback on the tutorial will show whether they do.
- Espal supports the Postgres releases still maintained upstream. Pipeline mode needs libpq 14 or later, so an older client library rules out pipelining.
- Apps on MySQL, MariaDB or SQLite accept tenant isolation without a layer the database enforces. If schools require one, those adapters need another mechanism, such as a database per tenant.

## Decisions so far

These came out of the planning discussion in October 2026.

- **Scope.** Batteries included, built from packages in one repository that also work alone.
- **Example apps.** A benchmark app and a realistic multi-tenant app.
- **HTTP layer and Postgres client.** Spike first, then decide.
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
- **Contracts.** One prototype with `vcgen` in M3 before committing.
- **Candidate dependencies.** lean-linq, lean-routing, LeanIO and cedar-lean, each evaluated in M1.
- **Tenant app.** A QTI-shaped grading app, without XML import at first.
- **Load target.** 100,000 submissions within one minute at the end of an exam.
- **Databases in 0.1.** Postgres only.
- **Benchmark hardware.** GitHub runners for regression checks now, and a dedicated machine for published latency figures by M4.
- **Throughput goal.** The exam-end burst. Comparisons with Go and Axum get reported without a promised ratio.
- **Where the plan lives.** This file, with a GitHub milestone and issues for each milestone once M1 starts.
- **Dates.** None. A milestone ends when its exit criteria pass.
- **Contributors.** You and Claude until 0.1. Outside pull requests open after the first release.
- **Memory in CI.** Overruns get reported until M4 calibrates the model, and fail CI after that.
- **Package names.** `espal-<area>`, with modules under `Espal.<Area>`.
- **SQLite binding.** leansqlite, when SQLite support arrives after 0.1.
- **Versions.** One version for all packages, following Semantic Versioning.
- **Lean versions.** One stable Lean version per release.
- **Security reports.** GitHub's private vulnerability reporting.
- **Documentation.** A Verso site on GitHub Pages.
- **M1 order.** Open the issues, then run the HTTP spike first.

## Open decisions

None right now. The M1 spikes settle the HTTP server, the Postgres client and which dependencies Espal keeps.
