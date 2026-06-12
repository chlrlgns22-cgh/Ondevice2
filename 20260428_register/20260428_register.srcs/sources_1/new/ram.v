`timescale 1ns / 1ps

module ram (
    input        clk,
    input  [3:0] addr,
    input  [7:0] wdata,
    input        we,
    output [7:0] rdata
);

    reg [7:0] ram[0:15];

    always @(posedge clk) begin
        if (we) begin
            //write to ram
            ram[addr] <= wdata;
        end
        //else begin
        //     //read from ram
        //     //SL output
        //     rdata <= ram[addr];
        // end
    end

    assign rdata = ram[addr];

endmodule
