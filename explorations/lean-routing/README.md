# lean-routing trial

This trial checks [lean-routing](https://github.com/paulbutcher/lean-routing) as Espal's router, for the dependency trials in the [spikes and a baseline](../../ROADMAP.md#spikes-and-a-baseline) milestone. It pins commit `75d8bc3` from 18 October 2026, which is release 0.10.1 plus a workflow change, under the Apache 2.0 license.

## Files

- `Trial/Behaviour.lean` checks each claim below that mentions a path, with `#guard`.
- `DispatchBench.lean` times dispatch with many routes.
- `serve/` runs Std.Http on Lean 4.36.0-rc1 with and without lean-routing, and `serve/bench_router.py` compares them.
- `upstream/` holds the changes to offer lean-routing, as patches, with how realistic each one is.

## Running it

```bash
lake build                       # fails if any #guard in Trial/ fails
.lake/build/bin/dispatch-bench
```

## Builds and tests

| Lean | Change to lean-routing | Build warnings | `lake test` |
|---|---|---|---|
| 4.35.0 | none | 0 | passes |
| 4.36.0-rc1 | `lean-toolchain` only | 0 | passes |

Its tests also check that an executable using its macros links nothing from the Lean package. That executable was 2.9 MB on 4.35.0 and 3.9 MB on 4.36.0-rc1.

## What it gives Espal

- A pattern such as `"/users/:id:Nat"` sets the handler's type, so a handler with the wrong arguments fails to compile.
- Each route gets a typed link function, such as `App.links.user : Nat → String`. Links are percent-encoded, and no link has an empty, `.` or `..` segment.
- Mounts, routers with their own middleware and fallback, and a `308` redirect for a mounted index requested without its trailing slash.
- The matched route's template, such as `/users/:id`, which is what OpenTelemetry's `http.route` attribute wants.
- Relative links that come out the same wherever an app mounts the module.
- It uses Lean's module system, and it builds with no warnings.

## Against Espal's route properties

- **Round trip.** A theorem shows that the pattern syntax round-trips (`parsePattern_renderPattern`). The round trip from a link back to its route has examples and Plausible fuzzing but no theorem. Its tests give the reason: `String.splitOn` and `String.toNat?` had no lemmas in Lean's core. Lean 4.35.0 proves `Nat.toNat?_repr`, which `upstream/0001` uses for that proof. `Espal.Route` already proves a decimal codec round trip (`parseNatSeg_natSeg`) that could replace `String.toNat?`.
- **One URL per resource.** A `Nat` capture parses with `String.toNat?`, which accepts leading zeros and `_` separators. `/users/42`, `/users/0042` and `/users/4_2` all reach user 42. The [route round trip](../../ROADMAP.md#route-round-trip) property rules that out.
- **Reachability.** Dispatch takes the first route that matches. Listed first, `/users/:name:String` takes both `/users/new` and `/users/42`, so the routes for those paths never run. Nothing reports it. `route_table` also accepts two rows with the same pattern. Under [every endpoint is reachable](../../ROADMAP.md#every-endpoint-is-reachable), each of these fails to compile.
- **Capture types.** A capture is a `Nat` or a `String`, from a closed inductive type. Espal also needs signed integers, UUIDs and enumerations.
- **Theorems in the test package.** A project that depends on lean-routing can't use its theorems in its own proofs.

## Against the endpoint shape

An Espal endpoint declares its method and path. It also declares parameters, a body, a response, typed errors, a permission and a statement budget. Of these, lean-routing covers the method and the path, and Espal's endpoint layer adds the rest.

- `Route result`, `dispatchTable` and `matchTable` work for any result type. An Espal handler can return its effects as data for Espal's interpreter to run.
- `Router`, `Entry` and `toHandler` take Std.Http handlers, which run `IO`. Espal would need them generalized to use their mounts and middleware, or would write its own.
- Patterns are data, so the OpenAPI description can come from them. OpenAPI writes `/users/{id}` where lean-routing writes `/users/:id`.
- lean-routing doesn't parse query parameters.

## Dispatch cost

Dispatch tries each route in order. Pinned to one CPU, `dispatch-bench` reached the last of 200 routes in 3.1 µs. Std.Http spent about 540 µs of CPU per request in the [HTTP spike](../../bench/results/http/2026-10-18-cloud-4vcpu/README.md), so the scan adds under 1 percent.

## Overhead in a server

`serve/bench_router.py` ran four handlers in one Std.Http server on Lean 4.36.0-rc1, pinned to one CPU, for three alternating rounds. Each answered `/plaintext`.

| Handler | Peak req/s, median | CPU per request at 2,000 req/s, median |
|---|---|---|
| String match on the URI, as in the HTTP spike | 5,973 | 361 µs |
| `toHandler` with 2 routes | 6,151 | 343 µs |
| `toHandler` with 200 routes, `/plaintext` last | 6,195 | 375 µs |
| `Router` with 200 routes and two middlewares | 6,049 | 361 µs |

- The medians spread by 4 percent in peak and 9 percent in CPU, in no consistent order. The 200-route `Router` used as much CPU as the bare handler, so the spread is noise. The 3.1 µs that `dispatch-bench` measured for 200 routes is under 1 percent of a request.
- A request that matches nothing scans the routes twice, the second time to see whether a trailing slash would match. A `Router` also asks each sub-router. With 200 routes that still comes to a few microseconds.
- Std.Http's own work takes almost all of a request's CPU time.

## Code style

Espal's `scripts/Lint.lean`, run over lean-routing's modules, reports 2 problems in one declaration. `MatchedRoute` derives `TypeName`, and Lean implements that instance with `unsafe` code, which also depends on the axiom `lcProof`. Std.Http's request extensions need the instance. The lint reports nothing else.

lean-fmt prints each `route_table` block on one line, such as `route_table App[userByName:="/users/:name:String", newUser:="/users/new"]`. Its syntax declares no spacing or line-break hints for Lean's pretty-printer, so `.lean-fmt.toml` leaves `Trial/Behaviour.lean` out of formatting.

## Size and activity

- 1,073 lines of Lean in the library and 1,011 in tests.
- 130 commits since 11 July 2026, the latest on 18 October 2026. Paul Butcher wrote 128 of them.
- The same author maintains [lean-middleware](https://github.com/paulbutcher/lean-middleware) and wrote about the library in [Formally verified CRUD](https://paulbutcher.com/lean2.html).

## Options

1. **Keep it as it is.** Espal depends on lean-routing and accepts a link round trip that tests cover, more than one URL per number, and silent shadowing.
2. **Adapt it, upstream first.** Espal depends on lean-routing and offers each change upstream on its own, as `upstream/` lists. Espal's endpoint layer adds the reachability check, endpoints and OpenAPI on top of `Route`.
3. **Replace it.** Espal ports its prototype's `route_type` and `api` macros, and borrows lean-routing's rules for dot segments and encoding with its notice.
