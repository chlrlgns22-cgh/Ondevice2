`timescale 1ns / 1ps

module image_rom (
    input  logic        clk,
    input  logic [16:0] addr,
    output logic [15:0] data
);
    logic [15:0] mem[0:320*240-1];
    initial $readmemh("Lenna_320x240.mem", mem);

    always_ff @(posedge clk) begin
    data <= mem[addr];
    end

    // assign data = mem[addr];
endmodule
