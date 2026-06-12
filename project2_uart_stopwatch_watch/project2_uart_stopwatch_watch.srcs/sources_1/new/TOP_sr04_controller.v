`timescale 1ns / 1ps

module TOP_sr04_controller(
    input           clk,
    input           rst,
    input           sr04_start,
    input           echo,
    output          trig,
    output [15:0]   sr04_data
);

    wire        w_tick_us;
    wire [8:0]  w_distance;

    wire [3:0]  w_hundreds;
    wire [3:0]  w_tens;
    wire [3:0]  w_ones;

    sr04_controller U_SR04_CNTL (
        .clk        (clk),
        .rst        (rst),
        .sr04_start (sr04_start),
        .tick_us    (w_tick_us),
        .echo       (echo),
        .trig       (trig),
        .distance   (w_distance)
    );
    
    tick_gen_us U_TICK_GEN_US (
        .clk        (clk),
        .rst        (rst),
        .tick_us    (w_tick_us)
    );

    assign w_hundreds = w_distance / 100;
    assign w_tens     = (w_distance % 100) / 10;
    assign w_ones     = w_distance % 10;

    assign sr04_data = {4'd0, w_hundreds, w_tens, w_ones};

endmodule

