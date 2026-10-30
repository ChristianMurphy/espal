/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import Json.FromTo

/-!
# Lawful JSON codecs

`LawfulJson α` says that decoding what `toJson` writes gives the value back, for every value of
`α`. It covers the trip from a value to a `Json` tree and back. Printing and parsing are a separate
step, which the design note's `WireJson` covers.

`Option α` writes `none` as `null`, so `none` and `some none` share an encoding in
`Option (Option α)`. Its instance therefore needs `NotNullJson α`, which says no value of `α`
encodes as `null`.

The classes take the form lean-json would give them. lean-json#6 asks whether they belong there.
-/

@[expose] public section

universe u v

namespace Espal

open Json

/-- `fromJson?` reads back what `toJson` writes. -/
class LawfulJson (α : Type u) [ToJson α] [FromJson α] : Prop where
  /-- Decoding an encoded value gives that value back. -/
  fromJson?_toJson (x : α) : fromJson? (toJson x) = .ok x

/-- `toJson` never writes `null`, so `Option α` can use `null` for `none`. -/
class NotNullJson (α : Type u) [ToJson α] : Prop where
  /-- No value encodes as `null`. -/
  toJson_ne_null (x : α) : toJson x ≠ .null

export LawfulJson (fromJson?_toJson)
export NotNullJson (toJson_ne_null)

instance : LawfulJson Json :=
  ⟨fun _ => rfl⟩

instance : LawfulJson Number :=
  ⟨fun _ => rfl⟩

instance : NotNullJson Number :=
  ⟨fun _ => nofun⟩

instance : LawfulJson Bool :=
  ⟨fun _ => rfl⟩

instance : NotNullJson Bool :=
  ⟨fun _ => nofun⟩

instance : LawfulJson String :=
  ⟨fun _ => rfl⟩

instance : NotNullJson String :=
  ⟨fun _ => nofun⟩

instance : LawfulJson Unit :=
  ⟨fun () => rfl⟩

instance : NotNullJson Unit :=
  ⟨fun _ => nofun⟩

instance {α : Type u} [ToJson α] [FromJson α] [LawfulJson α] : LawfulJson (Array α) where
  fromJson?_toJson xs := by
    show Array.mapM fromJson? (xs.map toJson) = .ok xs
    rw [Array.mapM_map]
    have : (fromJson? ∘ toJson : α → Except String α) = fun x => pure x := by
      funext x
      exact fromJson?_toJson x
    rw [this, Array.mapM_pure, Array.map_id']
    rfl

instance {α : Type u} [ToJson α] : NotNullJson (Array α) :=
  ⟨fun _ => nofun⟩

instance {α : Type u} [ToJson α] [FromJson α] [LawfulJson α] : LawfulJson (List α) where
  fromJson?_toJson l := by
    show Array.toList <$> fromJson? (toJson l.toArray) = .ok l
    rw [fromJson?_toJson]
    rfl

instance {α : Type u} [ToJson α] : NotNullJson (List α) :=
  ⟨fun _ => nofun⟩

instance {α : Type u} {β : Type v} [ToJson α] [FromJson α] [LawfulJson α] [ToJson β] [FromJson β]
    [LawfulJson β] : LawfulJson (α × β)
    where
  fromJson?_toJson p := by
    obtain ⟨a, b⟩ := p
    show prodFromJson? (.arr #[toJson a, toJson b]) = _
    simp [prodFromJson?, fromJson?_toJson]
    rfl

instance {α : Type u} {β : Type v} [ToJson α] [ToJson β] : NotNullJson (α × β) :=
  ⟨fun _ => nofun⟩

instance {α : Type u} [ToJson α] [FromJson α] [LawfulJson α] [NotNullJson α] : LawfulJson (Option α)
    where
  fromJson?_toJson
    | none => rfl
    | some a => by
      show optionFromJson? (toJson a) = _
      unfold optionFromJson?
      split
      · next h => exact absurd h (toJson_ne_null a)
      · simp [fromJson?_toJson]
        rfl

end Espal
