Require Import Coq.Bool.Bool.
Require Import Coq.NArith.BinNatDef.
Require Import Coq.ZArith.BinIntDef.
Require Import Coq.NArith.BinNat.
Require Import Coq.ZArith.BinInt.
Require Import P4light.AST.

(** Notation entries. *)
Declare Custom Entry p4value.
Declare Custom Entry p4lvalue.

Section Values.
  Variable (tags_t : Type).

  (** Values from expression evaluation. *)
  Inductive v : Type :=
  | VBool (b : bool)
  | VInt (w : positive) (n : Z)
  | VBit (w : positive) (n : N)
  | VRecord (fs : Field.fs tags_t v)
  | VHeader (fs : Field.fs tags_t v) (validity : bool)
  | VError (err : option (string tags_t))
  | VMatchKind (mk : P4light.Expr.matchkind)
  | VHeaderStack (headers : list (bool * Field.fs tags_t v))
                 (size : positive) (nextIndex : N).
  (**[]*)

  (** Lvalues. *)
  Inductive lv : Type :=
  | LVVar (x : name tags_t)                 (* Local variables. *)
  | LVMember (arg : lv) (x : string tags_t) (* Member access. *)
  | LVAccess (stack : lv) (index : N)       (* Header stack indexing. *).
  (**[]*)

  (** Evaluated arguments. *)
  Definition argsv : Type := Field.fs tags_t (P4light.paramarg v lv).

  (** A custom induction principle for value. *)
  Section ValueInduction.
    Variable P : v -> Prop.

    Hypothesis HVBool : forall b, P (VBool b).

    Hypothesis HVBit : forall w n, P (VBit w n).

    Hypothesis HVInt : forall w n, P (VInt w n).

    Hypothesis HVRecord : forall fs,
        Field.predfs_data P fs -> P (VRecord fs).

    Hypothesis HVHeader : forall fs b,
        Field.predfs_data P fs -> P (VHeader fs b).

    Hypothesis HVError : forall err, P (VError err).

    Hypothesis HVMatchKind : forall mk, P (VMatchKind mk).

    Hypothesis HVHeaderStack : forall hs size ni,
        Forall (Field.predfs_data P ∘ snd) hs -> P (VHeaderStack hs size ni).

    Definition custom_value_ind : forall v' : v, P v' :=
      fix custom_value_ind (val : v) : P val :=
        let fix fields_ind
                (flds : Field.fs tags_t v) : Field.predfs_data P flds :=
            match flds as fs return Field.predfs_data P fs with
            | [] => Forall_nil (Field.predf_data P)
            | (_, hfv) as hf :: tf =>
              Forall_cons hf (custom_value_ind hfv) (fields_ind tf)
            end in
        let fix ffind
                (fflds : list (bool * Field.fs tags_t v))
            : Forall (Field.predfs_data P ∘ snd) fflds :=
            match fflds as ffs
                  return Forall (Field.predfs_data P ∘ snd) ffs with
            | [] => Forall_nil (Field.predfs_data P ∘ snd)
            | (_, vs) as bv :: ffs => Forall_cons bv (fields_ind vs) (ffind ffs)
            end in
        match val as v' return P v' with
        | VBool b  => HVBool b
        | VInt w n => HVInt w n
        | VBit w n => HVBit w n
        | VRecord vs     => HVRecord vs (fields_ind vs)
        | VHeader vs b   => HVHeader vs b (fields_ind vs)
        | VError err     => HVError err
        | VMatchKind mk  => HVMatchKind mk
        | VHeaderStack hs size ni => HVHeaderStack hs size ni (ffind hs)
        end.
  End ValueInduction.

  Section ValueEquality.

    Import Field.FieldTactics.
    Instance P4StringEquivalence : Equivalence (@P4String.equiv tags_t) :=
      P4String.EquivEquivalence tags_t.
    (**[]*)

    Instance P4StringEqDec : EqDec (string tags_t) (@P4String.equiv tags_t) :=
      P4String.P4StringEqDec tags_t.
    (**[]*)

    (** Computational Value equality *)
    Fixpoint eqbv (v1 v2 : v) : bool :=
      let fix fields_rec (vs1 vs2 : Field.fs tags_t v) : bool :=
          match vs1, vs2 with
          | [],           []           => true
          | (x1, v1)::vs1, (x2, v2)::vs2 => if P4String.equivb x1 x2 then
                                           eqbv v1 v2 && fields_rec vs1 vs2
                                         else false
          | [],            _::_
          | _::_,           []          => false
          end in
      let fix ffrec (v1ss v2ss : list (bool * Field.fs tags_t v)) : bool :=
          match v1ss, v2ss with
          | [], _::_ | _::_, [] => false
          | [], [] => true
          | (b1,vs1) :: v1ss, (b2, vs2) :: v2ss => (eqb b1 b2)%bool &&
                                                fields_rec vs1 vs2 &&
                                                ffrec v1ss v2ss
          end in
      match v1, v2 with
      | VBool b1,       VBool b2       => eqb b1 b2
      | VInt w1 z1,     VInt w2 z2     => (w1 =? w2)%positive &&
                                         (z1 =? z2)%Z
      | VBit w1 n1,     VBit w2 n2     => (w1 =? w2)%positive &&
                                         (n1 =? n2)%N
      | VMatchKind mk1, VMatchKind mk2 => if equiv_dec mk1 mk2
                                         then true
                                         else false
      | VError err1,    VError err2    => if equiv_dec err1 err2
                                         then true
                                         else false
      | VHeader vs1 b1, VHeader vs2 b2 => (eqb b1 b2)%bool && fields_rec vs1 vs2
      | VRecord vs1,    VRecord vs2    => fields_rec vs1 vs2
      | VHeaderStack vss1 n1 ni1,
        VHeaderStack vss2 n2 ni2       => (n1 =? n2)%positive &&
                                         (ni1 =? ni2)%N && ffrec vss1 vss2
      | _,              _              => false
      end.
    (**[]*)

    (** Value equivalence relation. *)
    Inductive equivv : v -> v -> Prop :=
    | equivv_bool (b : bool) :
        equivv (VBool b) (VBool b)
    | equivv_int (w : positive) (n : Z) :
        equivv (VInt w n) (VInt w n)
    | equivv_bit (w : positive) (n : N) :
        equivv (VBit w n) (VBit w n)
    | equivv_record (fs1 fs2 : Field.fs tags_t v) :
        Field.relfs equivv fs1 fs2 ->
        equivv (VRecord fs1) (VRecord fs2)
    | equivv_header (fs1 fs2 : Field.fs tags_t v) (b : bool) :
        Field.relfs equivv fs1 fs2 ->
        equivv (VHeader fs1 b) (VHeader fs2 b)
    | equivv_error (err1 err2 : option (string tags_t)) :
        equiv err1 err2 ->
        equivv (VError err1) (VError err2)
    | equivv_matchkind (mk : P4light.Expr.matchkind) :
        equivv (VMatchKind mk) (VMatchKind mk)
    | equivv_stack (n : positive) (ni : N)
                   (vss1 vss2 : list (bool * Field.fs tags_t v)) :
        Forall2 (fun bv1 bv2 =>
                   fst bv1 = fst bv2 /\
                   Field.relfs equivv (snd bv1) (snd bv2))
                vss1 vss2 ->
        equivv (VHeaderStack vss1 n ni) (VHeaderStack vss2 n ni).
    (**[]*)

    (** A custom induction principle for value equivalence. *)
    Section ValueEquivalenceInduction.
      (** An arbitrary predicate. *)
      Variable P : v -> v -> Prop.

      Hypothesis HBool : forall b, P (VBool b) (VBool b).

      Hypothesis HBit : forall w n, P (VBit w n) (VBit w n).

      Hypothesis HInt : forall w z, P (VInt w z) (VInt w z).

      Hypothesis HError : forall err1 err2,
          equiv err1 err2 -> P (VError err1) (VError err2).

      Hypothesis HMatchkind : forall mk, P (VMatchKind mk) (VMatchKind mk).

      Hypothesis HRecord : forall fs1 fs2,
          Field.relfs equivv fs1 fs2 ->
          Field.relfs P fs1 fs2 ->
          P (VRecord fs1) (VRecord fs2).

      Hypothesis HHeader : forall fs1 fs2 b,
          Field.relfs equivv fs1 fs2 ->
          Field.relfs P fs1 fs2 ->
          P (VHeader fs1 b) (VHeader fs2 b).

      Hypothesis HStack : forall n ni vss1 vss2,
          Forall2 (fun bv1 bv2 =>
                     fst bv1 = fst bv2 /\
                     Field.relfs equivv (snd bv1) (snd bv2))
                  vss1 vss2 ->
          Forall2 (fun vss1 vss2 => Field.relfs P (snd vss1) (snd vss2)) vss1 vss2 ->
          P (VHeaderStack vss1 n ni) (VHeaderStack vss2 n ni).

      (** Custom [eqiuvv] induction principle.
          Do [induction ?H using custom_equivv_ind] *)
      Definition custom_equivv_ind : forall (v1 v2 : v) (H : equivv v1 v2), P v1 v2 :=
        fix vind v1 v2 H :=
          let fix find
                  {vs1 vs2 : Field.fs tags_t v}
                  (HR : Field.relfs equivv vs1 vs2) : Field.relfs P vs1 vs2 :=
              match HR in Forall2 _ v1s v2s return Forall2 (Field.relf P) v1s v2s with
              | Forall2_nil _ => Forall2_nil (Field.relf P)
              | Forall2_cons v1 v2
                             (conj HName Hequivv)
                             Htail => Forall2_cons
                                       v1 v2
                                       (conj
                                          HName
                                          (vind _ _ Hequivv))
                                       (find Htail)
                end in
          let fix ffind
                  {vss1 vss2 : list (bool * Field.fs tags_t v)}
                  (HR : Forall2
                          (fun bv1 bv2 =>
                             fst bv1 = fst bv2 /\
                             Field.relfs equivv (snd bv1) (snd bv2))
                          vss1 vss2)
              : Forall2
                  (fun vss1 vss2 =>
                     Field.relfs P (snd vss1) (snd vss2)) vss1 vss2 :=
              match HR
                    in Forall2 _ v1ss v2ss
                    return Forall2
                             (fun vss1 vss2 => Field.relfs P (snd vss1) (snd vss2))
                             v1ss v2ss with
              | Forall2_nil _ => Forall2_nil _
              | Forall2_cons head _ (conj _ Hhead)
                             Htail => Forall2_cons
                                       head _
                                       (find Hhead)
                                       (ffind Htail)
                end in
          match H in (equivv v1' v2') return P v1' v2' with
          | equivv_bool b => HBool b
          | equivv_bit w n => HBit w n
          | equivv_int w z => HInt w z
          | equivv_error err1 err2 H12 => HError err1 err2 H12
          | equivv_matchkind mk => HMatchkind mk
          | equivv_record _ _ H12 => HRecord _ _ H12 (find H12)
          | equivv_header _ _ b H12 => HHeader _ _ b H12 (find H12)
          | equivv_stack n ni _ _ H12 => HStack n ni _ _ H12 (ffind H12)
          end.
      (**[]*)
    End ValueEquivalenceInduction.

    Lemma equivv_reflexive : Reflexive equivv.
    Proof.
      intros v; induction v using custom_value_ind;
        constructor; try reflexivity;
      try (induction fs as [| [x v] vs];
           inversion H; subst; constructor;
           [ unfold Field.predf_data in H2;
             constructor; simpl; try reflexivity; auto
           | apply IHvs; auto]).
      - induction hs as [| [b vs] hs IHhs];
          inv H; constructor; auto; simpl; split; auto.
        unfold Basics.compose in H2; simpl in H2.
        rename H2 into H. clear b hs IHhs H3 ni size.
        induction vs as [| [x v] vs IHvs];
          constructor; invert_cons_predfs; simpl in *;
        [ split; simpl; auto; reflexivity
        | apply IHvs; auto ].
    Qed.

    Lemma equivv_symmetric : Symmetric equivv.
    Proof.
      unfold Symmetric.
      intros v1 v2 Hv;
        induction Hv using custom_equivv_ind;
        constructor; try (symmetry; assumption);
      try (induction H; inv H0; constructor;
          destruct x as [x1 v1]; destruct y as [x2 v2];
            unfold Field.relf in *; simpl in *;
        [ destruct H5; split; try symmetry; auto
        | apply IHForall2; auto ]; assumption).
      - induction H; inv H0; constructor;
          destruct x as [b1 vs1];
          destruct y as [b2 vs2]; auto; simpl in *.
        destruct H as [Hb H]; subst; split; auto.
        clear b2 l l' H1 IHForall2 H7 n ni.
        induction H; inv H5; constructor;
          destruct x as [x1 v1]; destruct y as [x2 v2].
            unfold Field.relf in *; simpl in *.
            + destruct H4; split; try symmetry; auto.
            + apply IHForall2; auto.
    Qed.

    Lemma equivv_transitive : Transitive equivv.
    Proof.
      intros v1; induction v1 using custom_value_ind; intros v2 v3 H12 H23;
        inversion H12; subst; inversion H23; subst;
          clear H12 H23; constructor;
            try (transitivity err2; auto); try (transitivity mk2; auto);
      try (generalize dependent fs0; generalize dependent fs2;
           rename fs into fs1;
           induction fs1 as [| [x1 v1] vs1 IHvs1];
           intros [| [x2 v2] vs2] H12 [| [x3 v3] vs3] H23;
           inversion H12; subst; inversion H23; subst;
           clear H12 H23; constructor; inversion H; subst; clear H;
           [ unfold Field.relf in *; simpl in *;
             unfold Field.predf_data;
             destruct H3; destruct H4;
             pose proof (H2 v2 v3) as H23; try split; auto;
             transitivity x2; auto
           | apply IHvs1 with vs2; auto]).
      - rename hs into vss1; rename vss0 into vss3.
        generalize dependent vss3;
          generalize dependent vss2.
        induction vss1 as [| [b1 vs1] vss1 IHvss1];
          intros [| [b2 vs2] vss2] H12ss [| [b3 vs3] vss3] H23ss;
          inv H; inv H12ss; inv H23ss;
            constructor; eauto; simpl in *.
        destruct H4; destruct H5; subst; split; auto.
        unfold Basics.compose in H2; simpl in H2.
        clear b3 IHvss1 size ni vss1 vss2 vss3 H3 H6 H8.
        generalize dependent vs3; generalize dependent vs2.
        induction vs1 as [| [x1 v1] vs1 IHvs1];
          intros [| [x2 v2] vs2] H12s [| [x3 v3] vs3] H23s;
          inv H2; inv H12s; inv H23s; constructor.
        + unfold Field.relf in *; simpl in *.
          destruct H4; destruct H5; split;
            try (etransitivity; eassumption).
          eapply H1; eauto.
        + eapply IHvs1; eauto.
    Qed.

    Instance ValueEquivalence : Equivalence equivv.
    Proof.
      constructor; [ apply equivv_reflexive
                   | apply equivv_symmetric
                   | apply equivv_transitive].
    Defined.

    Lemma equivv_eqbv : forall v1 v2 : v, equivv v1 v2 -> eqbv v1 v2 = true.
    Proof.
      intros v1 v2 H.
      induction H using custom_equivv_ind; simpl in *;
        try rewrite eqb_reflx;
        try rewrite Pos.eqb_refl;
        try rewrite N.eqb_refl;
        try rewrite Z.eqb_refl;
        simpl; auto.
      - unfold equiv in H. inversion H; subst.
        + destruct (equiv_dec None None) as [H' | H'];
            unfold equiv, complement in *; try contradiction; auto.
        + destruct (equiv_dec (Some a1) (Some a2)) as [H' | H'];
            unfold equiv, complement in *; try inversion H';
              try contradiction; auto.
      - destruct (equiv_dec mk mk) as [H' | H'];
          unfold equiv, complement in *; try contradiction; auto.
      - clear H. induction H0; auto.
        destruct x as [x1 v1]; destruct y as [x2 v2];
          inversion H; simpl in *.
        pose proof P4String.equiv_reflect x1 x2 as Hx.
        inversion Hx; subst; try contradiction.
        rewrite H2; auto.
      - clear H. induction H0; auto.
        destruct x as [x1 v1]; destruct y as [x2 v2];
          inversion H; simpl in *.
        pose proof P4String.equiv_reflect x1 x2 as Hx.
        inversion Hx; subst; try contradiction.
        rewrite H2; auto.
      - induction H; inv H0; auto.
        rewrite IHForall2 by auto; clear IHForall2.
        destruct x as [b1 vs1]; destruct y as [b2 vs2];
          simpl in *; destruct H as [Hb H]; subst.
        rewrite andb_true_r. rewrite eqb_reflx.
        clear l l' H1 H7 n ni b2.
        induction H; inv H5; auto.
        destruct x as [x1 v1]; destruct y as [x2 v2].
        invert_relf; simpl in *.
        pose proof P4String.equiv_reflect x1 x2 as Hx.
        inv Hx; try contradiction. rewrite H2.
        rewrite IHForall2 by auto; auto.
    Qed.

    Lemma eqbv_equivv : forall v1 v2 : v, eqbv v1 v2 = true -> equivv v1 v2.
    Proof.
      induction v1 using custom_value_ind; intros [] Heqbv; simpl in *;
        try discriminate.
      - apply eqb_prop in Heqbv; subst; constructor.
      - apply andb_prop in Heqbv as [Hw Hn];
          apply Peqb_true_eq in Hw; apply N.eqb_eq in Hn;
            subst; constructor.
      - apply andb_prop in Heqbv as [Hw Hn];
          apply Peqb_true_eq in Hw; apply Z.eqb_eq in Hn;
            subst; constructor.
      - constructor. generalize dependent fs0.
        induction fs as [| [x1 v1] vs1 IHvs1]; intros [| [x2 v2] vs2] IH;
          inversion IH; subst; inversion H; subst; clear IH H; simpl in *;
            constructor; auto; simpl in *;
              destruct (P4String.equivb x1 x2) eqn:Hx;
              destruct (eqbv v1 v2) eqn:Hv; simpl in *; try discriminate.
        + split; simpl; auto.
          pose proof P4String.equiv_reflect x1 x2 as H';
            inversion H'; subst; auto.
          rewrite Hx in H. discriminate.
        + apply IHvs1; auto.
      - apply andb_true_iff in Heqbv as [Hb Hfs].
        apply eqb_prop in Hb; subst. constructor.
        generalize dependent fs0.
        induction fs as [| [x1 v1] vs1 IHvs1]; intros [| [x2 v2] vs2] IH;
          inversion IH; subst; inversion H; subst; clear IH H; simpl in *;
            constructor; auto; simpl in *;
              destruct (P4String.equivb x1 x2) eqn:Hx;
              destruct (eqbv v1 v2) eqn:Hv; simpl in *; try discriminate.
        + split; simpl; auto.
          pose proof P4String.equiv_reflect x1 x2 as H';
            inversion H'; subst; auto.
          rewrite Hx in H. discriminate.
        + apply IHvs1; auto.
      - destruct (equiv_dec err err0) as [H | H];
          try discriminate; constructor; auto.
      - destruct (equiv_dec mk mk0) as [H | H];
          try discriminate; inversion H; constructor; auto.
      - apply andb_true_iff in Heqbv as [Hsizeni Hffs].
        apply andb_true_iff in Hsizeni as [Hsize Hni].
        apply Peqb_true_eq in Hsize; apply N.eqb_eq in Hni;
          symmetry in Hni; subst; constructor. clear size0 ni.
        rename hs into hs1; rename headers into hs2.
        generalize dependent hs2.
        induction hs1 as [| [b1 vs1] hs1 IHhs1];
          intros [| [b2 vs2] hs2] Heqbv; simpl in *; inv H;
            try discriminate; constructor;
              apply andb_true_iff in Heqbv as [Hfs Hffs];
              auto; simpl in *. unfold Basics.compose in H2.
        simpl in H2. rename H2 into H.
        apply andb_true_iff in Hfs as [Hb Hfs].
        apply eqb_prop in Hb; subst; split; auto.
        clear IHhs1 hs1 Hffs H3 b2. generalize dependent vs2.
        induction vs1 as [| [x1 v1] vs1 IHvs1]; intros [| [x2 v2] vs2] IH;
          inv IH; inv H; simpl in *;
            constructor; auto; simpl in *;
              destruct (P4String.equivb x1 x2) eqn:Hx;
              destruct (eqbv v1 v2) eqn:Hv; simpl in *; try discriminate.
        + split; simpl; auto.
          pose proof P4String.equiv_reflect x1 x2 as H';
            inversion H'; subst; auto.
          rewrite Hx in H. discriminate.
        + apply IHvs1; auto.
    Qed.

    Lemma equivv_eqbv_iff : forall v1 v2 : v, equivv v1 v2 <-> eqbv v1 v2 = true.
    Proof.
      intros v1 v2; split; [apply equivv_eqbv | apply eqbv_equivv].
    Qed.

    Lemma equivv_reflect : forall v1 v2, reflect (equivv v1 v2) (eqbv v1 v2).
    Proof.
      intros v1 v2.
      destruct (eqbv v1 v2) eqn:Heqbv; constructor.
      - apply eqbv_equivv; assumption.
      - intros H. apply equivv_eqbv in H.
        rewrite H in Heqbv. discriminate.
    Qed.

    Lemma equivv_dec : forall v1 v2 : v,
        equivv v1 v2 \/ ~ equivv v1 v2.
    Proof.
      intros v1 v2. pose proof equivv_reflect v1 v2 as H.
      inversion H; subst; auto.
    Qed.
  End ValueEquality.
