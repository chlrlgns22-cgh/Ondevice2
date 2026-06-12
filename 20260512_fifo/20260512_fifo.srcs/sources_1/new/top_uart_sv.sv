`timescale 1ns / 1ps

module top_uart_sv (
    input              clk,
    input              rst,
    input              rx,
    output             tx,
    output       [7:0] rx_data,
    output             rx_done,
    output logic       uart_R,
    output logic       uart_L,
    output logic       uart_U,
    output logic       uart_D,
    output logic       uart_M,
    output logic       uart_S

);

    logic [7:0] w_rx_data, w_rx_pop_data, w_tx_pop_data;
    logic w_rx_done, w_rx_pop_empty, w_tx_push_full, w_tx_pop_empty, w_tx_busy;

    assign rx_data = w_rx_data;
    assign rx_done = w_rx_done;

    uart_sv U_UART_TOP (
        .clk     (clk),
        .rst     (rst),
        .tx_start(~w_tx_pop_empty),
        .tx_data (w_tx_pop_data),
        .rx      (rx),
        .rx_data (w_rx_data),
        .rx_done (w_rx_done),
        .tx_busy (w_tx_busy),
        .tx      (tx)
    );

    fifo_sv U_FIFO_RX (
        .clk      (clk),
        .rst      (rst),
        .push_data(w_rx_data),
        .push     (w_rx_done),
        .pop      (~w_tx_push_full),
        .pop_data (w_rx_pop_data),
        .full     (),
        .empty    (w_rx_pop_empty)
    );
    ascii_decoder U_ASCII_DECODER (
        .clk(clk),
        .rst(rst),
        .pop_data(w_rx_pop_data),
        .empty(w_rx_pop_empty),
        .uart_R(uart_R),
        .uart_L(uart_L),
        .uart_U(uart_U),
        .uart_D(uart_D),
        .uart_M(uart_M),
        .uart_S(uart_S)
    );

    fifo_sv U_FIFO_TX (
        .clk      (clk),
        .rst      (rst),
        .push_data(w_rx_pop_data),
        .push     (~w_rx_pop_empty),
        .pop      (~w_tx_busy),
        .pop_data (w_tx_pop_data),
        .full     (w_tx_push_full),
        .empty    (w_tx_pop_empty)
    );
endmodule
