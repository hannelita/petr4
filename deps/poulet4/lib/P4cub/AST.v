Require Export Coq.Lists.List.
Export ListNotations.
Require Export Coq.Bool.Bool.
Require Export Coq.Classes.Morphisms.
Require Import Coq.PArith.BinPosDef.
Require Import Coq.PArith.BinPos.
Require Import Coq.ZArith.BinIntDef.
Require Import Coq.ZArith.BinInt.

Require Import Poulet4.P4Arith.
Require Export Poulet4.P4cub.Utiliser.

(** Notation entries. *)
Declare Custom Entry p4type.
Declare Custom Entry p4constructortype.
Declare Custom Entry p4uop.
Declare Custom Entry p4bop.
Declare Custom Entry p4matchkind.
Declare Custom Entry p4hdr_op.
Declare Custom Entry p4hdr_stk_op.
Declare Custom Entry p4expr.

Reserved Notation "∮ e1 ≡ e2"
         (at level 200, e1 custom p4expr, e2 custom p4expr, no associativity).

Declare Custom Entry p4stmt.
Declare Custom Entry p4decl.
Declare Custom Entry p4prsrexpr.
Declare Custom Entry p4prsrstate.
Declare Custom Entry p4ctrldecl.
Declare Custom Entry p4topdecl.

