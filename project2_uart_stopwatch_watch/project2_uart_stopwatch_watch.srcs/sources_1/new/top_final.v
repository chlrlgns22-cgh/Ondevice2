`timescale 1ns / 1ps

module top_final (
    input clk,
    input rst,
    input rx,
    input btnR,
    input btnL,
    input btnU,
    input btnD,
    input echo,
    input [3:0] sw,

    inout dht11_io,

    output tx,
    output trig,
    output [3:0] fnd_com,
    output [7:0] fnd_data,
    output [2:0] led
);
    wire [31:0] w_watchdata, w_mux_data;
    wire [15:0] w_temp_humidity, w_distance;
    wire w_uart_R, w_uart_L, w_uart_U, w_uart_D, w_uart_M;
    wire [1:0] w_sel;

    top_uart U_TOP_UART (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .select(w_sel),  //select=00 => watch /select= 01 => stopwatch / 10: sr04 11:dht11
        .data(w_mux_data),  //data of stopwatch or watch
        .uart_R(w_uart_R),
        .uart_L(w_uart_L),
        .uart_U(w_uart_U),
        .uart_D(w_uart_D),
        .uart_M(w_uart_M),
        .tx(tx)
    );

    top_fnd U_TOP_FND (
        .clk(clk),
        .rst(rst || w_uart_M),
        .btnR(btnR),
        .btnL(btnL),
        .btnU(btnU),
        .btnD(btnD),
        .uart_R(w_uart_R),
        .uart_L(w_uart_L),
        .uart_U(w_uart_U),
        .uart_D(w_uart_D),
        .uart_M(w_uart_M),
        .echo(echo),
        .sw(sw),
        .dht11_io(dht11_io),
        .watchdata(w_watchdata),
        .temp_humidity(w_temp_humidity),
        .distance(w_distance),
        .trig(trig),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data),
        .led(led)
    );
    mux_3x1 U_MUX_3X1_data (
        .sw        ({sw[3], sw[1]}),            // sw= {sw[3],sw[1]}
        .watchdata (w_watchdata),
        .sr04_data ({16'h0, w_distance}),       // {16'h0, distance}
        .dht11_data({16'h0, w_temp_humidity}),  // {16'h0,temp/humidity}
        .sel       (w_sel),
        .mux_data  (w_mux_data)
    );
endmodule
module mux_3x1 (
    input      [ 1:0] sw,          // sw= {sw[3],sw[1]}
    input      [31:0] watchdata,
    input      [31:0] sr04_data,   // {16'h0000, distance}
    input      [31:0] dht11_data,  // {16'h0000,temp/humidity}
    output reg [ 1:0] sel,
    output reg [31:0] mux_data
);

    always @(*) begin
        // 2-bit selection signal
        if (sw[1] == 1'b0) begin
            if (sw[0] == 1'b0) sel = 2'b00;  // watch
            else sel = 2'b01;  // stopwatch
        end else begin
            if (sw[0] == 1'b0) sel = 2'b10;  // sr04
            else sel = 2'b11;  // dht11
        end

        case (sel)
            2'b00: mux_data = watchdata;
            2'b01: mux_data = watchdata;
            2'b10: mux_data = sr04_data;
            2'b11: mux_data = dht11_data;
        endcase
    end

endmodule
