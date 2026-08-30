`timescale 1ns / 1ps

module top_OV7670 #(
    parameter IMG_W = 320,
    parameter IMG_H = 240,
    parameter DW    = 16,
    parameter AW    = $clog2(IMG_W * IMG_H)
) (
    input logic clk,
    input logic rst,
    //ov7670 side
    input logic pclk,
    input logic cam_href,
    input logic cam_vsync,
    input logic [7:0] cam_data,
    output logic xclk,
    output logic scl,
    inout logic sda,
    //vga side
    output logic h_sync,
    output logic v_sync,
    output logic [3:0] port_red,
    output logic [3:0] port_green,
    output logic [3:0] port_blue
);

    logic          we;
    logic [AW-1:0] wAddr;
    logic [DW-1:0] wData;

    logic [AW-1:0] rAddr;
    logic [DW-1:0] rData;


    logic [   9:0] x_pixel;
    logic [   9:0] y_pixel;
    logic          de;
    logic [  11:0] w_rgb;
    logic          w_h_sync;
    logic          w_v_sync;

    pclk_gen U_CAM_CLK_GEN (
        .clk (clk),
        .rst (rst),
        .pclk(xclk)
    );
    ov7670_mem_controller U_OV7670_MEM_CONTROLLER (
        .pclk     (pclk),
        .rst      (rst),
        .cam_href (cam_href),
        .cam_vsync(cam_vsync),
        .cam_data (cam_data),
        .we       (we),
        .wAddr    (wAddr),
        .wData    (wData)
    );

    framebuffer U_FRAMEBUFFER (
        //write side(camera,pclk)
        .wclk (pclk),
        .we   (we),
        .waddr(wAddr),
        .wdata(wData),
        //read side(VGA,clk)
        .rclk (clk),
        .raddr(rAddr),
        .rdata(rData)
    );

    VGA_Decoder U_VGA_DECODER (
        .clk    (clk),
        .rst    (rst),
        .h_sync (w_h_sync),
        .v_sync (w_v_sync),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .de     (de)
    );


    framebuffer_reader U_FRAMEBUFFER_READER (
        .clk    (clk),
        .rst    (rst),
        .de     (de),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .px_data(rData),
        .addr   (rAddr),
        .o_rgb  (w_rgb)
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

    sccb_controller U_SCCB_CONTROLLER (
        .clk(clk),
        .rst(rst),
        .scl(scl),
        .sda(sda)
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

module xclk_gen (
    input  logic clk,
    input  logic rst,
    output logic xclk
);

    logic x_counter;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            x_counter <= 1'b0;
            xclk <= 1'b0;
        end else begin
            if (x_counter == 1'b1) begin
                xclk <= 1'b1;
                x_counter <= 1'b0;
            end else begin
                x_counter <= x_counter + 1;
                xclk <= 1'b0;
            end
        end
    end

endmodule
