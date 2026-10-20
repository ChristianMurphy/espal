module

public import Cedar.Spec
import all Cedar.Spec.Authorizer
import Cedar.Thm.Data.Set

/-!
Restates two of Cedar's authorization theorems in a module, since `Cedar.Thm.Authorization` isn't
one and so a module can't import it. `import all` makes `isAuthorized`'s body visible here.
-/

open Cedar.Spec

/-- A request is allowed only when some permit policy is satisfied. -/
public theorem allow_needs_permit (req : Request) (es : Entities) (ps : Policies)
    (h : (isAuthorized req es ps).decision = .allow) :
    ∃ p ∈ ps, p.effect = .permit ∧ satisfied p req es := by
  simp only [isAuthorized] at h
  split at h
  · rename_i hc
    simp only [Bool.and_eq_true, Bool.not_eq_true'] at hc
    have hne : ps.filterMap (satisfiedWithEffect .permit · req es) ≠ [] := by
      intro h0
      have := hc.2
      simp [satisfiedPolicies, h0] at this
    obtain ⟨id, hid⟩ := List.exists_mem_of_ne_nil _ hne
    obtain ⟨p, hp, hsome⟩ := List.mem_filterMap.mp hid
    unfold satisfiedWithEffect at hsome
    split at hsome
    · rename_i hcond
      simp only [Bool.and_eq_true, beq_iff_eq] at hcond
      exact ⟨p, hp, hcond.1, hcond.2⟩
    · simp at hsome
  · simp at h

/-- A satisfied forbid policy denies the request. -/
public theorem forbid_denies (req : Request) (es : Entities) (ps : Policies) (p : Policy)
    (hp : p ∈ ps) (he : p.effect = .forbid) (hs : satisfied p req es) :
    (isAuthorized req es ps).decision = .deny := by
  have hne : ps.filterMap (satisfiedWithEffect .forbid · req es) ≠ [] := by
    intro h0
    have hs' : satisfiedWithEffect .forbid p req es = some p.id := by
      simp [satisfiedWithEffect, he, hs]
    have : p.id ∈ ps.filterMap (satisfiedWithEffect .forbid · req es) :=
      List.mem_filterMap.mpr ⟨p, hp, hs'⟩
    simp [h0] at this
  have hf : (satisfiedPolicies .forbid ps req es).isEmpty = false := by
    simpa [satisfiedPolicies, Cedar.Data.Set.isEmpty_make] using hne
  simp [isAuthorized, hf]
