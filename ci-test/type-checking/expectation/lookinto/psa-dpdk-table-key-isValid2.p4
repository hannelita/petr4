/petr4/ci-test/type-checking/testdata/p4_16_samples/psa-dpdk-table-key-isValid2.p4
\n
#include <core.p4>
#include <psa.p4>


typedef bit<48>  EthernetAddress;

header ethernet_t {
    EthernetAddress dstAddr;
    EthernetAddress srcAddr;
    bit<16>         etherType;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
    bit<80> newfield;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<3>  res;
    bit<3>  ecn;
    bit<6>  ctrl;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

struct empty_metadata_t {
}


struct metadata {
     bit<16> data;
}

struct headers {
    ethernet_t       ethernet;
    ipv4_t           ipv4;
    tcp_t            tcp;
}


parser IngressParserImpl(packet_in buffer,
                         out headers hdr,
                         inout metadata user_meta,
                         in psa_ingress_parser_input_metadata_t istd,
                         in empty_metadata_t resubmit_meta,
                         in empty_metadata_t recirculate_meta)
{
    state start {
        buffer.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            0x0800 &&& 0x0F00 : parse_ipv4;
            16w0x0d00 : parse_tcp;
            default : accept;
        }
    }
    state parse_ipv4 {
        buffer.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            8w4 .. 8w7: parse_tcp;
            default: accept;
        }
    }
    state parse_tcp {
        buffer.extract(hdr.tcp);
        transition accept;
    }
}

control ingress(inout headers hdr,
                inout metadata user_meta,
                in    psa_ingress_input_metadata_t  istd,
                inout psa_ingress_output_metadata_t ostd)
{
    action execute() {
        user_meta.data = 1;
    }
    table tbl {
        key = {
            hdr.ethernet.isValid() || hdr.ipv4.isValid(): exact @name ("hdrValid") ;
            hdr.ethernet.dstAddr : exact;
            hdr.ethernet.srcAddr : exact;
        }
        actions = { NoAction; execute; }
    }
    apply {
            tbl.apply();
    }
}

parser EgressParserImpl(packet_in buffer,
                        out headers hdr,
                        inout metadata user_meta,
                        in psa_egress_parser_input_metadata_t istd,
                        in empty_metadata_t normal_meta,
                        in empty_metadata_t clone_i2e_meta,
                        in empty_metadata_t clone_e2e_meta)
{
    state start {
        transition accept;
    }
}

control egress(inout headers hdr,
               inout metadata user_meta,
               in    psa_egress_input_metadata_t  istd,
               inout psa_egress_output_metadata_t ostd)
{
    apply { }
}

control IngressDeparserImpl(packet_out packet,
                            out empty_metadata_t clone_i2e_meta,
                            out empty_metadata_t resubmit_meta,
                            out empty_metadata_t normal_meta,
                            inout headers hdr,
                            in metadata meta,
                            in psa_ingress_output_metadata_t istd)
{
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
    }
}

control EgressDeparserImpl(packet_out packet,
                           out empty_metadata_t clone_e2e_meta,
                           out empty_metadata_t recirculate_meta,
                           inout headers hdr,
                           in metadata meta,
                           in psa_egress_output_metadata_t istd,
                           in psa_egress_deparser_input_metadata_t edstd)
{
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
    }
}

IngressPipeline(IngressParserImpl(),
                ingress(),
                IngressDeparserImpl()) ip;

EgressPipeline(EgressParserImpl(),
               egress(),
               EgressDeparserImpl()) ep;

PSA_Switch(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;
************************\n******** petr4 type checking result: ********\n************************\n
/petr4/ci-test/type-checking/testdata/p4_16_samples/psa-dpdk-table-key-isValid2.p4:2:10: fatal error: psa.p4: No such file or directory
    2 | #include <psa.p4>
      |          ^~~~~~~~
compilation terminated.
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

************************\n******** p4c type checking result: ********\n************************\n
/usr/local/share/p4c/p4include/bmv2/psa.p4(546): [--Wwarn=unused] warning: 'W' is unused
extern Counter<W, S> {
               ^
/usr/local/share/p4c/p4include/bmv2/psa.p4(575): [--Wwarn=unused] warning: 'W' is unused
extern DirectCounter<W> {
                     ^
