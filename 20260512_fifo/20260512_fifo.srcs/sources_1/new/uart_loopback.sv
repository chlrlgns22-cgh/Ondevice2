`timescale 1ns / 1ps

module uart_loopback_sv (
    input        clk,
    input        rst,
    input        rx,
    output       tx,
    output [7:0] rx_data,
    output       rx_done
);

    logic [7:0] w_rx_data;
    logic w_tx_start;

    assign rx_data = w_rx_data;
    assign rx_done = w_tx_start;

    uart_sv U_UART_TOP (
        .clk(clk),
        .rst(rst),
        .tx_start(w_tx_start),
        .tx_data(w_rx_data),
        .rx(rx),
        .rx_data(w_rx_data),
        .rx_done(w_tx_start),
        .tx_busy(),
        .tx(tx)
    );

endmodule
