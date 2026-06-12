`timescale 1ns / 1ps

module dht11_top (
    input           clk,
    input           rst,
    input           dht11_start,
    output [15:0]   dht11_data,
    output          valid,
    inout           dht11_io

);

    wire        w_tick_us;
    wire [7:0]  w_humidity;
    wire [7:0]  w_temperature;

    wire [3:0]  w_temp_10;
    wire [3:0]  w_temp_1;
    wire [3:0]  w_hum_10;
    wire [3:0]  w_hum_1;


    dht11_controller U_DHT11_CTRL (
        .clk         (clk),
        .rst         (rst),
        .dht11_start (dht11_start),
        .tick_us     (w_tick_us),
        .humidity    (w_humidity),
        .temperature (w_temperature),
        .valid       (valid),
        .dht11       (dht11_io)
    );

    tick_gen_us U_TICK_GEN_US (
        .clk        (clk),
        .rst        (rst),
        .tick_us    (w_tick_us)
    );


    // 앞 2자리 온도 & 뒤 2자리 습도
    assign w_temp_10 = w_temperature / 10;
    assign w_temp_1  = w_temperature % 10;
    assign w_hum_10  = w_humidity / 10;
    assign w_hum_1   = w_humidity % 10;

    assign dht11_data = {w_temp_10, w_temp_1, w_hum_10, w_hum_1};

endmodule
