# lean-routing as the router

Espal builds its routes on [lean-routing](https://github.com/paulbutcher/lean-routing), and changes go to lean-routing first. This note records the decision from the lean-routing trial in the [spikes and a baseline](../../ROADMAP.md#spikes-and-a-baseline) milestone, made in October 2026. The [trial's README](https://github.com/ChristianMurphy/espal/blob/explore/lean-routing/explorations/lean-routing/README.md) on the `explore/lean-routing` branch has the setup and every result.

## What Espal takes

- Route patterns such as `"/users/:id:Nat"`, which set each handler's type.
- Typed link functions, with percent-encoding and no empty, `.` or `..` segments.
- `Route`, `dispatchTable` and `matchTable`. They work for any result type, so an Espal handler can return its effects as data.
- Mounts, relative links, and the matched route's template for telemetry.

## Why

- It built with no warnings on Lean 4.35.0 and 4.36.0-rc1, and its tests passed on both. Lean 4.36.0-rc1 needed only a new `lean-toolchain`.
- It uses Lean's module system. An executable that uses its macros links nothing from the Lean package.
- Espal's lint found one problem, the `TypeName` instance that Std.Http's request extensions need.
- Dispatch to the last of 200 routes took 3.1 µs, under 1 percent of the CPU Std.Http spends on a request.
- A theorem covers its pattern syntax, and its tests name the link round-trip theorem they lack.
- Building the same parts ourselves would go against the [contributing guide](../../CONTRIBUTING.md), which prefers an existing library under a compatible license.

## What has to change in lean-routing

Espal's [route round trip](../../ROADMAP.md#route-round-trip) property needs these:

- **One URL per number.** A `Nat` capture parses with `String.toNat?`, so `/users/0042` and `/users/4_2` both reach user 42. A parser that accepts only the shortest spelling fixes it. `Espal.Route`'s decimal codec rejects `4_2` and `+42` and proves that parsing a printed number returns it. It still accepts `0042`, so the strict parser and its proof in the other direction are new work.
- **A proof of the link round trip.** With that parser, a theorem can show that dispatching a link returns the values passed to its link function.
- **Theorems in the library.** They sit in the test package today, where a dependent's proofs can't use them.

These would help, and Espal can add them on top if upstream prefers not to:

- Capture types through a codec class with a round-trip proof, for signed integers, UUIDs and enumerations.
- A `Router` that accepts handlers other than Std.Http's, so Espal's handlers can use its mounts and middleware.
- Spacing and line-break hints in the `route_table` syntax. lean-fmt prints each table on one line today.
- A compile error for two `route_table` rows with the same pattern.

## What Espal adds

- Endpoints that declare their parameters, body, response, typed errors, permission and statement budget on top of a `Route`.
- The check from [every endpoint is reachable](../../ROADMAP.md#every-endpoint-is-reachable). Dispatch takes the first route that matches, so an earlier route can hide a later one. The layer that orders the routes rejects that at compile time.
- Typed query parameters.
- The OpenAPI description, built from the patterns.

## If upstream declines

Espal copies the library with its Apache 2.0 notice, as the contributing guide allows, and keeps it current by hand. That happens if lean-routing won't take the one-URL change or the round-trip proof. It also happens if they haven't landed when the [packages, endpoints and the JSON API](../../ROADMAP.md#packages-endpoints-and-the-json-api) milestone starts.

## Risks

- One person maintains lean-routing.
- It builds on Std.Http, whose API can change with each Lean release. Its own workflow bumps the toolchain when a new Lean ships.
