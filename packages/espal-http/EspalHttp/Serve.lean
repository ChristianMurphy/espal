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
index, and `serve` runs it. A route that takes a body gets the request's bytes, up to `maxBody`.
A longer body gets `413`, and the route's handler doesn't run.

Espal's link theorem is stated over lean-routing's `matchTable`. The index finds the same route as
`matchTable`, by `RouteIndex.matchTable_eq`, which lean-routing proves in its tests.
-/

@[expose] public section

namespace Espal

open Routing Std Async Http

/-- The most bytes of a request body that a route reads by default, 1 MiB. -/
def defaultMaxBody : Nat :=
  1048576

/-- The response for `reply`. A status code that HTTP doesn't define answers `500`. -/
def Reply.toResponse (reply : Reply) : ContextAsync (Response Body.Any) :=
  let status := (Status.ofCode none reply.status).getD .internalServerError
  let builder := Response.withStatus status
  Engine.stdBytes ((builder.header? "content-type" reply.contentType).getD builder) reply.body

/-- The decoded query of `request`. A key or value that isn't valid UTF-8 once decoded is left
out. -/
def requestQuery (request : Request Body.Stream) : Query :=
  request.line.uri.query.toArray.toList.filterMap fun (key, value) => do
    let key ← key.decode
    let value ←
      match value with
      | some value =>
        value.decode
      | none =>
        some ""
    return (key, value)

/-- The response of `endpoint` to `request`. A route that takes a body reads at most `maxBody`
bytes of it. -/
def Endpoint.answer (endpoint : Endpoint) (maxBody : Nat) (request : Request Body.Stream) :
    ContextAsync (Response Body.Any) :=
  match endpoint with
  | .noBody run => (run (requestQuery request)).toResponse
  | .withBody run => do
    match ← Engine.stdRead request.body maxBody with
    | .ok bytes =>
      (run (requestQuery request) bytes).toResponse
    | .tooLarge =>
      Reply.tooLarge.toResponse

/-- The handler that answers `t`'s routes, and `404 Not Found` for any other request. -/
def Api.toHandler (t : Api Endpoint) (maxBody : Nat := defaultMaxBody) : StatelessHandler .std :=
  (t.map fun endpoint => endpoint.answer maxBody).index.toHandler

/-- Serves `t` on `addr` until the server shuts down. -/
def serve (t : Api Endpoint) (addr : Net.SocketAddress) (config : Http.Config := {})
    (maxBody : Nat := defaultMaxBody) : IO Unit :=
  Async.block do
    let server ← Server.serve addr (t.toHandler maxBody) config
    server.waitShutdown

end Espal
