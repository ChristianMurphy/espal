/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import Routing.Route
import Std.Data.String.ToNat
import all Std.Http.Data.Method

/-!
# Route tables whose links reach their routes

lean-routing's `matchTable` tries routes in order and takes the first that matches. An earlier
route can then catch a link built for a later one, as `/users/new` catches the link for a user
named `new` under `/users/:id:String`. `linksDisjoint` rules that out for a whole table.
`matchTable_pathOf` shows that every link then reaches the route it was built for, with the
arguments it was built from.

The paths here are decoded segments. Percent-encoding them, and reading them back out of a request
target, is the HTTP layer's job.
-/

@[expose] public section

namespace Espal.Route

open Routing

/-- One value per capture in `segs`, in order. -/
def Args : List PathSeg → Type
  | [] => Unit
  | .lit _ _ :: rest => Args rest
  | .capture _ kind :: rest => kind.type × Args rest

/-- The decoded segments of the link built from `args`. -/
def pathOf : (segs : List PathSeg) → Args segs → List String
  | [], _ => []
  | .lit s _ :: rest, args => s :: pathOf rest args
  | .capture _ .nat :: rest, (n, args) => toString n :: pathOf rest args
  | .capture _ .string :: rest, (s, args) => s :: pathOf rest args

/-- Every `String` capture in `args` is one a link can carry: not empty, `.` or `..`. -/
def Linkable : (segs : List PathSeg) → Args segs → Prop
  | [], _ => True
  | .lit _ _ :: rest, args => Linkable rest args
  | .capture _ .nat :: rest, (_, args) => Linkable rest args
  | .capture _ .string :: rest, (s, args) => unlinkable s = false ∧ Linkable rest args

/-- The handler applied to `args`. -/
def applyHandler {α : Type} : (segs : List PathSeg) → HandlerType segs α → Args segs → α
  | [], h, _ => h
  | .lit _ _ :: rest, h, args => applyHandler rest h args
  | .capture _ _ :: rest, h, (a, args) => applyHandler rest (h a) args

/-- Whether `cs` spells a numeral that `toString` writes for a `Nat`. Such a numeral is one or more
decimal digits with no leading zero. -/
def decimalDigits : List Char → Bool
  | [] => false
  | c :: cs => (c :: cs).all Char.isDigit && (c != '0' || cs.isEmpty)

/-- Whether a `Nat` capture accepts `s`. `natAccepts_eq` proves it equals
`(Internal.parseNat? s).isSome`. The kernel can evaluate it from any module, unlike `String.toNat?`
and `toString`, so `decide +kernel` can check a table. -/
def natAccepts (s : String) : Bool :=
  decimalDigits s.toList

/-- Whether `dispatch` can accept, for the segment `j`, a segment that a link renders for `i`. -/
def segAccepts : PathSeg → PathSeg → Bool
  | .lit a _, .lit b _ => a == b
  | .lit a _, .capture _ .nat => natAccepts a
  | .lit a _, .capture _ .string => !unlinkable a
  | .capture _ .nat, .lit b _ => natAccepts b
  | .capture _ .nat, .capture _ _ => true
  | .capture _ .string, .lit b _ => !unlinkable b
  | .capture _ .string, .capture _ _ => true

/-- Whether `dispatch` on `js` can accept a path that a link renders for `is`. `dispatch` also
accepts one trailing empty segment, so a pattern ending in `.lit ""` overlaps the pattern without
it. -/
def overlaps : List PathSeg → List PathSeg → Bool
  | [], [] => true
  | [], [.lit s _] => s == ""
  | j :: js, i :: is => segAccepts j i && overlaps js is
  | _, _ => false

/-- No route accepts a path that a link renders for a later route with the same method. Methods
compare with `DecidableEq`, since the kernel can't unfold `Method`'s `BEq` instance outside
`Std.Http`. -/
def linksDisjoint {α : Type} : List (Route α) → Bool
  | [] => true
  | r :: rs =>
    rs.all (fun i => decide (r.method ≠ i.method) || !overlaps r.segs i.segs) && linksDisjoint rs

