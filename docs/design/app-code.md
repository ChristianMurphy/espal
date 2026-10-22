# What app code looks like

This note sketches the code an author writes for the two [example apps](../../ROADMAP.md#example-apps), before the `api` macro and the model attribute exist. It sets the shape of the author's side first, so the macros and proofs serve that shape. Each piece names its evidence, using the roadmap's [kinds of evidence](../../ROADMAP.md#kinds-of-evidence), and each label gives the target for 0.1. The names are placeholders, and the [questions](#questions) at the end need answers before any macro work starts.

## What we take from other frameworks

We read how FastAPI, Axum, Phoenix, Rails, Django REST Framework, Servant, Yesod, tRPC, ASP.NET Core and three Lean frameworks handle the same jobs. Each item says what the framework does and what Espal takes from it.

- **FastAPI and [LeanAPI](https://github.com/theoriclabs/leanapi).** A handler's parameter types decide how the request decodes. LeanAPI answers bad input with a 422 that names the field, such as `body.price`, and rejects conflicting routes at compile time. Espal reads handler signatures the same way. LeanAPI uses the Business Source License 1.1, so Espal can borrow its ideas and none of its code.
- **Phoenix 1.8.** Generated functions such as `list_posts(scope)` take the [scope](https://phoenix.hexdocs.pm/scopes.html) first and filter on `post.user_id == ^scope.user.id`. Espal's model functions take a `Scope` first too, and a theorem covers the filter.
- **Phoenix verified routes.** A `~p` path with no matching route [issues a compiler warning](https://phoenix.hexdocs.pm/Phoenix.VerifiedRoutes.html). Espal builds links from handlers and their arguments, so a link to a missing route fails to compile.
- **Servant.** The client comes from the same type as the server, so the two can't drift within one build. Espal's Lean client works that way, and a theorem covers it.
- **[LeanTEA](https://github.com/Verilean/lean-tea).** A handler takes `Proof .admin`, and only the module that checks the session can construct one. Espal's access values follow the same idea.
- **Django REST Framework and Rails 8.** DRF's default permission is [`AllowAny`](https://www.django-rest-framework.org/api-guide/permissions/), and its list views skip object permissions. The Rails 8 generator adds `require_authentication` to every controller. Espal has no default. Each handler names its access, and lists go through scoped queries.
- **Axum.** Bodies stop at 2 MB unless a route [raises the limit](https://docs.rs/axum/latest/axum/extract/struct.DefaultBodyLimit.html). Espal's default is 1 MiB.

## The benchmark app

The app follows TechEmpower's rules. Its five endpoints come in two milestones, and `/fortunes` waits for pages.

```lean
import Espal
open Espal

structure Message where
  message : String
  deriving Json

@[model "World"]
structure World where
  id : Key World Int32
  randomNumber : Int32
  deriving Json

/-- TechEmpower reads a missing or malformed count as 1, and clamps counts to 1–500. -/
abbrev Count := Clamp 1 500

def randomWorld : Handler (Key World Int32) := Key.random 1 10000

def plaintext (_ : Public) : Handler Text :=
  return "Hello, World!"

def json (_ : Public) : Handler Message :=
  return { message := "Hello, World!" }

def db (_ : Public) : Db 1 World := do
  World.get (← randomWorld)

def multipleQueries (_ : Public) (queries : Count) : Db queries (List World) :=
  Db.times queries fun _ => do World.get (← randomWorld)

def updates (_ : Public) (queries : Count) : Db (queries + 1) (List World) := do
  let worlds ← Db.times queries fun _ => do World.get (← randomWorld)
  let worlds ← worlds.mapM fun w => return { w with randomNumber := ← random 1 10000 }
  World.updateAll worlds
  return worlds

api Bench where
  GET "/plaintext" => plaintext
  GET "/json"      => json
  GET "/db"        => db
  GET "/queries"   => multipleQueries
  GET "/updates"   => updates

def main : IO Unit := serve Bench
```

The table names a method, a path and a handler. The handler's signature gives the rest. Its first argument is the access value. The other arguments are path captures, query parameters and the body. Its type gives the response and the statement budget. A capture matches a binder by name. Any other scalar binder is a query parameter, such as TechEmpower's `queries`, and the one binder of a record type is the body, as in FastAPI.

| Code | What holds | Evidence |
|---|---|---|
| `api Bench` | Each request reaches its handler, and no route hides another | Proved at compile time |
| `api Bench` | A link built for a route dispatches back to it with the same arguments | Proved |
| `(_ : Public)` | Every handler says who may call it | Typed |
| `deriving Json` | Decoding an encoded value gives it back, and the wire form suits JavaScript | Proved |
| `Db 1 World` | The handler sends at most one statement | Proved |
| `Db queries` | `/queries` sends at most 500 statements, since `Count` stops at 500 | Proved |
| `World.get` | The SQL text holds no parameter value | Proved |
| `Int32` | Every number survives a round trip through a JavaScript double | Typed |
| `serve` | Bodies over 1 MiB get `413`, and each request has a deadline | Enforced |

The author writes no proof. That meets the roadmap's target of zero handwritten proofs in the benchmark app.

## The tenant app

### Grading, with the range in the type

The first tenant endpoint grades a choice item, shaped like QTI's `mapResponse`. A wrong choice can subtract points, so the raw sum can fall below zero or exceed the maximum.

```lean
structure Item where
  mapping : List (ChoiceId × Int)
  maxScore : Nat
  deriving Json

structure Response where
  selected : List ChoiceId
  deriving Json

/-- A score between zero and the item's maximum. -/
structure Graded where
  score : Nat
  maxScore : Nat
  inRange : score ≤ maxScore
  deriving Json

def grade (item : Item) (r : Response) : Graded :=
  let raw := (r.selected.map item.pointsFor).sum
  { score := min raw.toNat item.maxScore, maxScore := item.maxScore, inRange := by omega }

structure GradeRequest where
  item : Item
  response : Response
  deriving Json

def gradeItem (_ : Public) (body : GradeRequest) : Handler Graded :=
  return grade body.item body.response
```

`inRange` is the proof the roadmap asks for, and `omega` writes it. A handler can't return a `Graded` outside the range, because it can't build one without the proof. The decoder checks the same proposition, so a Lean client rejects a `Graded` that breaks it. We compiled `grade` and the range proof on Lean 4.35.0.

`gradeItem` stays public until sign-in lands. [Every endpoint checks permission](../../ROADMAP.md#every-endpoint-checks-permission) still holds, because `Public` is the declared access.

### Models and the three types each one generates

```lean
@[model, tenant School]
structure Assessment where
  @[generated] id : Key Assessment
  @[owner Teacher] teacher : Key Teacher
  @[reach Student via Enrolment] course : Key Course
  title : Title
  closesAt : Instant
  @[generated] createdAt : Instant
  deriving Json
```

The attribute generates three types from the field roles, so authors never write request and response types by hand.

- `Assessment.Create` holds `course`, `title` and `closesAt`.
- `Assessment.Update` holds `title?` and `closesAt?`. A missing field leaves the column unchanged.
- `Assessment.View` holds every field except the tenant column, which no type exposes.

`Title` is a string whose decoder rejects the empty string. A field that carries a proof works the same way in any type.

### Scoped queries for the teacher

```lean
def listAssessments (s : Scope Teacher) (page : Page) : Db 1 (Paged Assessment.View) :=
  Assessment.list s page

def showAssessment (s : Scope Teacher) (id : Key Assessment) :
    ExceptT NotFound (Db 1) Assessment.View :=
  Assessment.get s id

def createAssessment (s : Scope Teacher) (body : Assessment.Create) :
    Db 1 (Created Assessment.View) := do
  let a ← Assessment.insert s body
  return .created (link showAssessment a.id) a

api Grading where
  GET  "/assessments"     => listAssessments
  GET  "/assessments/:id" => showAssessment
  POST "/assessments"     => createAssessment
```

A `Scope Teacher` holds the school and the teacher, and only sign-in can build one. `Assessment.list s` filters on both. `Assessment.insert s` takes the school and the teacher from `s`, so a request can't set them. Another teacher's assessment answers `404`, the same as one that doesn't exist.

`link showAssessment a.id` builds the `Location` header from the handler and its arguments. A link to a handler that isn't in an `api` table fails to compile.

### Submissions at the end of an exam

```lean
inductive SubmitError where
  | notFound
  | @[status 409] closed (at : Instant)
  deriving Problem

def submit (s : Scope Student) (id : Key Assessment) (body : Submission.Create) :
    ExceptT SubmitError (Db 2) (Created Submission.View) := do
  let some a ← Assessment.find s id | throw .notFound
  if (← now) > a.closesAt then throw (.closed a.closesAt)
  let sub ← Submission.insert s a body
  return .created (link showSubmission sub.id) sub
```

`Assessment.find s` reaches an assessment through the student's enrolments, as the model's `reach` attribute declares. `SubmitError` lists the errors this endpoint can return, and the generated TypeScript client gets them as a discriminated union. `now` comes from the interpreter, so a test can fix the clock.

The handler says nothing about retries. POST endpoints accept an idempotency key by default, and the generated client sends one. A client that retries after a timeout then stores one submission.

### What holds in the tenant app

| Code | What holds | Evidence |
|---|---|---|
| `inRange` | A score stays between zero and the maximum | Proved by the author, checked on decode |
| `Scope Teacher` | Only sign-in can build a scope | Typed |
| `Assessment.list s` | Every row returned belongs to the school | Proved over the model, by the prototype's `scopedSelect_tenant` |
| `Assessment.list s` | Every row returned belongs to the teacher | Proved over the model, as a new extension of the tenant proof |
| `Assessment.find s` | A student reaches only assessments of their courses | Proved over the model, new design |
| `Assessment.Create` | A request can't set the school, the teacher or the ID | Typed |
| `link showAssessment` | The link reaches that handler with those arguments | Proved |
| `SubmitError` | The handler returns only the errors it declares | Typed |
| `closesAt : Instant` | Code that compares a deadline with a local time fails to compile | Typed |
| idempotency key | A retry stores the submission once | Proved over the model, Tested |
| Postgres policies | A raw query still can't cross schools | Enforced by Postgres |

The author writes one proof, `inRange`. That meets the roadmap's target of proofs only for grading rules.

## Messages for common mistakes

Each rejection gets a `#guard_msgs` test with its exact text. Both Axum and Servant added work on messages after release. Axum added [`#[debug_handler]`](https://docs.rs/axum-macros/latest/axum_macros/attr.debug_handler.html), and Servant 0.19 added [custom type errors](https://hackage.haskell.org/package/servant/changelog) for partly applied combinators. These are the target messages. Whether Lean lets a macro produce each one is part of the work.

A handler without an access value gets this message.

```text
handler `db` takes no access value, so nothing says who may call it.
Add `(_ : Public)` for a public endpoint, or a `Scope` for a signed-in one.
```

A query per element of a list gets this one.

```text
`World.get` runs once for each element of `ids`, so the number of statements depends on the data.
Use `World.getMany ids`, which sends one statement, or give the list a maximum length in its type.
```

An integer type whose values can outgrow a JavaScript number gets this one.

```text
`Submission.View` has no wire codec, because field `attempts : Nat` can exceed 2^53.
JavaScript reads larger integers inexactly. Use `UInt32`, or `UInt64`, which travels as a string.
```

A float in an API type gets this one.

```text
`Float` has no JSON codec, because JSON has no NaN or infinity.
Use an integer count of the smallest unit, such as cents.
```

Setting a field the model owns, such as `{ body with teacher := t }`, already fails with Lean's own message that `teacher` is not a field of `Assessment.Create`.

## JSON from the author's side

The [lean-json note](lean-json.md) records the decisions. This section covers what an author meets. We checked each statement about lean-json against commit `4a0cf59`.

- **One deriving clause.** `deriving Json` gives `ToJson`, `FromJson`, `LawfulJson`, `WireJson` and the schema. An author meets the classes only when writing a codec by hand.
- **Integer widths.** lean-json writes `Nat` and `Int` as numbers and `UInt64` and `USize` as decimal strings, and it has no instances for `Int32` or `UInt32`. Espal adds the 8, 16 and 32-bit types as numbers and `Int64` as a string. `Nat` and `Int` get no `WireJson` instance, since their values can exceed 2^53. A `Key` follows its column, so an `int4` key is a number and an `int8` key is a string.
- **Optional fields.** A field named `note?` is left out when it is `none`, and `null` and a missing key both decode to `none`. The TypeScript client types it as `note?: string`. `Option (Option α)` doesn't round trip, so update types use their own three-state type for nullable columns.
- **Proof fields.** A decoder checks a decidable proof field, as `Title` and `Graded` do. We wrote one such codec by hand, and its round-trip theorem needed only `propext`.
- **Error paths.** lean-json's derived decoders report `Order.items: Item.price: expected a number`. The message names types and fields but no array index, stops at the first failure, and reads a missing field as `null`. Problem details need a JSON Pointer such as `#/items/1/price`, every failure at once, and "missing" for a missing field. We would offer lean-json a structured decode error that carries the path.
- **Unknown keys.** lean-json's derived decoders ignore keys the type doesn't have. The [questions](#questions) cover whether Espal rejects them.

A bad request then gets one response that lists every failure. It follows the shape of RFC 9457's own example.

```json
{
  "type": "/problems/validation",
  "title": "The request body failed validation",
  "status": 422,
  "errors": [
    { "pointer": "#/items/1/price", "detail": "expected a number" },
    { "pointer": "#/title", "detail": "must not be empty" }
  ]
}
```

Malformed JSON gets `400`. A body that parses but fails its types or checks gets `422`, which RFC 9110 defines for content the server can parse but not process. The roadmap's packages milestone says `400` for both, and would change to match.

## Questions

1. **Where handlers live.** The sketch uses a table that names handler definitions, with types read from their signatures. The prototype declared each endpoint's types in the table and implemented them all in one `match`. A third option puts an attribute such as `@[get "/db"]` on each definition.
2. **Who may call a handler.** The sketch puts the access value in each signature, so the benchmark app writes `Public` five times. A table could instead mark a group of routes public once, with a `#guard_msgs` test that pins the list of public routes.
3. **Unknown keys in a request.** Rejecting them catches typos and fields the server doesn't know. Ignoring them lets a newer client call an older server during a rolling deploy.
4. **Validation as proof fields.** The sketch states each check as a proof field, which the handler, the decoder and the OpenAPI description share. The cost is that code building such a value must supply the proof.
