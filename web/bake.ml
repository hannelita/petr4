let core_p4_str =
  {|/*
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

/* This is the P4-16 core library, which declares some built-in P4 constructs using P4 */

#ifndef _CORE_P4_
#define _CORE_P4_

/// Standard error codes.  New error codes can be declared by users.
error {
    NoError,           /// No error.
    PacketTooShort,    /// Not enough bits in packet for 'extract'.
    NoMatch,           /// 'select' expression has no matches.
    StackOutOfBounds,  /// Reference to invalid element of a header stack.
    HeaderTooShort,    /// Extracting too many bits into a varbit field.
    ParserTimeout,     /// Parser execution time limit exceeded.
    ParserInvalidArgument  /// Parser operation was called with a value
                           /// not supported by the implementation.
}

extern packet_in {
    /// Read a header from the packet into a fixed-sized header @hdr and advance the cursor.
    /// May trigger error PacketTooShort or StackOutOfBounds.
    /// @T must be a fixed-size header type
    void extract<T>(out T hdr);
    /// Read bits from the packet into a variable-sized header @variableSizeHeader
    /// and advance the cursor.
    /// @T must be a header containing exactly 1 varbit field.
    /// May trigger errors PacketTooShort, StackOutOfBounds, or HeaderTooShort.
    void extract<T>(out T variableSizeHeader,
                    in bit<32> variableFieldSizeInBits);
    /// Read bits from the packet without advancing the cursor.
    /// @returns: the bits read from the packet.
    /// T may be an arbitrary fixed-size type.
    T lookahead<T>();
    /// Advance the packet cursor by the specified number of bits.
    void advance(in bit<32> sizeInBits);
    /// @return packet length in bytes.  This method may be unavailable on
    /// some target architectures.
    bit<32> length();
}

extern packet_out {
    /// Write @hdr into the output packet, advancing cursor.
    /// @T can be a header type, a header stack, a header_union, or a struct
    /// containing fields with such types.
    void emit<T>(in T hdr);
}

// TODO: remove from this file, convert to built-in
/// Check a predicate @check in the parser; if the predicate is true do nothing,
/// otherwise set the parser error to @toSignal, and transition to the `reject` state.
extern void verify(in bool check, in error toSignal);

/// Built-in action that does nothing.
action NoAction() {}

/// Standard match kinds for table key fields.
/// Some architectures may not support all these match kinds.
/// Architectures can declare additional match kinds.
match_kind {
    /// Match bits exactly.
    exact,
    /// Ternary match, using a mask.
    ternary,
    /// Longest-prefix match.
    lpm
}

#endif  /* _CORE_P4_ */
|}

