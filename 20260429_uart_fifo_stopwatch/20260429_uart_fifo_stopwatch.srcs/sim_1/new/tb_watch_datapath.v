`timescale 1ns / 100ps
module tb_watch_datapath ();

    parameter MSEC_WIDTH = 7, SEC_WIDTH = 6, MIN_WIDTH = 6, HOUR_WIDTH = 5;

    reg                     clk;
    reg                     rst;
    reg                     i_up;
    reg                     i_down;
    reg                     sel_hour;
    reg                     sel_min;
    reg                     sel_sec;
    wire [ SEC_WIDTH - 1:0] sec;
    wire [ MIN_WIDTH - 1:0] min;
    wire [HOUR_WIDTH - 1:0] hour;

    watch_datapath dut (
        .clk(clk),
        .rst(rst),
        .i_up(i_up),
        .i_down(i_down),
        .sel_hour(sel_hour),
        .sel_min(sel_min),
        .sel_sec(sel_sec),
        .sec(sec),
        .min(min),
        .hour(hour)
    );

    always #5 clk = ~clk;

    initial begin
        clk      = 0;
        rst      = 1;
        i_up     = 0;
        i_down   = 0;
        sel_hour = 0;
        sel_min  = 0;
        sel_sec  = 0;


        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        rst      = 0;
        sel_hour = 0;
        sel_min  = 1;
        sel_sec  = 0;

        repeat (3_000_000) @(negedge clk);
        #5 i_up = 1;
        @(posedge clk);
        i_up = 0;

        repeat (6_000_000) @(negedge clk);
        #5 i_up = 1;
        @(posedge clk);
        i_up = 0;

        repeat (6_000_000) @(negedge clk);
        #5 i_up = 1;
        @(posedge clk);
        i_up = 0;

        repeat (6_000_000) @(negedge clk);
        #5 i_down = 1;
        @(posedge clk);
        i_down = 0;

        repeat (6_000_000) @(negedge clk);
        $stop;



    end

endmodule
