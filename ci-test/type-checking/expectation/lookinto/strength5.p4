/petr4/ci-test/type-checking/testdata/p4_16_samples/strength5.p4
\n
action a(inout bit<32> x) {
    x = x >> 3 >> 8;
}
************************\n******** petr4 type checking result: ********\n************************\n
action a(inout bit<32> x) {
  x = x>>3>>8;
}

************************\n******** p4c type checking result: ********\n************************\n
[--Wwarn=missing] warning: Program does not contain a `main' module
