`timescale 1ns / 1ps
module ov7670_controller (
    input  logic        pclk,
    input  logic        href,
    input  logic        v_sync,
    input  logic [ 7:0] p_data,
    output logic        we,
    output logic [16:0] addr,
    output logic [15:0] data
);
    parameter [1:0] READ1 = 0, READ2 = 1, WRITE = 2;
    logic [16:0] addr_r;
    logic [7:0] data_r, data_r2;

    always_ff @(posedge pclk) begin
        if (pclk) begin
            
        end else begin
             
        end
    end

endmodule
