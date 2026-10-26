/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalRoute.Api
public import RoutingStd

/-!
# Serving an `api` table

`Api.toHandler` answers an `Espal.Api`'s routes on `Std.Http.Server`, through lean-routing's route
index, and `serve` runs it. `Respond` says how a handler's result becomes a response.

Espal's link theorem is stated over lean-routing's `matchTable`. The index finds the same route as
`matchTable`, by `RouteIndex.matchTable_eq`, which lean-routing proves in its tests.
-/

@[expose] public section

namespace Espal

open Routing Std Async Http

/-- How a handler's result becomes a response. -/
class Respond (α : Type) where
  /-- The response for `a`. -/
  respond : α → ContextAsync (Response Body.Any)

/-- Text answers `200 OK` with a plain-text body. -/
instance : Respond String where
  respond s := Engine.std.text Response.ok s

/-- The handler that answers `t`'s routes, and `404 Not Found` for any other request. -/
def Api.toHandler {α : Type} [Respond α] (t : Api α) : StatelessHandler .std :=
  (t.map fun a (_ : Request Body.Stream) => Respond.respond a).index.toHandler

/-- Serves `t` on `addr` until the server shuts down. -/
def serve {α : Type} [Respond α] (t : Api α) (addr : Net.SocketAddress)
    (config : Http.Config := {}) : IO Unit :=
  Async.block do
    let server ← Server.serve addr t.toHandler config
    server.waitShutdown

end Espal
