`timescale 1ns / 1ps

module top_vga_colorbar (
    input  logic       clk,
    input  logic       rst,
    input  logic       sw_mode,
    input  logic [3:0] sw_red,
    input  logic [3:0] sw_green,
    input  logic [3:0] sw_blue,
    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] port_red,
    output logic [3:0] port_green,
    output logic [3:0] port_blue
);
    logic [ 9:0] x_pixel;
    logic [ 9:0] y_pixel;
    logic        de;

    logic [11:0] w_colorbar_rgb;
    logic [11:0] w_switch_rgb;
    logic [11:0] w_rgb, r_rgb;

    logic w_h_sync, w_v_sync;

    assign port_red   = r_rgb[11:8];
    assign port_green = r_rgb[7:4];
    assign port_blue  = r_rgb[3:0];

    // logic [3:0] cb_red;
    // logic [3:0] cb_green;
    // logic [3:0] cb_blue;
    // logic [3:0] s_red;
    // logic [3:0] s_green;
    // logic [3:0] s_blue;

    // assign port_red   = sw_mode ? s_red : cb_red;
    // assign port_green = sw_mode ? s_green : cb_green;
    // assign port_blue  = sw_mode ? s_blue : cb_blue;

    VGA_Decoder U_VGA_DECODER (
        .clk    (clk),
        .rst    (rst),
        .h_sync (w_h_sync),
        .v_sync (w_v_sync),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .de     (de)
    );

    ColorBar U_ColorBar (
        .x_pixel   (x_pixel),
        .y_pixel   (y_pixel),
        .de        (de),
        .port_red  (w_colorbar_rgb[11:8]),
        .port_green(w_colorbar_rgb[7:4]),
        .port_blue (w_colorbar_rgb[3:0])
    );

    switch_color U_SWITCH_COLOR (
        .sw_red    (sw_red),
        .sw_green  (sw_green),
        .sw_blue   (sw_blue),
        .de        (de),
        .port_red  (w_switch_rgb[11:8]),
        .port_green(w_switch_rgb[7:4]),
        .port_blue (w_switch_rgb[3:0])
    );

    mux U_VGA_MUX (
        .sel(sw_mode),
        .a  (w_switch_rgb),
        .b  (w_colorbar_rgb),
        .y  (w_rgb)
    );

    VGA_OutReg U_VGA_OUTREG (
        .clk     (clk),
        .rst     (rst),
        .i_h_sync(w_h_sync),
        .i_v_sync(w_v_sync),
        .i_rgb   (w_rgb),
        .o_h_sync(h_sync),
        .o_v_sync(v_sync),
        .o_rgb   (r_rgb)
    );
endmodule

module mux (
    input logic sel,
    input logic [11:0] a,
    input logic [11:0] b,
    output logic [11:0] y
);
    assign y = sel ? b : a;
endmodule

module VGA_OutReg (
    input  logic        clk,
    input  logic        rst,
    input  logic        i_h_sync,
    input  logic        i_v_sync,
    input  logic [11:0] i_rgb,
    output logic        o_h_sync,
    output logic        o_v_sync,
    output logic [11:0] o_rgb
);

    logic r_h_sync, r_v_sync;
    logic [11:0] r_rgb;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            r_h_sync <= 1'b1;
            r_v_sync <= 1'b1;
            r_rgb <= 0;
        end else begin
            r_h_sync <= i_h_sync;
            r_v_sync <= i_v_sync;
            r_rgb <= i_rgb;
        end
    end

    assign o_h_sync = r_h_sync;
    assign o_v_sync = r_v_sync;
    assign o_rgb = r_rgb;

endmodule
