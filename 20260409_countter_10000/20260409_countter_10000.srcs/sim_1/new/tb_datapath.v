`timescale 1ns / 1ps

module tb_datapath ();

    reg clk;
    reg rst;
    wire [13:0] tick_counter;

    datapath U_DATAPATH (
        .clk         (clk),
        .rst         (rst),
        .tick_counter(tick_counter)
    );

    always #5 clk = ~clk;

    initial begin
        clk=0;
        rst=1;

        #20;
        rst=0;

        #500_000_000;
        $stop;

    end
endmodule
