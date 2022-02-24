/petr4/ci-test/type-checking/testdata/p4_16_samples/issue822.p4
\n
#include <core.p4>

// Architecture
control C();
package S(C c);

extern BoolRegister {
    BoolRegister();
}

extern ActionSelector {
    ActionSelector(BoolRegister reg);
}

// User Program
BoolRegister() r;

control MyC1() {
  ActionSelector(r) action_selector;
  apply {}
}

S(MyC1()) main;
************************\n******** petr4 type checking result: ********\n************************\n
error {
  NoError, PacketTooShort, NoMatch, StackOutOfBounds, HeaderTooShort,
  ParserTimeout, ParserInvalidArgument
}
extern packet_in {
  void extract<T>(out T hdr);
  void extract<T0>(out T0 variableSizeHeader,
                   in bit<32> variableFieldSizeInBits);
  T1 lookahead<T1>();
  void advance(in bit<32> sizeInBits);
  bit<32> length();
}

extern packet_out {
  void emit<T2>(in T2 hdr);
}

extern void verify(in bool check, in error toSignal);
@noWarn("unused")
action NoAction() { 
}
match_kind {
  exact, ternary, lpm
}
control C ();
package S (C c);
extern BoolRegister {
  BoolRegister();
}

extern ActionSelector {
  ActionSelector(BoolRegister reg);
}

BoolRegister() r;
control MyC1() {
  ActionSelector(r) action_selector;
  apply { 
  }
}
S(MyC1()) main;

************************\n******** p4c type checking result: ********\n************************\n
/petr4/ci-test/type-checking/testdata/p4_16_samples/issue822.p4(19): [--Wwarn=unused] warning: action_selector: unused instance
  ActionSelector(r) action_selector;
                    ^^^^^^^^^^^^^^^
