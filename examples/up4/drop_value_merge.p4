error {
  NoError, PacketTooShort, NoMatch, StackOutOfBounds, HeaderTooShort,
  ParserTimeout, ParserInvalidArgument
}
match_kind {
  exact, ternary, lpm
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
action NoAction() { 
}
typedef bit<9> PortId_t;
typedef bit<16> PktInstId_t;
typedef bit<16> GroupId_t;
const PortId_t PORT_CPU = 255;
const PortId_t PORT_RECIRCULATE = 254;
enum metadata_fields_t {
  QUEUE_DEPTH_AT_DEQUEUE
}
extern im_t {
  void set_out_port(in PortId_t out_port);
  PortId_t get_in_port();
  PortId_t get_out_port();
  bit<32> get_value(metadata_fields_t field_type);
  void drop();
}

action msa_no_action() { 
}
parser micro_parser<H, M, I, IO>
  (packet_in packet,
   im_t im,
   out H hdrs,
   inout M meta,
   in I in_param,
   inout IO inout_param);
control micro_control<H3, M4, I5, O, IO6>
  (im_t im,
   inout H3 hdrs,
   inout M4 meta,
   in I5 in_param,
   out O out_param,
   inout IO6 inout_param);
control micro_deparser<H7> (packet_out packet, in H7 hdrs);
package uP4Switch<H8, M9, I10, O11, IO12>
  (micro_parser<H8, M9, I10, IO12> p,
   micro_control<H8, M9, I10, O11, IO12> c,
   micro_deparser<H8> d);
package uP4Merge<H1, M1, I1, O1, IO1, H2, M2, I2, O2, IO2>
  (uP4Switch<H1, M1, I1, O1, IO1> left,
   uP4Switch<H2, M2, I2, O2, IO2> right,
   int split_port);
header head {
  bit<8> v;
}
struct metadata {
  
}
struct in_param_t {
  
}
struct out_param_t {
  
}
parser MyParser1(packet_in packet, im_t im, out head[13] hdrs,
                 inout metadata meta, in in_param_t in_param,
                 inout error parser_error) {
  state start
    {
    packet.extract(hdrs[0]);
    transition select(packet.lookahead<bit<8>>()) {
      42: next;
      _: reject;
    }
  }
  state next
    {
    hdrs.push_front(1);
    packet.extract(hdrs[0]);
    transition select(packet.lookahead<bit<8>>()) {
      42: next;
      33: final;
      _: reject;
    }
  }
  state final
    {
    hdrs.push_front(1);
    packet.extract(hdrs[0]);
    parser_error = error.NoError;
    transition accept;
  }
}
control MyControl1(im_t im, inout head[13] hdrs, inout metadata meta,
                   in in_param_t in_param, out out_param_t out_param,
                   inout error parser_error) {
  apply
    {
    im.drop();
    if (parser_error==error.NoError)
      {
      hdrs[0] = {72};
      hdrs[1] = {101};
      hdrs[2] = {108};
      hdrs[3] = {108};
      hdrs[4] = {111};
      hdrs[5] = {44};
      hdrs[6] = {32};
      hdrs[7] = {87};
      hdrs[8] = {111};
      hdrs[9] = {114};
      hdrs[10] = {108};
      hdrs[11] = {100};
      hdrs[12] = {33};
    }
  }
}
control MyDeparser1(packet_out packet, in head[13] hdr) {
  apply {
    packet.emit(hdr[0]);
    packet.emit(hdr);
  }
}
uP4Switch(MyParser1(), MyControl1(), MyDeparser1()) main1;
header head {
  bit<8> v;
}
struct metadata {
  
}
struct in_param_t {
  
}
struct out_param_t {
  
}
parser MyParser2(packet_in packet, im_t im, out head[13] hdrs,
                 inout metadata meta, in in_param_t in_param,
                 inout error parser_error) {
  state start
    {
    packet.extract(hdrs[0]);
    transition select(packet.lookahead<bit<8>>()) {
      42: next;
      _: reject;
    }
  }
  state next
    {
    hdrs.push_front(1);
    packet.extract(hdrs[0]);
    transition select(packet.lookahead<bit<8>>()) {
      42: next;
      33: final;
      _: reject;
    }
  }
  state final
    {
    hdrs.push_front(1);
    packet.extract(hdrs[0]);
    parser_error = error.NoError;
    transition accept;
  }
}
control MyControl2(im_t im, inout head[13] hdrs, inout metadata meta,
                   in in_param_t in_param, out out_param_t out_param,
                   inout error parser_error) {
  apply
    {
    if (parser_error==error.NoError)
      {
      hdrs[0] = {72};
      hdrs[1] = {101};
      hdrs[2] = {108};
      hdrs[3] = {108};
      hdrs[4] = {111};
      hdrs[5] = {44};
      hdrs[6] = {32};
      hdrs[7] = {87};
      hdrs[8] = {111};
      hdrs[9] = {114};
      hdrs[10] = {108};
      hdrs[11] = {100};
      hdrs[12] =
      {(bit<8>) im.get_value(metadata_fields_t.QUEUE_DEPTH_AT_DEQUEUE)};
    }
  }
}
control MyDeparser2(packet_out packet, in head[13] hdr) {
  apply {
    packet.emit(hdr[0]);
    packet.emit(hdr);
  }
}
uP4Switch(MyParser2(), MyControl2(), MyDeparser2()) main2;
parser NewParser(packet_in packet, im_t im, out head[13] hdrs,
                 inout metadata meta, in in_param_t in_param,
                 inout error parser_error) {
  MyParser2() parser2;
  MyParser1() parser1;
  state low_ports_state
    {
    MyParser1.apply(packet, im, hdrs, meta, in_param, parser_error);
    transition accept;
  }
  state high_ports_state
    {
    MyParser2.apply(packet, im, hdrs, meta, in_param, parser_error);
    transition accept;
  }
  state start
    {
    transition select(im.get_in_port()) {
      0 .. 8: low_ports_state;
      9 .. 65353: high_ports_state;
    }
  }
}
control NewControl(im_t im, inout head[13] hdrs, inout metadata meta,
                   in in_param_t in_param, out out_param_t out_param,
                   inout error parser_error) {
  MyControl2() control2;
  MyControl1() control1;
  apply
    {
    if (im.get_in_port()<=8)
      
      control1.apply(im, hdrs, meta, in_param, out_param, parser_error);
      else
        control2.apply(im, hdrs, meta, in_param, out_param, parser_error);
  }
}
control NewDeparser(packet_out packet, in head[13] hdr) {
  apply
    {
    packet.emit(hdr[0]);
    packet.emit(hdr);
    packet.emit(hdr[0]);
    packet.emit(hdr);
  }
}
uP4Switch(NewParser(), NewControl(), NewDeparser()) main;
