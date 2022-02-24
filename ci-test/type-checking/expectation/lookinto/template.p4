/petr4/ci-test/type-checking/testdata/p4_16_samples/template.p4
\n
/*
Copyright 2013-present Barefoot Networks, Inc. 

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

extern bit<32> f<T>(in T data);

action a() {
    bit<8> x;
    bit<4> y;
    bit<32> r = f(x) + f(y);
}
************************\n******** petr4 type checking result: ********\n************************\n
extern bit<32> f<T>(in T data);
action a() {
  bit<8> x;
  bit<4> y;
  bit<32> r = f(x)+f(y);
}

************************\n******** p4c type checking result: ********\n************************\n
[--Wwarn=missing] warning: Program does not contain a `main' module
