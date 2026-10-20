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

- **Binary size.** A program that only calls `isAuthorized` is 119 MB on Lean 4.35.0, against the 10 MB target. Four Batteries tactic modules, and the `Lean.ToJson` derivations in four files of `Cedar.Spec` and `Cedar.Data`, pull in the Lean package at run time. With both changed, the same program is 4.6 MB on 4.36.0-rc1, where the test ran. [cedar-spec#1056](https://github.com/cedar-policy/cedar-spec/issues/1056) asks about the JSON instances.
- **Theorems in the module system.** A module can't import `Cedar.Thm.Authorization`, which [cedar-spec#1057](https://github.com/cedar-policy/cedar-spec/issues/1057) asks about. Until it can, Espal proves the guarantees again over `isAuthorized`, as the trial did in 49 lines.
- **Lean 4.36.** cedar-lean needs the three-line fix in `Cedar/Data/LT.lean`, which [cedar-spec#1058](https://github.com/cedar-policy/cedar-spec/issues/1058) offers.

If the size changes don't land, Espal copies `Cedar.Spec` and `Cedar.Data` with the Apache 2.0 notice. The copy leaves out the JSON instances and the Batteries tactics.

## What Espal adds

- Policies written as Lean values, through a macro of its own, since cedar-lean has no parser for Cedar's policy text.
- The entities each request touches, loaded from Postgres. `Map.find?` scans a sorted list, so a check slows as the entity map grows.
- An index of policies by action if apps grow to hundreds of policies, proved to give the same response as the full set.
