/petr4/ci-test/type-checking/testdata/p4_16_samples/issue2542.p4
\n
#include <core.p4>
header ethernet_t {
    bit<16> eth_type;
}

struct Headers {
    ethernet_t eth_hdr;
}

control SubCtrl(bit<16> eth_type) {
    table dummy {
        key = {
            eth_type: exact @name("dummy_key") ;
        }
        actions = {
        }
    }
    apply {
        dummy.apply();
    }
}

control ingress(inout Headers h) {
    SubCtrl() sub;
    apply {
        sub.apply(16w2);
    }
}

control Ingress(inout Headers hdr);
package top(Ingress ig);
top(ingress()) main;
************************\n******** petr4 type checking result: ********\n************************\n
Uncaught exception:
  
  "Table must have a non-empty actions property"

Raised at Base__Error.raise in file "src/error.ml" (inlined), line 8, characters 14-30
Called from Base__Error.raise_s in file "src/error.ml", line 9, characters 19-40
Called from Petr4__Checker.type_table'.(fun) in file "lib/checker.ml", line 3644, characters 14-79
Called from Petr4__Checker.type_table in file "lib/checker.ml", line 3314, characters 2-95
Called from Petr4__Checker.type_declarations.f in file "lib/checker.ml", line 4118, characters 26-55
Called from Stdlib__list.fold_left in file "list.ml", line 121, characters 24-34
Called from Base__List0.fold in file "src/list0.ml" (inlined), line 21, characters 22-52
Called from Petr4__Checker.type_declarations in file "lib/checker.ml", line 4121, characters 19-58
Called from Petr4__Checker.open_control_scope in file "lib/checker.ml", line 3087, characters 26-73
Called from Petr4__Checker.type_control in file "lib/checker.ml", line 3096, characters 6-69
Called from Petr4__Checker.type_declarations.f in file "lib/checker.ml", line 4118, characters 26-55
Called from Stdlib__list.fold_left in file "list.ml", line 121, characters 24-34
Called from Base__List0.fold in file "src/list0.ml" (inlined), line 21, characters 22-52
Called from Petr4__Checker.type_declarations in file "lib/checker.ml", line 4121, characters 19-58
Called from Petr4__Checker.check_program in file "lib/checker.ml", line 4128, characters 18-78
Called from Petr4__Common.Make_parse.check_file' in file "lib/common.ml", line 95, characters 17-51
Called from Petr4__Common.Make_parse.check_file in file "lib/common.ml", line 108, characters 10-50
Called from Main.check_command.(fun) in file "bin/main.ml", line 70, characters 14-65
Called from Core_kernel__Command.For_unix.run.(fun) in file "src/command.ml", line 2453, characters 8-238
Called from Base__Exn.handle_uncaught_aux in file "src/exn.ml", line 111, characters 6-10
************************\n******** p4c type checking result: ********\n************************\n
/petr4/ci-test/type-checking/testdata/p4_16_samples/issue2542.p4(13): [--Wwarn=ignore-prop] warning: KeyElement: constant key element
            eth_type: exact @name("dummy_key") ;
            ^^^^^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/issue2542.p4(26): [--Wwarn=mismatch] warning: 16w2: Constant key field
        sub.apply(16w2);
                  ^^^^
