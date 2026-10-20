# cedar-lean trial

This trial checks [cedar-lean](https://github.com/cedar-policy/cedar-spec/tree/main/cedar-lean) as Espal's permission engine, for the dependency trials in the [spikes and a baseline](../../ROADMAP.md#spikes-and-a-baseline) milestone. It pins commit `7893e68` of cedar-spec from 19 October 2026, under the Apache 2.0 license. cedar-lean is the Lean model of Cedar that the Cedar team proves theorems about and tests the Rust engine against.

## Files

- `Trial/Probe.lean` imports `Cedar.Spec` from a module.
- `Trial/Guarantees.lean` proves two of Cedar's authorization guarantees in a module.
- `AuthzBench.lean` times `isAuthorized`, and `authz-bench.txt` holds its output.
- `SpecSize.lean` is the smallest program that calls `isAuthorized`, to measure its binary.
- `patches/lean-4.36.patch` lets `Cedar.Spec` build on Lean 4.36.0-rc1.

## Running it

```bash
lake build                       # builds Cedar.Spec and checks the proofs in Trial/
lake build Cedar SymCC           # builds all of cedar-lean, with its proofs
taskset -c 2 .lake/build/bin/authz-bench 5
```

## Builds

cedar-lean pins Lean 4.34.1 and Batteries v4.34.0. The trial requires the Batteries release that matches each Lean version.

| Lean | Change to cedar-lean | `Cedar.Spec` from a module | All of cedar-lean, with proofs |
|---|---|---|---|
| 4.35.0 | none | builds | builds in 4 minutes on 4 vCPUs, with 12 warnings |
| 4.36.0-rc1 | three lines in `Cedar/Data/LT.lean` | builds | not tried |

On Lean 4.36.0-rc1, `String.lt_iff` is deprecated, and three proofs in `Cedar/Data/LT.lean` fail. Rewriting with `String.toList_lt_toList_iff` in reverse fixes them. That lemma doesn't exist in 4.35.0, so the fix belongs with cedar-lean's move to 4.36.

## What Espal can cite

[Every endpoint checks permission](../../ROADMAP.md#every-endpoint-checks-permission) names three guarantees. cedar-lean proves each of them in `Cedar.Thm`.

- `default_deny` and `allowed_only_if_explicitly_permitted` say that a request is denied unless a permit policy is satisfied.
- `forbid_trumps_permit` says that a satisfied forbid policy denies the request.
- `validation_is_sound` covers policies that the validator accepts, with a request and entities that match the schema. Each policy then evaluates to a boolean or to one of three runtime errors.

These four theorems use only the axioms `propext`, `Classical.choice` and `Quot.sound`, as `#print axioms` shows. So does `isAuthorized_eq_for_scope_based_policy_slice`. It says that a slice of the policies, picked by their scopes, gets the same response as all of them. Cedar's `cedar-drt` fuzzes the Rust authorizer, evaluator and validator against this model.

`Cedar.Spec`, `Cedar.Data` and `Cedar.Validation` use Lean's module system. 58 of the 226 files in `Cedar/Thm` do, and `Cedar.Thm.Authorization` and the slicing code don't. So an Espal module can call `isAuthorized`, but it can't import those theorems. `Trial/Guarantees.lean` proves the first two guarantees again in a module, in 49 lines with the standard axioms. It reads `isAuthorized`'s body through `import all Cedar.Spec.Authorizer`.

cedar-lean has no parser for Cedar's policy text. The Rust tools parse policies and send them to Lean as protobuf. Espal would write policies as Lean values, through a macro of its own.

## Cost per check

`AuthzBench.lean` models a grading app with users, roles, courses, assignments and submissions. Six policies cover admins, teachers who grade, students who submit or view their own work, closed assignments and suspended users. The benchmark adds 100 or 1,000 permits for teaching assistants, and 100 or 1,000 users that no request touches. It checks that four requests get the expected decision, with and without slicing, and then times them.

The table gives the median µs per check over five runs, with the range. The benchmark ran on one pinned CPU of a 4-vCPU Xeon VM at 2.1 GHz. "Sliced" first picks the policies whose scope fits the request, then authorizes against those.

| Policies | Entities | All policies | Sliced |
|---|---|---|---|
| 6 | 5 | 6.65 (6.21 to 8.80) | 5.15 (4.88 to 6.01) |
| 6 | 105 | 23.8 (22.7 to 25.0) | 16.0 (15.6 to 17.1) |
| 6 | 1,005 | 168 (159 to 181) | 105 (101 to 109) |
| 106 | 5 | 63.6 (61.5 to 66.7) | 30.5 (29.8 to 31.0) |
| 106 | 105 | 82.9 (79.5 to 89.5) | 275 (268 to 283) |
| 106 | 1,005 | 239 (229 to 243) | 2,482 (2,473 to 2,538) |
| 1,006 | 5 | 602 (573 to 612) | 266 (259 to 291) |
| 1,006 | 105 | 590 (579 to 686) | 2,703 (2,573 to 2,737) |
| 1,006 | 1,005 | 791 (723 to 830) | 23,235 (22,787 to 23,343) |

In the [HTTP spike](../../bench/results/http/2026-10-18-cloud-4vcpu/README.md), Std.Http spent about 540 µs of CPU per request on the same VM. With six policies and five entities, a check adds about 1 percent to that, and with 106 policies about 12 percent.

- `isAuthorized` evaluates every policy, so its cost grows with the number of policies.
- `Map` and `Set` hold sorted lists, and `Map.find?` scans them. Each entity lookup costs time in proportion to the size of the entity map.
- Slicing looks up the principal once per policy. It helps with a few entities, and with many entities it costs more than it saves.

So Espal would pass only the principal, the resource and their ancestors, which the handler loads from Postgres anyway. With many policies, an index by action, proved sound the way cedar-lean proves its slicing sound, would keep the cost down.

## Binary size

`SpecSize.lean`, which only calls `isAuthorized`, builds a 119 MB binary, or 79 MB stripped. Espal's target is 10 MB. The compiled code of `Batteries.Tactic.Init` and `Batteries.Tactic.Alias` calls into the Lean package at start-up. `Cedar.Data.LT` imports the first, and Batteries' list lemmas import the second. Four Cedar files derive `Lean.ToJson`, which does the same. Removing those instances alone left the binary at 119 MB.

## Code style

Espal's `scripts/Lint.lean` reports 2 problems in `Cedar.Spec` and 5 in `Cedar.Data`.

- The derived `Repr` instances for `Value` and `Expr` are `partial`.
- `Map.find!` can panic.
- Two lemmas in `Cedar.Data.Int64` use `native_decide`, which adds an axiom for each. The four theorems above don't depend on them.

## Size and activity

- 3,201 lines of Lean in `Cedar/Spec` and `Cedar/Data`, and about 97,000 in `Cedar/Thm`.
- 24 commits changed cedar-lean between 20 July and 19 October 2026, by 8 people on the Cedar team.

## Options

1. **Keep it as it is.** Espal calls `isAuthorized` on each request, with the entities that request touches, and proves the guarantees in its own modules as `Trial/Guarantees.lean` does. Binaries stay over 100 MB.
2. **Adapt it, upstream first.** Espal depends on `Cedar.Spec` as in option 1. It asks upstream to move `Cedar.Thm.Authorization` to the module system, and to keep the Lean package out of its run-time imports. The Batteries imports need a change in Batteries too.
3. **Copy the authorizer.** Espal copies `Cedar.Spec` and `Cedar.Data` with the Apache 2.0 notice, without the JSON instances and the Batteries tactics, and proves the guarantees itself. It loses the validator's soundness proof and Cedar's differential tests, unless it copies those too.
4. **Replace it.** Espal writes a permission model of its own, with its own proofs of default deny and forbid beats permit. It loses Cedar's policy language, validator and tooling.
