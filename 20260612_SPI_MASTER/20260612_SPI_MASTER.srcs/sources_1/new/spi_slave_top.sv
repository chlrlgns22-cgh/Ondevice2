`timescale 1ns / 1ps

module spi_slave_top (
    input  logic       clk,
    input  logic       rst,
    // from master
    input  logic       sclk,
    input  logic       mosi,
    input  logic       ss_n,
    output logic       miso,
    // connect with IP
    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       busy,
    output logic       done
);

    typedef enum logic {
        IDLE = 1'b1,
        DATA
    } slave_state_e;

    slave_state_e state;

    logic [7:0] rx_shift_reg;
    logic [7:0] tx_shift_reg;
    logic [2:0] bit_cnt;


    always_ff @(posedge sclk, negedge rst) begin
        if (rst) begin
            state        <= IDLE;
            miso         <= 1'b1;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            rx_data      <= 0;
            busy         <= 0;
            done         <= 0;
            
        end
        case (state)
            IDLE: begin
                done<=0;
            end
            DATA: begin

            end
        endcase
    end

endmodule
