Require Import Syntax.
Require Import Eval.
Require Import Typed.
Require Import Strings.String.
Require String.
Require Import Coq.ZArith.BinIntDef.
Require Import Monads.State.

Require Import Step.

Open Scope list_scope.
Open Scope string_scope.

Definition tag_t := unit.
Definition tag := tt.
Definition constTyp : P4Type := TypInteger.
Definition name : P4String tag_t := MkP4String tag_t tag "hello_world".
Definition value : ValueBase tag_t := ValBaseInteger tag_t 42.

Definition parses (p: ValueObject tag_t) (fuel: nat) (start_state: String.t) (start_env: Environment.environment tag_t): bool :=
  match run_with_state start_env (step_trans tag_t tag p fuel start_state) with
  | (inl _, _) => true
  | _ => false
  end.

Definition EmptyParser : Declaration tag_t := DeclConstant tag_t tag constTyp name value.


(* Let's just parse an int... *)

(* 
parser IntExample (packet_in pkt, out int<2> output) {
  state start {
    pkt.extract(output);
    transition accept;
  }
}
*)

Definition scope : Env_EvalEnv := MkEnv_EvalEnv nil nil "dummy".

Definition pkt_param : P4Parameter := MkParameter true Directionless (TypExtern "packet_in") "pkt".
Definition out_type : P4Type := TypInt 2.
Definition out_param : P4Parameter := MkParameter true Out out_type "output".
Definition locals : list (Declaration tag_t) := nil.
Definition output_expr : Expression tag_t := MkExpression _ tt (ExpName _ (BareName "output")) out_type Directionless.
Definition pkt_extract_expr : Expression tag_t := MkExpression _ tt (ExpName _ (BareName "pkt")) (TypFunction (MkFunctionType nil ((MkParameter false Directionless out_type "t")::nil) FunBuiltin out_type)) Directionless.
Definition build_extract_stmt (into_type: P4Type) (into_expr: Expression tag_t) := MkStatement _ tt (StatMethodCall _ (MkExpression _ tt (ExpExpressionMember _ pkt_extract_expr (MkP4String _ tt String.extract)) TypVoid Directionless) (into_type :: nil) (Some into_expr :: nil)) StmVoid.
Definition extract_stmt : Statement tag_t := build_extract_stmt out_type output_expr.


Definition body: list (Statement tag_t) := extract_stmt :: nil.
Definition start_st : ParserState tag_t := MkParserState _ tt (MkP4String _ tt "start") body (ParserDirect _ tt (MkP4String _ tt String.accept)).

Definition states : list (ParserState tag_t) := start_st :: nil.

Definition IntParser : ValueObject tag_t := ValObjParser _ scope nil nil states.

Definition bad_env : Environment.environment tag_t := nil.

Lemma int_parses_fail : parses IntParser 2 "start" bad_env = false.
Proof.
  reflexivity.
Qed.

Definition pkt_value : Value tag_t := ValObj _ (ValObjPacket _ (true :: true :: nil)).
Definition out_value : Value tag_t := ValBase _ (ValBaseInteger _ 0).
Definition top_scope : Environment.scope tag_t := 
  Environment.extend_scope _ "pkt" pkt_value (
    Environment.extend_scope _ "output" out_value (
      Environment.MStr.empty _
    )
  ).

Definition inter_scope : Environment.scope tag_t := 
  Environment.MStr.add "pkt"
                              (ValObj tag_t (ValObjPacket tag_t nil))
                              top_scope.
Definition good_env: Environment.environment tag_t := top_scope :: nil.

Lemma top_find_pkt: Environment.MStr.find "pkt" top_scope = Some pkt_value.
Proof.
  unfold top_scope, Environment.extend_scope.
  apply Environment.MStr.find_1.
  now apply Environment.MStr.add_1.
Qed.
Lemma top_find_val : Environment.MStr.find "output" top_scope = Some out_value.
Proof.
  unfold top_scope, Environment.extend_scope.
  apply Environment.MStr.find_1.
  apply Environment.MStr.add_2;
    [congruence|].
  now apply Environment.MStr.add_1.
Qed.

Lemma top_find_val_inter : Environment.MStr.find "output" inter_scope = Some out_value.
Proof.
  unfold top_scope, Environment.extend_scope.
  apply Environment.MStr.find_1.
  apply Environment.MStr.add_2; [congruence|].
  apply Environment.MStr.add_2; [congruence|].
  now apply Environment.MStr.add_1.
Qed.

Hint Rewrite top_find_pkt top_find_val top_find_val_inter: int_example.

Lemma int_parses : parses IntParser 2 "start" good_env = true.
Proof.
  unfold parses.
  simpl.
  unfold IntParser.
  unfold states.
  unfold start_st.
  unfold parses.
  unfold step_trans. simpl.
  unfold run_with_state.
  unfold good_env. auto.

  unfold state_bind. simpl.

  unfold eval_statement. simpl.
  
  unfold state_bind. simpl.
  unfold Environment.toss_value. simpl.

  unfold eval_method_call. simpl.
  unfold state_bind. simpl.
  unfold Environment.find_environment, Environment.push_scope. simpl.
  unfold Environment.lift_env_lookup_fn, Environment.find_environment'.
  simpl.
  rewrite top_find_pkt. simpl.

  unfold eval_builtin_func. simpl.
  unfold state_bind. simpl.

  unfold Environment.find_environment, Environment.lift_env_lookup_fn, Environment.find_environment'. simpl.
  rewrite top_find_val. simpl.
  unfold Environment.dummy_value, eval_packet_func. simpl.
  unfold state_bind. simpl.
  unfold Environment.find_lvalue. simpl.
  unfold Environment.lift_env_lookup_fn, Environment.find_environment'. simpl.
  rewrite top_find_pkt. simpl.
  unfold Environment.update_lvalue. simpl.
  unfold Environment.lift_env_fn, Environment.update_environment'. simpl.
  
  
  unfold Option.option_bind.
  
  rewrite top_find_pkt. simpl.
  unfold Environment.insert_scope. simpl.
  unfold Option.option_bind. rewrite top_find_pkt. simpl.

  fold inter_scope. rewrite top_find_val_inter. 
  now simpl.
Qed.


(* OK, now consider the following two parsers: *)
(* 
parser Tupled (packet_in pkt, out int x, out int y) {
  state start {
    pkt.extract(x);
    pkt.extract(y);
    transition accept;
  }
}

parser Curried (packet_in pkt, out int x, out int y) {
  state start {
    pkt.extract(x);
    transition middle;
  }
  state middle {
    pkt.extract(y);
    transition accept;
  }
}

An interesting property is that Tupled and Curried behave the same on all packets!
*)

Definition x_param : P4Parameter := MkParameter true Out out_type "x".
Definition y_param : P4Parameter := MkParameter true Out out_type "y".
Definition x_expr : Expression tag_t := MkExpression _ tt (ExpName _ (BareName "x")) out_type Directionless.
Definition y_expr : Expression tag_t := MkExpression _ tt (ExpName _ (BareName "y")) out_type Directionless.
Definition extract_x := build_extract_stmt out_type x_expr.
Definition extract_y := build_extract_stmt out_type y_expr.

Definition body_tupled := extract_x :: extract_y :: nil.
Definition body_1_curried := extract_x :: nil.
Definition body_2_curried := extract_y :: nil.

Definition start_st_tupled : ParserState tag_t := MkParserState _ tt (MkP4String _ tt "start") body_tupled (ParserDirect _ tt (MkP4String _ tt String.accept)).
Definition start_st_curried : ParserState tag_t := MkParserState _ tt (MkP4String _ tt "start") body_1_curried (ParserDirect _ tt (MkP4String _ tt "middle")).
Definition mid_st_curried : ParserState tag_t := MkParserState _ tt (MkP4String _ tt "middle") body_2_curried (ParserDirect _ tt (MkP4String _ tt String.accept)).

Definition states_tupled : list (ParserState tag_t) := start_st_tupled :: nil.
Definition states_curried : list (ParserState tag_t) := start_st_curried :: nil.

Definition IntParserTupled := ValObjParser _ scope nil nil states_tupled.
Definition IntParserCurried := ValObjParser _ scope nil nil states_curried.

Definition build_env (bits: list bool): Environment.environment tag_t := 
  Environment.extend_scope _ "pkt" (ValObj _ (ValObjPacket _ bits)) (
    Environment.extend_scope _ "x" out_value (
      Environment.extend_scope _ "y" out_value (
        Environment.MStr.empty _
      )
    )
  ) :: nil.

Lemma find_x : 
  forall bits: list bool,
  Environment.find_scope _ "x" (List.hd (Environment.MStr.empty _) (build_env bits)) = Some out_value.
Proof.
Admitted.

Lemma curried_tupled_equiv: 
  forall (bits: list bool),
    parses IntParserTupled 4 "start" (build_env bits) = parses IntParserCurried 4 "start" (build_env bits).
Proof.
  (* induction bits.
  unfold build_env, IntParserTupled, IntParserCurried, parses. simpl.
  unfold run_with_state. simpl.
  unfold state_bind. simpl.
  unfold eval_statement. simpl.
  unfold state_bind. simpl.
  unfold Environment.toss_value. simpl.
  unfold eval_method_call. simpl.
  unfold state_bind. simpl.

  unfold Environment.find_environment, Environment.lift_env_lookup_fn, Environment.find_environment'.
  simpl.
  unfold Environment.extend_scope. simpl. 
  
  assert (lookup_env := Environment.MStr.find_1).
  specialize (lookup_env (Value tag_t)).
  remember (
  (Environment.MStr.add "x" out_value
     (Environment.MStr.add "y" out_value
        (Environment.MStr.empty (Value tag_t))))) as env_inner.
  remember (Environment.MStr.add "pkt" (ValObj tag_t (ValObjPacket tag_t nil)) env_inner) as env.
  specialize (lookup_env env).

  pose proof (lookup_env "pkt") as lookup_pkt.

  rewrite Heqenv in lookup_pkt.

  pose proof (@Environment.MStr.add_1 (Value tag_t) env_inner "pkt" "pkt") as add_pkt.
  specialize (add_pkt (ValObj tag_t (ValObjPacket tag_t nil))).

  assert (pkt_eq := eq_refl "pkt").
  specialize (add_pkt pkt_eq).

  specialize (lookup_pkt (ValObj tag_t (ValObjPacket tag_t nil)) add_pkt).

  rewrite <- Heqenv in lookup_pkt.
  rewrite lookup_pkt. simpl.

  unfold eval_builtin_func. simpl.
  unfold state_bind. simpl.
  

  unfold Environment.push_scope. simpl.

  assert (Fx := find_x).

  unfold build_env in Fx.

  unfold Environment.find_environment, Environment.lift_env_lookup_fn, Environment.find_environment'.
  simpl.

  pose proof (lookup_env "x") as lookup_x.

  (* rewrite Heqenv in lookup_x. *)

  pose proof (@Environment.MStr.add_1 (Value tag_t) env_inner "x" "x") as add_x.
  specialize (add_pkt (ValObj tag_t (ValObjPacket tag_t nil))).

  unfold Environment.MStr.find, Environment.MStr.Raw.find. simpl.
  rewrite Heqenv.
  rewrite Heqenv_inner.
  unfold Environment.MStr.Raw.add. simpl.
  unfold Environment.MStr.Raw.add. simpl.
  unfold String.ascii_compare. simpl.
  unfold Bool.reflect_dec. auto.
  unfold BinNat.N.ltb_spec0. simpl.
  unfold and_rec. simpl.
  (* cbv beta. cbv delta. *)
  simpl.
  unfold env. *)
Admitted.

