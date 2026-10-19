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
- The check from [every endpoint is reachable](../../ROADMAP.md#every-endpoint-is-reachable). Dispatch takes the first route that matches, so an earlier route can hide a later one, and lean-routing doesn't report it. Espal's endpoint layer rejects that at compile time, including two routes with the same pattern.
- One URL per resource. lean-routing also reaches user 42 at `/users/042`, `/users/4_2` and `/users/%34%32`. Espal compares the request's encoded path with the link rebuilt from the captured values, and redirects when they differ.
- Capture types beyond `Nat` and `String`, such as UUIDs and enumerations, over a `String` capture with a codec of Espal's own.
- Typed query parameters, and the OpenAPI description, built from the patterns.

## Changes offered upstream

Espal needs no change to lean-routing. The trial prototyped four changes that would help its other users, and the [upstream plan](https://github.com/ChristianMurphy/espal/blob/explore/lean-routing/explorations/lean-routing/upstream/README.md) has the patches. They prove the link round trip, give a `Nat` capture one spelling per number, reject duplicate patterns in `route_table`, and add layout hints to its syntax. Espal can offer them as contributions without waiting on them.

## If lean-routing stalls

Espal copies the library with its Apache 2.0 notice, as the contributing guide allows, and keeps it current by hand. That happens if lean-routing stops following Lean releases.

## Risks

- One person maintains lean-routing.
- It builds on Std.Http, whose API can change with each Lean release. Its own workflow bumps the toolchain when a new Lean ships.
