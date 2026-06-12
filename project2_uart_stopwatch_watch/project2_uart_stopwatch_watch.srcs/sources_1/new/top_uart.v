`timescale 1ns / 1ps

module top_uart (
    input         clk,
    input         rst,
    input         rx,
    input  [ 1:0] select,  //select=1 => watch /select= 0 => stopwatch
    input  [31:0] data,    //data of stopwatch or watch
    output        uart_R,
    output        uart_L,
    output        uart_U,
    output        uart_D,
    output        uart_M,
    output        tx
);

    wire [7:0] w_rx_data, w_pop_data_rx, w_pop_data_tx, w_push_data;
    wire w_rx_done, w_empty_rx, w_empty_tx;
    wire w_push, w_tx_busy, w_uart_S;
    assign w_pop_tx = !w_empty_tx && !w_tx_busy;

    uart U_UART (
        .clk(clk),
        .rst(rst),
        .tx_start(!w_empty_tx && !w_tx_busy),
        .tx_data(w_pop_data_tx),
        .rx(rx),
        .rx_data(w_rx_data),  //to FIFO_RX
        .rx_done(w_rx_done),
        .tx_busy(w_tx_busy),
        .tx(tx)
    );

    fifo U_FIFO_RX (
        .clk(clk),
        .rst(rst),
        .push_data(w_rx_data),
        .push(w_rx_done),
        .pop(~w_empty_rx),
        .pop_data(w_pop_data_rx),  // to ASCII_DECODER
        .full(),
        .empty(w_empty_rx)
    );

    ascii_decoder U_ASCII_DECODER (
        .clk     (clk),
        .rst     (rst),
        .pop_data(w_pop_data_rx),
        .empty   (w_empty_rx),
        .uart_R  (uart_R),         // btn R
        .uart_L  (uart_L),         // btn L
        .uart_U  (uart_U),         // btn U
        .uart_D  (uart_D),         // btn D
        .uart_M  (uart_M),         // stopwatch/watch mode
        .uart_S  (w_uart_S)          // status
    );

    ascii_sender U_ASCII_SENDER (
        .clk(clk),
        .rst(rst),
        .start(w_uart_S),
        .select(select),     //select=1 => watch /select= 0 => stopwatch
        .data(data),
        .push_data(w_push_data),
        .push(w_push)
    );

    fifo #(
        .DEPTH(21)
    ) U_FIFO_TX (
        .clk(clk),
        .rst(rst),
        .push_data(w_push_data),
        .push(w_push),
        .pop(w_pop_tx),
        .pop_data(w_pop_data_tx),
        .full(),
        .empty(w_empty_tx)
    );
endmodule
