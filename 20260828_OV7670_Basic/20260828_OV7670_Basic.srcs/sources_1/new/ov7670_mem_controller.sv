`timescale 1ns / 1ps

module ov7670_mem_controller #(
    parameter IMG_W = 320,
    parameter IMG_H = 240,
    parameter DW    = 16,
    parameter AW    = $clog2(IMG_W * IMG_H)
) (
    input  logic          pclk,
    input  logic          rst,
    input  logic          cam_href,
    input  logic          cam_vsync,
    input  logic [   7:0] cam_data,
    output logic          we,
    output logic [AW-1:0] wAddr,
    output logic [DW-1:0] wData
);
    logic        byteSel;
    logic [15:0] px_data;

    assign wData = px_data;

    always_ff @(posedge pclk, posedge rst) begin
        if (rst) begin
            wAddr   <= 0;
            byteSel <= 1'b0;
            px_data <= 16'b0;
            we      <= 1'b0;
        end else begin
            we <= 1'b0;
            if (we) wAddr <= wAddr + 1;
            if (cam_vsync) begin
                wAddr   <= 0;
                byteSel <= 1'b0;
            end
            if (cam_href) begin
                byteSel <= ~byteSel;
                if (!byteSel) begin
                    px_data[15:8] <= cam_data;
                end else begin
                    px_data[7:0] <= cam_data;
                    we <= 1'b1;
                end
            end
        end
    end
endmodule
