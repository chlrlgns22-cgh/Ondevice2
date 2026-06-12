`timescale 1ns / 1ps

module register_8bit(
    input clk,
    input rst,
    input [7:0] d,
    output [7:0] q
    );

    reg [7:0] q_req;
    assign q = q_req;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            q_req <= 8'h00;
        end else begin
            q_req <= d;
        end
    end
endmodule
