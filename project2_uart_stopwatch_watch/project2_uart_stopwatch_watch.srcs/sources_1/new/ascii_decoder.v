`timescale 1ns / 1ps

module ascii_decoder (
    input            clk,
    input            rst,
    input      [7:0] pop_data,
    input            empty,
    output reg       uart_R,
    output reg       uart_L,
    output reg       uart_U,
    output reg       uart_D,
    output reg       uart_M,
    output reg       uart_S
);

    always @(*) begin
        uart_R = 1'b0;
        uart_L = 1'b0;
        uart_U = 1'b0;
        uart_D = 1'b0;
        uart_M = 1'b0;
        uart_S = 1'b0;
        if (!empty) begin
            case (pop_data)
                8'h52: uart_R = 1'b1;
                8'h4C: uart_L = 1'b1;
                8'h55: uart_U = 1'b1;
                8'h44: uart_D = 1'b1;
                8'h4D: uart_M = 1'b1;
                8'h53: uart_S = 1'b1;
            endcase
        end
    end
endmodule
