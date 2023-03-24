(** This file is based on FirstOrder.v from mirrorsolve but avoids
    using dependently typed syntax.  *)
Require Import Coq.Strings.String.
Require Import Poulet4.P4flat.Sig.
Require Import Coq.Classes.EquivDec.

Section FOL.
  Variable (var: Type).
  Context `{Equivalence var eq}.
  Context `{EqDec var eq}.
  Variable (sig: signature).

  (* First-order terms (either functions or variables). *)
  Inductive tm: Type :=
  | TVar (v: var)
  | TFun (f: sig.(sig_funs))
         (args: list tm).

  (* First-order formulas. *)
  Inductive fm: Type :=
  (* True and False *)
  | FTrue
  | FFalse
  (* Equality *)
  | FEq (t1 t2: tm)
  (* A relation (with arguments) *)
  | FRel (r: sig.(sig_rels))
         (args: list tm)
  (* Negation, disjunction, conjunction, and implication *)
  | FNeg (f: fm)
  | FOr (f1 f2: fm)
  | FAnd (f1 f2: fm)
  | FImpl (f1 f2: fm).

  Fixpoint tm_subst (x: var) (e: tm) (t: tm) : tm :=
    match t with
    | TVar v =>
        if v == x then e else t
    | TFun f args =>
        TFun f (List.map (tm_subst x e) args)
    end.

  Fixpoint fm_subst (x: var) (e: tm) (f: fm) : fm :=
    match f with
    | FTrue
    | FFalse => f
    | FEq t1 t2 =>
        FEq (tm_subst x e t1)
            (tm_subst x e t2)
    | FRel r args =>
        FRel r (List.map (tm_subst x e) args)
    | FNeg f =>
        FNeg (fm_subst x e f)
    | FOr f1 f2 =>
        FOr (fm_subst x e f1)
            (fm_subst x e f2)
    | FAnd f1 f2 =>
        FAnd (fm_subst x e f1)
             (fm_subst x e f2)
    | FImpl f1 f2 =>
        FImpl (fm_subst x e f1)
              (fm_subst x e f2)
    end.

End FOL.

Arguments TVar {var sig}.
Arguments TFun {var sig}.
Arguments FEq {var sig}.
Arguments FRel {var sig}.
Arguments FNeg {var sig}.
Arguments FOr {var sig}.
Arguments FAnd {var sig}.
Arguments FImpl {var sig}.
Arguments tm_subst {var _ _ sig} x e t.
Arguments fm_subst {var _ _ sig} x e f.

Fixpoint tm_map_vars {V W sig} (m: V -> W) (t: tm V sig) : tm W sig :=
  match t with
  | TVar v => TVar (m v)
  | TFun f args => TFun f (List.map (tm_map_vars m) args)
  end.

Fixpoint fm_map_vars {V W sig} (m: V -> W) (f: fm V sig) : fm W sig :=
  match f with
  | FTrue _ _ => FTrue _ _
  | FFalse _ _ => FFalse _ _
  | FEq t1 t2 => FEq (tm_map_vars m t1) (tm_map_vars m t2)
  | FRel r args => FRel r (List.map (tm_map_vars m) args)
  | FNeg f => fm_map_vars m f
  | FOr f1 f2 => FOr (fm_map_vars m f1) (fm_map_vars m f2)
  | FAnd f1 f2 => FAnd (fm_map_vars m f1) (fm_map_vars m f2)
  | FImpl f1 f2 => FImpl (fm_map_vars m f1) (fm_map_vars m f2)
  end.
