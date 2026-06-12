`timescale 1ns / 1ps

module tb_dedicated_cpu();

    logic       clk;
    logic       rst;
    logic [7:0] out;


dedicated_cpu dut(.*);

always #5 clk = ~clk;

initial begin
    clk =0;
    rst=1;
    repeat (2) @(negedge clk);
    rst=0;
    #500;
    $stop;
end 

endmodule
