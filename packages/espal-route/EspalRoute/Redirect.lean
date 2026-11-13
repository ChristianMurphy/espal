/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalCore.Reply
public import EspalRoute.Link

/-!
# Redirects

A handler that sends the client elsewhere returns a `Redirect`. It holds a `Link`, which a handler
gets from `linkTo`, so the `Location` header can't hold text from the request. A `Link` writes a
path on the same host, so a redirect never leaves the site.

`seeOther` answers `303`, and the client fetches the link with `GET`. A handler uses it after a
`POST`. `temporary` answers `307` and `permanent` answers `308`, and the client repeats its
request with the same method. `301` and `302` are left out, since clients differ on whether they
keep the method.
-/

@[expose] public section

namespace Espal

/-- A reply that sends the client to another route of the same site. -/
inductive Redirect where
  /-- `303 See Other`. The client fetches the link with `GET`. -/
  | seeOther (location : Link)
  /-- `307 Temporary Redirect`. The client repeats its request at the link. -/
  | temporary (location : Link)
  /-- `308 Permanent Redirect`. The client repeats this request and later ones at the link. -/
  | permanent (location : Link)

/-- The status code of a redirect. -/
def Redirect.status : Redirect → UInt16
  | .seeOther _ => 303
  | .temporary _ => 307
  | .permanent _ => 308

/-- The link a redirect sends the client to. -/
def Redirect.location : Redirect → Link
  | .seeOther location => location
  | .temporary location => location
  | .permanent location => location

/-- A redirect answers its status with the link in `Location` and an empty body. -/
instance : ToReply Redirect :=
  ⟨fun redirect =>
    { status := redirect.status
      contentType := "text/plain; charset=utf-8"
      body := .empty
      headers := [("location", toString redirect.location)] }⟩

end Espal
