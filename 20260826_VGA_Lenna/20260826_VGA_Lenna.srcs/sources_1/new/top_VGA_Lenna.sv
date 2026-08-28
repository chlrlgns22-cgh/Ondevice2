`timescale 1ns / 1ps
module top_VGA_Lenna (
    input  logic       clk,
    input  logic       rst,
    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] port_red,
    output logic [3:0] port_green,
    output logic [3:0] port_blue
);

    logic        w_h_sync;
    logic        w_v_sync;
    logic [ 9:0] x_pixel;
    logic [ 9:0] y_pixel;
    logic        de;
    logic [16:0] addr;
    logic [15:0] px_data;
    logic [11:0] w_rgb;

    VGA_Decoder U_VGA_DECODER (
        .clk(clk),
        .rst(rst),
        .h_sync(w_h_sync),
        .v_sync(w_v_sync),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .de(de)
    );

    rom_reader U_ROM_READER (
        .clk(clk),
        .rst(rst),
        .de(de),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .px_data(px_data),
        .addr(addr),
        .o_rgb(w_rgb)
    );


    image_rom U_IMAGE_ROM (
        .clk (clk),
        .addr(addr),
        .data(px_data)
    );

    VGA_OutReg U_VGA_OUTREG (
        .clk     (clk),
        .rst     (rst),
        .i_h_sync(w_h_sync),
        .i_v_sync(w_v_sync),
        .i_rgb   (w_rgb),
        .o_h_sync(h_sync),
        .o_v_sync(v_sync),
        .o_rgb   ({port_red, port_green, port_blue})
    );
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
