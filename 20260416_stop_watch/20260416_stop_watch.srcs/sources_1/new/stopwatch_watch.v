`timescale 1ns / 1ps
module top_stopwatch_watch (
    input       clk,
    input       rst,
    input       btnR,
    input       btnL,
    input       btnU,
    input       btnD,
    input [1:0] sw,

    output [7:0] fnd_data,
    output [3:0] fnd_com,
    output [1:0] led
);

    parameter MSEC_WIDTH = 7, SEC_WIDTH = 6, MIN_WIDTH = 6, HOUR_WIDTH = 5;

    wire [MSEC_WIDTH-1:0] w_msec, w_msec_stopwatch, w_msec_watch;
    wire [SEC_WIDTH-1:0] w_sec, w_sec_stopwatch, w_sec_watch;
    wire [MIN_WIDTH-1:0] w_min, w_min_stopwatch, w_min_watch;
    wire [HOUR_WIDTH-1:0] w_hour, w_hour_stopwatch, w_hour_watch;
    wire w_run_stop, w_clear, w_mode;
    wire w_btnR, w_btnL, w_btnU, w_btnD;

    // BTN debouncer
    button_debounce U_BTNR (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnR),
        .o_btn(w_btnR)
    );
    button_debounce U_BTNL (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnL),
        .o_btn(w_btnL)
    );
    button_debounce U_BTNU (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnU),
        .o_btn(w_btnU)
    );
    button_debounce U_BTND (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnD),
        .o_btn(w_btnD)
    );

    //------------------------------Control Unit--------------------------------//
    wire w_c_hour, w_c_min, w_c_sec;
    wire w_hour_up, w_hour_down, w_min_up, w_min_down, w_sec_up, w_sec_down;
    // CTRL unit
    control_unit_fsm U_CRTL_UNIT (
        .clk        (clk),
        .rst        (rst),
        .btnR       (w_btnR),
        .btnL       (w_btnL),
        .btnU       (w_btnU),
        .btnD       (w_btnD),
        .sw         (sw[1]),
        .o_run_stop (w_run_stop),
        .o_clear    (w_clear),
        .o_mode     (w_mode),
        // H, M, S control sig
        .o_hour     (w_c_hour),
        .o_min      (w_c_min),
        .o_sec      (w_c_sec),
        // UP, DOWN control sig 
        .o_hour_up  (w_hour_up),
        .o_hour_down(w_hour_down),
        .o_min_up   (w_min_up),
        .o_min_down (w_min_down),
        .o_sec_up   (w_sec_up),
        .o_sec_down (w_sec_down)
    );


    //-------------------------------DATAPATH--------------------------------------//
    // stopwatch datapath
    stopwatch_datapath U_STOPWATCH_DATAPATH (
        .clk       (clk),
        .rst       (rst),
        .i_run_stop(w_run_stop),
        .i_clear   (w_clear),
        .i_mode    (w_mode),
        .msec      (w_msec_stopwatch),
        .sec       (w_sec_stopwatch),
        .min       (w_min_stopwatch),
        .hour      (w_hour_stopwatch)
    );

    // watch datapath
    watch_datapath U_WATCH_DATAPATH (
        .clk        (clk),
        .rst        (rst),
        .i_hour_up  (w_hour_up),
        .i_hour_down(w_hour_down),
        .i_min_up   (w_min_up),
        .i_min_down (w_min_down),
        .i_sec_up   (w_sec_up),
        .i_sec_down (w_sec_down),
        .msec       (w_msec_watch),
        .sec        (w_sec_watch),
        .min        (w_min_watch),
        .hour       (w_hour_watch)
    );

    //-----------------------------FND_data selection-------------------------------??
    fnd_mux #(
        .BIT_WIDTH(5)
    ) U_HOUR_DATA (
        .in0    (w_hour_stopwatch),
        .in1    (w_hour_watch),
        .sel    (sw[1]),
        .out_mux(w_hour)
    );
    fnd_mux #(
        .BIT_WIDTH(6)
    ) U_MIN_DATA (
        .in0    (w_min_stopwatch),
        .in1    (w_min_watch),
        .sel    (sw[1]),
        .out_mux(w_min)
    );
    fnd_mux #(
        .BIT_WIDTH(6)
    ) U_SEC_DATA (
        .in0    (w_sec_stopwatch),
        .in1    (w_sec_watch),
        .sel    (sw[1]),
        .out_mux(w_sec)
    );
    fnd_mux #(
        .BIT_WIDTH(7)
    ) U_MSEC_DATA (
        .in0(w_msec_stopwatch),
        .in1(w_msec_watch),
        .sel(sw[1]),
        .out_mux(w_msec)
    );

    //--------------------------------FND CONTROLLER--------------------------------//

    fnd_controller U_FND_CTRL (
        .clk     (clk),
        .rst     (rst),
        .sw      (sw),     // sw[0], 0: msec_sec, 1: min_hour
        .msec    (w_msec),
        .sec     (w_sec),
        .min     (w_min),
        .hour    (w_hour),
        .h       (w_c_hour),
        .m       (w_c_min),
        .s       (w_c_sec),
        .fnd_com (fnd_com),
        .fnd_data(fnd_data),
        .led     (led[0])
    );

    assign led[1] = sw[1];
endmodule

module fnd_mux #(
    parameter BIT_WIDTH = 7
) (
    input  [BIT_WIDTH -1:0] in0,
    input  [BIT_WIDTH -1:0] in1,
    input                   sel,
    output [BIT_WIDTH -1:0] out_mux
);
    assign out_mux = (sel) ? in0 : in1;

endmodule
