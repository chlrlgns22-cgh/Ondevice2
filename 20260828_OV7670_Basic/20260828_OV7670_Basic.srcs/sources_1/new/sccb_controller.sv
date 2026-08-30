`timescale 1ns / 1ps

module sccb_controller (
    input clk,
    input rst,
    output logic scl,
    inout logic sda
);

    logic cmd_start, cmd_write, cmd_read, cmd_stop;
    logic [7:0] tx_data;
    logic [7:0] rx_data;
    logic ack_in, ack_out;
    logic busy, done;

    ov7670_setup U_SETUP (
        .clk(clk),
        .rst(rst),
        .ack_out(ack_out),
        .busy(busy),
        .done(done),
        .cmd_start(cmd_start),
        .cmd_write(cmd_write),
        .cmd_read(cmd_read),
        .cmd_stop(cmd_stop),
        .tx_data(tx_data),
        .ack_in(ack_in)
    );


    I2C_Master_top U_I2C (
        .clk(clk),
        .rst(rst),
        // command port
        .cmd_start(cmd_start),
        .cmd_write(cmd_write),
        .cmd_read(cmd_read),
        .cmd_stop(cmd_stop),
        // internal port
        .tx_data(tx_data),
        .rx_data(rx_data),
        .ack_in(ack_in),  // read 시 master가 보낼 ACK(0) / NACK(1)
        .ack_out(ack_out),  // write 시 slave로부터 받은 ACK(0)/NACK(1)
        .busy(busy),
        .done(done),
        // external i2c port
        .scl(scl),
        .sda(sda)
    );
endmodule
