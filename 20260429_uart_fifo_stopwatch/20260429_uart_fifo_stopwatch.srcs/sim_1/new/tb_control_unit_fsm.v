`timescale 1ns / 1ps

module tb_control_unit_fsm ();

    reg clk, rst, btnR, btnL, btnD, btnU, sw;
    wire o_run_stop, o_clear, o_mode, o_record, o_view, 
    o_hour,o_min,o_sec,o_hour_up,o_hour_down,o_min_up,o_min_down,o_sec_up,o_sec_down;

    control_unit_fsm dut (
        .clk        (clk),
        .rst        (rst),
        .btnR       (btnR),         // runstop    
        .btnL       (btnL),         // clear
        .btnD       (btnD),         // mode
        .btnU       (btnU),         // re-define
        .sw         (sw),
        .o_run_stop (o_run_stop),   // stopwatch output
        .o_clear    (o_clear),
        .o_mode     (o_mode),
        .o_record   (o_record),
        .o_view     (o_view),
        .o_hour     (o_hour),       // watch output
        .o_min      (o_min),
        .o_sec      (o_sec),
        .o_hour_up  (o_hour_up),
        .o_hour_down(o_hour_down),
        .o_min_up   (o_min_up),
        .o_min_down (o_min_down),
        .o_sec_up   (o_sec_up),
        .o_sec_down (o_sec_down)
    );

    always #5 clk = ~clk;

    initial begin
        clk  = 1'b0;
        rst  = 1'b1;
        btnR = 1'b0;
        btnL = 1'b0;
        btnD = 1'b0;
        btnU = 1'b0;
        sw   = 1'b1;
        #10;
        rst = 1'b0;
        #10;

        // stop -> run
        btnR = 1'b1;
        @(negedge clk);
        @(negedge clk);
        btnR = 1'b0;
        @(negedge clk);
        //@(negedge clk);

        // run -> stop
        btnR = 1'b1;
        @(negedge clk);
        //@(negedge clk);
        btnR = 1'b0;
        @(negedge clk);
        //@(negedge clk);
        
        // stop -> clear -> stop
        btnL = 1'b1;
        @(negedge clk);
        btnL = 1'b0;
        @(negedge clk);

        // o_mode on
        btnD = 1'b1;
        @(negedge clk);
        btnD = 1'b0;
        @(negedge clk);
        @(negedge clk);

        // o_mode off
        btnD = 1'b1;
        @(negedge clk);
        btnD = 1'b0;
        @(negedge clk);

        // stop -> run -> record
        btnR = 1'b1;
        @(negedge clk);
        btnR = 1'b0;
        @(negedge clk);

        btnD = 1'b1;
        @(negedge clk);
        btnD = 1'b0;
        btnU = 1'b1;
        @(negedge clk);
        btnU = 1'b0;
        @(negedge clk);
        
        sw = 1'b0;
        @(negedge clk);
        @(negedge clk);

        // WATCH
        btnR = 1'b1;
        @(negedge clk);
        btnR = 1'b0;
        btnU = 1'b1;
        @(negedge clk);
        btnU = 1'b0;
        btnD = 1'b1;
        @(negedge clk);
        btnD = 1'b0;

        btnR = 1'b1;
        @(negedge clk);
        btnR = 1'b0;
        btnU = 1'b1;
        @(negedge clk);
        btnU = 1'b0;
        btnD = 1'b1;
        @(negedge clk);
        btnD = 1'b0;

        btnR = 1'b1;
        @(negedge clk);
        btnR = 1'b0;
        btnU = 1'b1;
        @(negedge clk);
        btnU = 1'b0;
        btnD = 1'b1;
        @(negedge clk);
        btnD = 1'b0;

        btnR = 1'b1;
        @(negedge clk);
        btnR = 1'b0;
        btnU = 1'b1;
        @(negedge clk);
        btnU = 1'b0;
        btnD = 1'b1;
        @(negedge clk);
        btnD = 1'b0;

        btnL = 1'b1;
        @(negedge clk);
        btnL = 1'b0;
        btnU = 1'b1;
        @(negedge clk);
        btnU = 1'b0;
        btnD = 1'b1;
        @(negedge clk);
        btnD = 1'b0;




        $stop;
    end

endmodule


