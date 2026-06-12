`timescale 1ns / 1ps

module top_uart_stopwatch_watch (
    input        clk,
    input        rst,
    input        rx,
    input  [3:0] sw,
    output       tx
);

    top_uart U_TOP_UART (
        .clk   (clk),
        .rst   (rst),
        .rx    (rx),
        .select(),     //select=1 => watch /select= 0 => stopwatch
        .data  (),     //data of stopwatch or watch
        .uart_R(),
        .uart_L(),
        .uart_U(),
        .uart_D(),
        .uart_M(),
        .uart_S(),
        .tx    (tx)
    );

endmodule
