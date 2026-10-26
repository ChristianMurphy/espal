# lean-routing as the router

Espal builds its routes on [lean-routing](https://github.com/paulbutcher/lean-routing) as it is, with its own layer on top. This note records the decision from the lean-routing trial in the [spikes and a baseline](../../ROADMAP.md#spikes-and-a-baseline) milestone, made in October 2026. The [trial's README](https://github.com/ChristianMurphy/espal/blob/explore/lean-routing/explorations/lean-routing/README.md) on the `explore/lean-routing` branch has the setup and every result.

## What Espal takes

- Route patterns such as `"/users/:id:Nat"`, which set each handler's type.
- Typed link functions, with percent-encoding and no empty, `.` or `..` segments.
- `Route`, `dispatchTable` and `matchTable`, and `Router` with its mounts and middleware. A pure Espal handler fits them, since Espal's interpreter turns its effects into a Std.Http response inside the function lean-routing calls.
- Relative links, and the matched route's template for telemetry.

## Why

- It built with no warnings on Lean 4.35.0 and 4.36.0-rc1, and its tests passed on both. Lean 4.36.0-rc1 needed only a new `lean-toolchain`.
- It uses Lean's module system. An executable that uses its macros links nothing from the Lean package.
- Espal's lint found one problem, the `TypeName` instance that Std.Http's request extensions need.
- Dispatch to the last of 200 routes took 3.1 µs, under 1 percent of the CPU Std.Http spends on a request. In a Std.Http server on one CPU, a `Router` with 200 routes and two middlewares stayed within the noise between rounds. That held for both throughput and CPU per request.
- It exposes its definitions, so Espal can prove theorems about them in its own package.
- Building the same parts ourselves would go against the [contributing guide](../../CONTRIBUTING.md), which prefers an existing library under a compatible license.

## What Espal adds

- Endpoints that declare their parameters, body, response, typed errors, permission and statement budget on top of a `Route`.
- The [route round trip](../../ROADMAP.md#route-round-trip), proved over lean-routing's `dispatch` and `linkFor`, as a lemma for [client and server agreement](../../ROADMAP.md#client-and-server-agree).
- The check from [every endpoint is reachable](../../ROADMAP.md#every-endpoint-is-reachable). Dispatch takes the first route that matches. Since 0.12.0, lean-routing rejects a route that an earlier one always beats. Espal's `api` command rejects more: a table where an earlier route takes any link built for a later one, such as `/users/new` before `/users/:name`. Routes that share a pattern under different methods are fine. `unshadowed_of_linksDisjoint` turns Espal's check into the proof that lean-routing's route index asks for, so building the index checks nothing twice.
- One URL per resource. Since 0.11.0, lean-routing refuses `/users/042` and `/users/4_2`. Std.Http decodes the path before dispatch, though, so `/users/%34%32` still reaches user 42. Espal compares the request's encoded path with the link rebuilt from the captured values, and redirects when they differ.
- Capture types beyond `Nat` and `String`, such as UUIDs and enumerations, over a `String` capture with a codec of Espal's own.
- Typed query parameters, and the OpenAPI description, built from the patterns.

## Changes offered upstream

Espal needs no change to lean-routing. The trial led to pull requests that help its other users, and the [upstream plan](https://github.com/ChristianMurphy/espal/blob/explore/lean-routing/explorations/lean-routing/upstream/README.md) records how each began. lean-routing 0.11.0 shipped the first four.

- [#10](https://github.com/paulbutcher/lean-routing/pull/10) proves that a link from `linkFor` reaches its handler, given one fuzzed assumption about Std.Http's parser and decoder. The theorem sits in lean-routing's tests, so Espal still proves its own [route round trip](../../ROADMAP.md#route-round-trip). [lean4#15834](https://github.com/leanprover/lean4/issues/15834) asks Lean to add the `ByteArray` fold lemma that its proof needed.
- [#11](https://github.com/paulbutcher/lean-routing/pull/11) matches requests with a trie. The maintainer welcomed one in [#8](https://github.com/paulbutcher/lean-routing/issues/8) if it kept the formal guarantees, and theorems prove that it picks the route `matchTable` picks.
- [#12](https://github.com/paulbutcher/lean-routing/pull/12) lets a `Nat` capture match only the digits a link renders.
- [#15](https://github.com/paulbutcher/lean-routing/pull/15) starts a link or slash redirect with `/./` when its first segment is empty, so browsers keep it on the same host. [#9](https://github.com/paulbutcher/lean-routing/issues/9) describes the bug. #15 replaced [#13](https://github.com/paulbutcher/lean-routing/pull/13), which rejected such a mount root instead.
- [#17](https://github.com/paulbutcher/lean-routing/pull/17) adds spacing and line-break hints to the syntax of `route_table`, and is open.
- [#16](https://github.com/paulbutcher/lean-routing/pull/16) would have rejected two `route_table` rows with the same pattern. It closed unmerged, because a row carries no method, so two rows can share a pattern for a GET and a POST.
- The maintainer's [#18](https://github.com/paulbutcher/lean-routing/pull/18) rejects shadowed routes, and 0.12.0 shipped it. Following a comment there, `decide +kernel` can prove a table's check, so a table needs no `native_decide` axiom.

## If lean-routing stalls

Espal copies the library with its Apache 2.0 notice, as the contributing guide allows, and keeps it current by hand. That happens if lean-routing stops following Lean releases.

## Risks

- One person maintains lean-routing.
- It builds on Std.Http, whose API can change with each Lean release. Its own workflow bumps the toolchain when a new Lean ships.
