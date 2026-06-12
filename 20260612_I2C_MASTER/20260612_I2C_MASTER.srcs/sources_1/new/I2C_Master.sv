`timescale 1ns / 1ps

module I2C_Master (
    input logic clk,
    input logic reset,
    // command port
    input logic cmd_start,
    input logic cmd_write,
    input logic cmd_read,
    input logic cmd_stop,
    // internal port
    input logic [7:0] tx_data,
    output logic [7:0] rx_data,
    input logic ack_in,  // read 시 master가 보낼 ACK(0) / NACK(1)
    output logic ack_out,  // write 시 slave로부터 받은 ACK(0)/NACK(1)
    output logic busy,
    output logic done,
    // external i2c port
    output logic scl,
    output logic sda_o,
    input logic sda_i
);
    typedef enum logic [2:0] {
        IDLE = 3'b000,
        START,
        WAIT_CMD,
        DATA,
        DATA_ACK,
        STOP
    } i2c_state_e;
endmodule
