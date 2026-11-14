/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalPostgres.Connection
public import EspalPostgres.Libpq
public import EspalPostgres.Pool

/-!
# espal-postgres

Espal's Postgres client. `Pool.connect` opens connections, and `Pool.database` is the `Database`
that a served table runs its statements on.
-/
