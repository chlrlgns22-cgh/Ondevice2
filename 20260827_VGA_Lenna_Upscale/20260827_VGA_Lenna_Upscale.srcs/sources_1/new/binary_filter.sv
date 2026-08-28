`timescale 1ns / 1ps

module binary_filter (
    input  logic        clk,
    input  logic        rst,
    input  logic        en,
    input  logic        invert,
    input  logic [ 3:0] threshold,
    input  logic        i_h_sync,
    input  logic        i_v_sync,
    input  logic [11:0] i_rgb,
    output logic        o_h_sync,
    output logic        o_v_sync,
    output logic [11:0] o_rgb
);
    logic [3:0] gray;
    logic [11:0] bin_rgb;
    logic over;

    assign gray = i_rgb[11:8];
    assign over = (gray >= threshold) ^ invert;
    assign bin_rgb = over ? 12'hfff : 12'h000;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            o_rgb <= 0;
        end else begin
            o_rgb <= en ? bin_rgb : i_rgb;
        end
    end

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            o_h_sync <= 1'b1;
            o_v_sync <= 1'b1;
        end else begin
            o_h_sync <= i_h_sync;
            o_v_sync <= i_v_sync;
        end
    end
endmodule
