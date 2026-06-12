`timescale 1ns / 1ps

module sram (
    input              clk,
    input        [7:0] addr,
    input        [7:0] wdata,
    input              we,
    output logic [7:0] rdata
);

    logic [7:0] ram[0:255];

    always_ff @(posedge clk) begin
        if (we) begin
            ram[addr] <= wdata;
        end
    end

    always_comb begin
        rdata = ram[addr];
    end
endmodule
