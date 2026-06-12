`timescale 1ns / 1ps

module gd ();
    reg clk;
    reg rst;

    tests dut (
        .clk(clk),
        .rst(rst)
    );

    initial begin
        clk = 0;
    end
endmodule
