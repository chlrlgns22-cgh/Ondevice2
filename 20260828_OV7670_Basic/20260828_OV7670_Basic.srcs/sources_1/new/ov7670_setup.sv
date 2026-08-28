`timescale 1ns / 1ps

module ov7670_setup (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] rx_data,
    input  logic       ack_out,
    input  logic       busy,
    input  logic       done,
    output logic       cmd_start,
    output logic       cmd_write,
    output logic       cmd_read,
    output logic       cmd_stop,
    output logic [7:0] tx_data,
    output logic       ack_in
);

    typedef enum logic [2:0] {
        IDLE = 3'b000,
        START,
        DEVADDR,
        REGADDR,
        DATA,
        STOP
    } setup_state_e;

    setup_state_e       state;

    logic         [7:0] tx_data_reg;
    logic               cmd_start_reg;
    logic               cmd_write_reg;
    logic               cmd_read_reg;
    logic               cmd_stop_reg;

    assign tx_data   = tx_data_reg;
    assign cmd_start = cmd_start_reg;
    assign cmd_write = cmd_write_reg;
    assign cmd_read  = cmd_read_reg;
    assign cmd_stop  = cmd_stop_reg;
    assign ack_in    = 1'b1;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= IDLE;
            cmd_start_reg <= 0;
            cmd_write_reg <= 0;
            cmd_read_reg <= 0;
            cmd_stop_reg <= 0;
            tx_data_reg <= 0;
        end else begin
            cmd_start_reg <= 0;
            cmd_write_reg <= 0;
            cmd_read_reg <= 0;
            cmd_stop_reg <= 0;
            tx_data_reg <= 0;
            case (state)
                IDLE: begin
                    state <= START;
                end
                START: begin
                    cmd_start_reg <= 1;
                    if (done) state <= DEVADDR;
                end
                DEVADDR: begin

                end
                REGADDR: begin

                end
                DATA: begin

                end
                STOP: begin

                end
                default: begin

                end
            endcase
        end
    end

endmodule