let v1model_p4_str =
  {|/*
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

/* P4-16 declaration of the P4 v1.0 switch model */

#ifndef _V1_MODEL_P4_
#define _V1_MODEL_P4_

#include "core.p4"

match_kind {
    range,
    // Used for implementing dynamic_action_selection
    selector
}

// Are these correct?
@metadata @name("standard_metadata")
struct standard_metadata_t {
    bit<9>  ingress_port;
    bit<9>  egress_spec;
    bit<9>  egress_port;
    bit<32> clone_spec;
    bit<32> instance_type;
    // The drop and recirculate_port fields are not used at all by the
    // behavioral-model simple_switch software switch as of September
    // 2018, and perhaps never was.  They may be considered
    // deprecated, at least for that P4 target device.  simple_switch
    // uses the value of the egress_spec field to determine whether a
    // packet is dropped or not, and it is recommended to use the
    // P4_14 drop() primitive action, or the P4_16 + v1model
    // mark_to_drop() primitive action, to cause that field to be
    // changed so the packet will be dropped.
    bit<1>  drop;
    bit<16> recirculate_port;
    bit<32> packet_length;
    //
    // @alias is used to generate the field_alias section of the BMV2 JSON.
    // Field alias creates a mapping from the metadata name in P4 program to
    // the behavioral model's internal metadata name. Here we use it to
    // expose all metadata supported by simple switch to the user through
    // standard_metadata_t.
    //
    // flattening fields that exist in bmv2-ss
    // queueing metadata
    @alias("queueing_metadata.enq_timestamp") bit<32> enq_timestamp;
    @alias("queueing_metadata.enq_qdepth")    bit<19> enq_qdepth;
    @alias("queueing_metadata.deq_timedelta") bit<32> deq_timedelta;
    @alias("queueing_metadata.deq_qdepth")    bit<19> deq_qdepth;
    // intrinsic metadata
    @alias("intrinsic_metadata.ingress_global_timestamp") bit<48> ingress_global_timestamp;
    @alias("intrinsic_metadata.egress_global_timestamp") bit<48> egress_global_timestamp;
    @alias("intrinsic_metadata.lf_field_list") bit<32> lf_field_list;
    @alias("intrinsic_metadata.mcast_grp")     bit<16> mcast_grp;
    @alias("intrinsic_metadata.resubmit_flag") bit<32> resubmit_flag;
    @alias("intrinsic_metadata.egress_rid")    bit<16> egress_rid;
    /// Indicates that a verify_checksum() method has failed.
    // 1 if a checksum error was found, otherwise 0.
    bit<1>  checksum_error;
    @alias("intrinsic_metadata.recirculate_flag") bit<32> recirculate_flag;
    /// Error produced by parsing
    error parser_error;
}

enum CounterType {
    packets,
    bytes,
    packets_and_bytes
}

enum MeterType {
    packets,
    bytes
}

extern counter {
    counter(bit<32> size, CounterType type);
    void count(in bit<32> index);
}

extern direct_counter {
    direct_counter(CounterType type);
    void count();
}

extern meter {
    meter(bit<32> size, MeterType type);
    void execute_meter<T>(in bit<32> index, out T result);
}

extern direct_meter<T> {
    direct_meter(MeterType type);
    void read(out T result);
}

extern register<T> {
    register(bit<32> size);
    void read(out T result, in bit<32> index);
    void write(in bit<32> index, in T value);
}

// used as table implementation attribute
extern action_profile {
    action_profile(bit<32> size);
}

// Get a random number in the range lo..hi
extern void random<T>(out T result, in T lo, in T hi);
// If the type T is a named struct, the name is used
// to generate the control-plane API.
extern void digest<T>(in bit<32> receiver, in T data);

enum HashAlgorithm {
    crc32,
    crc32_custom,
    crc16,
    crc16_custom,
    random,
    identity,
    csum16,
    xor16
}

extern void mark_to_drop();
extern void hash<O, T, D, M>(out O result, in HashAlgorithm algo, in T base, in D data, in M max);

extern action_selector {
    action_selector(HashAlgorithm algorithm, bit<32> size, bit<32> outputWidth);
}

enum CloneType {
    I2E,
    E2E
}

@deprecated("Please use verify_checksum/update_checksum instead.")
extern Checksum16 {
    Checksum16();
    bit<16> get<D>(in D data);
}

/**
Verifies the checksum of the supplied data.
If this method detects that a checksum of the data is not correct it
sets the standard_metadata checksum_error bit.
@param T          Must be a tuple type where all the fields are bit-fields or varbits.
                  The total dynamic length of the fields is a multiple of the output size.
@param O          Checksum type; must be bit<X> type.
@param condition  If 'false' the verification always succeeds.
@param data       Data whose checksum is verified.
@param checksum   Expected checksum of the data; note that is must be a left-value.
@param algo       Algorithm to use for checksum (not all algorithms may be supported).
                  Must be a compile-time constant.
*/
extern void verify_checksum<T, O>(in bool condition, in T data, inout O checksum, HashAlgorithm algo);
/**
Computes the checksum of the supplied data.
@param T          Must be a tuple type where all the fields are bit-fields or varbits.
                  The total dynamic length of the fields is a multiple of the output size.
@param O          Output type; must be bit<X> type.
@param condition  If 'false' the checksum is not changed
@param data       Data whose checksum is computed.
@param checksum   Checksum of the data.
@param algo       Algorithm to use for checksum (not all algorithms may be supported).
                  Must be a compile-time constant.
*/
extern void update_checksum<T, O>(in bool condition, in T data, inout O checksum, HashAlgorithm algo);

/**
Verifies the checksum of the supplied data including the payload.
The payload is defined as "all bytes of the packet which were not parsed by the parser".
If this method detects that a checksum of the data is not correct it
sets the standard_metadata checksum_error bit.
@param T          Must be a tuple type where all the fields are bit-fields or varbits.
                  The total dynamic length of the fields is a multiple of the output size.
@param O          Checksum type; must be bit<X> type.
@param condition  If 'false' the verification always succeeds.
@param data       Data whose checksum is verified.
@param checksum   Expected checksum of the data; note that is must be a left-value.
@param algo       Algorithm to use for checksum (not all algorithms may be supported).
                  Must be a compile-time constant.
*/
extern void verify_checksum_with_payload<T, O>(in bool condition, in T data, inout O checksum, HashAlgorithm algo);
/**
Computes the checksum of the supplied data including the payload.
The payload is defined as "all bytes of the packet which were not parsed by the parser".
@param T          Must be a tuple type where all the fields are bit-fields or varbits.
                  The total dynamic length of the fields is a multiple of the output size.
@param O          Output type; must be bit<X> type.
@param condition  If 'false' the checksum is not changed
@param data       Data whose checksum is computed.
@param checksum   Checksum of the data.
@param algo       Algorithm to use for checksum (not all algorithms may be supported).
                  Must be a compile-time constant.
*/
extern void update_checksum_with_payload<T, O>(in bool condition, in T data, inout O checksum, HashAlgorithm algo);

extern void resubmit<T>(in T data);
extern void recirculate<T>(in T data);
extern void clone(in CloneType type, in bit<32> session);
extern void clone3<T>(in CloneType type, in bit<32> session, in T data);

extern void truncate(in bit<32> length);

// The name 'standard_metadata' is reserved

// Architecture.
// M should be a struct of structs
// H should be a struct of headers, stacks or header_unions

parser Parser<H, M>(packet_in b,
                    out H parsedHdr,
                    inout M meta,
                    inout standard_metadata_t standard_metadata);

/* The only legal statements in the implementation of the
VerifyChecksum control are: block statements, calls to the
verify_checksum and verify_checksum_with_payload methods,
and return statements. */
control VerifyChecksum<H, M>(inout H hdr,
                             inout M meta);
@pipeline
control Ingress<H, M>(inout H hdr,
                      inout M meta,
                      inout standard_metadata_t standard_metadata);
@pipeline
control Egress<H, M>(inout H hdr,
                     inout M meta,
                     inout standard_metadata_t standard_metadata);

/* The only legal statements in the implementation of the
ComputeChecksum control are: block statements, calls to the
update_checksum and update_checksum_with_payload methods,
and return statements. */
control ComputeChecksum<H, M>(inout H hdr,
                              inout M meta);
@deparser
control Deparser<H>(packet_out b, in H hdr);

package V1Switch<H, M>(Parser<H, M> p,
                       VerifyChecksum<H, M> vr,
                       Ingress<H, M> ig,
                       Egress<H, M> eg,
                       ComputeChecksum<H, M> ck,
                       Deparser<H> dep
                       );

#endif  /* _V1_MODEL_P4_ */
|}

