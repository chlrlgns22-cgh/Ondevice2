`timescale 1ns / 1ps

module sensor_fnd (
    input           clk,
    input           rst,
    input           sw,
    input [15:0]    sr04_data,  // 0:SR04, 1:DHT11
    input [15:0]    dht11_data,  // (0, hundreds, tens, ones)
    output [3:0]    fnd_com,  // (temp_10, temp_1, humid_10, humid_1)
    output [7:0]    fnd_data
);

    wire [15:0]     w_sensor_data;

    wire [ 3:0]     w_digit_1;
    wire [ 3:0]     w_digit_10;
    wire [ 3:0]     w_digit_100;
    wire [ 3:0]     w_digit_1000;

    wire [ 3:0]     w_digit_10_out;
    wire [ 3:0]     w_digit_100_out;
    wire [ 3:0]     w_digit_1000_out;

    wire [ 1:0]     w_digit_sel;
    wire [ 3:0]     w_out_mux;
    wire            w_1khz;


    sensor_data_mux U_SENSOR_DATA_MUX (
        .in0    (sr04_data),
        .in1    (dht11_data),
        .sel    (sw),
        .out_mux(w_sensor_data)
    );

    assign w_digit_1    = w_sensor_data[3:0];
    assign w_digit_10   = w_sensor_data[7:4];
    assign w_digit_100  = w_sensor_data[11:8];
    assign w_digit_1000 = w_sensor_data[15:12];

    eraze_zero_sensor U_ERAZE_ZERO_SENSOR (
        .sw             (sw),
        .i_digit_1000   (w_digit_1000),
        .i_digit_100    (w_digit_100),
        .i_digit_10     (w_digit_10),
        .o_digit_1000   (w_digit_1000_out),
        .o_digit_100    (w_digit_100_out),
        .o_digit_10     (w_digit_10_out)
    );

    mux_4x1_sensor U_MUX_4X1_SENSOR (
        .in0        (w_digit_1),
        .in1        (w_digit_10_out),
        .in2        (w_digit_100_out),
        .in3        (w_digit_1000_out),
        .sel        (w_digit_sel),
        .out_mux    (w_out_mux)
    );

    bcd U_BCD (
        .bin        (w_out_mux),
        .bcd_data   (fnd_data)
    );

    clk_div_1khz U_CLK_DIV_1KHZ (
        .clk    (clk),
        .rst    (rst),
        .o_1khz (w_1khz)
    );

    counter_4_sensor U_COUNTER_4_SENSOR (
        .clk        (w_1khz),
        .rst        (rst),
        .digit_sel  (w_digit_sel)
    );

    decoder_2x4 U_DECODER_2x4 (
        .decoder_in (w_digit_sel),
        .decoder_out(fnd_com)
    );

endmodule

module sensor_data_mux (
    input  [15:0] in0,
    input  [15:0] in1,
    input         sel,
    output [15:0] out_mux
);

    assign out_mux = (sel) ? in1 : in0;

endmodule

// sr04일때 앞자리 0(천의자리 부분 출력X. 최대 출력값이 190이었던것 같음..) 만드는 용도
module eraze_zero_sensor (
    input sw,  // 0: SR04, 1: DHT11
    input [3:0]         i_digit_1000,
    input [3:0]         i_digit_100,
    input [3:0]         i_digit_10,
    output reg [3:0]    o_digit_1000,
    output reg [3:0]    o_digit_100,
    output reg [3:0]    o_digit_10
);

    always @(*) begin
        if (sw) begin
            o_digit_1000 = i_digit_1000;
            o_digit_100  = i_digit_100;
            o_digit_10   = i_digit_10;
        end else begin
            o_digit_1000 = 4'hf;

            if (i_digit_100 == 0) begin
                o_digit_100 = 4'hf;
                if (i_digit_10 == 0) begin
                    o_digit_10 = 4'hf;
                end else begin
                    o_digit_10 = i_digit_10;
                end
            end else begin
                o_digit_100 = i_digit_100;
                o_digit_10  = i_digit_10;
            end
        end
    end

endmodule

module mux_4x1_sensor (
    input  [3:0] in0,
    input  [3:0] in1,
    input  [3:0] in2,
    input  [3:0] in3,
    input  [1:0] sel,
    output [3:0] out_mux
);

    reg [3:0] out_reg;
    assign out_mux = out_reg;

    always @(*) begin
        case (sel)
            2'b00:   out_reg = in0;
            2'b01:   out_reg = in1;
            2'b10:   out_reg = in2;
            2'b11:   out_reg = in3;
            default: out_reg = 4'hf;
        endcase
    end

endmodule

module counter_4_sensor (
    input           clk,
    input           rst,
    output [1:0]    digit_sel
);
    reg [1:0] counter_reg;
    assign digit_sel = counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
        end else begin
            counter_reg <= counter_reg + 1;
        end
    end

endmodule
