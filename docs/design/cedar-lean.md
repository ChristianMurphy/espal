# cedar-lean as the permission engine

Espal checks permissions with [cedar-lean](https://github.com/cedar-policy/cedar-spec/tree/main/cedar-lean)'s authorizer, and sends the changes it needs upstream first. This note records the decision from the cedar-lean trial in the [spikes and a baseline](../../ROADMAP.md#spikes-and-a-baseline) milestone, made in October 2026. The [trial's README](https://github.com/ChristianMurphy/espal/blob/explore/cedar-lean/explorations/cedar-lean/README.md) on the `explore/cedar-lean` branch has the setup and every result.

## What Espal takes

- `Cedar.Spec.isAuthorized`, with Cedar's policies, entities and requests.
- The theorems behind [every endpoint checks permission](../../ROADMAP.md#every-endpoint-checks-permission). They cover default deny, forbid beats permit and the validator's soundness.
- The validator, to check an app's policies against its schema when the app builds.

## Why

- All of cedar-lean, proofs included, built on Lean 4.35.0 with no change. On 4.36.0-rc1, three proofs in `Cedar/Data/LT.lean` need a new lemma name.
- The theorems use only Lean's three standard axioms. Cedar fuzzes its Rust engine against this model.
- With six policies and the five entities a request touches, a check took 6.7 µs. That is about 1 percent of the CPU Std.Http spends on a request.
- The Cedar team changed cedar-lean 24 times between 20 July and 19 October 2026. It has moved to nearly every Lean release since April.

## What has to change upstream

- **Binary size.** A program that only calls `isAuthorized` is 119 MB on Lean 4.35.0, against the 10 MB target. Four Batteries tactic modules, and the `Lean.ToJson` derivations in four files of `Cedar.Spec` and `Cedar.Data`, pull in the Lean package at run time. With both changed, the same program is 4.6 MB on 4.36.0-rc1, where the test ran. [cedar-spec#1065](https://github.com/cedar-policy/cedar-spec/pull/1065) moved the JSON derivations into `Cedar.Spec.Json` in October 2026. [batteries#2034](https://github.com/leanprover-community/batteries/pull/2034), which changes the Batteries imports, still waits for a review.
- **Theorems in the module system.** [cedar-spec#1064](https://github.com/cedar-policy/cedar-spec/pull/1064) made `Cedar.Thm.Authorization` a module in October 2026. Espal can now import and cite its theorems, where the trial proved the guarantees again over `isAuthorized` in 49 lines.
- **Lean 4.36.** Three proofs in `Cedar/Data/LT.lean` need the new lemma name. [cedar-spec#1058](https://github.com/cedar-policy/cedar-spec/issues/1058) offered the fix, and the Cedar team plans to make it when it moves to the stable 4.36.0 release.

If the Batteries change doesn't land, Espal copies `Cedar.Spec` and `Cedar.Data` with the Apache 2.0 notice. The copy leaves out the Batteries tactics.

## What Espal adds

- Policies written as Lean values, through a macro of its own, since cedar-lean has no parser for Cedar's policy text.
- The entities each request touches, loaded from Postgres. `Map.find?` scans a sorted list, so a check slows as the entity map grows.
- An index of policies by action if apps grow to hundreds of policies, proved to give the same response as the full set.
