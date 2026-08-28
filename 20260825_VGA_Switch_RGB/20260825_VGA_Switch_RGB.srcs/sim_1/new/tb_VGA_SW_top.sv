`timescale 1ns / 1ps

module tb_VGA_SW_top ();
    logic       clk;
    logic       rst;
    logic       h_sync;
    logic       v_sync;
    logic [3:0] port_red;
    logic [3:0] port_green;
    logic [3:0] port_blue;

    VGA_SW_Top dut (.*);

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        wait (!v_sync);
        @(posedge clk);
        wait (v_sync);
        @(posedge clk);

        wait (!v_sync);
        @(posedge clk);
        wait (v_sync);
        @(posedge clk);

        wait (!v_sync);
        @(posedge clk);
        wait (v_sync);
        @(posedge clk);

        $finish;
    end
endmodule
