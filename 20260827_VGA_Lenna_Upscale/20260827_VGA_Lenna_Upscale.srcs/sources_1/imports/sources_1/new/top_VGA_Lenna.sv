`timescale 1ns / 1ps
module top_VGA_Lenna (
    input  logic       clk,
    input  logic       rst,
    input  logic       sw_mode,
    input  logic       sw_gray,
    input  logic       sw_binary,
    input  logic       sw_invert,
    input  logic [3:0] sw_thr,
    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] port_red,
    output logic [3:0] port_green,
    output logic [3:0] port_blue
);

    logic w_h_sync, w_h_sync2, w_h_sync3;
    logic w_v_sync, w_v_sync2, w_v_sync3;
    logic [9:0] x_pixel;
    logic [9:0] y_pixel;
    logic       de;
    logic [16:0] rom_addr, qvga_addr, upscale_addr;
    logic [15:0] rom_px_data, qvga_px_data, upscale_px_data;
    logic [11:0] w_rgb, qvga_w_rgb, upscale_w_rgb;
    logic [11:0] gray_rgb, w_rgb2, w_rgb3, w_rgb4;

    VGA_Decoder U_VGA_DECODER (
        .clk    (clk),
        .rst    (rst),
        .h_sync (w_h_sync),
        .v_sync (w_v_sync),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .de     (de)
    );

    rom_reader U_ROM_READER (
        .clk    (clk),
        .rst    (rst),
        .de     (de),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .px_data(qvga_px_data),
        .addr   (qvga_addr),
        .o_rgb  (qvga_w_rgb)
    );

    rom_reader_upscale U_ROM_READER_UPSCALER (
        .clk    (clk),
        .rst    (rst),
        .de     (de),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .px_data(upscale_px_data),
        .addr   (upscale_addr),
        .o_rgb  (upscale_w_rgb)
    );

    assign rom_addr = sw_mode ? upscale_addr : qvga_addr;
    image_rom U_IMAGE_ROM (
        .clk (clk),
        .addr(rom_addr),
        .data(rom_px_data)
    );

    always_comb begin
        qvga_px_data = 0;
        upscale_px_data = 0;
        case (sw_mode)
            1'b0: qvga_px_data = rom_px_data;
            1'b1: upscale_px_data = rom_px_data;
        endcase
    end

    assign w_rgb = sw_mode ? upscale_w_rgb : qvga_w_rgb;



    VGA_OutReg U_VGA_OUTREG (
        .clk     (clk),
        .rst     (rst),
        .i_h_sync(w_h_sync),
        .i_v_sync(w_v_sync),
        .i_rgb   (w_rgb),
        .o_h_sync(w_h_sync2),
        .o_v_sync(w_v_sync2),
        .o_rgb   (w_rgb2)
    );

    // gray_filter U_GRAY_FILTER (
    // .i_rgb(w_rgb2),
    // .o_rgb(gray_rgb)
    // );

    gray_filter_pipe U_GRAY_FILTER_PIPE (
        .clk     (clk),
        .rst     (rst),
        .sw_gray (sw_gray),
        .i_h_sync(w_h_sync2),
        .i_v_sync(w_v_sync2),
        .i_rgb   (w_rgb2),
        .o_h_sync(w_h_sync3),
        .o_v_sync(w_v_sync3),
        .o_rgb   (w_rgb3)
    );

    binary_filter U_BINARY_FILTER (
        .clk      (clk),
        .rst      (rst),
        .en       (sw_binary),
        .invert   (sw_invert),
        .threshold(sw_thr),
        .i_h_sync (w_h_sync3),
        .i_v_sync (w_v_sync3),
        .i_rgb    (w_rgb3),
        .o_h_sync (h_sync),
        .o_v_sync (v_sync),
        .o_rgb    (w_rgb4)
    );

    assign {port_red, port_green, port_blue} = w_rgb4;
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
