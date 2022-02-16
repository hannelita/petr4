/petr4/ci-test/type-checking/testdata/p4_16_samples/newtype2.p4
\n
#include <core.p4>

typedef bit<9> PortIdUInt_t;
type bit<9> PortId_t;

struct M {
    PortId_t e;
    PortIdUInt_t es;
}

control Ingress(inout M sm);
package V1Switch(Ingress ig);

control Forwarding (inout M sm) {
    apply {
        sm.es = (PortIdUInt_t)sm.e;
    }
}

control FabricIngress (inout M sm) {
    Forwarding() forwarding;
    apply {
        forwarding.apply(sm);
    }
}

V1Switch(FabricIngress()) main;
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
typedef bit<9> PortIdUInt_t;
type bit<9> PortId_t;
struct M {
  PortId_t e;
  PortIdUInt_t es;
}
control Ingress (inout M sm);
package V1Switch (Ingress ig);
control Forwarding(inout M sm) {
  apply {
    sm.es = (PortIdUInt_t) sm.e;
  }
}
control FabricIngress(inout M sm) {
  Forwarding() forwarding;
  apply {
    forwarding.apply(sm);
  }
}
V1Switch(FabricIngress()) main;

************************\n******** p4c type checking result: ********\n************************\n
