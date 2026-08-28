`timescale 1ns / 1ps

module rom_reader (
    input  logic        clk,
    input  logic        rst,
    input  logic        de,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic [15:0] px_data,
    output logic [16:0] addr,
    output logic [11:0] o_rgb
);
    logic dispArea, dispArea_d;

    assign dispArea = de && (x_pixel < 640) && (y_pixel < 480);
    assign addr = dispArea ? (320 * (y_pixel>>1) + (x_pixel>>1)) : 0;

    always_ff @( posedge clk, posedge rst ) begin
        if (rst) begin
            dispArea_d <= 1'b0;
        end else begin
            dispArea_d <= dispArea;
        end
    end

    assign o_rgb = dispArea_d ? {px_data[15:12], px_data[10:7], px_data[4:1]} : 0;
endmodule