/-- A `Nat` capture matches the digits a link renders for it. -/
theorem parseNat?_toString (n : Nat) : Internal.parseNat? (toString n) = some n := by
  simp [Internal.parseNat?, Option.filter, toString, Nat.toNat?_repr]

/-- A `Nat` capture accepts only the digits `toString` prints. -/
theorem toString_of_parseNat? {s : String} {n : Nat} (h : Internal.parseNat? s = some n) :
    toString n = s := by simp_all [Internal.parseNat?, Option.filter_eq_some_iff]

/-- `decimalDigits` as a proposition. -/
theorem decimalDigits_iff {cs : List Char} :
    decimalDigits cs = true ↔
      cs ≠ [] ∧ (∀ c ∈ cs, c.isDigit) ∧ (cs.head? = some '0' → cs.length = 1) := by
  rcases cs with _ | ⟨c, cs⟩
  · simp [decimalDigits]
  · simp only [decimalDigits, List.all_cons, ↓Char.isValue, Bool.and_eq_true, List.all_eq_true,
      Bool.or_eq_true, bne_iff_ne, ne_eq, List.isEmpty_iff, reduceCtorEq, not_false_eq_true,
      List.mem_cons, forall_eq_or_imp, List.head?_cons, Option.some.injEq, List.length_cons,
      Nat.add_eq_right, List.length_eq_zero_iff, true_and, and_congr_right_iff, and_imp]
    exact fun _ _ => Decidable.imp_iff_not_or.symm

/-- Only `0` prints with a leading zero. -/
theorem eq_zero_of_head?_toDigits (n : Nat) (h : (Nat.toDigits 10 n).head? = some '0') : n = 0 := by
  induction n using Nat.strongRecOn with
  | ind n ih =>
    rw [Nat.toDigits_eq_ite (by decide)] at h
    split at h
    · simpa using h
    · obtain ⟨c, cs, hcs⟩ := List.exists_cons_of_ne_nil (@Nat.toDigits_ne_nil (n / 10) 10)
      rw [hcs, List.cons_append, List.head?_cons] at h
      have := ih (n / 10) (by omega) (by rw [hcs, List.head?_cons, h])
      omega

/-- Every numeral `toString` writes passes `decimalDigits`. -/
theorem decimalDigits_toDigits (n : Nat) : decimalDigits (Nat.toDigits 10 n) = true := by
  refine decimalDigits_iff.mpr ⟨Nat.toDigits_ne_nil, fun _ hc => ?_, fun h => ?_⟩
  · exact Nat.isDigit_of_mem_toDigits (by decide) (by decide) hc
  · obtain rfl := eq_zero_of_head?_toDigits n h
    simp [Nat.toDigits_zero]

/-- `Nat.digitChar` turns a decimal digit's value back into the digit. -/
theorem digitChar_toNat_sub {d : Char} (hd : d.isDigit) : (d.toNat - 48).digitChar = d := by
  rw [Char.isDigit_iff_toNat] at hd
  simp at hd
  rw [← Char.toNat_inj, Nat.toNat_digitChar_of_lt_ten (by omega)]
  omega

