`timescale 1ns / 1ps

module tb_clk_div ();
    reg clk, rst;
    wire o_1khz;

    clk_div_1khz dut (
        .clk(clk),
        .rst(rst),
        .o_1khz(o_1khz)
    );


    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;

        #20;
        rst = 0;
    end

endmodule
