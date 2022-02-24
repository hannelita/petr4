/petr4/ci-test/type-checking/testdata/p4_16_samples/invalid-hdr-warnings7.p4
\n
header H1 { bit<32> a; }
header H2 { bit<32> a; }

header_union U {
    H1 h1;
    H2 h2;
}

control ct(inout bit<32> param);
package top(ct _ct);

control c(inout bit<32> x) {
    U u;
    H1[2] hs;
    U[2] us;

    action initialize(out U u1, out H1[2] hs1, out U[2] us1) {
        // all these should be invalid regardless of the actual arguments
        u1.h1.a = 1;
        u1.h2.a = 1;
        hs1[0].a = 1;
        hs1[1].a = 1;
        us1[0].h1.a = 1;
        us1[0].h2.a = 1;

        u1.h1.setValid();
        u1.h2.setValid();
        hs1[0].setValid();
        hs1[1].setValid();
        us1[0].h1.setValid();
        us1[0].h2.setValid();
    }

    action inout_action1(inout U u1, inout H1[2] hs1, inout U[2] us1) {
        // checking if the valid bits have the same values as before the call
        u1.h1.a = 1;        // expected invalid
        u1.h2.a = 1;
        hs1[0].a = 1;
        hs1[1].a = 1;
        us1[0].h1.a = 1;    // expected invalid
        us1[0].h2.a = 1;

        hs1[0].setInvalid();
        u1.h1.setValid();
        us1[0].h1.setValid();
    }

    action inout_action2(inout U u1, inout H1[2] hs1, inout U[2] us1) {
        bit i = 1;
        us1[i].h1.setInvalid();  // no effect (we don't know which union needs to be invalidated)
        us1[i].h2.setValid();    // sets the valid bit of h2 in all unions within the stack
                                 // without invalidating other valid fields
    }

    action xor(in U u1, in H1[2] hs1, in U[2] us1, out bit<32> result) {
        result = u1.h1.a ^ u1.h2.a ^ hs1[0].a ^ hs1[1].a ^ us1[0].h1.a
                 ^ us1[0].h2.a ^ us1[1].h1.a ^ us1[1].h2.a;
    }

    apply @noWarn("uninitialized_use") {
        u.h1.setValid();
        hs[0].setValid();
        us[0].h1.setValid();

        initialize(u, hs, us);

        // checking the result of initialize
        u.h1.a = 1;         // expected invalid
        u.h2.a = 1;
        hs[0].a = 1;
        hs[1].a = 1;
        us[0].h1.a = 1;     // expected invalid
        us[0].h2.a = 1;

        inout_action1(u, hs, us);

        // checking the result of inout_action1
        u.h1.a = 1;
        u.h2.a = 1;        // expected invalid
        hs[0].a = 1;       // expected invalid
        hs[1].a = 1;
        us[0].h1.a = 1;
        us[0].h2.a = 1;    // expected invalid

        inout_action2(u, hs, us);
        xor(u, hs, us, x);
    }
}

top(c()) main;
************************\n******** petr4 type checking result: ********\n************************\n
header H1 {
  bit<32> a;
}
header H2 {
  bit<32> a;
}
header_union U {
  H1 h1;
  H2 h2;
}
control ct (inout bit<32> param);
package top (ct _ct);
control c(inout bit<32> x) {
  U u;
  H1[2] hs;
  U[2] us;
  action initialize(out U u1, out H1[2] hs1, out U[2] us1)
    {
    u1.h1.a = 1;
    u1.h2.a = 1;
    hs1[0].a = 1;
    hs1[1].a = 1;
    us1[0].h1.a = 1;
    us1[0].h2.a = 1;
    u1.h1.setValid();
    u1.h2.setValid();
    hs1[0].setValid();
    hs1[1].setValid();
    us1[0].h1.setValid();
    us1[0].h2.setValid();
  }
  action inout_action1(inout U u1, inout H1[2] hs1, inout U[2] us1)
    {
    u1.h1.a = 1;
    u1.h2.a = 1;
    hs1[0].a = 1;
    hs1[1].a = 1;
    us1[0].h1.a = 1;
    us1[0].h2.a = 1;
    hs1[0].setInvalid();
    u1.h1.setValid();
    us1[0].h1.setValid();
  }
  action inout_action2(inout U u1, inout H1[2] hs1, inout U[2] us1)
    {
    bit<1> i = 1;
    us1[i].h1.setInvalid();
    us1[i].h2.setValid();
  }
  action xor(in U u1, in H1[2] hs1, in U[2] us1, out bit<32> result)
    {
    result =
    u1.h1.a ^ u1.h2.a ^ hs1[0].a ^ hs1[1].a ^ us1[0].h1.a ^ us1[0].h2.a ^ us1[
                                                                    1].h1.a ^ us1[
                                                                    1].h2.a;
  }
  apply
    @noWarn("uninitialized_use")
    {
    u.h1.setValid();
    hs[0].setValid();
    us[0].h1.setValid();
    initialize(u, hs, us);
    u.h1.a = 1;
    u.h2.a = 1;
    hs[0].a = 1;
    hs[1].a = 1;
    us[0].h1.a = 1;
    us[0].h2.a = 1;
    inout_action1(u, hs, us);
    u.h1.a = 1;
    u.h2.a = 1;
    hs[0].a = 1;
    hs[1].a = 1;
    us[0].h1.a = 1;
    us[0].h2.a = 1;
    inout_action2(u, hs, us);
    xor(u, hs, us, x);
  }
}
top(c()) main;

