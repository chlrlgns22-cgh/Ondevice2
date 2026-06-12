`timescale 1ns / 1ps

module top_fnd (
    input         clk,
    input         rst,
    input         btnR,
    input         btnL,
    input         btnU,
    input         btnD,
    input         uart_R,
    input         uart_L,
    input         uart_U,
    input         uart_D,
    input  [ 3:0] sw,
    output [ 1:0] select,
    output [31:0] watch_data,
    output [15:0] temp_humidity,
    output [11:0] distance,
    output [ 3:0] fnd_com,
    output [ 7:0] fnd_data,

    output [2:0] led
);

    parameter MSEC_WIDTH = 7, SEC_WIDTH = 6, MIN_WIDTH = 6, HOUR_WIDTH = 5;

    wire [MSEC_WIDTH-1:0] w_msec, w_msec_stopwatch, w_msec_watch;
    wire [SEC_WIDTH-1:0] w_sec, w_sec_stopwatch, w_sec_watch;
    wire [MIN_WIDTH-1:0] w_min, w_min_stopwatch, w_min_watch;
    wire [HOUR_WIDTH-1:0] w_hour, w_hour_stopwatch, w_hour_watch;
    wire w_run_stop, w_clear, w_mode, w_record, w_view;
    wire w_btnR, w_btnL, w_btnU, w_btnD;
    wire w_sr04_start, w_dht11_start;
    wire [15:0] w_sr04_data, w_dht11_data;
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


    control_unit_fsm U_CRTL_UNIT_FSM (
        .clk(clk),
        .rst(rst),
        .btnR(w_btnR),  // runstop
        .btnL(w_btnL),  // clear
        .btnD(w_btnD),  // mode
        .btnU(w_btnU),  // re-define
        .sw({
            sw[3], sw[1]
        }),  // sw[3],sw[1] 00:stopwatch 01:watch 10: sr04 11:dht11
        .uart_R(uart_R),  //uart_input       
        .uart_L(uart_L),  //uart_input
        .uart_U(uart_U),  //uart_input
        .uart_D(uart_D),  //uart_input
        .uart_M(uart_M),  //uart_input
        .o_run_stop(w_run_stop),  // stopwatch output
        .o_clear(w_clear),
        .o_mode(w_mode),
        .o_record(w_record),
        .o_view(w_view),
        .o_hour(w_c_hour),  // watch output
        .o_min(w_c_min),
        .o_sec(w_c_sec),
        .o_hour_up(w_hour_up),
        .o_hour_down(w_hour_down),
        .o_min_up(w_min_up),
        .o_min_down(w_min_down),
        .o_sec_up(w_sec_up),
        .o_sec_down(w_sec_down),
        .sr04_start(w_sr04_start),  //sr04_input   
        .dht11_start(w_dht11_start),  //dht11_input
        .select(select)
    );

    //-------------------------------DATAPATH--------------------------------------//
    // stopwatch datapath
    stopwatch_datapath U_STOPWATCH_DATAPATH (
        .clk       (clk),
        .rst       (rst),
        .i_run_stop(w_run_stop),
        .i_clear   (w_clear),
        .i_mode    (w_mode),
        .i_record  (w_record),
        .i_view    (w_view),
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
    //---------------------------SR04-------------------------------------------//
    TOP_sr04_controller U_TOP_SR04_CONTROLLER (
        .clk(clk),
        .rst(rst),
        .sr04_start(w_sr04_start),
        .echo(),
        .trig(),
        .sr04_data()
    );

    //-------------------------------DHT11---------------------------------------//
    dht11_top U_DHT11_TOP (
        .clk(clk),
        .rst(rst),
        .dht11_start(dht11_start),
        .dht11_data(dht11_data),
        .valid(),
        .dht11_io()

    );

    //---------------------------------FND_CONTROLLER----------------------------//
    fnd_controller U_FND_CNTL (
        .clk           (clk),
        .rst           (rst),
        .sw            (sw),                // sw[0], 0: msec_sec, 1: min_hour
        .msec_stopwatch(w_msec_stopwatch),
        .sec_stopwatch (w_sec_stopwatch),
        .min_stopwatch (w_min_stopwatch),
        .hour_stopwatch(w_hour_stopwatch),
        .msec_watch    (w_msec_watch),
        .sec_watch     (w_sec_watch),
        .min_watch     (w_min_watch),
        .hour_watch    (w_hour_watch),
        .h             (w_c_hour),
        .m             (w_c_min),
        .s             (w_c_sec),
        .fnd_com       (fnd_com),
        .fnd_data      (fnd_data),
        .led           (led)                // ON: hour, min  OFF: msec,sec
    );

    assign led[1] = sw[1];

endmodule


module mux_4x1 #(
    BIT_WIDTH = 31
) (
    input      [        1:0] sw,
    input      [BIT_WIDTH:0] watch_data,
    input      [BIT_WIDTH:0] stopwatch_data,
    input      [BIT_WIDTH:0] sr04_data,
    input      [BIT_WIDTH:0] dht11_data,
    output reg [        1:0] sel,
    output reg [BIT_WIDTH:0] mux_data
);

    always @(*) begin
        // 2-bit selection signal
        if (sw[1] == 1'b0) begin
            if (sw[0] == 1'b0) sel = 2'b00;  // watch
            else sel = 2'b01;  // stopwatch
        end else begin
            if (sw[0] == 1'b0) sel = 2'b10;  // sr04
            else sel = 2'b11;  // dht11
        end

        case (sel)
            2'b00: mux_data = watch_data;
            2'b01: mux_data = stopwatch_data;
            2'b10: mux_data = sr04_data;
            2'b11: mux_data = dht11_data;
        endcase
    end

endmodule
