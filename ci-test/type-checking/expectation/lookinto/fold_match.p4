/petr4/ci-test/type-checking/testdata/p4_16_samples/fold_match.p4
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

parser p()
{
    state start
    {
        transition select(32w0)
        {
            32w5 &&& 32w7 : reject;
            32w0          : accept;
            default       : reject;
        }
    }

    state next0
    {
        transition select(32w0)
        {
            32w1 &&& 32w1 : reject;
            default       : accept;
            32w0          : reject;
        }
    }

    state next1
    {
        transition select(32w1)
        {
            32w1 &&& 32w1 : accept;
            32w0          : reject;
            default       : reject;
        }
    }

    state next2
    {
        transition select(32w1)
        {
            32w0 .. 32w7 : accept;
            32w0         : reject;
            default       : reject;
        }
    }

    state next3
    {
        transition select(32w3)
        {
            32w1 &&& 32w1 : accept;
            32w0          : reject;
            default       : reject;
        }
    }

    state next00
    {
        transition select(true, 32w0)
        {
            (true, 32w1 &&& 32w1) : reject;
            default       : accept;
            (true, 32w0)          : reject;
        }
    }

    state next01
    {
        transition select(true, 32w1)
        {
            (true, 32w1 &&& 32w1) : accept;
            (true, 32w0)          : reject;
            default       : reject;
        }
    }

    state next02
    {
        transition select(true, 32w1)
        {
            (true, 32w0 .. 32w7) : accept;
            (true, 32w0)          : reject;
            default       : reject;
        }
    }

    state next03
    {
        transition select(true, 32w3)
        {
            (true, 32w1 &&& 32w1) : accept;
            (true, 32w0)          : reject;
            default       : reject;
        }
    }

    state last
    {
        transition select(32w0)
        {
            32w5 &&& 32w7 : reject;
            32w1          : reject;
        }
    }
}
************************\n******** petr4 type checking result: ********\n************************\n
parser p() {
  state start
    {
    transition select(32w0) {
      32w5 &&& 32w7: reject;
      32w0: accept;
      default: reject;
    }
  }
  state next0
    {
    transition select(32w0) {
      32w1 &&& 32w1: reject;
      default: accept;
      32w0: reject;
    }
  }
  state next1
    {
    transition select(32w1) {
      32w1 &&& 32w1: accept;
      32w0: reject;
      default: reject;
    }
  }
  state next2
    {
    transition select(32w1) {
      32w0 .. 32w7: accept;
      32w0: reject;
      default: reject;
    }
  }
  state next3
    {
    transition select(32w3) {
      32w1 &&& 32w1: accept;
      32w0: reject;
      default: reject;
    }
  }
  state next00
    {
    transition select(true, 32w0) {
      (true, 32w1 &&& 32w1): reject;
      default: accept;
      (true, 32w0): reject;
    }
  }
  state next01
    {
    transition select(true, 32w1) {
      (true, 32w1 &&& 32w1): accept;
      (true, 32w0): reject;
      default: reject;
    }
  }
  state next02
    {
    transition select(true, 32w1) {
      (true, 32w0 .. 32w7): accept;
      (true, 32w0): reject;
      default: reject;
    }
  }
  state next03
    {
    transition select(true, 32w3) {
      (true, 32w1 &&& 32w1): accept;
      (true, 32w0): reject;
      default: reject;
    }
  }
  state last {
    transition select(32w0) {
      32w5 &&& 32w7: reject;
      32w1: reject;
    }
  }
}

************************\n******** p4c type checking result: ********\n************************\n
/petr4/ci-test/type-checking/testdata/p4_16_samples/fold_match.p4(25): [--Wwarn=parser-transition] warning: SelectCase: unreachable case
            default : reject;
            ^^^^^^^^^^^^^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/fold_match.p4(35): [--Wwarn=parser-transition] warning: SelectCase: unreachable case
            32w0 : reject;
            ^^^^^^^^^^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/fold_match.p4(44): [--Wwarn=parser-transition] warning: SelectCase: unreachable case
            32w0 : reject;
            ^^^^^^^^^^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/fold_match.p4(45): [--Wwarn=parser-transition] warning: SelectCase: unreachable case
            default : reject;
            ^^^^^^^^^^^^^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/fold_match.p4(54): [--Wwarn=parser-transition] warning: SelectCase: unreachable case
            32w0 : reject;
            ^^^^^^^^^^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/fold_match.p4(55): [--Wwarn=parser-transition] warning: SelectCase: unreachable case
            default : reject;
            ^^^^^^^^^^^^^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/fold_match.p4(64): [--Wwarn=parser-transition] warning: SelectCase: unreachable case
            32w0 : reject;
            ^^^^^^^^^^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/fold_match.p4(65): [--Wwarn=parser-transition] warning: SelectCase: unreachable case
            default : reject;
            ^^^^^^^^^^^^^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/fold_match.p4(75): [--Wwarn=parser-transition] warning: SelectCase: unreachable case
            (true, 32w0) : reject;
            ^^^^^^^^^^^^^^^^^^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/fold_match.p4(84): [--Wwarn=parser-transition] warning: SelectCase: unreachable case
            (true, 32w0) : reject;
            ^^^^^^^^^^^^^^^^^^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/fold_match.p4(85): [--Wwarn=parser-transition] warning: SelectCase: unreachable case
            default : reject;
            ^^^^^^^^^^^^^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/fold_match.p4(94): [--Wwarn=parser-transition] warning: SelectCase: unreachable case
            (true, 32w0) : reject;
            ^^^^^^^^^^^^^^^^^^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/fold_match.p4(95): [--Wwarn=parser-transition] warning: SelectCase: unreachable case
            default : reject;
            ^^^^^^^^^^^^^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/fold_match.p4(104): [--Wwarn=parser-transition] warning: SelectCase: unreachable case
            (true, 32w0) : reject;
            ^^^^^^^^^^^^^^^^^^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/fold_match.p4(105): [--Wwarn=parser-transition] warning: SelectCase: unreachable case
            default : reject;
            ^^^^^^^^^^^^^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/fold_match.p4(111): [--Wwarn=parser-transition] warning: SelectExpression: no case matches
        transition select(32w0)
                   ^
[--Wwarn=missing] warning: Program does not contain a `main' module
