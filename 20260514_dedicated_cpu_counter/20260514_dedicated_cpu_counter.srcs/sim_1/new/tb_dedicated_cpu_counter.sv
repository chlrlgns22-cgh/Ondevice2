`timescale 1ns / 1ps

module tb_dedicated_cpu_counter ();

    logic       clk;
    logic       rst;
    logic [7:0] out;

    dedicated_cpu_counter dut (
        .rst(rst),
        .clk(clk),
        .out(out)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        @(negedge clk);
        @(negedge clk);
        rst = 0;

        repeat (12) @(negedge clk);
        $stop;
    end
endmodule
