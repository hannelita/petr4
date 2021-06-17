Require Import Coq.Lists.List.
Require Import Coq.Classes.EquivDec.
Require Import Coq.micromega.Lia.

Require Import Poulet4.P4automata.P4automaton.

Open Scope list_scope.

Definition chunked_relation
  (a1 a2: p4automaton)
:=
  list (
    configuration a1 ->
    configuration a2 ->
    Prop
  )
.

Inductive chunked_related_and
  {a1 a2: p4automaton}
  : chunked_relation a1 a2 ->
    configuration a1 ->
    configuration a2 ->
    Prop
:=
| ChunkedRelatedHead:
    forall c1 c2 (R: configuration a1 -> configuration a2 -> Prop) rel,
      R c1 c2 ->
      chunked_related_and rel c1 c2 ->
      chunked_related_and (R :: rel) c1 c2
| ChunkedRelatedNil:
    forall c1 c2,
      chunked_related_and nil c1 c2
.

Lemma chunked_related_and_correct
  {a1 a2: p4automaton}
  (R: chunked_relation a1 a2)
  (c1: configuration a1)
  (c2: configuration a2)
:
  chunked_related_and R c1 c2 <->
  forall R', In R' R -> R' c1 c2.
Proof.
  induction R.
  - split; intros.
    + simpl in *.
      tauto.
    + constructor.
  - split; intros.
    + simpl in *.
      destruct H0; subst.
      * inversion H; congruence.
      * eapply IHR.
        -- now inversion H.
        -- change (fun c0 c3 => R' c0 c3) with R'.
           auto.
    + constructor.
      * eapply H; simpl.
        tauto.
      * eapply IHR.
        intros.
        eapply H.
        right.
        eauto.
Qed.

Lemma chunked_related_and_subset
  {a1 a2: p4automaton}
  (R1 R2: chunked_relation a1 a2)
  (c1: configuration a1)
  (c2: configuration a2)
:
  incl R1 R2 ->
  chunked_related_and R2 c1 c2 ->
  chunked_related_and R1 c1 c2
.
Proof.
  intros.
  apply chunked_related_and_correct.
  intros.
  eapply chunked_related_and_correct in H0; eauto.
Qed.

Lemma chunked_related_and_app
  {a1 a2: p4automaton}
  (R1 R2: chunked_relation a1 a2)
  (c1: configuration a1)
  (c2: configuration a2)
:
  chunked_related_and R1 c1 c2 ->
  chunked_related_and R2 c1 c2 ->
  chunked_related_and (R1 ++ R2) c1 c2.
Proof.
  intros.
  eapply chunked_related_and_correct.
  intros.
  assert (In R' R1 -> R' c1 c2)
    by (eapply chunked_related_and_correct; eauto).
  assert (In R' R2 -> R' c1 c2)
    by (eapply chunked_related_and_correct; eauto).
  eapply in_app_or in H1.
  destruct H1;  eauto.
Qed.

Lemma chunked_related_and_app'
  {a1 a2: p4automaton}
  (R1 R2: chunked_relation a1 a2)
  (c1: configuration a1)
  (c2: configuration a2)
:
  chunked_related_and (R1 ++ R2) c1 c2 ->
  chunked_related_and R1 c1 c2 /\
  chunked_related_and R2 c1 c2.
Proof.
  intros.
  split;
    eapply chunked_related_and_correct;
    intros;
    eapply chunked_related_and_correct in H; 
      eauto using in_or_app.
Qed.

Ltac split_chunked :=
  match goal with
  | [ |- chunked_related_and (_ ++ _) _ _ ] => apply chunked_related_and_app
  | [ |- chunked_related_and (_ :: _) _ _ ] => apply ChunkedRelatedHead 
  | [ |- chunked_related_and nil _ _ ] => apply ChunkedRelatedNil
  end.

Ltac break_chunked :=
  match goal with
  | [ H: chunked_related_and (_ ++ _) _ _ |- _ ] => apply chunked_related_and_app' in H; destruct H as [? ?]
  | [ H: chunked_related_and (_ :: _) _ _ |- _ ] => inversion H; subst; clear H
  end.

Definition precedes
  {a1 a2: p4automaton}
  (r: chunked_relation a1 a2)
  (t: chunked_relation a1 a2)
:=
  forall c1 c2,
    chunked_related_and (r ++ t) c1 c2 ->
    forall b, chunked_related_and r (step c1 b) (step c2 b).

Definition acceptance_ok
  {a1 a2: p4automaton}
  (R: chunked_relation a1 a2)
:=
  forall c1 c2,
    chunked_related_and R c1 c2 ->
    accepting c1 <-> accepting c2
.

Definition pre_bisimulation
  {a1 a2: p4automaton}
  (r: chunked_relation a1 a2)
  (t: chunked_relation a1 a2) :=
  (forall c1 c2,
     bisimilar c1 c2 ->
     chunked_related_and (r ++ t) c1 c2) /\
  precedes r t.

Lemma pre_bisimulation_intro
  {a1 a2: p4automaton}
  (R: configuration a1 -> configuration a2 -> Prop)
:
  pre_bisimulation nil (R :: nil) ->
  (forall c1 c2, bisimilar c1 c2 -> R c1 c2).
Proof.
  intros.
  cut (chunked_related_and (R :: nil) c1 c2).
  { intro Hc. inversion Hc; subst; eauto. }
  eapply H.
  eauto.
Qed.

Ltac solve_incl :=
  match goal with
  | |- incl nil ?l =>
    exact (incl_nil_l l)
  | |- incl ?l ?l  =>
    apply incl_refl
  | |- incl _ (_ :: _)  =>
    apply incl_tl; solve_incl
  | |- In ?x (_ ++ ?x :: _) =>
    apply in_elt
  | |- incl (_ ++ _) _  =>
    apply incl_app; solve_incl
  | |- incl (_ :: _) _  =>
    apply incl_cons; solve_incl
  | |- incl ?l1 (?l2 ++ ?l3) =>
    match l2 with
    | context [ l1 ] =>
      apply incl_appl; solve_incl
    | _ =>
      match l3 with
      | context [ l1 ] =>
        apply incl_appr; solve_incl
      end
    end
  end
.

Definition rel_wp
  {a1 a2: p4automaton}
  (R: configuration a1 -> configuration a2 -> Prop)
  (c1: configuration a1)
  (c2: configuration a2)
  : Prop :=
  forall b c1' c2',
    step c1 b = c1' ->
    step c2 b = c2' ->
    R c1' c2'.

Lemma pre_bisimulation_grow
  {a1 a2: p4automaton}
  (checked: chunked_relation a1 a2)
  (front: chunked_relation a1 a2)
  (phi: configuration a1 -> configuration a2 -> Prop)
:
  pre_bisimulation checked (phi :: front) ->
  pre_bisimulation (phi :: checked) (rel_wp phi :: front).
Proof.
  split.
  - intros.
    cut (chunked_related_and (rel_wp phi :: nil) c1 c2 /\
         chunked_related_and (checked ++ phi :: front) c1 c2).
    {
      intros.
      intuition.
      repeat break_chunked.
      repeat split_chunked; assumption.
    }
    split.
    + repeat constructor.
      unfold rel_wp; intros; subst.
      assert (bisimilar (step c1 b) (step c2 b)).
      {
        unfold bisimilar in *.
        destruct H0 as [RR [? ?]].
        exists RR; intuition.
        now eapply H0.
      }
      eapply H in H1.
      cut (chunked_related_and (phi :: nil) (step c1 b) (step c2 b)).
      { intros Hc. inversion Hc. eauto. }
      eapply chunked_related_and_subset; eauto.
      repeat solve_incl.
    + eapply H.
      auto.
  - unfold precedes.
    intros.
    repeat break_chunked.
    repeat split_chunked.
    + eapply H4; eauto.
    + destruct H.
      eapply H0.
      repeat split_chunked; eauto.
Qed.