************************\n******** p4c type checking result: ********\n************************\n
/petr4/ci-test/type-checking/testdata/p4_16_samples/invalid-hdr-warnings7.p4(48): [--Wwarn=unused] warning: 'u1' is unused
    action inout_action2(inout U u1, inout H1[2] hs1, inout U[2] us1) {
                                 ^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/invalid-hdr-warnings7.p4(48): [--Wwarn=unused] warning: 'hs1' is unused
    action inout_action2(inout U u1, inout H1[2] hs1, inout U[2] us1) {
                                                 ^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/invalid-hdr-warnings7.p4(19): [--Wwarn=invalid_header] warning: accessing a field of an invalid header u1.h1
        u1.h1.a = 1;
        ^^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/invalid-hdr-warnings7.p4(20): [--Wwarn=invalid_header] warning: accessing a field of an invalid header u1.h2
        u1.h2.a = 1;
        ^^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/invalid-hdr-warnings7.p4(21): [--Wwarn=invalid_header] warning: accessing a field of an invalid header hs1[0]
        hs1[0].a = 1;
        ^^^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/invalid-hdr-warnings7.p4(22): [--Wwarn=invalid_header] warning: accessing a field of an invalid header hs1[1]
        hs1[1].a = 1;
        ^^^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/invalid-hdr-warnings7.p4(23): [--Wwarn=invalid_header] warning: accessing a field of an invalid header us1[0].h1
        us1[0].h1.a = 1;
        ^^^^^^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/invalid-hdr-warnings7.p4(24): [--Wwarn=invalid_header] warning: accessing a field of an invalid header us1[0].h2
        us1[0].h2.a = 1;
        ^^^^^^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/invalid-hdr-warnings7.p4(68): [--Wwarn=invalid_header] warning: accessing a field of an invalid header u.h1
        u.h1.a = 1; // expected invalid
        ^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/invalid-hdr-warnings7.p4(72): [--Wwarn=invalid_header] warning: accessing a field of an invalid header us[0].h1
        us[0].h1.a = 1; // expected invalid
        ^^^^^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/invalid-hdr-warnings7.p4(36): [--Wwarn=invalid_header] warning: accessing a field of an invalid header u1.h1
        u1.h1.a = 1; // expected invalid
        ^^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/invalid-hdr-warnings7.p4(40): [--Wwarn=invalid_header] warning: accessing a field of an invalid header us1[0].h1
        us1[0].h1.a = 1; // expected invalid
        ^^^^^^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/invalid-hdr-warnings7.p4(79): [--Wwarn=invalid_header] warning: accessing a field of an invalid header u.h2
        u.h2.a = 1; // expected invalid
        ^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/invalid-hdr-warnings7.p4(80): [--Wwarn=invalid_header] warning: accessing a field of an invalid header hs[0]
        hs[0].a = 1; // expected invalid
        ^^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/invalid-hdr-warnings7.p4(83): [--Wwarn=invalid_header] warning: accessing a field of an invalid header us[0].h2
        us[0].h2.a = 1; // expected invalid
        ^^^^^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/invalid-hdr-warnings7.p4(56): [--Wwarn=invalid_header] warning: accessing a field of an invalid header u1.h2
        result = u1.h1.a ^ u1.h2.a ^ hs1[0].a ^ hs1[1].a ^ us1[0].h1.a
                           ^^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/invalid-hdr-warnings7.p4(56): [--Wwarn=invalid_header] warning: accessing a field of an invalid header hs1[0]
        result = u1.h1.a ^ u1.h2.a ^ hs1[0].a ^ hs1[1].a ^ us1[0].h1.a
                                     ^^^^^^
/petr4/ci-test/type-checking/testdata/p4_16_samples/invalid-hdr-warnings7.p4(57): [--Wwarn=invalid_header] warning: accessing a field of an invalid header us1[1].h1
                 ^ us1[0].h2.a ^ us1[1].h1.a ^ us1[1].h2.a;
                                 ^^^^^^^^^
