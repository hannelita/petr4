Set Warnings "custom-entry-overridden,parsing".
Require Import Coq.PArith.BinPosDef Coq.PArith.BinPos
        Coq.ZArith.BinIntDef Coq.ZArith.BinInt.

Require Import Poulet4.P4Arith Poulet4.P4cub.Syntax.AST
        Poulet4.P4cub.Syntax.Equality.

Module P := P4cub.
Module E := P.Expr.

Module SynDefs.
  Import E TypeNotations.

  Fixpoint width_of_typ (τ : t) : option nat :=
    match τ with
    | {{ Bool }} => Some 1%nat
    | {{ bit<w> }}
    | {{ int<w> }} => Some $ Pos.to_nat w
    | {{ error }}
    | {{ matchkind }} => Some 0%nat
    | {{ tuple ts }} =>
      ns <<| sequence $ List.map width_of_typ ts ;;
      List.fold_left Nat.add ns 0%nat
    | {{ struct { fs } }}
    | {{ hdr { fs } }} =>
      ns <<| sequence $ List.map (fun '(_,t) => width_of_typ t) fs ;;
      List.fold_left Nat.add ns 0%nat
    | {{ stack fs[s] }} =>
      ns <<| sequence $ List.map (fun '(_,t) => width_of_typ t) fs ;;
      (Pos.to_nat s * List.fold_left Nat.add ns 0%nat)%nat
    | TVar _ => None
    | {{ Str }} => Some 1%nat (* TODO: how wide is a string? *)
    | {{ enum _ { xs } }} => Some (length xs) (* TODO: how wide is an enum? *)
    end.
End SynDefs.

(** Restrictions on type-nesting. *)
Module ProperType.
  Import E TypeNotations TypeEquivalence.
  
  Section ProperTypeNesting.
    (** Evidence a type is a base type. *)
    Inductive base_type : t -> Prop :=
    | base_bool : base_type {{ Bool }}
    | base_bit (w : positive) : base_type {{ bit<w> }}
    | base_int (w : positive) : base_type {{ int<w> }}.
    
    (** Allowed types within headers. *)
    Inductive proper_inside_header : t -> Prop :=
    | pih_bool (τ : t) :
        base_type τ ->
        proper_inside_header τ
    | pih_struct (ts : F.fs string t) :
        F.predfs_data base_type ts ->
        proper_inside_header {{ struct { ts } }}.
    
    (** Properly nested type. *)
    Inductive proper_nesting : t -> Prop :=
    | pn_base (τ : t) :
        base_type τ -> proper_nesting τ
    | pn_error : proper_nesting {{ error }}
    | pn_matchkind : proper_nesting {{ matchkind }}
    | pn_struct (ts : F.fs string t) :
        F.predfs_data
          (fun τ => proper_nesting τ /\ τ <> {{ matchkind }}) ts ->
        proper_nesting {{ struct { ts } }}
    | pn_tuple (ts : list t) :
        Forall
          (fun τ => proper_nesting τ /\ τ <> {{ matchkind }}) ts ->
        proper_nesting {{ tuple ts }}
    | pn_header (ts : F.fs string t) :
        F.predfs_data proper_inside_header ts ->
        proper_nesting {{ hdr { ts } }}
    | pn_header_stack (ts : F.fs string t)
                      (n : positive) :
        BitArith.bound 32%positive (Zpos n) ->
        F.predfs_data proper_inside_header ts ->
        proper_nesting {{ stack ts[n] }}.
    
    Import F.FieldTactics.
    
    Lemma proper_inside_header_nesting : forall τ,
        proper_inside_header τ ->
        proper_nesting τ.
    Proof.
      intros τ H. induction H.
      - inv H; repeat econstructor.
      - apply pn_struct.
        ind_predfs_data; constructor; auto; cbv.
        inv H; split; try (repeat constructor; assumption);
          try (intros H'; inv H'; contradiction).
    Qed.
  End ProperTypeNesting.
  
  Ltac invert_base_ludicrous :=
    match goal with
    | H: base_type {{ tuple _ }} |- _ => inv H
    | H: base_type {{ struct { _ } }} |- _ => inv H
    | H: base_type {{ hdr { _ } }} |- _ => inv H
    | H: base_type {{ stack _[_] }} |- _ => inv H
    end.
  (**[]*)
  
  Ltac invert_proper_nesting :=
    match goal with
    | H: proper_nesting _
      |- _ => inv H; try invert_base_ludicrous
    end.
  (**[]*)
End ProperType.