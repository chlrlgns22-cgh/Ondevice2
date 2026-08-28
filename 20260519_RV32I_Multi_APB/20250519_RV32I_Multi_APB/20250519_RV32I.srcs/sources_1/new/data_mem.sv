`timescale 1ns / 1ps
`include "define.vh"

module data_mem (
    input  logic        clk,
    input  logic        dwe,
    input  logic [ 2:0] mem_mode,
    input  logic [31:0] daddr,
    input  logic [31:0] dwdata,
    output logic [31:0] drdata
);

    logic [31:0] data_ram[0:63];

    always_ff @(posedge clk) begin
        if (dwe) begin
            case (mem_mode)
                `SW:  // SW
                data_ram[daddr[31:2]] <= dwdata;
            endcase
        end

    end

    assign drdata = data_ram[daddr[31:2]];

endmodule
