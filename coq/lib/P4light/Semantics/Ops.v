From Coq Require Import Strings.String Bool.Bool
     ZArith.BinInt ZArith.ZArith Lists.List
     micromega.Lia.
Require Import
        VST.zlist.Zlist
        Poulet4.P4light.Syntax.Value
        Poulet4.P4light.Syntax.Syntax.
From Poulet4.P4light.Syntax Require Import
     Typed P4String SyntaxUtil.
From Poulet4.Utils Require Import AList AListUtil CoqLib P4Arith.
Import ListNotations.

Section BitStringSlice.
  Context {A : Type}.

  Fixpoint bitstring_slice' (bits: list A) (lo : nat) (hi : nat) (slice: list A) : list A :=
    match bits, lo, hi with
    | _ ::tl, S lo', S hi' => bitstring_slice' tl lo' hi' slice
    | hd::tl, O, S hi' => bitstring_slice' tl O hi' (hd::slice)
    | hd::tl, O, O => hd::slice
    | _, _, _ => slice
    end.

  Definition bitstring_slice (bits: list A) (lo : nat) (hi : nat) : list A :=
    bitstring_slice' (List.rev bits) lo hi [].

  Lemma bitstring_slice'_length : forall bits slice hi lo,
        (lo <= hi < length bits)%nat ->
        length (bitstring_slice' bits lo hi slice)
        = (hi - lo + 1 + length slice)%nat.
  Proof.
    intro bits; induction bits as [| bit bits IHbits];
      intros slice [| hi] [| lo] H; cbn in *; try lia.
    - rewrite IHbits by lia; cbn; lia.
    - rewrite IHbits by lia; reflexivity.
  Qed.

  Lemma bitstring_slice_length : forall bits hi lo,
      (lo <= hi < length bits)%nat ->
      length (bitstring_slice bits lo hi)
      = (hi - lo + 1)%nat.
  Proof.
    intros bits hi lo H.
    unfold bitstring_slice.
    rewrite bitstring_slice'_length by (rewrite rev_length; lia).
    cbn; lia.
  Qed.

  Lemma Forall2_bitstring_slice': forall l1 l2 s1 s2 R lo hi,
      Forall2 R l1 l2 -> Forall2 R s1 s2 ->
      Forall2 R (bitstring_slice' l1 lo hi s1) (bitstring_slice' l2 lo hi s2).
  Proof.
    intros. revert s1 s2 lo hi H0. induction H; intros; simpl; auto. destruct lo, hi; auto.
  Qed.

  Lemma Forall2_bitstring_slice: forall l1 l2 R lo hi,
      Forall2 R l1 l2 -> Forall2 R (bitstring_slice l1 lo hi) (bitstring_slice l2 lo hi).
  Proof.
    intros. unfold bitstring_slice.
    apply Forall2_bitstring_slice'; auto.
    apply Forall2_rev; auto.
  Qed.

  Fixpoint update_bitstring (bits : list A) (lo : nat) (hi : nat)
    (nbits : list A) : list A :=
    match bits, lo, hi, nbits with
    | hd::tl, S lo', S hi', _ => hd :: (update_bitstring tl lo' hi' nbits)
    | _::tl, O, S hi', nhd::ntl => nhd :: (update_bitstring tl lo hi' ntl)
    | _::tl, O, O, [nhd] => nhd :: tl
    | _, _, _, _ => bits
    end.
End BitStringSlice.

Coercion pos_of_N: N >-> positive.

