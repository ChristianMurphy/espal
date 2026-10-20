module

import Cedar.Spec

/-! The smallest program that runs Cedar's authorizer, to measure the binary that `Cedar.Spec` gives. -/

open Cedar.Spec

public def main : IO Unit :=
  IO.println (repr (isAuthorized default default []).decision)
