<h1>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/brand/espal-lockup-on-dark.svg">
    <img alt="Espal" src="docs/brand/espal-lockup-on-light.svg" width="300">
  </picture>
</h1>

Espal is a web framework for Lean 4 whose building blocks come with proofs. Build an endpoint from them and the proofs cover your code too. Lean checks them whenever the app builds.

Espal is in early development, and [Status](#status) says what works today.

## What it catches

These bugs pass type checks, tests and review in most stacks, and they reach production:

- **A query for each row in a loop.** Each endpoint declares how many database round trips it may make. A loop that runs a query per row has no fixed count, so it fails to build before it can flood the database.
- **A missing permission check.** Every endpoint declares the permission it needs. Its handler receives a value that only the permission check can create, so a handler that skips the check fails to build.
- **A query that forgets the tenant.** Queries against a tenant's tables go through a scope that only the signed-in session can create. A proof shows they return that tenant's rows alone.
- **A client and server that drift apart.** Routes, request bodies and responses come from one declaration, which generates the TypeScript client.

[ROADMAP.md](ROADMAP.md) lists every property Espal aims to prove, what each one assumes, and how it can break.

## What 0.1 includes

- **Routing.** Typed routes and links. A proof shows that parsing a route's path gives back the same route, and an endpoint that an earlier one shadows fails to build.
- **Endpoints and JSON.** Each endpoint declares its method, path, parameters, body, response, errors and permission. JSON codecs come with round-trip proofs. Large bodies stream, and Espal checks each element as it arrives.
- **Generated client.** An OpenAPI 3.2.1 description and a TypeScript client, both generated from the endpoints.
- **Models and migrations.** An attribute on an ordinary Lean structure declares a model. Migrations, seed data and test fixtures come from it, and the app checks the database schema when it starts.
- **Queries.** A query builder and query syntax in `do` notation, built on [lean-linq](https://github.com/palladin/lean-linq). Values travel as bind parameters, and a proof shows that no value changes the SQL text. Postgres comes first, and SQLite, MySQL, MariaDB and SQL Server follow after 0.1.
- **Pagination.** Lists use keyset pagination with signed cursors and `Link` headers. A page holds 25 items by default and 100 at most. Filters and sorts accept only the fields a route declares.
- **Errors and writes.** Errors follow RFC 9457 problem details and name the field that failed. Updates check `ETag` against `If-Match`, and writes accept idempotency keys.
- **Sign-in and permissions.** Sessions, passwords, OpenID Connect and roles, with a permission check on every endpoint.
- **Pages.** Server-rendered pages in a JSX-like syntax, with forms and partial page updates in the style of htmx. A proof shows that escaped text can't open a tag.
- **Jobs and mail.** Background jobs and scheduled tasks in a queue stored in Postgres, with outgoing mail sent through it.
- **Limits.** Defaults for body size, rows per query, statements per request and time per request. Under overload, new requests get `503` with `Retry-After`.
- **Stateless processes.** Handlers return their effects as data and keep no state between requests, so any process can serve any request.
- **Command line.** `espal` creates projects, endpoints, models and migrations, and prints a report for every route.

Later releases add HTTP caching, file uploads and OpenTelemetry. Caches and rate limits run outside the app process.

## Defaults and escape hatches

Every app starts with the defaults above, and a route can override them. When a proof gets in the way, `Espal.escape` lets code through with a reason. A report for each route lists every escape for a team to clean up. Linters flag new ones, and a strict profile rejects them.

## Performance

Espal aims to be fast enough for production APIs. The fixes in Lean 4.36.0-rc1 let its HTTP server handle 4.7 times as many requests as before. [Current numbers](bench/results/http/2026-10-19-runtimes/README.md) compare it with Node, Ruby, Python and Go.

## Who it's for

- **Mission-critical apps**, where a broken property costs more than the work of proving it.
- **Large teams.** The proofs keep holding as many people change the code.
- **Teams that use coding agents.** An agent can write the Lean while people review the properties a change claims. When a change breaks one, the build says which property and where.

## Status

The repository holds the eleven packages from the roadmap. `espal-route` provides the `api` command, whose tables come with a proof that every link reaches its route. It also holds typed routes and a decimal path codec with a proved round trip. `espal-json` adds JSON codecs on lean-json. It proves that basic types round trip, and `deriving Json` proves the same for structures and inductive types. `espal-core` holds the `Public` access value, and the other eight packages hold no code yet. A prototype proved statement budgets, tenant scoping, SQL injection safety, HTML escaping and client agreement. Everything else in this README describes plans for 0.1, and [ROADMAP.md](ROADMAP.md) tracks the work.

## Building

Espal uses [Lake](https://github.com/leanprover/lean4/tree/master/src/lake) and the Lean version pinned in `lean-toolchain`.

```bash
lake build      # library
lake test       # tests
```

## FAQ

### Do I have to write proofs?

Not for standard web concerns. The building blocks prove properties such as query budgets, tenant scoping and permission checks, and those proofs cover every endpoint built from them. Your application's own logic, such as how an invoice total adds up, needs proofs that you write.

### Where does the name come from?

Espal is short for espalier, a tree trained along a frame as it grows.

## License

Apache 2.0. See [LICENSE](LICENSE).
