`timescale 1ns / 1ps

module tb_adder ();

    reg a, b, cin;
    wire s, c;
    //instaciation
    //dut : design under test
    //uut : unit under test
    full_adder dut (
        .a  (a),
        .b  (b),
        .cin(cin),
        .s  (s),
        .c  (c)
    );
    initial begin
        //unit time control

        a   = 0;
        b   = 0;
        cin = 0;
        #10;
        a   = 0;
        b   = 1;
        cin = 0;
        #10;
        a   = 1;
        b   = 0;
        cin = 0;
        #10;
        a   = 1;
        b   = 1;
        cin = 0;
        #10;
        a   = 0;
        b   = 0;
        cin = 1;
        #10;
        a   = 0;
        b   = 1;
        cin = 1;
        #10;
        a   = 1;
        b   = 0;
        cin = 1;
        #10;
        a   = 1;
        b   = 1;
        cin = 1;
        #10;
        $stop;
    end
endmodule
