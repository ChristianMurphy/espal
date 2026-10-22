# What app code looks like

This note sketches the code an author writes for the two [example apps](../../ROADMAP.md#example-apps), before the `api` macro and the model attribute exist. We wrote the author's side first so the macros and proofs can fit it. Each piece of code names its evidence, using the roadmap's [kinds of evidence](../../ROADMAP.md#kinds-of-evidence), and each label is the target for 0.1. The names are placeholders. The [decisions](#decisions) at the end record what we settled.

## What we take from other frameworks

We read how FastAPI, Axum, Phoenix, Rails, Django REST Framework, Servant, Yesod, tRPC, ASP.NET Core and three Lean frameworks handle routing, decoding, errors and permissions.

- FastAPI and [LeanAPI](https://github.com/theoriclabs/leanapi) decode each request from the handler's parameter types. LeanAPI answers bad input with a 422 that names the field, such as `body.price`, and rejects conflicting routes at compile time. Espal decodes from handler signatures too. LeanAPI uses the Business Source License 1.1, so Espal can borrow its ideas but none of its code.
- Phoenix 1.8 generates functions such as `list_posts(scope)`, which take the [scope](https://phoenix.hexdocs.pm/scopes.html) first and filter on `post.user_id == ^scope.user.id`. Espal's model functions take a `Scope` first too, and a theorem covers the filter.
- Phoenix's verified routes [only warn](https://phoenix.hexdocs.pm/Phoenix.VerifiedRoutes.html) when a `~p` path matches no route. Espal builds links from handlers and their arguments, so a link to a missing route fails to compile.
- Servant derives the client from the same type as the server, so the two can't drift within one build. Espal derives its Lean client from the `api` table, and a theorem covers it.
- In [LeanTEA](https://github.com/Verilean/lean-tea), an admin handler takes a `Proof .admin`, and only the module that checks the session can construct one. Espal's `Scope` has a private constructor for the same reason.
- Django REST Framework's default permission is [`AllowAny`](https://www.django-rest-framework.org/api-guide/permissions/), and its list views skip object permissions. The Rails 8 generator adds `require_authentication` to every controller. Espal has no default, so each handler names its access, and lists go through scoped queries.
- Axum stops bodies at 2 MB unless a route [raises the limit](https://docs.rs/axum/latest/axum/extract/struct.DefaultBodyLimit.html). Espal's default is 1 MiB.

## The benchmark app

The app follows TechEmpower's rules. `/plaintext` and `/json` arrive with the [packages milestone](../../ROADMAP.md#packages-endpoints-and-the-json-api), the database routes with the [query layer](../../ROADMAP.md#query-layer-models-and-postgres), and `/fortunes` with [server-rendered pages](../../ROADMAP.md#server-rendered-pages).

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

/-- TechEmpower reads a missing or malformed count as 1, and clamps counts to the range 1 to 500. -/
abbrev Count := Clamp 1 500

def randomWorld : Handler (Key World Int32) := Key.random 1 10000

def plaintext (_ : Public) : Handler Text :=
  return "Hello, World!"

def json (_ : Public) : Handler Message :=
  return { message := "Hello, World!" }

def db (_ : Public) : Db 1 World NotFound := do
  World.get (← randomWorld)

def multipleQueries (_ : Public) (queries : Count) : Db queries (List World) NotFound :=
  Db.times queries fun _ => do World.get (← randomWorld)

def updates (_ : Public) (queries : Count) : Db (queries + 1) (List World) NotFound := do
  let worlds ← Db.times queries fun _ => do World.get (← randomWorld)
  let worlds ← worlds.mapM fun w => return { w with randomNumber := ← random 1 10000 }
  World.updateAll worlds
  return worlds

api Bench where
  GET "/plaintext" => plaintext
  GET "/json"      => json
  GET "/db"        => db
  GET "/queries"   => multipleQueries (statements := 500)
  GET "/updates"   => updates (statements := 501)

def main : IO Unit := serve Bench
```

The table gives each route a method, a path and a handler. The handler's signature gives the rest.

- The first argument is the access value.
- A path capture fills the binder with the same name.
- A binder whose type has a `QueryParams` instance reads from the query string. `Count` has one, which is how TechEmpower's `queries` parameter arrives.
- Any other binder is the body, decoded from JSON. Only POST, PUT and PATCH take a body, so a GET handler with a body binder fails to compile.
- The result type gives the response, the statement budget and the errors.

`Db n α ε` counts statements in its type. A `Db a` followed by a `Db b` makes a `Db (a + b)`, and an `if` takes the larger of its two branches. `ε` lists the errors the handler can return, and it defaults to none. Because the count changes from one step to the next, `Db` has no `Monad` instance, so Espal needs its own `do` notation for it. The roadmap's [statement budget](../../ROADMAP.md#statement-budget) section already asks for that, and it is the largest piece of this design that nobody has built yet. `Handler` touches no database, so it is an ordinary monad.

The roadmap's defaults allow 10 statements per request. `/queries` can send up to 500 and `/updates` up to 501, so the table raises their limits. The macro checks each handler's count against its route's limit, so the table shows every route that goes past the default.

`World.get` answers `404` when the row is missing. TechEmpower's table always holds the row, but a total function still needs a result for a key with no row.

| Code | What holds | Evidence |
|---|---|---|
| `api Bench` | Each request reaches its handler, and no route hides another | Proved at compile time |
| `api Bench` | A link built for a route dispatches back to it with the same arguments | Proved |
| `(_ : Public)` | Every handler says who may call it | Typed |
| `deriving Json` | Decoding an encoded value gives that value back | Proved |
| `deriving Json` | Every number Espal writes is a finite double | Proved |
| `deriving Json` | JavaScript reads each of those numbers back unchanged | Tested in Node |
| `Int32` | IDs and random numbers travel as JSON numbers | Typed |
| `Db 1 World NotFound` | The handler sends at most one statement | Proved |
| `Db queries` | `/queries` sends at most 500 statements, because `Count` stops at 500 | Proved |
| `World.get` | The SQL text holds no parameter value | Proved |
| `serve` | Bodies over 1 MiB get `413`, and each request has a deadline | Enforced |

The author writes no proof, which meets the roadmap's target of zero handwritten proofs in the benchmark app.

## The tenant app

### Grading

The first tenant endpoint grades a choice item by the rule of QTI's `mapResponse`. Each selected choice adds its mapped points once, even when the response repeats it. A wrong choice can subtract points, so the total is then clamped between zero and the item's maximum.

```lean
structure Item where
  mapping : List (ChoiceId × Int)
  maxScore : Small
  keysDistinct : (mapping.map (·.1)).Nodup
  deriving Json

structure Response where
  selected : List ChoiceId
  deriving Json

/-- A score between zero and the item's maximum. -/
structure Graded where
  score : Small
  maxScore : Small
  inRange : score ≤ maxScore
  deriving Json

def grade (item : Item) (r : Response) : Graded :=
  let raw := ((item.mapping.filter (·.1 ∈ r.selected)).map (·.2)).sum
  { score := ⟨min raw.toNat item.maxScore.val, by have := item.maxScore.lt; omega⟩
    maxScore := item.maxScore
    inRange := by simp; omega }

structure GradeRequest where
  item : Item
  response : Response
  deriving Json

def gradeItem (_ : Public) (body : GradeRequest) : Handler Graded :=
  return grade body.item body.response
```

`inRange` keeps every score in range, and `simp` and `omega` prove it. A handler can't return a `Graded` outside the range, because it can't build one without the proof. The decoder checks the same proposition, so a Lean client rejects a `Graded` that breaks it.

`Small` is Espal's type for a count below 2^53. It travels as a JSON number, so a client reads `"score": 2`. It has no `+`, so two scores can't add up past the limit and wrap around. `Fin (2^53)` would give the same wire form, but its `+` wraps, so `(2^53 - 1) + 2` is 1. Proofs about `Small` need `simp` before `omega`, with a simp lemma that Espal ships.

A range proof says nothing about whether the score is right. Take an item that maps `A` to 1 point and allows 3. A `grade` that summed every entry in `selected` would give `["A", "A", "A"]` full marks, and `inRange` would still hold. QTI 3 says a repeated value counts once, so `{B, B, C}` maps to 1.5 in its example and not 2.5. A wrong sign, a missing zero for an unmapped choice, or a misplaced clamp would also pass the range proof.

So the author states QTI's rule as a second, plain definition, and proves that `grade` always matches it.

```lean
/-- The points QTI maps a choice to, with 0 for a choice the item doesn't map. -/
def Item.pointsFor (item : Item) (c : ChoiceId) : Int :=
  ((item.mapping.find? (·.1 == c)).map (·.2)).getD 0

/-- QTI 3, section 2.11.1.5: sum the mapped value of each distinct selected choice, then clamp. -/
def mapResponse (item : Item) (r : Response) : Int :=
  max 0 (min ((r.selected.eraseDups.map item.pointsFor).sum) item.maxScore.val)

theorem grade_eq_mapResponse (item : Item) (r : Response) :
    ((grade item r).score.val : Int) = mapResponse item r
```

`mapResponse` follows the spec's sentence step by step. `grade` reaches the same number by walking the item's mapping, which counts each choice once. `keysDistinct` stops an item from mapping one choice twice, and the decoder checks it. `mapResponse` is code too, so a test checks it against QTI's own examples.

Nobody has written the proof yet. It needs a lemma that `eraseDups` leaves no duplicates, which Lean 4.35's core lacks, so we'd write it in core's style and offer it upstream. We compiled the code above on Lean 4.35.0 with the proof left out. `grade` and `mapResponse` both score `["A", "A", "A"]` as 1 on that item.

`gradeItem` is public until [sign-in](../../ROADMAP.md#sign-in-and-permissions) exists. [Every endpoint checks permission](../../ROADMAP.md#every-endpoint-checks-permission) still holds, because `Public` is the declared access.

### Models

```lean
@[model, tenant School]
structure Course where
  @[generated] id : Key Course
  @[owner Teacher] teacher : Key Teacher
  name : String
  deriving Json

@[model, tenant School]
structure Assessment where
  @[generated] id : Key Assessment
  @[owner Teacher] teacher : Key Teacher
  @[reach Student via Enrollment] course : Key Course
  title : Title
  closesAt : Instant
  @[generated] createdAt : Instant
  deriving Json
```

The model attribute generates three types from the field roles, so authors never write request and response types by hand.

- `Assessment.Create` holds `course`, `title` and `closesAt`.
- `Assessment.Update` holds `title?` and `closesAt?`, and a missing field leaves its column unchanged.
- `Assessment.View` holds every field except the tenant column, which no generated type has.

`Title` is a string with a proof field that rules out the empty string, so its decoder rejects `""`. A key names its column type when the table already exists, as `Key World Int32` does. Other keys are `int8` columns.

### The teacher's routes

```lean
def listAssessments (s : Scope Teacher) (page : Page) : Db 1 (Paged Assessment.View) :=
  Assessment.list s page

def showAssessment (s : Scope Teacher) (id : Key Assessment) : Db 1 Assessment.View NotFound :=
  Assessment.get s id

def createAssessment (s : Scope Teacher) (body : Assessment.Create) :
    Db 1 (Created Assessment.View) NotFound := do
  let a ← Assessment.insert s body
  return .created (link showAssessment a.id) a
```

A `Scope Teacher` holds the school and the teacher, and only sign-in can build one. `Assessment.list s` and `Assessment.get s` filter on both, so another teacher's assessment answers `404`, the same as one that doesn't exist.

`Assessment.insert s` takes the school and the teacher from `s`. In the same statement, it checks that `body.course` belongs to that teacher and school. A course from anyone else inserts nothing and answers `404`, whether or not the course exists, so the reply reveals nothing about other schools. A plain foreign key wouldn't stop this, because Postgres checks foreign keys [without row-level security](https://www.postgresql.org/docs/current/ddl-rowsecurity.html). Every key in a generated create type goes through the scope this way.

`link showAssessment a.id` builds the `Location` header from the handler and its arguments. A link to a handler that no `api` table lists fails to compile.

### Submissions at the end of an exam

```lean
inductive SubmitError where
  | notFound
  | @[status 409] closed (deadline : Instant)
  deriving Problem

def submit (s : Scope Student) (id : Key Assessment) (body : Submission.Create) :
    Db 2 (Created Submission.View) SubmitError := do
  let some a ← Assessment.find s id | throw .notFound
  if (← now) > a.closesAt then throw (.closed a.closesAt)
  let sub ← Submission.insert s a body
  return .created (link showSubmission sub.id) sub

def showSubmission (s : Scope Student) (id : Key Submission) :
    Db 1 Submission.View NotFound :=
  Submission.get s id
```

`Assessment.find s` reaches an assessment only through the student's enrollments, as the model's `reach` attribute declares. `SubmitError` lists the errors `submit` can return, and the generated TypeScript client gets them as a discriminated union. `now` comes from the interpreter, so a test can set the clock.

`submit` doesn't mention retries. POST endpoints accept an idempotency key by default, and the generated client sends one, so a client that retries after a timeout still stores one submission.

### The tenant app's routes

```lean
api Grading where
  POST "/grade"                       => gradeItem
  GET  "/assessments"                 => listAssessments
  GET  "/assessments/:id"             => showAssessment
  POST "/assessments"                 => createAssessment
  POST "/assessments/:id/submissions" => submit
  GET  "/submissions/:id"             => showSubmission
```

### What holds in the tenant app

| Code | What holds | Evidence |
|---|---|---|
| `inRange` | A score stays between zero and the item's maximum | Proved by the author, checked on decode |
| `grade_eq_mapResponse` | A score equals QTI's `mapResponse` for the same item and response | Proved by the author, once written |
| `mapResponse` | The plain definition matches QTI's own examples | Tested |
| `keysDistinct` | An item maps each choice at most once | Checked on decode |
| `Scope Teacher` | Only sign-in can build a scope | Typed |
| `Assessment.list s` | Every row returned belongs to the school | Proved over the model, by the prototype's `scopedSelect_tenant` |
| `Assessment.list s` | Every row returned belongs to the teacher | Proved over the model, as a new extension of the tenant proof |
| `Assessment.insert s` | A new assessment's course belongs to the same teacher and school | Proved over the model, new design |
| `Assessment.find s` | A student reaches only assessments of their own courses | Proved over the model, new design |
| `Assessment.Create` | A request can't set the school, the teacher or the ID | Typed |
| `link showAssessment` | The link reaches that handler with those arguments | Proved |
| `SubmitError` | `submit` returns only the errors it declares | Typed |
| `closesAt : Instant` | Code that compares a deadline with a local time fails to compile | Typed |
| idempotency key | A retry stores the submission once | Proved over the model, Tested |
| Postgres policies | A raw query still can't cross schools | Enforced by Postgres |

The author writes two proofs, `inRange` and `grade_eq_mapResponse`, and both are about grading. That meets the roadmap's target of proofs only for grading rules.

## Messages for common mistakes

Each rejection gets a `#guard_msgs` test with its exact text. Axum and Servant both improved their messages after release. Axum added [`#[debug_handler]`](https://docs.rs/axum-macros/latest/axum_macros/attr.debug_handler.html), and Servant 0.19 added [custom type errors](https://hackage.haskell.org/package/servant/changelog) for partly applied combinators. The messages below are targets, and part of the work is finding out whether a Lean macro can produce each one.

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

A GET handler that reads a body gets this one.

```text
handler `listAssessments` reads `filter : Filter` as a JSON body, but a GET request has no body.
Derive `QueryParams` for `Filter` to read it from the query string.
```

A float in an API type gets this one.

```text
`Float` has no wire codec. lean-json writes NaN and the infinities as strings,
so a `Float` field would hold a number or a string. Use an integer count of the smallest unit, such as cents.
```

Setting a field the model owns, such as `{ body with teacher := t }`, already fails with Lean's own message that `teacher` is not a field of `Assessment.Create`.

## JSON from the author's side

The [lean-json note](lean-json.md) records the JSON decisions. We checked each statement here about lean-json against its commit `4a0cf59`.

- `deriving Json` gives `ToJson`, `FromJson`, `LawfulJson`, `WireJson` and the schema. An author meets the classes only when writing a codec by hand.
- Integers of 64 bits or more, such as `Nat`, `Int`, `UInt64` and `Int64`, travel as decimal strings, as [client and server agreement](../../ROADMAP.md#client-and-server-agree) says. Smaller integers travel as numbers. lean-json writes `Nat` and `Int` as numbers and `UInt64` as a string. It has no instances for `Int64` or for the 8, 16 and 32-bit types, so Espal needs its own. Espal's `Small` travels as a number.
- lean-json leaves out a field named `note?` when it is `none`, and it decodes both `null` and a missing key to `none`. The TypeScript client types the field as `note?: string`. `Option (Option α)` doesn't round trip, so update types use their own three-state type for nullable columns.
- A decoder checks each decidable proof field, as in `Title`, `Item` and `Graded`. We wrote one such codec by hand, and its round-trip theorem needed only `propext`.
- lean-json's derived decoders report errors such as `Order.items: Item.price: expected a number`. The message names types and fields but gives no array index. The decoder stops at the first failure and reads a missing field as `null`. Problem details need a JSON Pointer such as `#/items/1/price`, every failure at once, and "missing" for a missing field. [lean-json#7](https://github.com/paulbutcher/lean-json/issues/7) asks for a structured decode error that includes the path.
- lean-json's derived decoders ignore keys the type doesn't have, and Espal [rejects them](#decisions). [lean-json#7](https://github.com/paulbutcher/lean-json/issues/7) asks for an option, and Espal's own derived decoder is the fallback.

A bad request gets one response that lists every failure, in the format of RFC 9457's own example.

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

Malformed JSON gets `400`. A body that parses but fails its types or checks gets `422`, which RFC 9110 defines for content the server can parse but not process. The roadmap's [packages milestone](../../ROADMAP.md#packages-endpoints-and-the-json-api) says the same.

## Decisions

We settled these in October 2026, before any macro work.

1. A table names handler definitions, and the macro reads their types from their signatures, so a handler stays an ordinary function that tests can call. We passed over the prototype's layout, which declared each endpoint's types in the table and implemented them all in one `match`. We also passed over an attribute such as `@[get "/db"]` on each definition, which spreads routes across files.
2. Each signature takes an access value, `Public` or a `Scope`, so a new handler can't leave it out. A table that marked a group of routes public once would repeat less, but a route added to that group would be public until review caught it.
3. Decoders reject keys a type doesn't have, with a `422` that names the key. That catches typos and fields the server doesn't know. A newer client calling an older server would then fail during a rolling deploy. So the generated client of each release sends only request fields that the previous release's server accepts, and CI checks that against the previous release's API description.
4. Each check is a proof field, which the handler, the decoder and the OpenAPI description share. Code that builds such a value supplies the proof, with `by decide`, `by omega`, or an `if h :` test at run time.
5. Scores and other counts that need proofs use Espal's `Small`, a `Nat` below 2^53. It travels as a JSON number and has no `+`, so it can't wrap. We passed over `Nat`, which travels as a string, `UInt32`, whose range proof needs two `toNat` lemmas, and `Fin (2^53)`, whose `+` wraps.
6. The grading theorem states QTI's rule as its own definition, `mapResponse`, and proves that `grade` matches it. That pins the exact score. A theorem that a repeated choice leaves the score unchanged would rule out only one bug.