let sr_acl_p4_str =
  {|#include <core.p4>
#include <v1model.p4>

const int MAX_HOPS = 10;
const int STANDARD = 0x00;
const int HOPS = 0x01;

typedef standard_metadata_t std_meta_t;

header type_t {
  bit<8> tag;
}

header hop_t {
  bit<8> port;
  bit<8> bos;
}

header standard_t {
  bit<8> src;
  bit<8> dst;
}

struct headers_t {
  type_t type;
  hop_t[MAX_HOPS] hops;
  standard_t standard;
}

struct meta_t { }

parser MyParser(packet_in pkt, out headers_t hdr, inout meta_t meta, inout std_meta_t std_meta) {
    state start {
        pkt.extract(hdr.type);
        transition select(hdr.type.tag) {
            HOPS: parse_hops;
            STANDARD: parse_standard;
            default: accept;
        }
    }
    state parse_hops {
        pkt.extract(hdr.hops.next);
        transition select(hdr.hops.last.bos) {
            1: parse_standard;
            default: parse_hops;
        }
    }
    
    state parse_standard {
        pkt.extract(hdr.standard);
        transition accept;
    }
}

control MyVerifyChecksum(inout headers_t hdr, inout meta_t meta) {
    apply { }
}

control MyComputeChecksum(inout headers_t hdr, inout meta_t meta) {
    apply { }
}

control MyIngress(inout headers_t hdr, inout meta_t meta, inout std_meta_t std_meta) {
  action allow() { }
  action deny() { std_meta.egress_spec = 9w511; }
  table acl {
    key = { hdr.standard.src : exact; hdr.standard.dst : exact; }
    actions = { allow; deny; }
    const entries = { (0xCC, 0xDD) : deny(); }
    default_action = allow();
  }
  apply {
    std_meta.egress_spec = (bit<9>) hdr.hops[0].port;
    hdr.hops.pop_front(1);
    if (!hdr.hops[0].isValid()) {
        hdr.type.tag = 0x00;
    }
    acl.apply();
  }
}

control MyEgress(inout headers_t hdr, inout meta_t meta, inout std_meta_t std_meta) {
    apply { }
}

control MyDeparser(packet_out pkt, in headers_t hdr) {
    apply {
        pkt.emit(hdr.type);
        pkt.emit(hdr.hops);
        pkt.emit(hdr.standard);
    }
}

V1Switch(MyParser(), MyVerifyChecksum(), MyIngress(), MyEgress(), MyComputeChecksum(), MyDeparser()) main;
|}

