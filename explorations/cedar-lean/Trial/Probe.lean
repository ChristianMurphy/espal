module

public import Cedar.Spec

/-! Checks that a module can import Cedar's authorizer. -/

open Cedar.Spec

public def probeDecision : Decision :=
  (isAuthorized default default []).decision
