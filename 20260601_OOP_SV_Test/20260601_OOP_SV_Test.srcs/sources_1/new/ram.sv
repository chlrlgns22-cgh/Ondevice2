`timescale 1ns / 1ps

module ram (
    input  logic       clk,
    input  logic       we,
    input  logic [7:0] addr,
    input  logic [7:0] wdata,
    output logic [7:0] rdata
);

    logic [7:0] ram_reg[255:0];

    always_ff @(posedge clk) begin
        if (we) begin
            ram_reg[addr] <= wdata;
        end else begin
            rdata <= ram_reg[addr];
        end
    end
endmodule
