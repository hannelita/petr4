/petr4/ci-test/type-checking/testdata/p4_16_samples/issue2735-bmv2.p4
\n
#include <core.p4>
#include <v1model.p4>

typedef bit<48>  EthernetAddress;

header Ethernet_h {
    EthernetAddress dst;
    EthernetAddress src;
    bit<16>         type;
}

struct metadata {
}

struct headers {
    Ethernet_h eth;
}

parser SnvsParser(packet_in packet,
		  out headers hdr,
		  inout metadata meta,
		  inout standard_metadata_t standard_metadata) {
    state start {
        packet.extract(hdr.eth);
	transition accept;
    }
}

control SnvsVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {}
}

typedef bit<(48 + 12 + 9)> Mac_entry;
const bit<32> N_MAC_ENTRIES = 4096;
typedef register<Mac_entry> Mac_table;

control SnvsIngress(inout headers hdr,
		    inout metadata meta,
		    inout standard_metadata_t standard_metadata) {
    Mac_table(N_MAC_ENTRIES) mac_table;

    apply {
	Mac_entry b0;
	mac_table.read(b0, 0);
    }
}

control SnvsEgress(inout headers hdr,
		   inout metadata meta,
		   inout standard_metadata_t standard_metadata) {
    apply {}
}

control SnvsComputeChecksum(inout headers hdr, inout metadata meta) {
    apply {}
}

control SnvsDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.eth);
    }
}

V1Switch (
    SnvsParser(),
    SnvsVerifyChecksum(),
    SnvsIngress(),
    SnvsEgress(),
    SnvsComputeChecksum(),
    SnvsDeparser()
) main;************************\n******** petr4 type checking result: ********\n************************\n
Uncaught exception:
  
  ("bad constructor type or no matching constructor"
   (name
    (BareName
     ((I
       (filename
        /petr4/ci-test/type-checking/testdata/p4_16_samples/issue2735-bmv2.p4)
       (line_start 40) (line_end ()) (col_start 4) (col_end 13))
      Mac_table)))
   (ctor ()) (candidates ()))

Raised at Base__Error.raise in file "src/error.ml" (inlined), line 8, characters 14-30
Called from Base__Error.raise_s in file "src/error.ml", line 9, characters 19-40
Called from Petr4__Checker.type_constructor_invocation in file "lib/checker.ml", line 2542, characters 25-72
Called from Petr4__Checker.type_nameless_instantiation in file "lib/checker.ml", line 2573, characters 32-97
Called from Petr4__Checker.type_instantiation in file "lib/checker.ml", line 2928, characters 23-77
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