End Values.

Arguments VBool {_}.
Arguments VInt {_}.
Arguments VBit {_}.
Arguments VRecord {_}.
Arguments VHeader {_}.
Arguments VError {_}.
Arguments VMatchKind {_}.
Arguments VHeaderStack {_}.
Arguments LVVar {_}.
Arguments LVMember {_}.
Arguments LVAccess {_}.

Module ValueNotations.
  Notation "'*{' val '}*'" := val (val custom p4value at level 99).
  Notation "( x )" := x (in custom p4value, x at level 99).
  Notation "x" := x (in custom p4value at level 0, x constr at level 0).
  Notation "'TRUE'" := (VBool true) (in custom p4value at level 0).
  Notation "'FALSE'" := (VBool false) (in custom p4value at level 0).
  Notation "'VBOOL' b" := (VBool b) (in custom p4value at level 0).
  Notation "w 'VW' n" := (VBit w n) (in custom p4value at level 0).
  Notation "w 'VS' n" := (VInt w n) (in custom p4value at level 0).
  Notation "'REC' { fs }" := (VRecord fs)
                               (in custom p4value at level 6,
                                   no associativity).
  Notation "'HDR' { fs } 'VALID' ':=' b" := (VHeader fs b)
                               (in custom p4value at level 6,
                                   no associativity).
  Notation "'ERROR' x" := (VError x) (in custom p4value at level 0).
  Notation "'MATCHKIND' mk"
    := (VMatchKind mk)
         (in custom p4value at level 0, mk custom p4matchkind).
  Notation "'STACK' vs [ n ] 'NEXT' ':=' ni"
           := (VHeaderStack vs n ni)
                (in custom p4value at level 0, no associativity).
End ValueNotations.

Module LValueNotations.
  Notation "'l{' lval '}l'" := lval (lval custom p4lvalue at level 99).
  Notation "( x )" := x (in custom p4lvalue, x at level 99).
  Notation "x" := x (in custom p4lvalue at level 0, x constr at level 0).
  Notation "'VAR' x" := (LVVar x) (in custom p4lvalue at level 0).
  Notation "lval 'DOT' x"
    := (LVMember lval x) (in custom p4lvalue at level 1,
                             lval custom p4lvalue).
  Notation "lval [ n ]"
           := (LVAccess lval n) (in custom p4lvalue at level 1,
                                   lval custom p4lvalue).
End LValueNotations.