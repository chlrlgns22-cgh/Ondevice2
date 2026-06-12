`timescale 1ns / 1ps

module tb_register ();
    reg clk, rst;
    reg [7:0] d;
    wire [7:0] q;
    integer i;

    register_8bit dut (
        .clk(clk),
        .rst(rst),
        .d  (d),
        .q  (q)
    );



    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        d   = 8'h00;
        #10;
        rst = 0;

        for (i = 0; i < 256; i = i + 1) begin
            d = i;
            @(negedge clk);
            #6;
        end

        @(negedge clk);
    end
endmodule
