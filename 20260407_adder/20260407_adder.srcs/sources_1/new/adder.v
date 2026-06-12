`timescale 1ns / 1ps
module full_adder (
    input  a,
    input  b,
    input  cin,
    output s,
    output c
);
    wire w_s1, w_c1, w_c2;

    assign c = w_c1 | w_c2;

    half_adder U_HA0 (
        .a(a),  //from full_adder input a
        .b(b),  //from full_adder input b
        .s(w_s1),
        .c(w_c1)
    );
    half_adder U_HA1 (
        .a(w_s1),
        .b(cin),  //from full_adder input cin
        .s(s),  //to full_adder output c
        .c(w_c2)
    );
endmodule

module half_adder (
    input  a,
    input  b,
    output s,
    output c
);

    //assign s = a ^ b;
    //assign c = a & b;
    xor (s, a, b);
    and (c, a, b);
endmodule
