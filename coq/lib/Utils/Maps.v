Require Import Coq.Lists.List.
Require Import Coq.Bool.Bool.
Require Import Poulet4.Utils.Util.EquivUtil.
(* TODO: maybe replace with setoid rewrite so this isn;t needed...?*)
Require Import Coq.Logic.FunctionalExtensionality.
Import ListNotations.

Module FuncAsMap.

  Section FuncAsMap.

    Context {key: Type}.
    Context {key_eqb: key -> key -> bool}.

    (* TODO: maybe [key_eqb] should be replaced with
       decidable equality, or all lemmas need
       assumptions that [key_eqb] agrees with equality. *)
    Axiom key_eqb_eq_iff : forall k₁ k₂,
        key_eqb k₁ k₂ = true <-> k₁ = k₂.

    Corollary key_eqb_neq_iff : forall k₁ k₂,
        key_eqb k₁ k₂ = false <-> k₁ <> k₂.
    Proof.
      intros k1 k2; split.
      - intros Hf H.
        rewrite <- key_eqb_eq_iff, Hf in H; discriminate.
      - intro H; destruct (key_eqb k1 k2) eqn:Hk1k2;
          try reflexivity.
        rewrite key_eqb_eq_iff in Hk1k2; contradiction.
    Qed.

    Corollary key_eqb_same : forall k, key_eqb k k = true.
    Proof.
      intro k; rewrite key_eqb_eq_iff; reflexivity.
    Qed.

    Context {value: Type}.

    Definition t := key -> option value.

    Definition empty: t := fun _ => None.
    Definition get: key -> t -> option value := fun k fmap => fmap k.
    Definition set: key -> value -> t -> t :=
      fun k v fmap x => if key_eqb x k then Some v else fmap x.
    Definition remove (ky : key) (fmap : t) : t :=
      fun k => if key_eqb k ky then None else fmap k.

    Lemma remove_sound : forall X fmap,
        get X (remove X fmap) = None.
    Proof.
      intros X fmap; cbv.
      rewrite key_eqb_same; reflexivity.
    Qed.

    Lemma remove_complete : forall X Y fmap,
        X <> Y -> get X (remove Y fmap) = get X fmap.
    Proof.
      intros X Y fmap HXY; cbv.
      rewrite <- key_eqb_neq_iff in HXY.
      rewrite HXY; reflexivity.
    Qed.

    Definition sets: list key -> list value -> t -> t :=
      fun kList vList fmap =>
        fold_left (fun fM kvPair => set (fst kvPair) (snd kvPair) fM)
                  (combine kList vList) fmap.

    Definition gets (kl: list key) (m: t): list (option value) :=
      map (fun k => get k m) kl.

    Definition removes (ks : list key) (m : t) : t :=
      List.fold_right remove m ks.

    Lemma get_set_same:
      forall k v m, (forall k, key_eqb k k = true) -> get k (set k v m) = Some v.
    Proof. intros. unfold set, get. now rewrite H. Qed.

    Lemma get_set_diff:
      forall k k' v m, (forall k k', k <> k' -> key_eqb k k' = false) ->
                       k <> k' -> get k (set k' v m) = get k m.
    Proof. intros. unfold set, get. specialize (H _ _ H0). now rewrite H. Qed.

    (** Property of all elements in a map. *)
    Definition forall_elem (P : value -> Prop) (m : t) : Prop :=
      forall k v, m k = Some v -> P v.
    
    (** [m1 ⊆ m2]. *)
    Definition submap (m1 m2 : t) : Prop :=
      forall k v, m1 k = Some v -> m2 k = Some v.

    Lemma submap_eq : forall m1 m2 k,
        submap m1 m2 -> submap m2 m1 -> m1 k = m2 k.
    Proof.
      unfold submap.
      intros m1 m2 k Hsub1 Hsub2.
      destruct (m1 k) as [v |] eqn:Hm1k.
      - symmetry; auto.
      - destruct (m2 k) as [v |] eqn:Hm2k; try reflexivity.
        apply Hsub2 in Hm2k.
        rewrite Hm1k in Hm2k; discriminate.
    Qed.

    Lemma submap_refl : forall m, submap m m.
    Proof.
      unfold submap; trivial.
    Qed.
  End FuncAsMap.

  Section FuncMapMap.
    Context {key: Type} {key_eqb: key -> key -> bool} {U V : Type}.

    Section Map.
      Variable f : U -> V.

      Definition map_map (e : @t key U) : @t key V :=
        fun k => match e k with
              | Some u => Some (f u)
              | None   => None
              end.

      Lemma get_map_map : forall k e,
          get k (map_map e) = option_map f (get k e).
      Proof.
        intros k e.
        unfold map_map, get.
        destruct (e k); reflexivity.
      Qed.
    End Map.
    
    Section Rel.
      Variable R : U -> V -> Prop.

      Definition related (eu : @t key U) (ev : @t key V) : Prop :=
        forall k : key,
          relop R (get k eu) (get k ev).
    End Rel.
  End FuncMapMap.
  
  Lemma map_map_map :
    forall {K U V W : Type} {key_eqb: K -> K -> bool}
      (f : U -> V) (g : V -> W) (e : @t K U),
      map_map g (map_map f e) = map_map (g ∘ f) e.
  Proof.
    intros K U V W key_eqb f g e.
    unfold map_map, "∘".
    extensionality k.
    destruct (e k); reflexivity.
  Qed.