(** * Definitions and Lemmas regarding Fields *)
Module Field.
  Section FieldTypes.
    Variables K V : Type. (* key & value type. *)

    (** Field type. *)
    Definition f : Type := K * V.

    (** Fields. *)
    Definition fs : Type := list f.
  End FieldTypes.

  Section FieldLibrary.
    Definition key {K V : Type} : f K V -> K := fst.

    Definition value {K V : Type} : f K V -> V := snd.

    Definition keys {K V : Type} : fs K V -> list K := List.map key.

    Definition values {K V : Type} : fs K V -> list V := List.map value.

    Lemma key_value : forall {K V : Type} (fld : f K V),
        (key fld, value fld) = fld.
    Proof. intros K V []; reflexivity. Qed.

    Lemma keys_values : forall {K V : Type} (flds : fs K V),
        combine (keys flds) (values flds) = flds.
    Proof.
      induction flds as [| [? ?] ? ?]; unravel;
      try f_equal; assumption.
    Qed.

    (** Predicate on a field's data. *)
    Definition predf_data {K T : Type} (P : T -> Prop) : f K T -> Prop := P ∘ snd.
    (**[]*)

    (** Predicate over every data in fields. *)
    Definition predfs_data {K T : Type} (P : T -> Prop) : fs K T -> Prop :=
      Forall (predf_data P).
    (**[]*)

    Lemma predfs_data_map : forall {K V : Type} (P : V -> Prop) (flds : fs K V),
        predfs_data P flds <-> Forall P (map snd flds).
    Proof.
      induction flds as [| [k v] flds IHflds];
        unravel; split; intros H; inv H; constructor;
          unfold predfs_data, predf_data, "∘" in *;
          unravel in *; intuition.
    Qed.

    (** Filter. *)
    Definition filter {K U : Type} (pred : U -> bool) : fs K U -> fs K U :=
      List.filter (pred ∘ snd).
    (**[]*)

    (** Map. *)
    Definition map {K U V : Type} (f : U -> V) : fs K U -> fs K V :=
      List.map (fun '(x,u) => (x, f u)).
    (**[]*)

    Lemma map_fst : forall {K U V : Type} (g : U -> V) (flds : fs K U),
        List.map fst (map g flds) = List.map fst flds.
    Proof.
      intros; induction flds as [| [? ?] ? ?]; unravel; auto.
      rewrite IHflds; reflexivity.
    Qed.

    Lemma map_snd : forall {K U V : Type} (g : U -> V) (flds : fs K U),
        List.map snd (map g flds) = List.map (g ∘ snd) flds.
    Proof.
      intros; induction flds as [| [? ?] ? ?]; unravel in *; auto.
      rewrite IHflds; reflexivity.
    Qed.

    (** Fold. *)
    Definition fold {K U V : Type} (f : K -> U -> V -> V)
               (fds : fs K U) (init : V) : V :=
      List.fold_right (fun '(x,u) acc => f x u acc) init fds.
    (**[]*)

    Section GetUpdate.
      Context {K U : Type}.
      Context {keq : K -> K -> Prop}.
      Context `{Equivalence K keq}.
      Context `{EqDec K keq}.

      (** Member access. *)
      Fixpoint get (k : K) (fds : fs K U) : option U :=
        match fds with
        | []            => None
        | (k',u') :: fds => if equiv_dec k k' then Some u'
                          else get k fds
        end.
      (**[]*)

      (** Member update. *)
      Fixpoint update (k : K) (u : U) (fds : fs K U) : fs K U :=
        match fds with
        | [] => []
        | (k',u') :: fds => (k', if equiv_dec k k' then u else u') :: update k u fds
        end.
      (**[]*)
    End GetUpdate.

    Section FieldRelations.
      Context {K U V : Type}.
      Context {keq : K -> K -> Prop}.
      Context `{HK : Equivalence K keq}.
      Variable R : U -> V -> Prop.

      (** Relation betwixt two field instances. *)
      Definition relf : f K U -> f K V -> Prop :=
        fun u v => equiv (fst u) (fst v) /\ R (snd u) (snd v).
      (**[]*)

      (** Relation between two instances of fields. *)
      Definition relfs : fs K U -> fs K V -> Prop := Forall2 relf.
      (**[]*)

      Ltac inv_prod_eq :=
        match goal with
        | H: (_,_) = (_,_) |- _ => inv H
        end.
      (**[]*)

      Ltac let_pair_simpl :=
        match goal with
        | H: context [let (_,_) := ?x in _]
          |- context [let (_,_) := ?x in _] => destruct x as [? ?] eqn:?
        | H: context [let (_,_) := ?x in _] |- _ => destruct x as [? ?] eqn:?
        | |- context [let (_,_) := ?x in _] => destruct x as [? ?] eqn:?
        | H: (_,_) = (_,_) |- _ => inv H
        end.
      (**[]*)

      Lemma relfs_split : forall us vs,
          relfs us vs ->
          let (xus, uus) := split us in
          let (xvs, vvs) := split vs in
          Forall2 keq xus xvs /\ Forall2 R uus vvs.
      Proof.
        intros us vs H; induction H;
        unfold relf in *; unravel in *; intuition.
        destruct x as [xu u]; destruct y as [xv v]; simpl in *.
        repeat let_pair_simpl. intuition.
      Qed.

      Lemma combine_relfs : forall xus xvs uus vvs,
          Forall2 keq xus xvs -> Forall2 R uus vvs ->
          let us := combine xus uus in
          let vs := combine xvs vvs in
          relfs us vs.
      Proof.
        intros xus xvs uus vvs Hu Hv;
        generalize dependent vvs; generalize dependent uus.
        induction Hu; intros uus vvs Hv; inv Hv;
        unfold relfs, relf in *; unravel in *; intuition.
      Qed.

      Lemma relfs_split_iff : forall us vs,
          let (xus, uus) := split us in
          let (xvs, vvs) := split vs in
          relfs us vs <-> Forall2 keq xus xvs /\ Forall2 R uus vvs.
      Proof.
        intros; repeat let_pair_simpl; split.
        - intros H. pose proof relfs_split us vs.
          repeat let_pair_simpl; auto.
        - intros [Hx Huv]. pose proof combine_relfs _ _ _ _ Hx Huv.
          unravel in *. pose proof split_combine us.
          pose proof split_combine vs. repeat let_pair_simpl; auto.
      Qed.

      Lemma relfs_split_map_iff : forall us vs,
          relfs us vs <->
          Forall2 keq (List.map fst us) (List.map fst vs) /\
          Forall2 R (List.map snd us) (List.map snd vs).
      Proof.
        intros. pose proof relfs_split_iff us vs. repeat let_pair_simpl.
        rewrite split_map in Heqp. rewrite split_map in Heqp0.
        repeat let_pair_simpl. assumption.
      Qed.

      Context `{EqDec K keq}.

      Lemma relfs_get_l : forall k u us vs,
          relfs us vs ->
          get k us = Some u -> exists v : V, get k vs = Some v /\ R u v.
      Proof.
        intros x u us vs HRs.
        generalize dependent x; generalize dependent u.
        induction HRs; intros u z Hu;
        unravel in *; try discriminate.
        destruct x as [xu u']; destruct y as [xv v']; inv H0; unravel in *.
        destruct (equiv_dec z xu) as [Hzu | Hzu];
          destruct (equiv_dec z xv) as [Hzv | Hzv];
          unfold equiv, complement in *; eauto.
        - inv Hu. exists v'; auto.
        - assert (equiv z xv) by (etransitivity; eauto).
          contradiction.
        - symmetry in Hzv.
          assert (keq xu z) by (etransitivity; eauto).
          symmetry in H0; contradiction.
      Qed.

      Lemma relfs_get_r : forall k (v : V) us vs,
        relfs us vs ->
        get k vs = Some v -> exists u : U, get k us = Some u /\ R u v.
      Proof.
      intros x v us vs HRs.
      generalize dependent x;
        generalize dependent v.
      induction HRs; intros v z Hu;
        unravel in *; try discriminate;
      destruct x as [xu u']; destruct y as [xv v']; inv H0; unravel in *.
      destruct (equiv_dec z xu) as [Hzu | Hzu];
        destruct (equiv_dec z xv) as [Hzv | Hzv];
        unfold equiv, complement in *; eauto.
      - inv Hu. exists u'; auto.
      - assert (equiv z xv) by (etransitivity; eauto).
        contradiction.
      - symmetry in H1.
        assert (equiv z xu) by (etransitivity; eauto).
        contradiction.
      Qed.

      Lemma get_relfs : forall k (u : U) (v : V) us vs,
          get k us = Some u -> get k vs = Some v ->
          relfs us vs -> R u v.
      Proof.
      intros x u v us vs Hu Hv HRs.
      generalize dependent x;
        generalize dependent v;
        generalize dependent u.
      induction HRs; intros u v z Hu Hv;
        unravel in *; try discriminate.
      destruct x as [xu u']; destruct y as [xv v']; unravel in *.
      inv H0; unravel in *.
      destruct (equiv_dec z xu) as [Hzu | Hzu];
        destruct (equiv_dec z xv) as [Hzv | Hzv];
        unfold equiv, complement in *; eauto.
      - inv Hu; inv Hv; auto.
      - assert (equiv z xv) by (etransitivity; eauto).
        contradiction.
      - symmetry in H1.
        assert (equiv z xu) by (etransitivity; eauto).
        contradiction.
      Qed.
    End FieldRelations.

    (** Decidable Equality *)
    Section DecEq.
      Context {K U : Type}.
      Context {keq : K -> K -> Prop}.
      Context `{Equivalence K keq}.
      Context `{EqDec K keq}.
      Variable feq : U -> U -> bool.

      Definition eqb_f : f K U -> f K U -> bool :=
        fun '(x1, u1) '(x2, u2) => equiv_dec x1 x2 &&&& feq u1 u2.
      (**[]*)

      Fixpoint eqb_fs (fs1 fs2 : fs K U) : bool :=
        match fs1, fs2 with
        | [], _::_ | _::_, [] => false
        | [], [] => true
        | f1::fs1, f2::fs2 => eqb_f f1 f2 && eqb_fs fs1 fs2
        end.
      (**[]*)

      Section ReflxEqb.
        Hypothesis Hfeq : forall u : U, feq u u = true.

        Lemma eqb_f_reflx : forall fld : f K U, eqb_f fld fld = true.
        Proof.
          Hint Rewrite Hfeq.
          intros [k u]; unravel; equiv_dec_refl_tactic;
          autorewrite with core; auto.
          assert (keq k k) by reflexivity; contradiction.
        Qed.

        Lemma eqb_fs_reflx : forall flds : fs K U, eqb_fs flds flds = true.
        Proof.
          Hint Rewrite eqb_f_reflx.
          induction flds; unravel; autorewrite with core; auto.
        Qed.
      End ReflxEqb.
    End DecEq.
  End FieldLibrary.

  Module RelfEquiv.
    Instance RelfEquiv
             (K U : Type)
             (keq : K -> K -> Prop) `{Equivalence K keq}
             (R : U -> U -> Prop) `{Equivalence U R}
      : Equivalence (@relf _ _ _ keq _ R) :=
      ProdEquiv keq R.
    (**[]*)

    Instance RelfsEquiv
             (K U : Type)
             (keq : K -> K -> Prop) `{Equivalence K keq}
             (R : U -> U -> Prop) `{Equivalence U R}
      : Equivalence (@relfs _ _ _ keq _ R) :=
      Forall2Equiv (relf R).
    (**[]*)

    Section EqReflect.
      Context {K U : Type}.
      Context {keq : K -> K -> Prop}.
      Context `{EQkeq : Equivalence K keq}.
      Context `{EQDeckeq : EqDec K keq}.
      Variable R : U -> U -> Prop.
      Context `{EQR : Equivalence U R}.
      Variable feq : U -> U -> bool.
      Hypothesis HR : forall u1 u2, reflect (R u1 u2) (feq u1 u2).

      Lemma equiv_eqb_f : forall (f1 f2 : f K U),
          equiv f1 f2 -> eqb_f feq f1 f2 = true.
      Proof.
        unfold equiv in *; intros [? ?] [? ?] [? ?]; unravel in *;
        match goal with
        | Hx : keq ?x1 ?x2,
          HRu: R ?u1 ?u2 |- _
          => specialize HR with u1 u2; inv HR;
              destruct (equiv_dec x1 x2) as [? | ?];
              unfold equiv, complement in *; auto
        end.
      Qed.

      Lemma equiv_eqb_fs : forall (fs1 fs2 : fs K U),
          equiv fs1 fs2 -> eqb_fs feq fs1 fs2 = true.
      Proof.
        unfold equiv; intros ? ? ?;
        match goal with
        | H: relfs _ _ _ |- _ => induction H
        end; unravel; auto;
        match goal with
        | |- _ && _ = true => apply andb_true_intro; split;
                            try apply equiv_eqb_f; auto
        end.
      Qed.

      Lemma eqb_f_equiv : forall (f1 f2 : f K U),
          eqb_f feq f1 f2 = true -> equiv f1 f2.
      Proof.
        unfold equiv, relf; intros [? ?] [? ?] ?; unravel in *;
        match goal with
        | H: ?x &&&& feq ?u1 ?u2 = true |- _
          => specialize HR with u1 u2;
            destruct x as [? | ?]; inv HR;
              destruct (feq u1 u2) eqn:?;
            unfold equiv, complement in *; split; auto;
                try discriminate
        end.
      Qed.

      Lemma eqb_fs_equiv : forall (fs1 fs2 : fs K U),
          eqb_fs feq fs1 fs2 = true -> equiv fs1 fs2.
      Proof.
        unfold equiv; induction fs1 as [| ? ? ?]; intros [| ? ?] ?;
        unravel in *; try discriminate; constructor;
        unfold relfs in *;
        match goal with
        | H: _ && _ = true |- _ => apply andb_true_iff in H as [? ?]
        end; try apply eqb_f_equiv; eauto.
      Qed.
    End EqReflect.

    (** Syntactic Equality. *)
    Section RelfEq.
      Context {K V : Type}.

      Lemma eq_relf : forall f1 f2 : f K V, relf eq f1 f2 -> f1 = f2.
      Proof.
        intros [? ?] [? ?] [? ?]; unfold equiv in *;
        unravel in *; subst; reflexivity.
      Qed.

      Lemma eq_relfs : forall fs1 fs2 : fs K V, relfs eq fs1 fs2 -> fs1 = fs2.
      Proof.
        Hint Resolve eq_relf : core.
        intros ? ? H; induction H; auto; subst; f_equal; auto.
      Qed.
    End RelfEq.
  End RelfEquiv.

  Module FieldTactics.
    Ltac predf_destruct :=
      match goal with
      | H: predf_data _ (_, _) |- _ => unfold predf_data in H; unravel in *
      | H: predf_data _ ?f
        |- _ => destruct f as [? ?]; unfold predf_data in H; unravel in *
      end.
    (**[]*)

    Ltac invert_cons_predfs :=
      match goal with
      | H:predfs_data _ (_::_) |- _ => inv H; try predf_destruct
      end.
    (**[]*)

    Ltac ind_list_predfs :=
      match goal with
      | H: predfs_data _ ?fs
        |- _ => induction fs; try invert_cons_predfs
      end.
    (**[]*)

    Ltac ind_predfs_data :=
      match goal with
      | H: predfs_data _ _
        |- _ => induction H; try predf_destruct
      end.
    (**[]*)

    Ltac invert_nil_cons_relate :=
      match goal with
      | H:relfs _ [] (_::_) |- _ => inv H
      | H:relfs _ (_::_) [] |- _ => inv H
      end.
    (**[]*)

    Ltac relf_destruct :=
      match goal with
      | H:relf _ (_,_) (_,_) |- _ => destruct H as [? ?]; unravel in *
      | H:relf _ ?fu (_,_)
        |- _ => destruct fu as [? ?];
              destruct H as [? ?]; unravel in *
      | H:relf _ (_,_) ?fv
        |- _ => destruct fv as [? ?];
              destruct H as [? ?]; unravel in *
      | H:relf _ ?fu ?fv
        |- _ => destruct fu as [? ?];
              destruct fv as [? ?];
              destruct H as [? ?]; unravel in *
      end.
    (**[]*)

    Ltac invert_cons_cons_relate :=
      match goal with
      | H:relfs _ (_::_) (_::_) |- _ => inv H; try relf_destruct
      end.
    (**[]*)

    Ltac ind_list_relfs :=
      match goal with
      | H: relfs _ ?fs1 ?fs2
        |- _ => generalize dependent fs2;
              induction fs1; intros [| ? ?]; intros;
              try invert_nil_cons_relate;
              try invert_cons_cons_relate
      end.

    Ltac ind_relfs :=
      match goal with
      | H: relfs _ _ _
        |- _ => induction H; try relf_destruct
      end.
  End FieldTactics.
End Field.

(** * P4cub AST *)
Module P4cub.
  Module F := Field.

  (** Function call parameters/arguments. *)
  Inductive paramarg (A B : Type) : Type :=
  | PAIn (a : A)
  | PAOut (b : B)
  | PAInOut (b : B).

  Arguments PAIn {_} {_}.
  Arguments PAOut {_} {_}.
  Arguments PAInOut {_} {_}.

  (** Relating [paramarg]s. *)
  Definition rel_paramarg {A1 A2 B1 B2 : Type}
             (RA : A1 -> A2 -> Prop) (RB : B1 -> B2 -> Prop)
             (pa1 : paramarg A1 B1)
             (pa2 : paramarg A2 B2) : Prop :=
    match pa1, pa2 with
    | PAIn a1, PAIn a2       => RA a1 a2
    | PAOut b1, PAOut b2
    | PAInOut b1, PAInOut b2 => RB b1 b2
    | _, _ => False
    end.
  (**[]*)

  Definition rel_paramarg_same
             {A B : Type} (R : A -> B -> Prop)
             (paa : paramarg A A) (pab : paramarg B B) : Prop :=
    rel_paramarg R R paa pab.
  (**[]*)

  (** Function signatures/instantiations. *)
  Inductive arrow (K A B R : Type) : Type :=
    Arrow (pas : F.fs K (paramarg A B)) (returns : option R).
  (**[]*)

  Arguments Arrow {_} {_} {_} {_}.

  (** * Expression Grammar *)
  Module Expr.
    (* Import Dir. *)

    Section P4Types.
      (** Expression types. *)
      Inductive t : Type :=
      | TBool                            (* bool *)
      | TBit (width : positive)          (* unsigned integers *)
      | TInt (width : positive)          (* signed integers *)
      | TError                           (* the error type *)
      | TMatchKind                       (* the matchkind type *)
      | TTuple (types : list t)          (* tuple type *)
      | TRecord (fields : F.fs string t) (* the record and struct type *)
      | THeader (fields : F.fs string t) (* the header type *)
      | THeaderStack (fields : F.fs string t)
                     (size : positive)   (* header stack type *).
      (**[]*)

      (** Function parameters. *)
      Definition params : Type := F.fs string (paramarg t t).

      (** Function types. *)
      Definition arrowT : Type := arrow string t t t.

      (** Constructor Types. *)
      Inductive ct : Type :=
      | CTType (type : t)                   (* expression types *)
      | CTControl (cparams : F.fs string ct)
                  (parameters : params)     (* control types *)
      | CTParser (cparams : F.fs string ct)
                 (parameters : params)      (* parser types *)
      | CTExtern (cparams : F.fs string ct)
                 (methods : F.fs string arrowT) (* extern types *).
      (**[]*)

      Definition constructor_params : Type := F.fs string ct.
    End P4Types.

    Module TypeNotations.
      Notation "'{{' ty '}}'" := ty (ty custom p4type at level 99).
      Notation "( x )" := x (in custom p4type, x at level 99).
      Notation "x" := x (in custom p4type at level 0, x constr at level 0).
      Notation "'Bool'" := TBool (in custom p4type at level 0).
      Notation "'bit' < w >"
        := (TBit w)
            (in custom p4type at level 2, no associativity).
      Notation "'int' < w >"
        := (TInt w)
            (in custom p4type at level 2, no associativity).
      Notation "'error'" := TError
                              (in custom p4type at level 0,
                                  no associativity).
      Notation "'matchkind'"
        := TMatchKind (in custom p4type at level 0, no associativity).
      Notation "'tuple' ts"
               := (TTuple ts) (in custom p4type at level 0, no associativity).
      Notation "'rec' { fields }"
        := (TRecord fields)
            (in custom p4type at level 6, no associativity).
      Notation "'hdr' { fields }"
        := (THeader fields)
            (in custom p4type at level 6, no associativity).
      Notation "'stack' fields [ n ]"
               := (THeaderStack fields n) (in custom p4type at level 7).

      Notation "'{{{' ty '}}}'" := ty (ty custom p4constructortype at level 99).
      Notation "( x )" := x (in custom p4constructortype, x at level 99).
      Notation "x" := x (in custom p4constructortype at level 0, x constr at level 0).
      Notation "'Type' τ"
        := (CTType τ)
             (in custom p4constructortype at level 0,
                 τ custom p4type).
      Notation "'ControlType' cps ps"
               := (CTControl cps ps)
                    (in custom p4constructortype at level 0).
      Notation "'ParserType' cps ps"
               := (CTControl cps ps)
                    (in custom p4constructortype at level 0).
      Notation "'Extern' cps { mthds }"
               := (CTExtern cps mthds)
                    (in custom p4constructortype at level 0).
    End TypeNotations.

    (** Custom induction principle for [t]. *)
    Section TypeInduction.
      Import TypeNotations.

      (** An arbitrary property. *)
      Variable P : t -> Prop.

      Hypothesis HTBool : P {{ Bool }}.

      Hypothesis HTBit : forall w, P {{ bit<w> }}.

      Hypothesis HTInt : forall w, P {{ int<w> }}.

      Hypothesis HTError : P {{ error }}.

      Hypothesis HTMatchKind : P {{ matchkind }}.

      Hypothesis HTTuple : forall ts,
          Forall P ts -> P {{ tuple ts }}.

      Hypothesis HTRecord : forall fields,
          F.predfs_data P fields -> P {{ rec { fields } }}.

      Hypothesis HTHeader : forall fields,
          F.predfs_data P fields -> P {{ hdr { fields } }}.

      Hypothesis HTHeaderStack : forall fields size,
          F.predfs_data P fields -> P {{ stack fields[size] }}.

      (** A custom induction principle.
          Do [induction ?t using custom_t_ind]. *)
      Definition custom_t_ind : forall ty : t, P ty :=
        fix custom_t_ind (type : t) : P type :=
          let fix list_ind (ts : list t) :
                Forall P ts :=
              match ts with
              | [] => Forall_nil _
              | h :: ts => Forall_cons _ (custom_t_ind h) (list_ind ts)
              end in
          let fix fields_ind
                  (flds : F.fs string t) : F.predfs_data P flds :=
              match flds as fs_ty return F.predfs_data P fs_ty with
              | [] => Forall_nil (F.predf_data P)
              | (_, hft) as hf :: tf =>
                Forall_cons hf (custom_t_ind hft) (fields_ind tf)
              end in
          match type as ty return P ty with
          | {{ Bool }} => HTBool
          | {{ bit<w> }} => HTBit w
          | {{ int<w> }} => HTInt w
          | {{ error }} => HTError
          | {{ matchkind }} => HTMatchKind
          | {{ tuple ts }}  => HTTuple ts (list_ind ts)
          | {{ rec { fields } }} => HTRecord fields (fields_ind fields)
          | {{ hdr { fields } }} => HTHeader fields (fields_ind fields)
          | {{ stack fields[n] }} => HTHeaderStack fields n (fields_ind fields)
          end.
      (**[]*)
    End TypeInduction.

    Module TypeEquivalence.
      Import Field.FieldTactics.
      Import TypeNotations.

      Section TypeEquivalence.
        (** Decidable equality. *)
        Fixpoint eqbt (τ1 τ2 : t) : bool :=
          let fix lrec (ts1 ts2 : list t) : bool :=
              match ts1, ts2 with
              | [], [] => true
              | t1::ts1, t2::ts2 => eqbt t1 t2 && lrec ts1 ts2
              | [], _::_ | _::_, [] => false
              end in
          let fix frec (ts1 ts2 : F.fs string t) : bool :=
              match ts1, ts2 with
              | [], [] => true
              | (x1,t1)::ts1, (x2,t2)::ts2
                => equiv_dec x1 x2 &&&& eqbt t1 t2 && frec ts1 ts2
              | [], _::_ | _::_, [] => false
              end in
          match τ1, τ2 with
          | {{ Bool }}, {{ Bool }}
          | {{ error }}, {{ error }}
          | {{ matchkind }}, {{ matchkind }} => true
          | {{ bit<w1> }}, {{ bit<w2> }}
          | {{ int<w1> }}, {{ int<w2> }} => (w1 =? w2)%positive
          | {{ tuple ts1 }}, {{ tuple ts2 }} => lrec ts1 ts2
          | {{ hdr { ts1 } }}, {{ hdr { ts2 } }}
          | {{ rec { ts1 } }}, {{ rec { ts2 } }} => frec ts1 ts2
          | {{ stack ts1[n1] }}, {{ stack ts2[n2] }}
            => (n1 =? n2)%positive && frec ts1 ts2
          | _, _ => false
          end.
        (**[]*)

        Lemma eqbt_refl : forall τ, eqbt τ τ = true.
        Proof.
          Hint Rewrite Pos.eqb_refl.
          Hint Rewrite equiv_dec_refl.
          Hint Extern 0 => equiv_dec_refl_tactic : core.
          induction τ using custom_t_ind; unravel;
          autorewrite with core; auto;
          try ind_list_Forall; try ind_list_predfs;
          intuition; autorewrite with core;
          repeat (rewrite_true; unravel); auto.
        Qed.

        Ltac eauto_too_dumb :=
          match goal with
          | H: ?f ?x ?y = ?z,
            IH: (forall y, ?f ?x y = ?z -> _)
            |- _ => apply IH in H; clear IH
          end.

        Lemma eqbt_eq : forall t1 t2, eqbt t1 t2 = true -> t1 = t2.
        Proof.
          Hint Resolve Peqb_true_eq : core.
          Hint Extern 5 =>
          match goal with
          | H: (_ =? _)%positive = true
            |- _ => apply Peqb_true_eq in H; subst; auto
          end : core.
          induction t1 using custom_t_ind; intros []; intros; unravel in *;
          try discriminate; repeat destruct_andb; auto; f_equal;
          try match goal with
              | IH: Forall _ ?ts1,
                H: _ ?ts1 ?ts2 = true
                |- _ => generalize dependent ts2;
                      induction ts1; intros []; intros;
                      try discriminate; try inv_Forall_cons;
                      repeat destruct_andb; intuition;
                      repeat eauto_too_dumb; subst; auto
              end;
          try match goal with
              | IH: F.predfs_data _ ?ts1,
                H: _ ?ts1 ?ts2 = true
                |- _ => generalize dependent ts2;
                      induction ts1; intros [| [? ?] ?]; intros;
                      try discriminate; try invert_cons_predfs;
                      try destruct_lifted_andb;
                      repeat destruct_andb; intuition;
                      unfold equiv in *; subst;
                      repeat eauto_too_dumb; subst; auto
              end.
        Qed.

        Lemma eqbt_eq_iff : forall t1 t2 : t,
            eqbt t1 t2 = true <-> t1 = t2.
        Proof.
          Hint Resolve eqbt_refl : core.
          Hint Resolve eqbt_eq : core.
          intros t1 t2; split; intros; subst; auto.
        Qed.

        Lemma eqbt_reflect : forall t1 t2, reflect (t1 = t2) (eqbt t1 t2).
        Proof.
          Hint Resolve eqbt_eq_iff : core.
          intros; reflect_split; auto.
          apply eqbt_eq_iff in H;
            rewrite H in Heqb; discriminate.
        Qed.

        Lemma eq_dec : forall t1 t2 : t,
            t1 = t2 \/ t1 <> t2.
        Proof.
          intros t1 t2. pose proof eqbt_reflect t1 t2 as H.
          inv H; auto.
        Qed.
      End TypeEquivalence.
    End TypeEquivalence.

    (** Restrictions on type-nesting. *)
    Module ProperType.
      Import TypeNotations.
      Import TypeEquivalence.

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
        | pih_record (ts : F.fs string t) :
            F.predfs_data base_type ts ->
            proper_inside_header {{ rec { ts } }}.

        (** Properly nested type. *)
        Inductive proper_nesting : t -> Prop :=
        | pn_base (τ : t) :
            base_type τ -> proper_nesting τ
        | pn_error : proper_nesting {{ error }}
        | pn_matchkind : proper_nesting {{ matchkind }}
        | pn_record (ts : F.fs string t) :
            F.predfs_data
              (fun τ => proper_nesting τ /\ τ <> {{ matchkind }}) ts ->
            proper_nesting {{ rec { ts } }}
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
          - apply pn_record.
            ind_predfs_data; constructor; auto; cbv.
            inv H; split; try (repeat constructor; assumption);
            try (intros H'; inv H'; contradiction).
        Qed.
      End ProperTypeNesting.

      Ltac invert_base_ludicrous :=
        match goal with
        | H: base_type {{ tuple _ }} |- _ => inv H
        | H: base_type {{ rec { _ } }} |- _ => inv H
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

    Inductive uop : Set :=
    | Not    (* boolean negation *)
    | BitNot (* bitwise negation *)
    | UMinus (* integer negation *).
    (**[]*)

    Module UopNotations.
      Notation "x" := x (in custom p4uop at level 0, x constr at level 0).
      Notation "!" := Not (in custom p4uop at level 0).
      Notation "~" := BitNot (in custom p4uop at level 0).
      Notation "-" := UMinus (in custom p4uop at level 0).
    End UopNotations.

    (** Binary operations.
        The "Sat" suffix denotes
        saturating arithmetic:
        where there is no overflow. *)
    Inductive bop : Set :=
    | Plus     (* integer addition *)
    | PlusSat  (* saturating addition *)
    | Minus    (* integer subtraction *)
    | MinusSat (* saturating subtraction *)
    | Times    (* multiplication *)
    | Shl      (* bitwise left-shift *)
    | Shr      (* bitwise right-shift *)
    | Le       (* integer less-than *)
    | Ge       (* integer greater-than *)
    | Lt       (* integer less-than or equals *)
    | Gt       (* integer greater-than or equals *)
    | Eq       (* expression equality *)
    | NotEq    (* expression inequality *)
    | BitAnd   (* bitwise and *)
    | BitXor   (* bitwise exclusive-or *)
    | BitOr    (* bitwise or *)
    | PlusPlus (* bit-string concatenation *)
    | And      (* boolean and *)
    | Or       (* boolean or *).
    (**[]*)

    Module BopNotations.
      Notation "x" := x (in custom p4bop at level 0, x constr at level 0).
      Notation "+" := Plus (in custom p4bop at level 0).
      Notation "-" := Minus (in custom p4bop at level 0).
      Notation "'|+|'" := PlusSat (in custom p4bop at level 0).
      Notation "'|-|'" := MinusSat (in custom p4bop at level 0).
      Notation "×" := Times (in custom p4bop at level 0).
      Notation "'<<'" := Shl (in custom p4bop at level 0).
      Notation "'>>'" := Shr (in custom p4bop at level 0).
      Notation "'<='" := Le (in custom p4bop at level 0).
      Notation "'>='" := Ge (in custom p4bop at level 0).
      Notation "<" := Lt (in custom p4bop at level 0).
      Notation ">" := Gt (in custom p4bop at level 0).
      Notation "'=='" := Eq (in custom p4bop at level 0).
      Notation "'!='" := NotEq (in custom p4bop at level 0).
      Notation "&" := BitAnd (in custom p4bop at level 0).
      Notation "^" := BitXor (in custom p4bop at level 0).
      Notation "|" := BitOr (in custom p4bop at level 0).
      Notation "'&&'" := And (in custom p4bop at level 0).
      Notation "'||'" := Or (in custom p4bop at level 0).
      Notation "'++'" := PlusPlus (in custom p4bop at level 0).
    End BopNotations.

    (** Default matchkinds. *)
    Inductive matchkind : Set :=
    | MKExact
    | MKTernary
    | MKLpm.
    (**[]*)

    Instance MatchKindEqDec : EqDec matchkind eq.
    Proof.
      unfold EqDec; unfold equiv, complement.
      intros [] []; try (left; reflexivity);
        try (right; intros H; inversion H).
    Defined.

    Module MatchkindNotations.
      Notation "x" := x (in custom p4matchkind at level 0, x constr at level 0).
      Notation "'exact'" := MKExact (in custom p4matchkind at level 0).
      Notation "'ternary'" := MKTernary (in custom p4matchkind at level 0).
      Notation "'lpm'" := MKLpm (in custom p4matchkind at level 0).
    End MatchkindNotations.

    (** Header operations. *)
    Inductive hdr_op : Set :=
    | HOIsValid
    | HOSetValid
    | HOSetInValid.
    (**[]*)

    Module HeaderOpNotations.
      Notation "x" := x (in custom p4hdr_op at level 0, x constr at level 0).
      Notation "'isValid'" := HOIsValid (in custom p4hdr_op at level 0).
      Notation "'setValid'" := HOSetValid (in custom p4hdr_op at level 0).
      Notation "'setInValid'" := HOSetInValid (in custom p4hdr_op at level 0).
    End HeaderOpNotations.

    (** Header Stack Operations.. *)
    Inductive hdr_stk_op : Set :=
    | HSONext         (* get element at [nextIndex] *)
    | HSOSize         (* get the size *)
    | HSOPush (n : positive) (* "push_front," shift stack right by [n] *)
    | HSOPop  (n : positive) (* "push_front," shift stack left by [n] *).

    Module HeaderStackOpNotations.
      Notation "x" := x (in custom p4hdr_stk_op at level 0, x constr at level 0).
      Notation "'Next'" := HSONext (in custom p4hdr_stk_op at level 0).
      Notation "'Size'" := HSOSize (in custom p4hdr_stk_op at level 0).
      Notation "'Push' n"
        := (HSOPush n) (in custom p4hdr_stk_op at level 0).
      Notation "'Pop' n"
        := (HSOPop n) (in custom p4hdr_stk_op at level 0).
    End HeaderStackOpNotations.

    Section Expressions.
      Variable (tags_t : Type).

      (** Expressions annotated with types,
          unless the type is obvious. *)
      Inductive e : Type :=
      | EBool (b : bool) (i : tags_t)                     (* booleans *)
      | EBit (width : positive) (val : Z) (i : tags_t) (* unsigned integers *)
      | EInt (width : positive) (val : Z) (i : tags_t) (* signed integers *)
      | EVar (type : t) (x : string)
             (i : tags_t)                              (* variables *)
      | ESlice (n : e) (τ : t)
               (hi lo : positive) (i : tags_t) (* bit-slicing *)
      | ECast (type : t) (arg : e) (i : tags_t) (* explicit casts *)
      | EUop (op : uop) (type : t)
             (arg : e) (i : tags_t)                    (* unary operations *)
      | EBop (op : bop) (lhs_type rhs_type : t)
             (lhs rhs : e) (i : tags_t)                (* binary operations *)
      | ETuple (es : list e) (i : tags_t)              (* tuples *)
      | ERecord (fields : F.fs string (t * e))
                (i : tags_t)                           (* records and structs *)
      | EHeader (fields : F.fs string (t * e))
                (valid : e) (i : tags_t)               (* header literals *)
      | EHeaderOp (op : hdr_op) (header : e)
                  (i : tags_t)                         (* header operations *)
      | EExprMember (mem : string)
                    (expr_type : t)
                    (arg : e) (i : tags_t)             (* member-expressions *)
      | EError (err : option string)
               (i : tags_t)                            (* error literals *)
      | EMatchKind (mk : matchkind) (i : tags_t)       (* matchkind literals *)
      | EHeaderStack (fields : F.fs string t)
                     (headers : list e) (size : positive)
                     (next_index : Z)                  (* header stack literals,
                                                          unique to p4light *)
      | EHeaderStackAccess (stack : e) (index : Z)
                           (i : tags_t)                (* header stack indexing *)
      | EHeaderStackOp (stack : e) (op : hdr_stk_op)
                       (i : tags_t)                    (* header stack builtin *).
      (**[]*)

      (** Function call arguments. *)
      Definition args : Type :=
        F.fs string (paramarg (t * e) (t * e)).
      (**[]*)

      (** Function call. *)
      Definition arrowE : Type :=
        arrow string (t * e) (t * e) (t * e).
      (**[]*)

      (** Constructor arguments. *)
      Inductive constructor_arg : Type :=
      | CAExpr (expr : e) (* plain expression *)
      | CAName (x : string) (* name of parser, control, etc *).
      (**[]*)

      Definition constructor_args : Type := F.fs string constructor_arg.
    End Expressions.

    Arguments EBool {tags_t}.
    Arguments EBit {_}.
    Arguments EInt {_}.
    Arguments EVar {tags_t}.
    Arguments ESlice {_}.
    Arguments ECast {_}.
    Arguments EUop {tags_t}.
    Arguments EBop {tags_t}.
    Arguments ETuple {_}.
    Arguments ERecord {tags_t}.
    Arguments EHeader {_}.
    Arguments EHeaderOp {_}.
    Arguments EExprMember {tags_t}.
    Arguments EError {tags_t}.
    Arguments EMatchKind {tags_t}.
    Arguments EHeaderStack {_}.
    Arguments EHeaderStackAccess {_}.
    Arguments EHeaderStackOp {_}.
    Arguments CAExpr {_}.
    Arguments CAName {_}.

    Module ExprNotations.
      Notation "'<{' exp '}>'" := exp (exp custom p4expr at level 99).
      Notation "( x )" := x (in custom p4expr, x at level 99).
      Notation "x" := x (in custom p4expr at level 0, x constr at level 0).
      Notation "'TRUE' @ i" := (EBool true i) (in custom p4expr at level 0).
      Notation "'FALSE' @ i" := (EBool false i) (in custom p4expr at level 0).
      Notation "'BOOL' b @ i" := (EBool b i) (in custom p4expr at level 0).
      Notation "w 'W' n @ i" := (EBit w n i) (in custom p4expr at level 0).
      Notation "w 'S' n @ i" := (EInt w n i) (in custom p4expr at level 0).
      Notation "'Var' x : ty @ i" := (EVar ty x i)
                            (in custom p4expr at level 0, no associativity).
      Notation "'Slice' n : τ [ hi : lo ] @ i"
               := (ESlice n τ hi lo i)
                    (in custom p4expr at level 10, τ custom p4type,
                        n custom p4expr, right associativity).
      Notation "'Cast' e : τ @ i"
        := (ECast τ e i)
             (in custom p4expr at level 10, τ custom p4type,
                 e custom p4expr, right associativity).
      Notation "'UOP' op x : ty @ i"
               := (EUop op ty x i)
                    (in custom p4expr at level 2,
                        x custom p4expr, ty custom p4type,
                        op custom p4uop, no associativity).
      Notation "'BOP' x : tx op y : ty @ i"
               := (EBop op tx ty x y i)
                    (in custom p4expr at level 10,
                        x custom p4expr, tx custom p4type,
                        y custom p4expr, ty custom p4type,
                        op custom p4bop, left associativity).
      Notation "'tup' es @ i"
               := (ETuple es i)
                    (in custom p4expr at level 0).
      Notation "'rec' { fields } @ i "
        := (ERecord fields i)
            (in custom p4expr at level 6, no associativity).
      Notation "'hdr' { fields } 'valid' ':=' b @ i "
        := (EHeader fields b i)
            (in custom p4expr at level 6,
                b custom p4expr, no associativity).
      Notation "'HDR_OP' op exp @ i"
               := (EHeaderOp op exp i)
                    (in custom p4expr at level 5, exp custom p4expr,
                        op custom p4hdr_op, no associativity).
      Notation "'Mem' x : ty 'dot' y @ i"
              := (EExprMember y ty x i)
                    (in custom p4expr at level 10, x custom p4expr,
                        ty custom p4type, left associativity).
      Notation "'Error' x @ i" := (EError x i)
                              (in custom p4expr at level 0, no associativity).
      Notation "'Matchkind' mk @ i" := (EMatchKind mk i)
                              (in custom p4expr at level 0,
                                  mk custom p4matchkind, no associativity).
      Notation "'Stack' hdrs : ts [ n ] 'nextIndex' ':=' ni"
               := (EHeaderStack ts hdrs n ni)
                    (in custom p4expr at level 0).
      Notation "'Access' e1 [ e2 ] @ i"
               := (EHeaderStackAccess e1 e2 i)
                    (in custom p4expr at level 10, e1 custom p4expr).
      Notation "'STK_OP' op exp @ i"
               := (EHeaderStackOp exp op i)
                    (in custom p4expr at level 5, exp custom p4expr,
                        op custom p4hdr_stk_op, no associativity).
    End ExprNotations.

    (** A custom induction principle for [e]. *)
    Section ExprInduction.
      Import TypeNotations.
      Import UopNotations.
      Import ExprNotations.
      Import BopNotations.
      Import MatchkindNotations.
      Import HeaderOpNotations.
      Import HeaderStackOpNotations.

      (** An arbitrary predicate. *)
      Context {tags_t : Type}.

      Variable P : e tags_t -> Prop.

      Hypothesis HEBool : forall b i, P <{ BOOL b @ i }>.

      Hypothesis HEBit : forall w n i, P <{ w W n @ i }>.

      Hypothesis HEInt : forall w n i, P <{ w S n @ i }>.

      Hypothesis HEVar : forall (ty : t) (x : string) i,
          P <{ Var x : ty @ i }>.

      Hypothesis HESlice : forall n τ hi lo i,
          P n -> P <{ Slice n:τ [ hi : lo ] @ i }>.

      Hypothesis HECast : forall τ exp i,
          P exp -> P <{ Cast exp:τ @ i }>.

      Hypothesis HEUop : forall (op : uop) (ty : t) (ex : e tags_t) i,
          P ex -> P <{ UOP op ex : ty @ i }>.

      Hypothesis HEBop : forall (op : bop) (lt rt : t) (lhs rhs : e tags_t) i,
          P lhs -> P rhs -> P <{ BOP lhs:lt op rhs:rt @ i }>.

      Hypothesis HETuple : forall es i,
          Forall P es -> P <{ tup es @ i }>.

      Hypothesis HERecord : forall fields i,
          F.predfs_data (P ∘ snd) fields -> P <{ rec {fields} @ i }>.

      Hypothesis HEHeader : forall fields b i,
          P b -> F.predfs_data (P ∘ snd) fields ->
          P <{ hdr {fields} valid:=b @ i }>.

      Hypothesis HEHeaderOp : forall op exp i,
          P exp -> P <{ HDR_OP op exp @ i }>.

      Hypothesis HEExprMember : forall x ty expr i,
          P expr -> P <{ Mem expr:ty dot x @ i }>.

      Hypothesis HEError : forall err i, P <{ Error err @ i }>.

      Hypothesis HEMatchKind : forall mkd i, P <{ Matchkind mkd @ i }>.

      Hypothesis HEStack : forall ts hs size ni,
          Forall P hs ->
          P <{ Stack hs:ts [size] nextIndex:=ni }>.

      Hypothesis HAccess : forall e1 e2 i,
          P e1 -> P <{ Access e1[e2] @ i }>.

      Hypothesis HEHeaderStackOp : forall op exp i,
          P exp -> P <{ STK_OP op exp @ i }>.

      (** A custom induction principle.
          Do [induction ?e using custom_e_ind]. *)
      Definition custom_e_ind : forall exp : e tags_t, P exp :=
        fix eind (expr : e tags_t) : P expr :=
          let fix fields_ind {A:Type} (flds : F.fs string (A * e tags_t))
              : F.predfs_data (P ∘ snd) flds :=
              match flds as fs_ex
                    return F.predfs_data (P ∘ snd) fs_ex with
              | [] => Forall_nil (F.predf_data (P ∘ snd))
              | (_, (_, hfe)) as hf :: tf =>
                Forall_cons hf (eind hfe) (fields_ind tf)
              end in
          let fix list_ind (es : list (e tags_t)) : Forall P es :=
              match es as ees return Forall P ees with
              | [] => Forall_nil P
              | exp :: ees => Forall_cons exp (eind exp) (list_ind ees)
              end in
          match expr as e' return P e' with
          | <{ BOOL b @ i }> => HEBool b i
          | <{ w W n @ i }>  => HEBit w n i
          | <{ w S n @ i }>  => HEInt w n i
          | <{ Var x:ty @ i }> => HEVar ty x i
          | <{ Slice n:τ [h:l] @ i }> => HESlice n τ h l i (eind n)
          | <{ Cast exp:τ @ i }> => HECast τ exp i (eind exp)
          | <{ UOP op exp:ty @ i }> => HEUop op ty exp i (eind exp)
          | <{ BOP lhs:lt op rhs:rt @ i }> =>
              HEBop op lt rt lhs rhs i
                    (eind lhs) (eind rhs)
          | <{ tup es @ i }>         => HETuple es i (list_ind es)
          | <{ rec { fields } @ i }> => HERecord fields i (fields_ind fields)
          | <{ hdr { fields } valid:=b @ i }>
            => HEHeader fields b i (eind b) (fields_ind fields)
          | <{ HDR_OP op exp @ i }> => HEHeaderOp op exp i (eind exp)
          | <{ Mem exp:ty dot x @ i }> =>
              HEExprMember x ty exp i (eind exp)
          | <{ Error err @ i }> => HEError err i
          | <{ Matchkind mkd @ i }> => HEMatchKind mkd i
          | <{ Stack hs:ts [n] nextIndex:=ni }> => HEStack ts hs n ni (list_ind hs)
          | <{ Access e1[e2] @ i }> => HAccess e1 e2 i (eind e1)
          | <{ STK_OP op exp @ i }> => HEHeaderStackOp op exp i (eind exp)
          end.
      (**[]*)
    End ExprInduction.

    (** Decidable Expression Equivalence. *)
    Module ExprEquivalence.
      Import Field.FieldTactics.
      Import TypeNotations.
      Import UopNotations.
      Import BopNotations.
      Import HeaderOpNotations.
      Import HeaderStackOpNotations.
      Import MatchkindNotations.
      Import ExprNotations.
      Import TypeEquivalence.

      Instance UopEqDec : EqDec uop eq.
      Proof.
        intros [] []; unfold equiv, complement in *;
          auto; right; intros ?; discriminate.
      Defined.

      Instance BopEqDec : EqDec bop eq.
      Proof.
        intros [] []; unfold equiv, complement in *;
          auto; right; intros ?; discriminate.
      Defined.

      Instance HeaderOpEqDec : EqDec hdr_op eq.
      Proof.
        intros [] []; unfold equiv, complement in *;
          auto; right; intros ?; discriminate.
      Defined.

      Instance HeaderStackOpEqDec : EqDec hdr_stk_op eq.
      Proof.
        intros [] []; unfold equiv, complement in *; auto;
        try match goal with
            | n1 : positive, n2: positive
              |- _ => destruct (Pos.eq_dec n1 n2) as [? | ?]; subst; auto
            end;
        try (right; intros ?; inv_eq; contradiction).
      Defined.

      (** Equality of expressions. *)
      Inductive equive {tags_t : Type} : e tags_t -> e tags_t -> Prop :=
      | equive_bool b i i' :
          ∮ BOOL b @ i ≡ BOOL b @ i'
      | equive_bit w n i i' :
          ∮ w W n @ i ≡ w W n @ i'
      | equive_int w z i i' :
          ∮ w S z @ i ≡ w S z @ i'
      | equive_var x τ i1 i2 :
          ∮ Var x:τ @ i1 ≡ Var x:τ @ i2
      | equive_slice e1 e2 τ h l i1 i2 :
          ∮ e1 ≡ e2 ->
          ∮ Slice e1:τ [h:l] @ i1 ≡ Slice e2:τ [h:l] @ i2
      | equive_cast τ e1 e2 i1 i2 :
          ∮ e1 ≡ e2 ->
          ∮ Cast e1:τ @ i1 ≡ Cast e2:τ @ i2
      | equive_uop op τ e1 e2 i1 i2 :
          ∮ e1 ≡ e2 ->
          ∮ UOP op e1:τ @ i1 ≡ UOP op e2:τ @ i2
      | equive_bop op τl τr el1 er1 el2 er2 i1 i2 :
          ∮ el1 ≡ el2 ->
          ∮ er1 ≡ er2 ->
          ∮ BOP el1:τl op er1:τr @ i1 ≡ BOP el2:τl op er2:τr @ i2
      | equive_tuple es1 es2 i1 i2 :
          Forall2 equive es1 es2 ->
          ∮ tup es1 @ i1 ≡ tup es2 @ i2
      | equive_record fs1 fs2 i1 i2 :
          F.relfs
            (fun et1 et2 =>
               let τ1 := fst et1 in
               let τ2 := fst et2 in
               let e1 := snd et1 in
               let e2 := snd et2 in
               τ1 = τ2 /\ ∮ e1 ≡ e2) fs1 fs2 ->
          ∮ rec { fs1 } @ i1 ≡ rec { fs2 } @ i2
      | equive_header fs1 fs2 e1 e2 i1 i2 :
          F.relfs
            (fun et1 et2 =>
               let τ1 := fst et1 in
               let τ2 := fst et2 in
               let e1 := snd et1 in
               let e2 := snd et2 in
               τ1 = τ2 /\ ∮ e1 ≡ e2) fs1 fs2 ->
          ∮ e1 ≡ e2 ->
          ∮ hdr { fs1 } valid:=e1 @ i1 ≡ hdr { fs2 } valid:=e2 @ i2
      | equive_header_op op h1 h2 i1 i2 :
          ∮ h1 ≡ h2 ->
          ∮ HDR_OP op h1 @ i1 ≡ HDR_OP op h2 @ i2
      | equive_member x τ e1 e2 i1 i2 :
          ∮ e1 ≡ e2 ->
          ∮ Mem e1:τ dot x @ i1 ≡ Mem e2:τ dot x @ i2
      | equive_error err i1 i2 :
          ∮ Error err @ i1 ≡ Error err @ i2
      | equive_matchkind mk i1 i2 :
          ∮ Matchkind mk @ i1 ≡ Matchkind mk @ i2
      | equive_header_stack ts hs1 hs2 n ni :
          Forall2 equive hs1 hs2 ->
          ∮ Stack hs1:ts[n] nextIndex:=ni ≡ Stack hs2:ts[n] nextIndex:=ni
      | equive_stack_access e1 e2 n i1 i2 :
          ∮ e1 ≡ e2 ->
          ∮ Access e1[n] @ i1 ≡ Access e2[n] @ i2
      | equive_stack_op op e1 e2 i1 i2 :
          ∮ e1 ≡ e2 ->
          ∮ STK_OP op e1 @ i1 ≡ STK_OP op e2 @ i2
      where "∮ e1 ≡ e2" := (equive e1 e2).

      (** Induction principle. *)
      Section ExprEquivalenceInduction.
        Variable tags_t : Type.

        Variable P : e tags_t -> e tags_t -> Prop.

        Hypothesis HBool : forall b i i', P <{ BOOL b @ i }> <{ BOOL b @ i' }>.

        Hypothesis HBit : forall w n i i', P <{ w W n @ i }> <{ w W n @ i' }>.

        Hypothesis HInt : forall w z i i', P <{ w S z @ i }> <{ w S z @ i' }>.

        Hypothesis HVar : forall x τ i1 i2,
            P <{ Var x:τ @ i1 }> <{ Var x:τ @ i2 }>.

        Hypothesis HSlice : forall e1 e2 τ h l i1 i2,
            ∮ e1 ≡ e2 ->
            P e1 e2 ->
            P <{ Slice e1:τ [h:l] @ i1 }> <{ Slice e2:τ [h:l] @ i2 }>.

        Hypothesis HCast : forall τ e1 e2 i1 i2,
            ∮ e1 ≡ e2 ->
            P e1 e2 ->
            P <{ Cast e1:τ @ i1 }> <{ Cast e2:τ @ i2 }>.

        Hypothesis HUop : forall op τ e1 e2 i1 i2,
            ∮ e1 ≡ e2 ->
            P e1 e2 ->
            P <{ UOP op e1:τ @ i1 }> <{ UOP op e2:τ @ i2 }>.

        Hypothesis HBop : forall op τl τr el1 er1 el2 er2 i1 i2,
            ∮ el1 ≡ el2 ->
            P el1 el2 ->
            ∮ er1 ≡ er2 ->
            P er1 er2 ->
            P <{ BOP el1:τl op er1:τr @ i1 }> <{ BOP el2:τl op er2:τr @ i2 }>.

        Hypothesis HTup : forall es1 es2 i1 i2,
            Forall2 equive es1 es2 ->
            Forall2 P es1 es2 ->
            P <{ tup es1 @ i1 }> <{ tup es2 @ i2 }>.

        Hypothesis HRecord : forall  fs1 fs2 i1 i2,
            F.relfs
              (fun et1 et2 =>
                 let τ1 := fst et1 in
                 let τ2 := fst et2 in
                 let e1 := snd et1 in
                 let e2 := snd et2 in
                 τ1 = τ2 /\ ∮ e1 ≡ e2) fs1 fs2 ->
            F.relfs
              (fun et1 et2 =>
                 let e1 := snd et1 in
                 let e2 := snd et2 in
                 P e1 e2) fs1 fs2 ->
            P <{ rec { fs1 } @ i1 }> <{ rec { fs2 } @ i2 }>.

        Hypothesis HHeader : forall  fs1 fs2 e1 e2 i1 i2,
            F.relfs
              (fun et1 et2 =>
                 let τ1 := fst et1 in
                 let τ2 := fst et2 in
                 let e1 := snd et1 in
                 let e2 := snd et2 in
                 τ1 = τ2 /\ ∮ e1 ≡ e2) fs1 fs2 ->
            F.relfs
              (fun et1 et2 =>
                 let e1 := snd et1 in
                 let e2 := snd et2 in
                 P e1 e2) fs1 fs2 ->
            ∮ e1 ≡ e2 ->
            P e1 e2 ->
            P <{ hdr { fs1 } valid:=e1 @ i1 }> <{ hdr { fs2 } valid:=e2 @ i2 }>.

        Hypothesis HHeaderOp : forall op h1 h2 i1 i2,
            ∮ h1 ≡ h2 ->
            P h1 h2 ->
            P <{ HDR_OP op h1 @ i1 }> <{ HDR_OP op h2 @ i2 }>.

        Hypothesis HMember : forall x τ e1 e2 i1 i2,
            ∮ e1 ≡ e2 ->
            P e1 e2 ->
            P <{ Mem e1:τ dot x @ i1 }> <{ Mem e2:τ dot x @ i2 }>.

        Hypothesis HError : forall err i1 i2,
            P <{ Error err @ i1 }> <{ Error err @ i2 }>.

        Hypothesis HMatchkind : forall mk i1 i2,
            P <{ Matchkind mk @ i1 }> <{ Matchkind mk @ i2 }>.

        Hypothesis HHeaderStack : forall ts hs1 hs2 n ni,
            Forall2 equive hs1 hs2 ->
            Forall2 P hs1 hs2 ->
            P <{ Stack hs1:ts[n] nextIndex:=ni }>
            <{ Stack hs2:ts[n] nextIndex:=ni }>.

        Hypothesis HAccess : forall e1 e2 n i1 i2,
            ∮ e1 ≡ e2 ->
            P e1 e2 ->
            P <{ Access e1[n] @ i1 }> <{ Access e2[n] @ i2 }>.

        Hypothesis HStackOp : forall op e1 e2 i1 i2,
            ∮ e1 ≡ e2 ->
            P e1 e2 ->
            P <{ STK_OP op e1 @ i1 }> <{ STK_OP op e2 @ i2 }>.

        (** Custom induction principle. *)
        Definition custom_equive_ind :
          forall (e1 e2 : e tags_t), ∮ e1 ≡ e2 -> P e1 e2 :=
          fix eeind e1 e2 (H : ∮ e1 ≡ e2) : P e1 e2 :=
            let fix lind {es1 es2 : list (e tags_t)}
                    (Hes : Forall2 equive es1 es2) : Forall2 P es1 es2 :=
                match Hes with
                | Forall2_nil _ => Forall2_nil _
                | Forall2_cons _ _ Hh Ht => Forall2_cons
                                             _ _
                                             (eeind _ _ Hh) (lind Ht)
                end in
            let fix fsind {fs1 fs2 : F.fs string (t * e tags_t)}
                    (Hfs : F.relfs
                             (fun et1 et2 =>
                                let τ1 := fst et1 in
                                let τ2 := fst et2 in
                                let e1 := snd et1 in
                                let e2 := snd et2 in
                                τ1 = τ2 /\ ∮ e1 ≡ e2) fs1 fs2)
                : F.relfs
                    (fun et1 et2 =>
                       let e1 := snd et1 in
                       let e2 := snd et2 in
                       P e1 e2) fs1 fs2 :=
                match Hfs with
                | Forall2_nil _ => Forall2_nil _
                | Forall2_cons _ _ (conj Hx (conj _ He))
                               Ht => Forall2_cons
                                      _ _
                                      (conj Hx (eeind _ _ He)) (fsind Ht)
                end in
            match H with
            | equive_bool b i i' => HBool b i i'
            | equive_bit w n i i' => HBit w n i i'
            | equive_int w z i i' => HInt w z i i'
            | equive_var x τ i1 i2 => HVar x τ i1 i2
            | equive_slice _ _ _ h l i1 i2
                           He => HSlice
                                  _ _ _ h l i1 i2
                                  He (eeind _ _ He)
            | equive_cast τ _ _ i1 i2
                          He => HCast
                                 τ _ _ i1 i2
                                 He (eeind _ _ He)
            | equive_uop op τ _ _ i1 i2
                         He => HUop
                                op τ _ _ i1 i2
                                He (eeind _ _ He)
            | equive_bop op tl tr _ _ _ _ i1 i2
                         Hel Her => HBop
                                     op tl tr _ _ _ _ i1 i2
                                     Hel (eeind _ _ Hel)
                                     Her (eeind _ _ Her)
            | equive_tuple _ _ i1 i2 Hes => HTup
                                             _ _ i1 i2
                                             Hes (lind Hes)
            | equive_record _ _ i1 i2 Hfs => HRecord
                                              _ _ i1 i2
                                              Hfs (fsind Hfs)
            | equive_header _ _ _ _ i1 i2
                            Hfs He => HHeader
                                       _ _ _ _ i1 i2
                                       Hfs (fsind Hfs)
                                       He (eeind _ _ He)
            | equive_header_op op _ _ i1 i2
                               He => HHeaderOp
                                      op _ _ i1 i2
                                      He (eeind _ _ He)
            | equive_member x τ _ _ i1 i2
                            He => HMember
                                   x τ _ _ i1 i2
                                   He (eeind _ _ He)
            | equive_error err i1 i2 => HError err i1 i2
            | equive_matchkind mk i1 i2 => HMatchkind mk i1 i2
            | equive_header_stack ts _ _ n ni
                                  Hhs => HHeaderStack
                                          ts _ _ n ni
                                          Hhs (lind Hhs)
            | equive_stack_access _ _ n i1 i2
                                  He => HAccess _ _ n i1 i2
                                               He (eeind _ _ He)
            | equive_stack_op op _ _ i1 i2
                              He => HStackOp
                                     op _ _ i1 i2
                                     He (eeind _ _ He)
            end.
        (**[]*)
      End ExprEquivalenceInduction.

      Section ExprEquivalenceDefs.
        Context {tags_t : Type}.

        Lemma equive_reflexive : Reflexive (@equive tags_t).
        Proof.
          unfold Reflexive; intros e;
          induction e using custom_e_ind;
          econstructor; eauto; try reflexivity;
          try (ind_list_Forall; eauto; assumption);
          try (ind_list_predfs; constructor;
               repeat split; unravel in *; intuition).
        Qed.

        Lemma equive_symmetric : Symmetric (@equive tags_t).
        Proof.
          intros ? ? ?;
                 match goal with
                 | H: ∮ _ ≡ _ |- _ => induction H using custom_equive_ind
                 end;
            econstructor; eauto; try (symmetry; assumption);
              try match goal with
                  | H: Forall2 equive ?es1 ?es2,
                       IH: Forall2 _ ?es1 ?es2
                    |- Forall2 equive ?es2 ?es1
                    => induction H; inv IH; constructor; intuition
                  end;
              try match goal with
                  | H: F.relfs
                         (fun et1 et2 : t * e tags_t =>
                            let τ1 := fst et1 in
                            let τ2 := fst et2 in
                            let e1 := snd et1 in
                            let e2 := snd et2 in
                            τ1 = τ2 /\ (∮ e1 ≡ e2))
                         ?fs1 ?fs2,
                       IH: F.relfs _ ?fs1 ?fs2 |- F.relfs _ ?fs2 ?fs1
                    => induction H; inv IH;
                      constructor; repeat relf_destruct;
                      unfold equiv in *; subst;
                        repeat split; intuition
                  end.
        Qed.

        Lemma equive_transitive : Transitive (@equive tags_t).
        Proof.
          intros e1; induction e1 using custom_e_ind;
            intros ? ? H12 H23; inv H12; inv H23;
              econstructor; try (etransitivity; eassumption); eauto;
                try match goal with
                    | H: Forall _ ?l1,
                      H12: Forall2 equive ?l1 ?l2,
                      H23: Forall2 equive ?l2 ?l3
                      |- Forall2 equive ?l1 ?l3
                      => generalize dependent l3;
                        generalize dependent l2; induction H;
                        intros [| ? ?] ? [| ? ?] ?;
                        repeat match goal with
                               | H: Forall2 _ _ (_ :: _) |- _ => inv H
                               | H: Forall2 _ (_ :: _) _ |- _ => inv H
                               end; constructor; eauto
                    end;
                try match goal with
                    | H: F.predfs_data _ ?f1,
                      H12: F.relfs _ ?f1 ?f2,
                      H23: F.relfs _ ?f2 ?f3 |- _
                      => generalize dependent f3;
                        generalize dependent f2; induction H;
                        intros [| [? [? ?]] ?] ? [| [? [? ?]] ?] ?;
                        try match goal with
                            | H: F.predf_data _ ?x |- _ => destruct x as [? [? ?]]
                            end;
                        repeat match goal with
                               | H: F.relfs _ _ (_ :: _) |- _ => inv H
                               | H: F.relfs _ (_ :: _) _ |- _ => inv H
                               end; constructor;
                          repeat relf_destruct; unravel in *; intuition;
                          repeat split; unravel; intuition; eauto;
                          try match goal with
                              | IH: forall _, _ -> forall _, _ -> _ |- _ => eapply IH; eauto
                              end; etransitivity; eauto
                    end.
          Qed.

        (** Decidable Expression Equivalence. *)
        Fixpoint eqbe (e1 e2 : e tags_t) : bool :=
          let fix lrec (es1 es2 : list (e tags_t)) : bool :=
              match es1, es2 with
              | [], _::_ | _::_, [] => false
              | [], [] => true
              | e1::es1, e2::es2 => eqbe e1 e2 && lrec es1 es2
              end in
          let fix efsrec {A : Type} (feq : A -> A -> bool)
                  (fs1 fs2 : F.fs string (A * e tags_t)) : bool :=
              match fs1, fs2 with
              | [], _::_ | _::_, [] => false
              | [], [] => true
              | (x1, (a1, e1))::fs1, (x2, (a2, e2))::fs2
                => equiv_dec x1 x2 &&&& feq a1 a2 &&
                  eqbe e1 e2 && efsrec feq fs1 fs2
              end in
          match e1, e2 with
          | <{ BOOL b1 @ _ }>, <{ BOOL b2 @ _ }> => eqb b1 b2
          | <{ w1 W n1 @ _ }>, <{ w2 W n2 @ _ }>
            => (w1 =? w2)%positive && (n1 =? n2)%Z
          | <{ w1 S z1 @ _ }>, <{ w2 S z2 @ _ }>
            => (w1 =? w2)%positive && (z1 =? z2)%Z
          | <{ Var x1:τ1 @ _ }>, <{ Var x2:τ2 @ _ }>
            => equiv_dec x1 x2 &&&& eqbt τ1 τ2
          | <{ Slice e1:t1 [h1:l1] @ _ }>, <{ Slice e2:t2 [h2:l2] @ _ }>
            => (h1 =? h2)%positive && (l1 =? l2)%positive &&
              eqbt t1 t2 && eqbe e1 e2
          | <{ Cast e1:τ1 @ _ }>, <{ Cast e2:τ2 @ _ }>
            => eqbt τ1 τ2 && eqbe e1 e2
          | <{ UOP u1 e1:τ1 @ _ }>, <{ UOP u2 e2:τ2 @ _ }>
            => equiv_dec u1 u2 &&&& eqbt τ1 τ2 && eqbe e1 e2
          | <{ BOP el1:τl1 o1 er1:τr1 @ _ }>,
            <{ BOP el2:τl2 o2 er2:τr2 @ _ }>
            => equiv_dec o1 o2 &&&& eqbt τl1 τl2 && eqbt τr1 τr2
              && eqbe el1 el2 && eqbe er1 er2
          | <{ tup es1 @ _ }>, <{ tup es2 @ _ }> => lrec es1 es2
          | <{ rec { fs1 } @ _ }>, <{ rec { fs2 } @ _ }>
            => efsrec eqbt fs1 fs2
          | <{ hdr { fs1 } valid:=e1 @ _ }>,
            <{ hdr { fs2 } valid:=e2 @ _ }>
            => eqbe e1 e2 && efsrec eqbt fs1 fs2
          | <{ HDR_OP o1 h1 @ _ }>,
            <{ HDR_OP o2 h2 @ _ }> => equiv_dec o1 o2 &&&& eqbe h1 h2
          | <{ Mem e1:τ1 dot x1 @ _ }>, <{ Mem e2:τ2 dot x2 @ _ }>
            => equiv_dec x1 x2 &&&& eqbt τ1 τ2 && eqbe e1 e2
          | <{ Error err1 @ _ }>, <{ Error err2 @ _ }>
            => if equiv_dec err1 err2 then true else false
          | <{ Matchkind mk1 @ _ }>, <{ Matchkind mk2 @ _ }>
            => if equiv_dec mk1 mk2 then true else false
          | <{ Stack hs1:ts1[n1] nextIndex:=ni1 }>,
            <{ Stack hs2:ts2[n2] nextIndex:=ni2 }>
            => (n1 =? n2)%positive && (ni1 =? ni2)%Z &&
              F.eqb_fs eqbt ts1 ts2 && lrec hs1 hs2
          | <{ Access hs1[n1] @ _ }>,
            <{ Access hs2[n2] @ _ }> => (n1 =? n2)%Z && eqbe hs1 hs2
          | <{ STK_OP o1 hs1 @ _ }>,
            <{ STK_OP o2 hs2 @ _ }> => equiv_dec o1 o2 &&&& eqbe hs1 hs2
          | _, _ => false
          end.
        (**[]*)

        Import F.RelfEquiv.

        Hint Rewrite eqb_reflx.
        Hint Rewrite Pos.eqb_refl.
        Hint Rewrite Z.eqb_refl.
        Hint Rewrite eqbt_refl.
        Hint Rewrite equiv_dec_refl.
        Local Hint Extern 5 => equiv_dec_refl_tactic : core.
        Hint Rewrite (@relop_eq string).

        Lemma equive_eqbe : forall e1 e2 : e tags_t,
            ∮ e1 ≡ e2 -> eqbe e1 e2 = true.
        Proof.
          intros ? ? ?;
          match goal with
          | H: ∮ _ ≡ _ |- _ => induction H using custom_equive_ind
          end; unravel in *; autorewrite with core; auto;
          repeat match goal with
                 | H: ?trm = true |- context [ ?trm ] => rewrite H; clear H
                 end; auto;
          try match goal with
              | H: Forall2 equive ?es1 ?es2,
                IH: Forall2 _ ?es1 ?es2 |- _
                => induction H; inv IH; unravel in *; auto; intuition
              end;
          try match goal with
              | H: F.relfs _ ?fs1 ?fs2,
                IH: F.relfs _ ?fs1 ?fs2 |- _
                => induction H; inv IH; auto;
                  match goal with
                  | H: F.relf _ ?f1 ?f2 |- _
                    => destruct f1 as [? [? ?]];
                      destruct f2 as [? [? ?]];
                      repeat relf_destruct; unravel in *;
                      unfold equiv in *;
                      intuition; subst;
                      autorewrite with core;
                      try equiv_dec_refl_tactic
                  end
              end;
          repeat match goal with
                 | H: ?trm = true |- context [ ?trm ] => rewrite H; clear H
                 end; auto;
            try match goal with
                | |- context [ F.eqb_fs eqbt ?ts ?ts ]
                  => rewrite (equiv_eqb_fs _ _ eqbt_reflect ts ts);
                      unfold equiv in *; auto; try reflexivity
                end;
          try (equiv_dec_refl_tactic; auto;
               autorewrite with core in *; contradiction).
        Qed.

        Ltac eq_true_terms :=
          match goal with
          | H: eqb _ _ = true |- _
            => apply eqb_prop in H; subst
          | H: (_ =? _)%positive = true |- _
            => apply Peqb_true_eq in H; subst
          | H: (_ =? _)%Z = true |- _
            => apply Z.eqb_eq in H; subst
          | H: _ && _ = true |- _
            => apply andb_true_iff in H as [? ?]
          | H: context [equiv_dec ?x1 ?x2 &&&& _] |- _
            => destruct (equiv_dec x1 x2) as [? | ?];
              unravel in H; try discriminate
          | H: context [if equiv_dec ?t1 ?t2 then _ else _] |- _
            => destruct (equiv_dec t1 t2) as [? | ?];
              unravel in H; try discriminate
          | H: context [if eqbt ?t1 ?t2 then _ else _] |- _
            => destruct (eqbt t1 t2) eqn:?;
              unravel in H; try discriminate
          | H: context [eqbt ?t1 ?t2 && _] |- _
            => destruct (eqbt t1 t2) eqn:?;
              unravel in H; try discriminate
          | H: context [eqbe ?e1 ?e2 && _] |- _
            => destruct (eqbe e1 e2) eqn:?;
              unravel in H; try discriminate
          | H: eqbt _ _ = true |- _
            => apply eqbt_eq_iff in H
          | H: context [if eqbe ?e1 ?e2 then _ else _] |- _
            => destruct (eqbe e1 e2) eqn:?;
              unravel in H; try discriminate
          | H: eqbe ?e1 _ = true,
            IH: forall e2, eqbe ?e1 e2 = true -> ∮ ?e1 ≡ e2 |- _
            => apply IH in H
          | H: _ === _ |- _ => unfold equiv in H;
                             match goal with
                             | H: _ = _ |- _ => subst
                             end
          | H: equiv _ _ |- _ => unfold equiv in H;
                               match goal with
                               | H: _ = _ |- _ => subst
                               end
          | H: Forall _ (_ :: _) |- _ => inv H
          | H: ?P, IH: ?P -> ?Q |- _ => apply IH in H as ?
          | H: (if ?trm then true else false) = true |- _
            => destruct trm eqn:?; unravel in H; try discriminate
          | H: relop _ _ _ |- _ => inv H
          | H: F.eqb_fs eqbt _ _ = true
            |- _ => pose proof eqb_fs_equiv _ _ eqbt_reflect _ _ H as ?; clear H
          | H: F.relfs eq _ _ |- _ => apply eq_relfs in H; subst
          end.
        (**[]*)

        Local Hint Constructors equive : core.
        Local Hint Extern 5 => eq_true_terms : core.

        Lemma eqbe_equive : forall e1 e2 : e tags_t,
            eqbe e1 e2 = true -> equive e1 e2.
        Proof.
          induction e1 using custom_e_ind;
          intros [] ?; unravel in *;
          try discriminate; auto;
          repeat eq_true_terms;
          unfold equiv in *;
          subst; auto; constructor; auto;
          try match goal with
              | |- Forall2 _ ?es1 ?es2
                => generalize dependent es2;
                  induction es1; intros [];
                  unravel in *; try discriminate; auto
              end;
          try match goal with
              | |- F.relfs _ ?fs1 ?fs2
                => generalize dependent fs2;
                  induction fs1 as [| [? [? ?]] ? ?];
                  intros [| [? [? ?]] ?]; intros;
                  unravel in *; try discriminate; auto;
                  try destruct_lifted_andb; repeat destruct_andb;
                  try invert_cons_predfs; repeat constructor;
                  intuition; unfold F.relfs in *; auto
              end.
        Qed.

        Local Hint Resolve equive_eqbe : core.
        Local Hint Resolve eqbe_equive : core.

        Lemma equive_eqbe_iff : forall e1 e2 : e tags_t,
            ∮ e1 ≡ e2 <-> eqbe e1 e2 = true.
        Proof. intros; split; auto 2. Qed.

        Hint Resolve equive_eqbe_iff : core.
        Hint Extern 5 =>
        match goal with
        | H: eqbe ?e1 ?e2 = false,
          H': ∮ ?e1 ≡ ?e2 |- False
          => apply equive_eqbe_iff in H';
            rewrite H' in H; discriminate
        end : core.

        Lemma equive_reflect : forall e1 e2 : e tags_t,
            reflect (∮ e1 ≡ e2) (eqbe e1 e2).
        Proof.
          intros; reflect_split; auto 2;
            autorewrite with core; auto 2.
        Qed.
      End ExprEquivalenceDefs.

      Local Hint Resolve equive_reflexive : core.
      Local Hint Resolve equive_symmetric : core.
      Local Hint Resolve equive_transitive : core.

      Instance ExprEquiv {tags_t : Type} : Equivalence (@equive tags_t).
      Proof. constructor; auto 1. Defined.
    End ExprEquivalence.
  End Expr.

  (** * Statement Grammar *)
  Module Stmt.
    Module E := Expr.

    Section Statements.
      Variable (tags_t : Type).

      Inductive s : Type :=
      | SSkip (i : tags_t)                              (* skip, useful for
                                                           small-step semantics *)
      | SVardecl (type : E.t)
                 (x : string) (i : tags_t)       (* Variable declaration. *)
      | SAssign (type : E.t) (lhs rhs : E.e tags_t)
                (i : tags_t)                            (* assignment *)
      | SConditional (guard_type : E.t)
                     (guard : E.e tags_t)
                     (tru_blk fls_blk : s) (i : tags_t) (* conditionals *)
      | SSeq (s1 s2 : s) (i : tags_t)                   (* sequences,
                                                           an alternative to blocks *)
      | SExternMethodCall (e : string) (f : string)
                          (args : E.arrowE tags_t)
                          (i : tags_t)                  (* extern method calls *)
      | SFunCall (f : string)
                 (args : E.arrowE tags_t) (i : tags_t)  (* function call *)
      | SActCall (f : string)
                 (args : E.args tags_t) (i : tags_t)    (* action call *)
      | SReturnVoid (i : tags_t)                        (* void return statement *)
      | SReturnFruit (t : E.t)
                     (e : E.e tags_t)(i : tags_t)       (* fruitful return statement *)
      | SExit (i : tags_t)                              (* exit statement *)
      | SInvoke (x : string) (i : tags_t)          (* table invocation *)
      | SApply (x : string)
               (args : E.args tags_t) (i : tags_t)      (* control apply statements,
                                                           where [x] is the
                                                           name of an instance *).
    (**[]*)
    End Statements.

    Arguments SSkip {tags_t}.
    Arguments SVardecl {_}.
    Arguments SAssign {tags_t}.
    Arguments SConditional {tags_t}.
    Arguments SSeq {tags_t}.
    Arguments SFunCall {_}.
    Arguments SActCall {_}.
    Arguments SExternMethodCall {_}.
    Arguments SReturnVoid {tags_t}.
    Arguments SReturnFruit {tags_t}.
    Arguments SExit {_}.
    Arguments SApply {_}.
    Arguments SInvoke {_}.

    Module StmtNotations.
      Notation "'-{' stmt '}-'" := stmt (stmt custom p4stmt at level 99).
      Notation "( x )" := x (in custom p4stmt, x at level 99).
      Notation "x"
        := x (in custom p4stmt at level 0, x constr at level 0).
      Notation "'skip' @ i" := (SSkip i) (in custom p4stmt at level 0).
      Notation "s1 ; s2 @ i"
        := (SSeq s1 s2 i) (in custom p4stmt at level 99,
                            s1 custom p4stmt, s2 custom p4stmt,
                            right associativity).
      Notation "'var' x : t @ i"
               := (SVardecl t x i)
                    (in custom p4stmt at level 0, t custom p4type).
      Notation "'asgn' e1 ':=' e2 : t @ i"
              := (SAssign t e1 e2 i)
                    (in custom p4stmt at level 40,
                        e1 custom p4expr, e2 custom p4expr,
                        t custom p4type, no associativity).
      Notation "'if' e : t 'then' s1 'else' s2 @ i"
              := (SConditional t e s1 s2 i)
                    (in custom p4stmt at level 80,
                        t custom p4type, e custom p4expr,
                        s1 custom p4stmt, s2 custom p4stmt,
                        no associativity).
      Notation "'call' f 'with' args @ i"
        := (SFunCall f (Arrow args None) i)
             (in custom p4stmt at level 30, no associativity).
      Notation "'let' e : t ':=' 'call' f 'with' args @ i"
               := (SFunCall f (Arrow args (Some (t,e))) i)
                    (in custom p4stmt at level 0,
                        e custom p4expr, t custom p4stmt, no associativity).
      Notation "'calling' a 'with' args @ i"
               := (SActCall a args i) (in custom p4stmt at level 0).
      Notation "'extern' e 'calls' f 'with' args 'gives' x @ i"
               := (SExternMethodCall e f (Arrow args x) i)
                    (in custom p4stmt at level 0, no associativity).
      Notation "'return' e : t @ i"
               := (SReturnFruit t e i)
                    (in custom p4stmt at level 30,
                        e custom p4expr, t custom p4type, no associativity).
      Notation "'returns' @ i"
               := (SReturnVoid i)
                    (in custom p4stmt at level 0, no associativity).
      Notation "'exit' @ i"
               := (SExit i) (in custom p4stmt at level 0, no associativity).
      Notation "'apply' x 'with' args @ i"
               := (SApply x args i) (in custom p4stmt at level 0, no associativity).
      Notation "'invoke' tbl @ i"
               := (SInvoke tbl i) (in custom p4stmt at level 0).
    End StmtNotations.
  End Stmt.

  (** * Declaration Grammar *)
  Module Decl.
    Module E := Expr.
    Module S := Stmt.

    Section Declarations.
      Variable (tags_t : Type).

      (** Here is the subset of declarations that
          may occur within controls, parsers,
          and even the top-level. *)
      Inductive d : Type :=
      | DVardecl (typ : E.t) (x : string)
                 (i : tags_t)                      (* unitialized variable *)
      | DVarinit (typ : E.t) (x : string)
                 (rhs : E.e tags_t) (i : tags_t)   (* initialized variable *)
      | DInstantiate (C : string) (x : string)
                     (cargs : E.constructor_args tags_t)
                     (i : tags_t)                  (* constructor [C]
                                                      with constructor [args]
                                                      makes instance [x]. *)
      | DSeq (d1 d2 : d) (i : tags_t)              (* sequence of declarations *).
    (**[]*)
    End Declarations.

    Arguments DVardecl {tags_t}.
    Arguments DVarinit {tags_t}.
    Arguments DInstantiate {tags_t}.
    Arguments DSeq {tags_t}.

    Module DeclNotations.
      Notation "';{' decl '};'" := decl (decl custom p4decl at level 99).
      Notation "( x )" := x (in custom p4decl, x at level 99).
      Notation "x"
        := x (in custom p4decl at level 0, x constr at level 0).
      Notation "'Var' x : t @ i"
        := (DVardecl t x i) (in custom p4decl at level 0, t custom p4type).
      Notation "'Let' x : t ':=' e @ i"
        := (DVarinit t x e i)
             (in custom p4decl at level 0, t custom p4type, e custom p4expr).
      Notation "'Instance' x 'of' c ( args ) @ i"
               := (DInstantiate c x args i) (in custom p4decl at level 0).
      Notation "d1 ';;' d2 @ i"
               := (DSeq d1 d2 i)
                    (in custom p4decl at level 10,
                        d1 custom p4decl, d2 custom p4decl,
                        right associativity).
    End DeclNotations.
  End Decl.

  (** * Parsers *)
  Module Parser.
    Module E := Expr.
    Module S := Stmt.

    Module ParserState.
      Section Parsers.
        Variable (tags_t : Type).

        (** Parser expressions, which evaluate to state names *)
        Inductive e : Type :=
        | PAccept (i : tags_t)        (* accept the packet *)
        | PReject (i : tags_t)        (* reject the packet. *)
        | PState (st : string)
                 (i : tags_t)         (* user-defined state name. *)
        | PSelect (exp : E.e tags_t)
                  (cases : list (option (E.e tags_t) * e))
                  (i : tags_t)        (* select expressions,
                                         where an optional represents
                                         the possibility of a "dontcare". *).
        (**[]*)

        (** Parser States. *)
        Inductive state : Type :=
        | State (stmt : S.s tags_t) (transition : e).
        (**[]*)
      End Parsers.

      Arguments PAccept {_}.
      Arguments PReject {_}.
      Arguments PState {_}.
      Arguments PSelect {_}.
      Arguments State {_}.

      Module ParserNotations.
        Notation "'p{' exp '}p'" := exp (exp custom p4prsrexpr at level 99).
        Notation "( x )" := x (in custom p4prsrexpr, x at level 99).
        Notation "x"
          := x (in custom p4prsrexpr at level 0, x constr at level 0).
        Notation "'accept' @ i" := (PAccept i) (in custom p4prsrexpr at level 0).
        Notation "'reject' @ i" := (PReject i) (in custom p4prsrexpr at level 0).
        Notation "'goto' st @ i"
                 := (PState st i) (in custom p4prsrexpr at level 0).
        Notation "'select' exp { cases } @ i"
                 := (PSelect exp cases i)
                      (in custom p4prsrexpr at level 10,
                          exp custom p4expr).
        Notation "'&{' st '}&'" := st (st custom p4prsrstate at level 99).
        Notation "'state' { s } 'transition' pe"
                 := (State s pe)
                      (in custom p4prsrstate at level 0,
                          s custom p4stmt, pe custom p4prsrexpr).
      End ParserNotations.

      (** A custom induction principle
          for parser expressions. *)
      Section ParserExpreInduction.
        Import ParserNotations.
        Import E.ExprNotations.

        Context {tags_t : Type}.

        (** An arbitrary predicate. *)
        Variable P : e tags_t -> Prop.

        Hypothesis HAccept : forall i, P p{ accept @ i }p.

        Hypothesis HReject : forall i, P p{ reject @ i }p.

        Hypothesis HState : forall st i, P p{ goto st @ i }p.

        Hypothesis HSelect : forall exp cases i,
            Forall (P ∘ snd) cases ->
            P p{ select exp { cases } @ i }p.
        (**[]*)

        (** A custom induction principle,
            do [induction ?H using pe_ind] *)
        Definition pe_ind : forall pe : e tags_t, P pe :=
          fix peind pe : P pe :=
            let fix lind {A : Type} (es : list (A * e tags_t))
                : Forall (P ∘ snd) es :=
                match es with
                | [] => Forall_nil _
                | (_,pe) as oe :: es =>
                  Forall_cons oe (peind pe) (lind es)
                end in
            match pe with
            | p{ accept @ i }p => HAccept i
            | p{ reject @ i }p => HReject i
            | p{ goto st @ i }p => HState st i
            | p{ select exp { cases } @ i }p => HSelect exp _ i (lind cases)
            end.
        (**[]*)
      End ParserExpreInduction.
    End ParserState.
  End Parser.

  (** * Controls *)
  Module Control.
    Module E := Expr.
    Module S := Stmt.
    Module D := Decl.

    Module ControlDecl.
      Section ControlDecls.
        Variable (tags_t : Type).

        (** Table. *)
        Inductive table : Type :=
        | Table (key : list (E.t * E.e tags_t * E.matchkind))
                (actions : list string).
        (**[]*)

        (** Declarations that may occur within Controls. *)
        (* TODO, this is a stub. *)
        Inductive d : Type :=
        | CDAction (a : string)
                   (signature : E.params)
                   (body : S.s tags_t) (i : tags_t) (* action declaration *)
        | CDTable (t : string) (bdy : table)
                  (i : tags_t)                      (* table declaration *)
        | CDDecl (d : D.d tags_t) (i : tags_t)
        | CDSeq (d1 d2 : d) (i : tags_t).
        (**[]*)
      End ControlDecls.

      Arguments Table {_}.
      Arguments CDAction {_}.
      Arguments CDTable {_}.
      Arguments CDDecl {_}.
      Arguments CDSeq {_}.

      Module ControlDeclNotations.
        Notation "'c{' decl '}c'" := decl (decl custom p4ctrldecl at level 99).
        Notation "( x )" := x (in custom p4ctrldecl, x at level 99).
        Notation "x"
          := x (in custom p4ctrldecl at level 0, x constr at level 0).
        Notation "d1 ';c;' d2 @ i"
          := (CDSeq d1 d2 i)
               (in custom p4ctrldecl at level 10,
                   d1 custom p4ctrldecl, d2 custom p4ctrldecl,
                   right associativity).
        Notation "'Decl' d @ i"
          := (CDDecl d i)
               (in custom p4ctrldecl at level 0, d custom p4decl).
        Notation "'action' a ( params ) { body } @ i"
          := (CDAction a params body i)
               (in custom p4ctrldecl at level 0, body custom p4stmt).
        Notation "'table' t 'key' ':=' ems 'actions' ':=' acts @ i"
          := (CDTable t (Table ems acts) i)
               (in custom p4ctrldecl at level 0).
      End ControlDeclNotations.
    End ControlDecl.
  End Control.

  (** * Top-Level Declarations *)
  Module TopDecl.
    Module E := Expr.
    Module S := Stmt.
    Module D := Decl.
    Module C := Control.ControlDecl.
    Module P := Parser.ParserState.

    Section TopDeclarations.
      Variable (tags_t : Type).

      (** Top-level declarations. *)
      (* TODO, this is a stub. *)
      Inductive d : Type :=
      | TPDecl (d : D.d tags_t) (i : tags_t) (* normal declarations *)
      | TPExtern (e : string)
                 (cparams : E.constructor_params)
                 (methods : F.fs string E.arrowT)
                 (i : tags_t) (* extern declarations *)
      | TPControl (c : string)
                  (cparams : E.constructor_params) (* constructor params *)
                  (params : E.params) (* apply block params *)
                  (body : C.d tags_t) (apply_blk : S.s tags_t) (i : tags_t)
      | TPParser (p : string)
                 (cparams : E.constructor_params) (* constructor params *)
                 (params : E.params)           (* invocation params *)
                 (states : F.fs string (P.state tags_t)) (* parser states *)
                 (i : tags_t) (* TODO: start state? *)
      | TPFunction (f : string) (signature : E.arrowT)
                   (body : S.s tags_t) (i : tags_t)
                   (* function/method declaration *)
      | TPSeq (d1 d2 : d) (i : tags_t).
      (**[]*)
    End TopDeclarations.

    Arguments TPDecl {_}.
    Arguments TPExtern {_}.
    Arguments TPControl {_}.
    Arguments TPParser {_}.
    Arguments TPFunction {_}.
    Arguments TPSeq {_}.

    Module TopDeclNotations.
      Notation "'%{' decl '}%'" := decl (decl custom p4topdecl at level 99).
      Notation "( x )" := x (in custom p4topdecl, x at level 99).
      Notation "x"
        := x (in custom p4topdecl at level 0, x constr at level 0).
      Notation "d1 ';%;' d2 @ i"
               := (TPSeq d1 d2 i)
                    (in custom p4topdecl at level 10,
                        d1 custom p4topdecl, d2 custom p4topdecl,
                        right associativity).
      Notation "'DECL' d @ i"
        := (TPDecl d i)
             (in custom p4topdecl at level 0, d custom p4decl).
      Notation "'void' f ( params ) { body } @ i"
               := (TPFunction f (Arrow params None) body i)
                    (in custom p4topdecl at level 0, body custom p4stmt).
      Notation "'fn' f ( params ) '->' t { body } @ i"
               := (TPFunction f (Arrow params (Some t)) body i)
                    (in custom p4topdecl at level 0,
                        t custom p4type, body custom p4stmt).
      Notation "'extern' e ( cparams ) { methods } @ i"
               := (TPExtern e cparams methods i)
                    (in custom p4topdecl at level 0).
      Notation "'control' c ( cparams ) ( params ) 'apply' { blk } 'where' { body } @ i"
               := (TPControl c cparams params body blk i)
                    (in custom p4topdecl at level 0,
                        blk custom p4stmt, body custom p4ctrldecl).
      Notation "'parser' p ( cparams ) ( params ) { states } @ i"
               := (TPParser p cparams params states i)
                    (in custom p4topdecl at level 0).
    End TopDeclNotations.
  End TopDecl.

  Module P4cubNotations.
    Export Expr.TypeNotations.
    Export Expr.UopNotations.
    Export Expr.BopNotations.
    Export Expr.MatchkindNotations.
    Export Expr.HeaderOpNotations.
    Export Expr.HeaderStackOpNotations.
    Export Expr.ExprNotations.
    Export Stmt.StmtNotations.
    Export Decl.DeclNotations.
    Export Parser.ParserState.ParserNotations.
    Export Control.ControlDecl.ControlDeclNotations.
    Export TopDecl.TopDeclNotations.
  End P4cubNotations.
End P4cub.