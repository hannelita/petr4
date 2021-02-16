Require Import Grammars.Grammar.
Require Import Grammars.Lib.
Require Import Grammars.Binary.
Require Import Grammars.Bits.

Record IPHeader := {
  src: bits 8;
  dest: bits 8;
  proto: bits 4
}.

Definition IPHeader_p : grammar IPHeader :=
  (
    bits_n 8 >= fun src => 
    bits_n 8 >= fun dest => 
    bits_n 4 >= fun proto => 
      ret {| src := src; dest := dest; proto := proto |}
  ) @ fun x => projT2 (projT2 (projT2 x)).


Record TCP := {
  sport_t: bits 8;
  dport_t: bits 8;
  flags_t: bits 4;
  seq: bits 8
}.

Definition TCP_p : grammar TCP :=
  (
    bits_n 8 >= fun sport_t => 
    bits_n 8 >= fun dport_t => 
    bits_n 4 >= fun flags_t => 
    bits_n 8 >= fun seq =>
      ret {| sport_t := sport_t; dport_t := dport_t; flags_t := flags_t; seq := seq |}
  ) @ fun x => projT2 (projT2 (projT2 (projT2 x))).

Record UDP := {
  sport_u: bits 8;
  dport_u: bits 8;
  flags_u: bits 4
}.

Definition UDP_p : grammar UDP :=
  (
    bits_n 8 >= fun sport_u => 
    bits_n 8 >= fun dport_u => 
    bits_n 4 >= fun flags_u => 
      ret {| sport_u := sport_u; dport_u := dport_u; flags_u := flags_u |}
  ) @ fun x => projT2 (projT2 (projT2 x)).

Record Headers := {
  ip: IPHeader;
  transport: option (TCP + UDP)
}.

Definition bits_foo : bits 2 := (true, (false, tt)).

Definition bits_bar : bool := 
  match bits_foo with
  | (true, (false, tt)) => true
  | _ => false
  end.

Definition babyParser : grammar Headers := 
  (IPHeader_p >= fun iph => 
  match proto iph return grammar (option (TCP + UDP)) with
  | (false, (false, (false, (false, tt)))) => 
    TCP_p @ inl @ Some
  | (false, (false, (false, (true, tt)))) => 
    UDP_p @ inr @ Some
  | _ => ret None
  end)
  @ fun x => let (ip, transport) := x in 
    {| ip := ip; transport := transport |}.