let register_p4_str =
  {|#include <core.p4>
#include <v1model.p4>

const bit<32> reg_size = 128;

header my_header_t {
    bit<32> h;
}

struct metadata { }
struct headers {
    my_header_t h;
}

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {
    state start {
        packet.extract(hdr.h);
        transition accept;
    }
}

control MyChecksum(inout headers hdr, inout metadata meta) {
    apply { }
}

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) { 

    apply { }
}

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply { }
}

control MyDeparser(packet_out packet, in headers hdr) {
    register<bit<32>>(reg_size) r;
    bit<32> index;
    bit<32> reg_read_val;
    bit<32> reg_write_val;
    apply {
        index = 2;
        reg_write_val = hdr.h.h;
        r.read(reg_read_val, index);
        r.write(index, reg_write_val);

        packet.emit(reg_read_val);
    }
}

//this is declaration
V1Switch(
    MyParser(),
    MyChecksum(),
    MyIngress(),
    MyEgress(),
    MyChecksum(),
    MyDeparser()
    )
main;
|}

let switch_ebpf_p4_str = {|/*
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

#include <ebpf_model.p4>
#include <core.p4>

#include "ebpf_headers.p4"

struct Headers_t
{
    Ethernet_h ethernet;
    IPv4_h     ipv4;
}

parser prs(packet_in p, out Headers_t headers)
{
    state start
    {
        p.extract(headers.ethernet);
        transition select(headers.ethernet.etherType)
        {
            16w0x800 : ip;
            default : reject;
        }
    }

    state ip
    {
        p.extract(headers.ipv4);
        transition accept;
    }
}

control pipe(inout Headers_t headers, out bool pass)
{
    action Reject(IPv4Address addr)
    {
        pass = false;
        headers.ipv4.srcAddr = addr;
    }

    table Check_src_ip {
        key = { headers.ipv4.srcAddr : exact; }
        actions =
        {
            Reject;
            NoAction;
        }

        implementation = hash_table(1024);
        const default_action = NoAction;
    }

    apply {
        pass = true;

        switch (Check_src_ip.apply().action_run) {
        Reject: {
            pass = false;
        }
        NoAction: {}
        }
    }
}

ebpfFilter(prs(), pipe()) main;
|}

let table_entries_lpm_bmv2_p4_str =
  {|/*
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

#include <core.p4>
#include <v1model.p4>

header hdr {
    bit<8>  e;
    bit<16> t;
    bit<8>  l;
    bit<8> r;
    bit<8>  v;
}

struct Header_t {
    hdr h;
}
struct Meta_t {}

parser p(packet_in b, out Header_t h, inout Meta_t m, inout standard_metadata_t sm) {
    state start {
        b.extract(h.h);
        transition accept;
    }
}

control vrfy(inout Header_t h, inout Meta_t m) { apply {} }
control update(inout Header_t h, inout Meta_t m) { apply {} }
control egress(inout Header_t h, inout Meta_t m, inout standard_metadata_t sm) { apply {} }
control deparser(packet_out b, in Header_t h) { apply { b.emit(h.h); } }

control ingress(inout Header_t h, inout Meta_t m, inout standard_metadata_t standard_meta) {

    action a() { standard_meta.egress_spec = 0; }
    action a_with_control_params(bit<9> x) { standard_meta.egress_spec = x; }

    table t_lpm {

  	key = {
            h.h.l : lpm;
        }

	actions = {
            a;
            a_with_control_params;
        }

	default_action = a;

        const entries = {
            0x11 &&& 0xF0 : a_with_control_params(11);
            0x12          : a_with_control_params(12);
            _             : a_with_control_params(13);
        }
    }

    apply {
        t_lpm.apply();
    }
}


V1Switch(p(), vrfy(), ingress(), egress(), update(), deparser()) main;
|}

let union_valid_bmv2_p4_str =
{|/*
Copyright 2017 VMware, Inc.

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

#include <core.p4>
#include <v1model.p4>

header Hdr1 {
    bit<32> a;
}

header Hdr2 {
    bit<64> b;
}

header_union U {
    Hdr1 h1;
    Hdr2 h2;
}

struct Headers {
    Hdr1 h1;
    U u;
}

struct Meta {}

parser p(packet_in b, out Headers h, inout Meta m, inout standard_metadata_t sm) {
    state start {
        b.extract(h.h1);
        transition select(h.h1.a) {
            0: getH1;
            default: getH1;
        }
    }

    state getH1 {
        b.extract(h.u.h1);
        transition accept;
    }

    state getH2 {
        b.extract(h.u.h2);
        transition accept;
    }
}

control vrfy(inout Headers h, inout Meta m) { apply {} }
control update(inout Headers h, inout Meta m) { apply {} }

control egress(inout Headers h, inout Meta m, inout standard_metadata_t sm) { apply {} }

control deparser(packet_out b, in Headers h) {
    apply {
        b.emit(h.h1);
        b.emit(h.u);
    }
}

control ingress(inout Headers h, inout Meta m, inout standard_metadata_t sm) {
    action a() { }
    table t {
        key = {
            h.u.isValid() : exact;
        }
        actions = { a; }
        default_action = a;
    }
    apply {
        t.apply();
    }
}

V1Switch(p(), vrfy(), ingress(), egress(), update(), deparser()) main;
|}

let sr_acl_p4_pkt =
  "01 0F 01 AA BB 50 65 74 72 34 20 69 73 20 61 77 65 73 6F 6D 65 21"

let null_pkt = "00 00 00 00 00 00 00 00"

let fs =
  [("/core.p4", core_p4_str);
   ("/v1model.p4", v1model_p4_str);
   ("/sr_acl.p4", sr_acl_p4_str);
   ("/sr_acl.p4.pkt", sr_acl_p4_pkt);
   ("/register.p4", register_p4_str);
   ("/register.p4.pkt", null_pkt);
   ("/switch_ebpf.p4", switch_ebpf_p4_str);
   ("/switch_ebpf.p4.pkt", null_pkt);
   ("/table-entries-lpm-bmv2.p4", table_entries_lpm_bmv2_p4_str);
   ("/table-entries-lpm-bmv2.p4.pkt", null_pkt);
   ("/union-valid-bmv2.p4", union_valid_bmv2_p4_str);
   ("/union-valid-bmv2.p4.pkt", null_pkt)]
