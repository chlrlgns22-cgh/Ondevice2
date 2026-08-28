`timescale 1ns / 1ps

module VGA_SW_Top (
    input  logic       clk,
    input  logic       rst,
    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] port_red,
    output logic [3:0] port_green,
    output logic [3:0] port_blue
);

    logic [9:0] x_pixel;
    logic [9:0] y_pixel;
    logic        de;

    VGA_Decoder U_VGA_Decoder (
        .clk(clk),
        .rst(rst),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .de(de)
    );

    VGA_RGB_SW U_VGA_RGB_SW (
        .de(de),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .port_red(port_red),
        .port_green(port_green),
        .port_blue(port_blue)
    );

endmodule