/-- Printing the value of a numeral `decimalDigits` accepts gives the numeral back. -/
theorem toDigits_ofDigitChars (cs : List Char) (h : decimalDigits cs = true) :
    Nat.toDigits 10 (Nat.ofDigitChars 10 cs 0) = cs := by
  obtain ⟨rs, rfl⟩ : ∃ rs : List Char, cs = rs.reverse := ⟨cs.reverse, by simp⟩
  induction rs with
  | nil => simp [decimalDigits] at h
  | cons d rs ih =>
    obtain ⟨-, hd, hz⟩ := decimalDigits_iff.mp h
    simp only [List.reverse_cons] at *
    generalize rs.reverse = ds at ih hd hz ⊢
    have hdd : d.isDigit := hd d (by simp)
    have he : d.toNat - 48 < 10 := by
      have := Char.isDigit_iff_toNat.mp hdd
      simp at this
      omega
    rw [Nat.ofDigitChars_append, Nat.ofDigitChars_cons, Nat.ofDigitChars_nil]
    simp only [Char.reduceToNat]
    cases ds with
    | nil =>
      simp only [Nat.ofDigitChars_nil, Nat.mul_zero, Nat.zero_add, List.nil_append]
      rw [Nat.toDigits_of_lt_base he, digitChar_toNat_sub hdd]
    | cons c cs =>
      have hc : c ≠ '0' := fun h0 => by simpa using hz (by simp [h0])
      have hcs : decimalDigits (c :: cs) = true :=
        decimalDigits_iff.mpr
          ⟨List.cons_ne_nil c cs, fun x hx => hd x (List.mem_append_left _ hx), fun h =>
            absurd (by simpa using h) hc⟩
      have ih' := ih hcs
      generalize Nat.ofDigitChars 10 (c :: cs) 0 = x at ih' ⊢
      have hx : x ≠ 0 := by
        rintro rfl
        rw [Nat.toDigits_zero, List.cons.injEq] at ih'
        exact hc ih'.1.symm
      rw [Nat.toDigits_eq_ite (by decide)]
      split
      · omega
      have h1 : (10 * x + (d.toNat - 48)) / 10 = x := by omega
      have h2 : (10 * x + (d.toNat - 48)) % 10 = d.toNat - 48 := by omega
      rw [h1, h2, ih', digitChar_toNat_sub hdd]

/-- `natAccepts` agrees with the parser a `Nat` capture runs. -/
theorem natAccepts_eq (s : String) : natAccepts s = (Internal.parseNat? s).isSome := by
  cases hp : Internal.parseNat? s with
  | some n =>
    obtain rfl := toString_of_parseNat? hp
    simpa [natAccepts, toString, Nat.toList_repr] using decimalDigits_toDigits n
  | none =>
    cases hn : natAccepts s with
    | false => rfl
    | true =>
      have hs : toString (Nat.ofDigitChars 10 s.toList 0) = s := by
        rw [← String.toList_inj]
        simpa [toString, Nat.toList_repr] using toDigits_ofDigitChars s.toList hn
      rw [← hs, parseNat?_toString] at hp
      cases hp

/-- A route accepts every link built for its own pattern. -/
theorem dispatch_pathOf {α : Type} :
    ∀ (segs : List PathSeg) (h : HandlerType segs α) (args : Args segs),
      Linkable segs args → dispatch segs h (pathOf segs args) = some (applyHandler segs h args)
  | [], h, _, _ => by simp [pathOf, dispatch, applyHandler]
  | .lit s _ :: rest, h, args, hl => by
    simp only [pathOf, dispatch, BEq.rfl, ite_true, applyHandler]
    exact dispatch_pathOf rest h args hl
  | .capture _ .nat :: rest, h, (n, args), hl => by
    simp only [pathOf, dispatch, parseNat?_toString, Option.bind_some, applyHandler]
    exact dispatch_pathOf rest (h n) args hl
  | .capture _ .string :: rest, h, (s, args), ⟨hs, hl⟩ => by
    simp only [pathOf, dispatch, hs, Bool.false_eq_true, ite_false, applyHandler]
    exact dispatch_pathOf rest (h s) args hl

/-- A link has one segment per segment of its pattern. -/
theorem length_pathOf :
    ∀ (segs : List PathSeg) (args : Args segs), (pathOf segs args).length = segs.length
  | [], _ => rfl
  | .lit _ _ :: rest, args => by simp [pathOf, length_pathOf rest args]
  | .capture _ .nat :: rest, (_, args) => by simp [pathOf, length_pathOf rest args]
  | .capture _ .string :: rest, (_, args) => by simp [pathOf, length_pathOf rest args]

/-- The empty pattern accepts only the empty path and a lone empty segment. -/
theorem dispatch_nil_cons {α : Type} (h : HandlerType [] α) (p : String) (ps : List String)
    (hp : p :: ps ≠ [""]) : dispatch [] h (p :: ps) = none := by
  cases ps with
  | nil =>
    have : p ≠ "" := by
      rintro rfl; exact hp rfl
    simp [dispatch, this]
  | cons q qs => simp [dispatch]

/-- A pattern with a segment rejects the empty path. -/
theorem dispatch_cons_nil {α : Type} (j : PathSeg) (js : List PathSeg)
    (h : HandlerType (j :: js) α) : dispatch (j :: js) h [] = none := by
  rcases j with ⟨_, _⟩ | ⟨_, k⟩
  · rfl
  · cases k <;> rfl

/-- A route that `overlaps` rules out rejects every link built for the other pattern. -/
theorem dispatch_pathOf_eq_none {α : Type} :
    ∀ (js is : List PathSeg) (h : HandlerType js α) (args : Args is),
      overlaps js is = false → Linkable is args → dispatch js h (pathOf is args) = none
  | [], [], _, _, ho, _ => by simp [overlaps] at ho
  | [], [.lit s _], h, _, ho, _ => by
    simp only [overlaps, beq_eq_false_iff_ne, ne_eq] at ho
    simp [pathOf, dispatch, ho]
  | [], .lit s _ :: i :: is, h, args, _, _ => by
    apply dispatch_nil_cons
    intro heq
    have hl := length_pathOf (i :: is) args
    rw [(List.cons.inj heq).2] at hl
    simp at hl
  | [], [.capture _ .nat], h, (n, _), _, _ => by simp [pathOf, dispatch]
  | [], .capture _ .nat :: i :: is, h, (n, args), _, _ => by
    apply dispatch_nil_cons
    intro heq
    have hl := length_pathOf (i :: is) args
    rw [(List.cons.inj heq).2] at hl
    simp at hl
  | [], [.capture _ .string], h, (s, _), _, ⟨hs, _⟩ => by
    have : s ≠ "" := by
      rintro rfl; simp [unlinkable] at hs
    simp [pathOf, dispatch, this]
  | [], .capture _ .string :: i :: is, h, (s, args), _, _ => by
    apply dispatch_nil_cons
    intro heq
    have hl := length_pathOf (i :: is) args
    rw [(List.cons.inj heq).2] at hl
    simp at hl
  | j :: js, [], h, _, _, _ => dispatch_cons_nil j js h
  | .lit a _ :: js, .lit b _ :: is, h, args, ho, hl => by
    simp only [overlaps, segAccepts, Bool.and_eq_false_iff] at ho
    simp only [pathOf, dispatch]
    split
    · rcases ho with ho | ho
      · simp_all
      · exact dispatch_pathOf_eq_none js is h args ho hl
    · rfl
  | .lit a _ :: js, .capture _ .nat :: is, h, (n, args), ho, hl => by
    simp only [overlaps, segAccepts, Bool.and_eq_false_iff] at ho
    simp only [pathOf, dispatch]
    split
    · rename_i heq
      rcases ho with ho | ho
      · have : a = toString n := by simpa using heq
        subst this
        rw [natAccepts_eq, parseNat?_toString] at ho
        simp at ho
      · exact dispatch_pathOf_eq_none js is h args ho hl
    · rfl
  | .lit a _ :: js, .capture _ .string :: is, h, (s, args), ho, ⟨hs, hl⟩ => by
    simp only [overlaps, segAccepts, Bool.and_eq_false_iff] at ho
    simp only [pathOf, dispatch]
    split
    · rename_i heq
      rcases ho with ho | ho
      · have : a = s := by simpa using heq
        subst this
        simp_all
      · exact dispatch_pathOf_eq_none js is h args ho hl
    · rfl
  | .capture _ .nat :: js, .lit b _ :: is, h, args, ho, hl => by
    simp only [overlaps, segAccepts, Bool.and_eq_false_iff] at ho
    simp only [pathOf, dispatch]
    cases hb : Internal.parseNat? b with
    | none => rfl
    | some m =>
      rcases ho with ho | ho
      · simp [natAccepts_eq, hb] at ho
      · exact dispatch_pathOf_eq_none js is (h m) args ho hl
  | .capture _ .nat :: js, .capture _ .nat :: is, h, (n, args), ho, hl => by
    simp only [overlaps, segAccepts, Bool.true_and] at ho
    simp only [pathOf, dispatch, parseNat?_toString, Option.bind_some]
    exact dispatch_pathOf_eq_none js is (h n) args ho hl
  | .capture _ .nat :: js, .capture _ .string :: is, h, (s, args), ho, ⟨_, hl⟩ => by
    simp only [overlaps, segAccepts, Bool.true_and] at ho
    simp only [pathOf, dispatch]
    cases Internal.parseNat? s with
    | none => rfl
    | some m => exact dispatch_pathOf_eq_none js is (h m) args ho hl
  | .capture _ .string :: js, .lit b _ :: is, h, args, ho, hl => by
    simp only [overlaps, segAccepts, Bool.and_eq_false_iff] at ho
    simp only [pathOf, dispatch]
    split
    · rfl
    · rcases ho with ho | ho
      · simp_all
      · exact dispatch_pathOf_eq_none js is (h b) args ho hl
  | .capture _ .string :: js, .capture _ .nat :: is, h, (n, args), ho, hl => by
    simp only [overlaps, segAccepts, Bool.true_and] at ho
    simp only [pathOf, dispatch]
    split
    · rfl
    · exact dispatch_pathOf_eq_none js is (h (toString n)) args ho hl
  | .capture _ .string :: js, .capture _ .string :: is, h, (s, args), ho, ⟨hs, hl⟩ => by
    simp only [overlaps, segAccepts, Bool.true_and] at ho
    simp only [pathOf, dispatch, hs, Bool.false_eq_true, ite_false]
    exact dispatch_pathOf_eq_none js is (h s) args ho hl

/-- `Method` derives `BEq` without a `LawfulBEq` instance, so reflexivity needs its own proof. -/
theorem method_beq_self (m : Std.Http.Method) : (m == m) = true := by cases m <;> rfl

/-- `==` on two methods is true only when they are equal. -/
theorem method_eq_of_beq {a b : Std.Http.Method} (h : (a == b) = true) : a = b := by
  have hi : a.ctorIdx = b.ctorIdx := by simpa [BEq.beq, Std.Http.instBEqMethod.beq] using h
  rw [← Std.Http.Method.ofNat_ctorIdx a, ← Std.Http.Method.ofNat_ctorIdx b, hi]

/-- In a table where `linksDisjoint` holds, every link reaches the route it was built for, with the
arguments it was built from. -/
theorem matchTable_pathOf {α : Type} {routes : List (Route α)} (h : linksDisjoint routes = true)
    (i : Fin routes.length) (args : Args routes[i].segs) (hl : Linkable routes[i].segs args) :
    matchTable routes routes[i].method (pathOf routes[i].segs args) =
      some
        (⟨routes[i].method, routes[i].segs⟩,
          applyHandler routes[i].segs routes[i].handler args) := by
  induction routes with
  | nil => exact i.elim0
  | cons r rs ih =>
    simp only [linksDisjoint, Bool.and_eq_true, List.all_eq_true] at h
    rcases i with ⟨_ | k, hk⟩
    · simp only [Fin.getElem_fin, List.getElem_cons_zero] at args hl ⊢
      simp only [matchTable, List.findSome?_cons, Route.tryMatch, Route.tryDispatch,
        method_beq_self, ite_true, dispatch_pathOf r.segs r.handler args hl, Option.map_some]
    · have hk' : k < rs.length := by simpa using hk
      simp only [Fin.getElem_fin, List.getElem_cons_succ] at args hl ⊢
      have hr : r.tryMatch rs[k].method (pathOf rs[k].segs args) = none := by
        have hd := h.1 rs[k] (List.getElem_mem hk')
        simp only [Route.tryMatch, Route.tryDispatch, Option.map_eq_none_iff]
        split
        · rename_i hm
          simp only [method_eq_of_beq hm, ne_eq, not_true_eq_false, decide_false, Bool.false_or,
            Bool.not_eq_eq_eq_not, Bool.not_true] at hd
          exact dispatch_pathOf_eq_none r.segs rs[k].segs r.handler args hd hl
        · rfl
      simp only [matchTable, List.findSome?_cons, hr]
      exact ih h.2 ⟨k, hk'⟩ args hl

end Espal.Route