End FuncAsMap.

Module IdentMap.

Section IdentMap.

Notation ident := String.string.
Context {A: Type}.

Definition t := @FuncAsMap.t ident A.
Definition empty : t := FuncAsMap.empty.
Definition get : ident -> t -> option A := FuncAsMap.get.
Definition set : ident -> A -> t -> t :=
  @FuncAsMap.set ident String.eqb A.
Definition remove : ident -> t -> t :=
  @FuncAsMap.remove ident String.eqb A.
Definition sets: list ident -> list A -> t -> t :=
  @FuncAsMap.sets ident String.eqb A.
Definition gets: list ident -> t -> list (option A) := FuncAsMap.gets.
Definition removes : list ident -> t -> t :=
  @FuncAsMap.removes ident String.eqb A.
End IdentMap.

End IdentMap.

Definition list_eqb {A} (eqb : A -> A -> bool) al bl :=
  ListUtil.list_eq eqb al bl.

Definition path_eqb :
  (list String.string) -> (list String.string) -> bool :=
  list_eqb String.eqb.

Lemma path_eqb_refl: forall k, path_eqb k k = true.
Proof.
  intros. unfold path_eqb. induction k; simpl; auto.
  rewrite IHk. rewrite String.eqb_refl. now simpl.
Qed.

Lemma path_eqb_eq: forall p1 p2, path_eqb p1 p2 = true <-> p1 = p2.
Proof.
  intros; split; intros. 2: subst; apply path_eqb_refl.
  revert p1 p2 H.
  induction p1, p2; intros; unfold path_eqb in H; simpl in H; auto; try (now inv H).
  rewrite andb_true_iff in H.
  destruct H. rewrite String.eqb_eq in H. subst a. f_equal.
  now apply IHp1.
Qed.

Lemma path_eqb_neq: forall k k', k <> k' <-> path_eqb k k' = false.
Proof.
  intros. split; intros.
  - destruct (path_eqb k k') eqn:?H; auto. rewrite path_eqb_eq in H0. now exfalso.
  - destruct (list_eq_dec String.string_dec k k'); auto.
    rewrite <- path_eqb_eq, H in e. inversion e.
Qed.

Module PathMap.

Section PathMap.

Notation ident := String.string.
Notation path := (list ident).
Context {A: Type}.

Definition t := @FuncAsMap.t path A.
Definition empty : t := FuncAsMap.empty.
Definition get : path -> t -> option A := FuncAsMap.get.
Definition set : path -> A -> t -> t :=
  @FuncAsMap.set path path_eqb A.
Definition remove : path -> t -> t :=
  @FuncAsMap.remove path path_eqb A.
Definition sets : list path -> list A -> t -> t :=
  @FuncAsMap.sets path path_eqb A.
Definition gets: list path -> t -> list (option A) := FuncAsMap.gets.
Definition removes : list path -> t -> t :=
  @FuncAsMap.removes path path_eqb A.

Lemma get_set_same: forall k v m, get k (set k v m) = Some v.
Proof. intros. apply FuncAsMap.get_set_same. apply path_eqb_refl. Qed.

Lemma get_set_diff:
  forall k k' v m, k <> k' -> get k (set k' v m) = get k m.
Proof. intros. apply FuncAsMap.get_set_diff; auto. apply path_eqb_neq. Qed.

End PathMap.

End PathMap.

Arguments IdentMap.t _: clear implicits.
Arguments PathMap.t _: clear implicits.
