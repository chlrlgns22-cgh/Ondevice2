`timescale 1ns / 1ps
module top_stopwatch_watch (
    input       clk,
    input       rst,

    // control unit fsm에서 받아온 stopwatch 동작 신호
    input       i_run_stop,
    input       i_clear,
    input       i_mode,
    input       i_record,
    input       i_view,

    // control unit fsm에서 받아온 watch 동작 신호
    input       i_hour_up,
    input       i_hour_down,
    input       i_min_up,
    input       i_min_down,
    input       i_sec_up,
    input       i_sec_down,

    output [6:0] msec_stopwatch,
    output [5:0] sec_stopwatch,
    output [5:0] min_stopwatch,
    output [4:0] hour_stopwatch,

    output [6:0] msec_watch,
    output [5:0] sec_watch,
    output [5:0] min_watch,
    output [4:0] hour_watch,

    output [31:0] stopwatch_data,
    output [31:0] watch_data

);

    parameter MSEC_WIDTH = 7, SEC_WIDTH = 6, MIN_WIDTH = 6, HOUR_WIDTH = 5;

    //-------------------------------DATAPATH--------------------------------------//
    // stopwatch datapath
    stopwatch_datapath U_STOPWATCH_DATAPATH (
        .clk       (clk),
        .rst       (rst),
        .i_run_stop(i_run_stop),
        .i_clear   (i_clear),
        .i_mode    (i_mode),
        .i_record  (i_record),
        .i_view    (i_view),
        .msec      (msec_stopwatch),
        .sec       (sec_stopwatch),
        .min       (min_stopwatch),
        .hour      (hour_stopwatch)
    );

    // watch datapath
    watch_datapath U_WATCH_DATAPATH (
        .clk        (clk),
        .rst        (rst),
        .i_hour_up  (i_hour_up),
        .i_hour_down(i_hour_down),
        .i_min_up   (i_min_up),
        .i_min_down (i_min_down),
        .i_sec_up   (i_sec_up),
        .i_sec_down (i_sec_down),
        .msec       (msec_watch),
        .sec        (sec_watch),
        .min        (min_watch),
        .hour       (hour_watch)
    );

    assign stopwatch_data = {8'd0, hour_stopwatch, min_stopwatch, sec_stopwatch, msec_stopwatch};
    assign watch_data = {8'd0, hour_watch, min_watch, sec_watch, msec_watch};


endmodule
