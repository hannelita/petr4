/petr4/ci-test/type-checking/testdata/p4_16_samples/issue1342.p4
\n
const bit X = 1;

bit f<X>() {
  return .X ;
}
************************\n******** petr4 type checking result: ********\n************************\n
const bit<1> X = 1;
bit<1> f<X0> () {
  return .X;
}

************************\n******** p4c type checking result: ********\n************************\n