Section Ops.
  Context {tags_t: Type} {inhabitant_tags_t : Inhabitant tags_t}.
  Definition dummy_tags := @default tags_t _.

  Notation Val := (@ValueBase bool).
  Notation ValSet := ValueSet.
  Definition Fields (A : Type):= AList.StringAList A.

  Definition eval_unary_op (op : OpUni) (v : Val) : option Val :=
    match op, v with
    | Not, ValBaseBool b => Some (ValBaseBool (negb b))
    | BitNot, ValBaseBit bits =>
        let (w, n) := BitArith.from_lbool bits
        in Some (ValBaseBit (to_lbool w (BitArith.bit_not w n)))
    | BitNot, ValBaseInt bits =>
        let (w, n) := BitArith.from_lbool bits
        in Some (ValBaseInt (to_lbool w (IntArith.bit_not w n)))
    | UMinus, ValBaseBit bits =>
        let (w, n) := BitArith.from_lbool bits
        in Some (ValBaseBit (to_lbool w (BitArith.neg w n)))
    | UMinus, ValBaseInt bits =>
        let (w, n) := BitArith.from_lbool bits
        in Some (ValBaseInt (to_lbool w (IntArith.neg w n)))
    | UMinus, ValBaseInteger n => Some (ValBaseInteger (- n))
    | _, _ => None
    end.


  Definition eval_binary_op_bit (op: OpBin) (w: N) (n1 n2 : Z) : option Val :=
    match op with
    | Plus      => Some (ValBaseBit (to_lbool w (BitArith.plus_mod w n1 n2)))
    | PlusSat   => Some (ValBaseBit (to_lbool w (BitArith.plus_sat w n1 n2)))
    | Minus     => Some (ValBaseBit (to_lbool w (BitArith.minus_mod w n1 n2)))
    | MinusSat  => Some (ValBaseBit (to_lbool w (BitArith.minus_sat w n1 n2)))
    | Mul       => Some (ValBaseBit (to_lbool w (BitArith.mult_mod w n1 n2)))
    | Le        => Some (ValBaseBool (n1 <=? n2))
    | Ge        => Some (ValBaseBool (n1 >=? n2))
    | Lt        => Some (ValBaseBool (n1 <? n2))
    | Gt        => Some (ValBaseBool (n1 >? n2))
    | BitAnd    => Some (ValBaseBit (to_lbool w (BitArith.bit_and w n1 n2)))
    | BitXor    => Some (ValBaseBit (to_lbool w (BitArith.bit_xor w n1 n2)))
    | BitOr     => Some (ValBaseBit (to_lbool w (BitArith.bit_or  w n1 n2)))
    (* Div and Mod are not allowed for bit<w> according to the P4 Spec. Also,
      dividing by a runtime value may cause runtime error. *)
    (* | Div       => if n2 =? 0 then None
                  else Some (ValBaseBit (to_lbool w (BitArith.div_mod w n1 n2)))
    | Mod       => if n2 =? 0 then None
                  else Some (ValBaseBit (to_lbool w (BitArith.modulo_mod w n1 n2))) *)
    (* implemented elsewhere *)
    | Shl | Shr | PlusPlus | Eq | NotEq
    (* not allowed *)
    | _      => None
    end.


  Definition eval_binary_op_int (op: OpBin) (w: N) (n1 n2 : Z) : option Val :=
    match op with
    | Plus      => Some (ValBaseInt (to_lbool w (IntArith.plus_mod w n1 n2)))
    | PlusSat   => Some (ValBaseInt (to_lbool w (IntArith.plus_sat w n1 n2)))
    | Minus     => Some (ValBaseInt (to_lbool w (IntArith.minus_mod w n1 n2)))
    | MinusSat  => Some (ValBaseInt (to_lbool w (IntArith.minus_sat w n1 n2)))
    | Mul       => Some (ValBaseInt (to_lbool w (IntArith.mult_mod w n1 n2)))
    | Le        => Some (ValBaseBool (n1 <=? n2))
    | Ge        => Some (ValBaseBool (n1 >=? n2))
    | Lt        => Some (ValBaseBool (n1 <? n2))
    | Gt        => Some (ValBaseBool (n1 >? n2))
    | BitAnd    => Some (ValBaseInt (to_lbool w (IntArith.bit_and w n1 n2)))
    | BitXor    => Some (ValBaseInt (to_lbool w (IntArith.bit_xor w n1 n2)))
    | BitOr     => Some (ValBaseInt (to_lbool w (IntArith.bit_or  w n1 n2)))
    (* implemented elsewhere *)
    | Shl | Shr | PlusPlus | Eq | NotEq
    (* not allowed *)
    | Div
    | Mod
    | And
    | Or        => None
    end.


  Definition eval_binary_op_integer (op: OpBin) (n1 n2 : Z) : option Val :=
    match op with
    | Plus      => Some (ValBaseInteger (n1 + n2))
    | Minus     => Some (ValBaseInteger (n1 - n2))
    | Mul       => Some (ValBaseInteger (n1 * n2))
    | Div       => if (n1 <? 0) || (n2 <=? 0) then None
                  else Some (ValBaseInteger (n1 / n2))
    | Mod       => if (n1 <? 0) || (n2 <=? 0) then None
                  else Some (ValBaseInteger (n1 mod n2))
    | Le        => Some (ValBaseBool (n1 <=? n2))
    | Ge        => Some (ValBaseBool (n1 >=? n2))
    | Lt        => Some (ValBaseBool (n1 <? n2))
    | Gt        => Some (ValBaseBool (n1 >? n2))
    (* implemented elsewhere *)
    | Shl | Shr | Eq | NotEq
    (* not allowed *)
    | PlusPlus
    | PlusSat
    | MinusSat
    | BitAnd
    | BitXor
    | BitOr
    | And
    | Or        => None
    end.

  Definition eval_binary_op_bool (op: OpBin) (b1 b2: bool) : option Val :=
  match op with
  | And         => Some (ValBaseBool (andb b1 b2))
  | Or          => Some (ValBaseBool (orb b1 b2))
  | Eq | NotEq
  | _ => None
  end.

  Definition eval_binary_op_plusplus (v1 : Val) (v2 : Val) : option Val :=
    match v1, v2 with
    | ValBaseBit bits1, ValBaseBit bits2
    | ValBaseBit bits1, ValBaseInt bits2 =>
        Some (ValBaseBit (bits1 ++ bits2))
        (* ATTN: big-endian! *)
        (* let (w1, n1) := BitArith.from_lbool bits1 in
        let (w2, n2) := different_cases.from_lbool bits2 in
        Some (ValBaseBit (to_lbool (w1 + w2) (BitArith.concat w1 w2 n1 n2))) *)
    | ValBaseInt bits1, ValBaseInt bits2
    | ValBaseInt bits1, ValBaseBit bits2 =>
        Some (ValBaseInt (bits1 ++ bits2))
        (* ATTN: big-endian! *)
        (* let (w1, n1) := IntArith.from_lbool bits1 in
        let (w2, n2) := different_cases.from_lbool bits2 in
        Some (ValBaseInt (to_lbool (w1 + w2) (IntArith.concat w1 w2 n1 n2))) *)
    | _, _ => None
    end.

  Definition eval_binary_op_shift (op: OpBin) (v1 : Val) (v2 : Val) : option Val :=
    let arith_op :=
      match op, v1 with
      | Shl, ValBaseBit bits =>
          let (w, n) := BitArith.from_lbool bits
          in (fun num_bits => Some (ValBaseBit (to_lbool w (BitArith.shift_left w n num_bits))))
      | Shr, ValBaseBit bits =>
          let (w, n) := BitArith.from_lbool bits
          in (fun num_bits => Some (ValBaseBit (to_lbool w (BitArith.shift_right w n num_bits))))
      | Shl, ValBaseInt bits =>
          let (w, n) := IntArith.from_lbool bits
          in (fun num_bits => Some (ValBaseInt (to_lbool w (IntArith.shift_left w n num_bits))))
      | Shr, ValBaseInt bits =>
          let (w, n) := IntArith.from_lbool bits
          in (fun num_bits => Some (ValBaseInt (to_lbool w (IntArith.shift_right w n num_bits))))
      | Shl, ValBaseInteger n =>
          (fun num_bits => Some (ValBaseInteger (Z.shiftl n num_bits)))
      | Shr, ValBaseInteger n =>
          (fun num_bits => Some (ValBaseInteger (Z.shiftr n num_bits)))
      | _, _ => (fun num_bits => None)
      end in
    match v2 with
    | ValBaseBit bits => arith_op (snd (BitArith.from_lbool bits))
    | ValBaseInteger n2 =>
      if 0 <=? n2 then arith_op n2 else None
    | _ => None
    end.

  Fixpoint eval_binary_op_eq (v1 : Val) (v2 : Val) : option bool :=
    let fix eval_binary_op_eq_struct' (l1 l2 : Fields Val) : option bool :=
      match l1, l2 with
      | nil, nil => Some true
      | (k1, v1) :: l1', (k2, v2) :: l2' =>
        if negb (String.eqb k1 k2) then None
        else match eval_binary_op_eq v1 v2, eval_binary_op_eq_struct' l1' l2' with
             | Some b1, Some b2 => Some (b1 && b2)
             | _, _ => None
        end
      | _, _ => None
      end in
    let eval_binary_op_eq_struct (l1 l2 : Fields Val) : option bool :=
      if negb ((AList.key_unique l1) && (AList.key_unique l2)) then None
      else eval_binary_op_eq_struct' l1 l2 in
    let fix eval_binary_op_eq_tuple (l1 l2 : list Val): option bool :=
      match l1, l2 with
      | nil, nil => Some true
      | x1 :: l1', x2 :: l2' =>
        match eval_binary_op_eq x1 x2, eval_binary_op_eq_tuple l1' l2' with
        | Some b1, Some b2 => Some (b1 && b2)
        | _, _ => None
        end
      | _, _ => None
      end in
    match v1, v2 with
    | ValBaseError s1, ValBaseError s2 =>
        Some (String.eqb s1 s2)
    | ValBaseEnumField t1 s1, ValBaseEnumField t2 s2 =>
        if String.eqb t1 t2 then Some (String.eqb s1 s2)
        else None
    | ValBaseSenumField t1 v1, ValBaseSenumField t2 v2 =>
        if String.eqb t1 t2 then eval_binary_op_eq v1 v2
        else None
    | ValBaseBool b1, ValBaseBool b2 =>
        Some (eqb b1 b2)
    | ValBaseBit bits1, ValBaseBit bits2 =>
        let (w1, n1) := BitArith.from_lbool bits1 in
        let (w2, n2) := BitArith.from_lbool bits2 in
        if (w1 =? w2)%N then Some (n1 =? n2)
        else None
    | ValBaseInt bits1, ValBaseInt bits2 =>
        let (w1, n1) := IntArith.from_lbool bits1 in
        let (w2, n2) := IntArith.from_lbool bits2 in
        if (w1 =? w2)%N then Some (n1 =? n2)
        else None
    | ValBaseInteger n1, ValBaseInteger n2 =>
        Some (n1 =? n2)
    | ValBaseVarbit m1 bits1, ValBaseVarbit m2 bits2 =>
        let (w1, n1) := BitArith.from_lbool bits1 in
        let (w2, n2) := BitArith.from_lbool bits2 in
        if (m1 =? m2)%N then Some ((w1 =? w2)%N && (n1 =? n2))
        else None
    | ValBaseStruct l1, ValBaseStruct l2 =>
        eval_binary_op_eq_struct l1 l2
    | ValBaseUnion l1, ValBaseUnion l2 =>
        eval_binary_op_eq_struct l1 l2
    | ValBaseHeader l1 b1, ValBaseHeader l2 b2 =>
        match eval_binary_op_eq_struct l1 l2 with (* implicit type check *)
        | None => None
        | Some b3 => Some (eqb b1 b2 && b3)
        end
    | ValBaseStack vs1 n1, ValBaseStack vs2 n2 =>
        if negb (Zlength vs1 =? Zlength vs2)%Z then None
        else match eval_binary_op_eq_tuple vs1 vs2 with
             | None => None
             | Some b => Some (N.eqb n1 n2 && b)
             end
    | ValBaseTuple vs1, ValBaseTuple vs2 =>
        eval_binary_op_eq_tuple vs1 vs2
    | _, _ => None
    end.

  Lemma eval_binary_op_eq_eq: forall v1 v2,
      eval_binary_op_eq v1 v2 = Some true -> v1 = v2.
  Proof.
    induction v1 using custom_ValueBase_ind;
      intros []; intros; simpl in *; try discriminate;
    repeat match goal with
      | H: Some _ = Some _ |- _ => inversion H; clear H
      | H: eqb _ _ = true |- _ => apply eqb_prop in H; subst
      | H: Z.eqb _ _ = true |- _ => rewrite Z.eqb_eq in H; subst
      | H: N.eqb _ _ = true |- _ => rewrite N.eqb_eq in H
      | H: String.eqb _ _ = true |- _ => rewrite String.eqb_eq in H; subst
      | H: andb _ _ = true |- _ => rewrite Bool.andb_true_iff in H; destruct H
      | H: match ?P with _ => _ end = _ |- _ => destruct P eqn:?H
      | _: None = Some _ |- _ => discriminate
      | H : Z.to_N (Zlength _) = Z.to_N (Zlength _) |- _ =>
          rewrite Z2N.inj_iff in H; [|apply Zlength_nonneg..]
      | H1 : Zlength ?l1 = Zlength ?l2,
          H2 : BitArith.lbool_to_val ?l1 1 0 = BitArith.lbool_to_val ?l2 1 0 |- _ =>
          apply BitArith.lbool_to_val_eq in H2; [subst | assumption]
      | H1 : Zlength ?l1 = Zlength ?l2,
          H2 : IntArith.lbool_to_val ?l1 1 0 = IntArith.lbool_to_val ?l2 1 0 |- _ =>
          apply IntArith.lbool_to_val_eq in H2; [subst | assumption]
      | IH: Forall _ ?ts1, H: _ ?ts1 ?ts2 = Some true
        |- _ ?ts1 = _ ?ts2 =>
          generalize dependent ts2; induction ts1; intros []; intros;
          try discriminate
      | IH: Forall _ ?ts1, H: _ ?ts1 ?ts2 = Some true
        |- _ ?ts1 _ = _ ?ts2 _ =>
          generalize dependent ts2; induction ts1; intros []; intros;
          try discriminate
      | H: Forall _ (_ :: _) |- _ => rewrite Forall_cons_iff in H; destruct H
      | H1: Forall ?P ?v, H2: Forall ?P ?v -> _ |- _ => specialize (H2 H1)
      | H1: _ = Some ?v, H2: ?v = true |- _ => subst v
      | [H1 : forall v2 : Val, eval_binary_op_eq ?v v2 = Some true -> ?v = v2,
           H2: eval_binary_op_eq ?v _ = Some true |- _ ] => apply H1 in H2; subst
      | H: negb _ = false |- _ => rewrite negb_false_iff in H
      | H: key_unique (_ :: _) = true |- _ => apply key_unique_cons in H
      end; try (subst; reflexivity).
    2-4: apply IHvs in H6; [inversion H6 | rewrite H0, H1]; reflexivity.
    - apply IHvs in H2. inversion H2. reflexivity.
    - apply IHvs in H4.
      + inversion H4. reflexivity.
      + rewrite negb_false_iff, Z.eqb_eq. list_solve.
  Qed.

  Lemma eval_binary_op_neq_neq: forall v1 v2,
      eval_binary_op_eq v1 v2 = Some false -> v1 <> v2.
  Proof.
    repeat intro. subst. revert v2 H. intro v.
    induction v using custom_ValueBase_ind; simpl; intros; try discriminate;
    repeat match goal with
      | H: Some _ = Some _ |- _ => inversion H; clear H
      | H: eqb _ _ = false |- _ => rewrite eqb_false_iff in H
      | H: ?b <> ?b |- False => apply H; reflexivity
      | H: Z.eqb _ _ = false |- _ => rewrite Z.eqb_neq in H
      | H: match ?P with _ => _ end = _ |- _ => destruct P eqn:?H
      | H: None = Some _ |- _ => discriminate
      | H: andb _ _ = false |- _ => rewrite Bool.andb_false_iff in H; destruct H
      | H: N.eqb _ _ = false |- _ => rewrite N.eqb_neq in H
      | IH: Forall _ ?ts1, H: _ ?ts1 ?ts2 = Some false |- _  => induction ts1
      | H1: _ = Some ?v, H2: ?v = false |- _ => subst v
      | H: String.eqb _ _ = false |- _ => rewrite String.eqb_neq in H
      | H: negb _ = false |- _ => rewrite negb_false_iff in H
      | H: key_unique (_ :: _) = true |- _ => apply key_unique_cons in H
      | H: andb _ _ = true |- _ => rewrite Bool.andb_true_iff in H; destruct H
      | H1: Forall (fun v : Val => ?f v v = Some false -> False) (?a :: _),
          H2: ?f ?a ?a = Some false |- False =>
          rewrite Forall_cons_iff in H1; destruct H1 as [H1 _];
          apply H1 in H2; assumption
      | H1: Forall (fun v : Val => ?f v v = Some false -> False) (_ :: ?vs),
          H2: Forall (fun v : Val => ?f v v = Some false -> False) ?vs ->
                Some false = Some false -> False |- False =>
          rewrite Forall_cons_iff in H1; destruct H1 as [_ H1];
          apply H2 in H1; [assumption | reflexivity]
      | H1: Forall (fun '(_, v) => ?f v v = Some false -> False) ((_, ?x) :: _),
          H2 : ?f ?x ?x = Some false |- False =>
          rewrite Forall_cons_iff in H1; destruct H1 as [H1 _];
          apply H1 in H2; assumption
      | H1: Forall (fun '(_, v) => ?f v v = Some false -> False) (_ :: ?vs),
          H2: key_unique ?vs = true,
            H3 : Forall (fun '(_, v) => ?f v v = Some false -> False) ?vs ->
                   (negb (key_unique ?vs && key_unique ?vs) = false) ->
                   Some false = Some false -> False |- False =>
          rewrite Forall_cons_iff in H1; destruct H1 as [_ H1];
          apply H3 in H1; [assumption | rewrite H2 |]; reflexivity
      | H1 : ?P -> False, H2 : ?P |- False => apply H1 in H2; assumption
      | H: Z.eqb _ _ = true |- _ => rewrite Z.eqb_eq in H
      end.
    rewrite Forall_cons_iff in H. destruct H as [_ H].
    apply IHvs in H; auto. rewrite negb_false_iff, Z.eqb_eq. list_solve.
 Qed.

  (* Definition eval_binary_op_eq (v1 : Val) (v2 : Val) : option bool :=
    eval_binary_op_eq' (sort_by_key_val v1) (sort_by_key_val v2). *)

  (* 1. After implicit_cast in checker.ml, ValBaseInteger no longer exists in
        binary operations with fixed-width bit and int.
     2. Types are checked to return None when binary operations are not allowed. *)
  Definition eval_binary_op (op: OpBin) (v1 : Val) (v2 : Val) : option Val :=
    match op, v1, v2 with
    | PlusPlus, _, _ =>
        eval_binary_op_plusplus v1 v2
    | Shl, _, _ | Shr, _, _ =>
        eval_binary_op_shift op v1 v2
    | Eq, _, _ =>
        match eval_binary_op_eq v1 v2 with
        | Some b => Some (ValBaseBool b)
        | None => None
        end
    | NotEq, _, _ =>
        match eval_binary_op_eq v1 v2 with
        | Some b => Some (ValBaseBool (negb b))
        | None => None
        end
    | _, ValBaseBit bits1, ValBaseBit bits2 =>
        let (w1, n1) := BitArith.from_lbool bits1 in
        let (w2, n2) := BitArith.from_lbool bits2 in
        if (w1 =? w2)%N then eval_binary_op_bit op w1 n1 n2
        else None
    | _, ValBaseInt bits1, ValBaseInt bits2 =>
        let (w1, n1) := IntArith.from_lbool bits1 in
        let (w2, n2) := IntArith.from_lbool bits2 in
        if (w1 =? w2)%N then eval_binary_op_int op w1 n1 n2
        else None
    | _, ValBaseInteger n1, ValBaseInteger n2 =>
        eval_binary_op_integer op n1 n2
    | _, ValBaseBool b1, ValBaseBool b2 =>
        eval_binary_op_bool op b1 b2
    | _, _, _ => None
    end.

  Definition bool_of_val (oldv : Val) : option Val :=
    match oldv with
    | ValBaseBool b => Some (ValBaseBool b)
    | ValBaseBit [true] => Some (ValBaseBool true)
    | ValBaseBit [false] => Some (ValBaseBool false)
    | _ => None
    end.

  Definition bit_of_val (w : N) (oldv : Val) : option Val :=
  match oldv with
  | ValBaseBool b =>
    if (w =? 1)%N then Some (ValBaseBit [b])
    else None
  | ValBaseInt bits =>
      let (w', n) := IntArith.from_lbool bits in
      if (w =? w')%N then Some (ValBaseBit (to_lbool w (BitArith.mod_bound w n)))
      else None
  | ValBaseBit bits =>
      let (w', n) := BitArith.from_lbool bits
      in Some (ValBaseBit (to_lbool w (BitArith.mod_bound w n)))
  | ValBaseInteger n =>
      Some (ValBaseBit (to_lbool w (BitArith.mod_bound w n)))
  | ValBaseSenumField _ v =>
      match v with
      | ValBaseBit bits =>
          if (Z.to_N (Zlength bits) =? w)%N then Some v else None
      | _ => None
      end
  | _ => None
  end.

  Definition int_of_val (w : N) (oldv : Val) : option Val :=
  match oldv with
  | ValBaseBit bits =>
      let (w', n) := BitArith.from_lbool bits in
      if (w' =? w)%N then Some (ValBaseInt (to_lbool w (IntArith.mod_bound w n)))
      else None
  | ValBaseInt bits =>
      let (w', n) := IntArith.from_lbool bits
      in Some (ValBaseInt (to_lbool w (IntArith.mod_bound w n)))
  | ValBaseInteger n =>
      Some (ValBaseInt (to_lbool w (IntArith.mod_bound w n)))
  | ValBaseSenumField _ v =>
      match v with
      | ValBaseInt bits =>
          if (Z.to_N (Zlength bits) =? w)%N then Some v else None
      | _ => None
      end
  | _ => None
  end.

  (* 1. An empty field name is inserted here since the P4 manual does not specify how
        casting to a senum assigns the field name, and multiple fields can share the same name.
        Also, the unnamed value is legal in senum, so an empty name is acceptable.
        Lastly, the senum field name is literally unused in all semantics involving senum.
     2. Currently, casting a senum to another senum explicitly is implemented here directly.
        However, according to the manual 8.3, what should more likely happen is a implicit cast
        from senum to its underlying type and then a explicit cast from the underlying type to
        the final senum type. However, since the implicit cast of senum is incorrect in the
        typechecker, the direct cast between senums are also implemented. *)
  Definition enum_of_val  (name: string) (typ: option (@P4Type tags_t))
                          (members: list (P4String.t tags_t)) (oldv : Val) : option Val :=
  match typ, oldv with
  | None, _ => None
  | Some (TypBit w), ValBaseBit bits
  | Some (TypBit w), ValBaseSenumField _ (ValBaseBit bits) =>
      if (w =? Z.to_N (Zlength bits))%N
      then Some (ValBaseSenumField name (ValBaseBit bits))
      else None
  | Some (TypInt w), ValBaseInt bits
  | Some (TypInt w), ValBaseSenumField _ (ValBaseInt bits) =>
      if (Z.to_N (Zlength bits) =? w)%N
      then Some (ValBaseSenumField name (ValBaseInt bits))
      else None
  | _, _ => None
  end.

  Fixpoint eval_cast (newtyp : @P4Type tags_t) (oldv : Val) : option Val :=
    let fix values_of_val_tuple (l1: list P4Type)
                                (l2: list Val) : option (list Val) :=
      match l1, l2 with
      | [], [] => Some []
      | t :: l1', oldv :: l2' =>
          match eval_cast t oldv, values_of_val_tuple l1' l2' with
          | Some newv, Some l3 => Some (newv :: l3)
          | _, _ => None
          end
      | _, _ => None
      end in
    let values_of_val (l1: list P4Type) (oldv: Val) : option (list Val) :=
      match oldv with
      | ValBaseTuple l2 => values_of_val_tuple l1 l2
      | _ => None
      end in
    let fix fields_of_val_tuple (l1: P4String.AList tags_t P4Type)
                                (l2: list Val) : option (Fields Val) :=
      match l1, l2 with
      | [], [] => Some []
      | (k, t) :: l1', oldv :: l2' =>
          match eval_cast t oldv, fields_of_val_tuple l1' l2' with
          | Some newv, Some l3 => Some ((str k, newv) :: l3)
          | _, _ => None
          end
      | _, _ => None
      end in
    let fix fields_of_val_record (l1: P4String.AList tags_t P4Type)
                                 (l2: Fields Val) : option (Fields Val) :=
      match l1 with
      | [] => Some []
      | (k, t) :: l1' =>
          match AList.get l2 (str k) with
          | None => None
          | Some oldv =>
              match eval_cast t oldv,
                fields_of_val_record l1'
                  (AListUtil.remove_first (str k) l2) with
              | Some newv, Some l3 => Some ((str k, newv) :: l3)
              | _, _ => None
              end
          end
      end in
    let fields_of_val (l1: P4String.AList tags_t P4Type) (oldv: Val) : option (Fields Val) :=
      match oldv with
      | ValBaseTuple l2 => if negb (AList.key_unique l1) then None
                          else fields_of_val_tuple l1 l2
      | ValBaseHeader l2 _
      | ValBaseStruct l2 => if negb ((AList.key_unique l1) && (AList.key_unique l2)) then None
                            else if negb ((List.length l1) =? (List.length l2))%nat then None
                            else fields_of_val_record l1 l2
      | _ => None
      end in
    match newtyp with
    | TypBool => bool_of_val oldv
    | TypBit w => bit_of_val w oldv
    | TypInt w => int_of_val w oldv
    | TypNewType _ typ => eval_cast typ oldv
    (* Two problems with TypTypName:
       1. Need to resolve the type from the name in the Semantics.v;
       2. Need to define name_to_type such that no loop is possible.
       eval_cast name_to_typ (name_to_typ name) oldv *)
    | TypTypeName name => None
    | TypEnum n typ mems => enum_of_val (str n) typ mems oldv
    | TypStruct fields =>
        match fields_of_val fields oldv with
        | Some fields' => Some (ValBaseStruct fields')
        | _ => None
        end
    (* header -> header cast is not clearly allowed in the manual *)
    (* Similar to a struct, a header object can be initialized with a list expression 8.11
        — the list fields are assigned to the header fields in the order they appear —
        or with a structure initializer expression 8.14. When initialized the header
        automatically becomes valid: *)
    | TypHeader fields =>
        match fields_of_val fields oldv with
        | Some fields' => Some (ValBaseHeader fields' true)
        | _ => None
        end
    | TypTuple types =>
        match values_of_val types oldv with
        | Some values => Some (ValBaseTuple values)
        | _ => None
        end
    | _ => None
    end.

  Definition eval_cast_set (newtyp : @P4Type tags_t) (oldv : Val) : option ValSet :=
    match newtyp with
    | TypSet eletyp =>
        (* Not necessary since the internal cast should be added into the oldv by the typechecker *)
        match eval_cast eletyp oldv with
        | Some newv => Some (ValSetSingleton newv)
        | _ => None
        end
    | _ => None
    end.

  (* Fixpoint sort_by_key_typ (t: P4Type) : P4Type :=
    let fix sort_by_key_typ' (ll : Fields P4Type) : Fields P4Type :=
      match ll with
      | nil => nil
      | (k, t) :: l' => (k, sort_by_key_typ t) :: sort_by_key_typ' l'
      end in
    match t with
    | TypStruct l => TypStruct (sort (sort_by_key_typ' l))
    | TypRecord l => TypRecord (sort (sort_by_key_typ' l))
    | TypHeaderUnion l => TypHeaderUnion (sort (sort_by_key_typ' l))
    | TypHeader l => TypHeader (sort (sort_by_key_typ' l))
    | TypSet eletyp => sort_by_key_typ eletyp
    | _ => t
    end.

  Definition eval_cast (newtyp : P4Type) (oldv : Val) : option Val :=
    eval_cast' (sort_by_key_typ newtyp) (sort_by_key_val oldv). *)

End Ops.
