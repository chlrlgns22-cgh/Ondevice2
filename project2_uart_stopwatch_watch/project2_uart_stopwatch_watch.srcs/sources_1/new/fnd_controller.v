`timescale 1ns / 1ps
//26.04.18 19:43
// datapath mux 하위모듈로 구성 
// stopwatch STOP-> dot flash stop -> watch msec select -> dot flash maintain  
module fnd_controller #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input                   clk,
    input                   rst,
    input  [           2:0] sw,              // sw[0], 0: msec_sec, 1: min_hour
    input  [MSEC_WIDTH-1:0] msec_stopwatch,
    input  [ SEC_WIDTH-1:0] sec_stopwatch,
    input  [ MIN_WIDTH-1:0] min_stopwatch,
    input  [HOUR_WIDTH-1:0] hour_stopwatch,
    input  [MSEC_WIDTH-1:0] msec_watch,
    input  [ SEC_WIDTH-1:0] sec_watch,
    input  [ MIN_WIDTH-1:0] min_watch,
    input  [HOUR_WIDTH-1:0] hour_watch,
    input                   h,
    input                   m,
    input                   s,
    output [           3:0] fnd_com,
    output [           7:0] fnd_data,
    output [           2:0] led,             // ON: hour, min  OFF: msec,sec
    output [          31:0] watchdata
);
    // mux out
    wire [MSEC_WIDTH-1:0] w_msec;
    wire [ SEC_WIDTH-1:0] w_sec;
    wire [ MIN_WIDTH-1:0] w_min;
    wire [HOUR_WIDTH-1:0] w_hour, o_hour_watch;
    wire [3:0] w_out_mux, w_out_mux_msec_sec, w_out_mux_min_hour;
    // digit splitter output to mux in
    wire [3:0] w_msec_digit_1, w_msec_digit_10;
    wire [3:0] w_sec_digit_1, w_sec_digit_10;
    wire [3:0] w_min_digit_1, w_min_digit_10;
    wire [3:0] w_hour_digit_1, w_hour_digit_10;
    // 4x1 mux selection
    wire [2:0] w_digit_sel;
    // 1KHz clock
    wire       w_1khz;
    // mux 상위 input 고정
    wire [3:0] w_f;
    assign w_f = 4'hF;
    // comp
    wire w_comp;
    wire [3:0] w_111comp;
    assign w_111comp = {3'b111, w_comp};
    wire w_sel;
    wire [2:0] w_blink_sel;
    wire [3:0] w_sec_digit_1_blink, w_sec_digit_10_blink;  //blink wire  8x1mux_in
    wire [3:0] w_min_digit_1_blink, w_min_digit_10_blink;  //blink wire  8x1mux_in
    wire [3:0] w_hour_digit_1_blink, w_hour_digit_10_blink;  //blink wire  8x1mux_in
    wire [3:0] w_msec_digit_1_eraze, w_msec_digit_10_eraze;
    assign watchdata = {
        w_hour_digit_10,
        w_hour_digit_1,
        w_min_digit_10,
        w_min_digit_1,
        w_sec_digit_10,
        w_sec_digit_1,
        w_msec_digit_10,
        w_msec_digit_1
    };

    //am_pm 추가
    am_pm U_AM_PM (
        .sw         (sw[2:1]),
        .i_hour_data(hour_watch),
        .o_hour_data(o_hour_watch),
        .led        (led[2])
    );


    // TOP mopdule FND MUX 통합 26.04.18 19:37
    fnd_mux #(
        .BIT_WIDTH(HOUR_WIDTH)
    ) U_HOUR_DATA (
        .in0    (hour_stopwatch),
        .in1    (o_hour_watch),
        .sel    (sw[1]),
        .out_mux(w_hour)
    );
    fnd_mux #(
        .BIT_WIDTH(MIN_WIDTH)
    ) U_MIN_DATA (
        .in0    (min_stopwatch),
        .in1    (min_watch),
        .sel    (sw[1]),
        .out_mux(w_min)
    );
    fnd_mux #(
        .BIT_WIDTH(SEC_WIDTH)
    ) U_SEC_DATA (
        .in0    (sec_stopwatch),
        .in1    (sec_watch),
        .sel    (sw[1]),
        .out_mux(w_sec)
    );
    fnd_mux #(
        .BIT_WIDTH(MSEC_WIDTH)
    ) U_MSEC_DATA (
        .in0(msec_stopwatch),
        .in1(msec_watch),
        .sel(sw[1]),
        .out_mux(w_msec)
    );

    // digit splitter
    digit_splitter #(
        .BIT_WIDTH(7)
    ) U_MSEC_DS (
        .digit_in(w_msec),
        .digit_1 (w_msec_digit_1),
        .digit_10(w_msec_digit_10)
    );
    digit_splitter #(
        .BIT_WIDTH(6)
    ) U_SEC_DS (
        .digit_in(w_sec),
        .digit_1 (w_sec_digit_1),
        .digit_10(w_sec_digit_10)
    );
    digit_splitter #(
        .BIT_WIDTH(6)
    ) U_MIN_DS (
        .digit_in(w_min),
        .digit_1 (w_min_digit_1),
        .digit_10(w_min_digit_10)
    );
    digit_splitter #(
        .BIT_WIDTH(5)
    ) U_HOUR_DS (
        .digit_in(w_hour),
        .digit_1 (w_hour_digit_1),
        .digit_10(w_hour_digit_10)
    );

    eraze_msec U_ERAZE_MSEC (
        .sw(sw[1]),
        .i_msec_digit_1(w_msec_digit_1),
        .i_msec_digit_10(w_msec_digit_10),
        .o_msec_digit_1(w_msec_digit_1_eraze),
        .o_msec_digit_10(w_msec_digit_10_eraze)
    );
    // for 2Hz flash of dot
    comparator U_COMP (
        .i_comp(msec_watch),
        .o_comp(w_comp)
    );


    blink U_BLINK (
        .comp_in(w_comp),
        .hour(h),
        .min(m),
        .sec(s),
        .blink_sel(w_blink_sel)
    );

    mux_2x1 U_MUX_2x1_SEC_DS_1 (
        .in0    (w_sec_digit_1),
        .in1    (4'hf),
        .sel    (w_blink_sel[0]),
        .out_mux(w_sec_digit_1_blink)  // U_MUX_8x1_MSEC_SEC    
    );
    mux_2x1 U_MUX_2x1_SEC_DS_10 (
        .in0    (w_sec_digit_10),
        .in1    (4'hf),
        .sel    (w_blink_sel[0]),
        .out_mux(w_sec_digit_10_blink)  // U_MUX_8x1_MSEC_SEC_in        
    );
    mux_2x1 U_MUX_2x1_MIN_DS_1 (
        .in0    (w_min_digit_1),
        .in1    (4'hf),
        .sel    (w_blink_sel[1]),
        .out_mux(w_min_digit_1_blink)  // U_MUX_8x1_MSEC_SEC_in        
    );
    mux_2x1 U_MUX_2x1_MIN_DS_10 (
        .in0    (w_min_digit_10),
        .in1    (4'hf),
        .sel    (w_blink_sel[1]),
        .out_mux(w_min_digit_10_blink)  // U_MUX_8x1_MSEC_SEC_in        
    );
    mux_2x1 U_MUX_2x1_HOUR_DS_1 (
        .in0    (w_hour_digit_1),
        .in1    (4'hf),
        .sel    (w_blink_sel[2]),
        .out_mux(w_hour_digit_1_blink)  // U_MUX_8x1_MSEC_SEC_in        
    );
    mux_2x1 U_MUX_2x1_HOUR_DS_10 (
        .in0    (w_hour_digit_10),
        .in1    (4'hf),
        .sel    (w_blink_sel[2]),
        .out_mux(w_hour_digit_10_blink)  // U_MUX_8x1_MSEC_SEC_in        
    );
    // MUX
    mux_8x1 U_MUX_8x1_MSEC_SEC (
        .in0    (w_msec_digit_1_eraze),
        .in1    (w_msec_digit_10_eraze),
        .in2    (w_sec_digit_1_blink),
        .in3    (w_sec_digit_10_blink),
        .in4    (w_f),                    // always off
        .in5    (w_f),                    // always off
        .in6    (w_111comp),              // for dot flash
        .in7    (w_f),                    // always off
        .sel    (w_digit_sel),            // to select input
        .out_mux(w_out_mux_msec_sec)
    );
    mux_8x1 U_MUX_8x1_MIN_HOUR (
        .in0    (w_min_digit_1_blink),
        .in1    (w_min_digit_10_blink),
        .in2    (w_hour_digit_1_blink),
        .in3    (w_hour_digit_10_blink),
        .in4    (w_f),
        .in5    (w_f),
        .in6    (w_111comp),
        .in7    (w_f),
        .sel    (w_digit_sel),            // to select input
        .out_mux(w_out_mux_min_hour)
    );

    // Fix
    sel_fix U_sel_fix (
        .sw     (sw[0]),
        .h      (h),
        .m      (m),
        .s      (s),
        .sel_out(w_sel)
    );

    mux_2x1 U_MUX_2x1 (
        .in0    (w_out_mux_msec_sec),
        .in1    (w_out_mux_min_hour),
        .sel    (w_sel),
        .out_mux(w_out_mux)            // to BCD
    );

    //BCD
    bcd U_BCD (
        .bin     (w_out_mux),
        .bcd_data(fnd_data)
    );

    clk_div_1khz U_DIV_1KHZ (
        .clk   (clk),
        .rst   (rst),
        .o_1khz(w_1khz)
    );

    counter_8 U_COUNTER_8 (
        .clk      (w_1khz),
        .rst      (rst),
        .digit_sel(w_digit_sel)
    );

    wire [3:0] w_fnd_com;
    decoder_2x4 U_DECODER_2x4 (
        .decoder_in (w_digit_sel[1:0]),
        .decoder_out(fnd_com)
    );

    assign led[0] = w_sel;

endmodule

module fnd_mux #(
    parameter BIT_WIDTH = 7
) (
    input  [BIT_WIDTH -1:0] in0,
    input  [BIT_WIDTH -1:0] in1,
    input                   sel,
    output [BIT_WIDTH -1:0] out_mux
);
    assign out_mux = (sel) ? in0 : in1;

endmodule

module sel_fix (
    input      sw,
    input      h,
    input      m,
    input      s,
    output reg sel_out
);

    always @(*) begin
        if ((h | m | s) == 1'b0) begin
            sel_out = sw;
        end else if (h | m) begin
            sel_out = 1'b1;
        end else sel_out = 1'b0;
    end

endmodule

module comparator (
    input  [6:0] i_comp,
    output       o_comp
);
    // 0~49 : false 0. 50~99: true 1
    assign o_comp = (i_comp > 7'd49);
endmodule


module clk_div_1khz (
    input  clk,
    input  rst,
    output o_1khz
);
    reg [15:0] counter_reg;
    reg o_1khz_reg;  // 출력이 0으로 시작할 수 있도록

    assign o_1khz = o_1khz_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 16'd0;  // Decimal이다.
            o_1khz_reg  <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == (50_000 - 1)) begin // 그래서 여기서 10진수 사용
                counter_reg <= 16'd0;
                o_1khz_reg  <= ~o_1khz_reg;  // duty cycle 50%
            end
        end
    end

endmodule

module counter_8 (
    input        clk,
    input        rst,
    output [2:0] digit_sel
);
    reg [2:0] counter_reg; // 왜 이건 output reg로 선언 안하고 이렇게?

    assign digit_sel = counter_reg;  // 이건 또 순서가 있네

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
        end else begin
            counter_reg <= counter_reg + 1;
        end
    end

endmodule

module decoder_2x4 (
    input      [1:0] decoder_in,
    output reg [3:0] decoder_out
);

    always @(*) begin
        case (decoder_in)
            2'b00:   decoder_out = 4'b1110;
            2'b01:   decoder_out = 4'b1101;
            2'b10:   decoder_out = 4'b1011;
            2'b11:   decoder_out = 4'b0111;
            default: decoder_out = 4'b1111;
        endcase
    end

endmodule

// ALU였네 이녀석
module digit_splitter #(
    parameter BIT_WIDTH = 7
) (
    input  [BIT_WIDTH - 1:0] digit_in,
    output [            3:0] digit_1,
    output [            3:0] digit_10
);

    assign digit_1  = digit_in % 10;  // digit 1
    assign digit_10 = (digit_in / 10) % 10;  // digit 10

endmodule

module mux_8x1 (
    input  [3:0] in0,     // digit 1
    input  [3:0] in1,     // digit 10
    input  [3:0] in2,     // digit 100
    input  [3:0] in3,     // digit 1000
    input  [3:0] in4,     // f
    input  [3:0] in5,     // f
    input  [3:0] in6,     // e or f
    input  [3:0] in7,     // f
    input  [2:0] sel,     // to select input
    output [3:0] out_mux
);

    reg [3:0] out_reg;
    assign out_mux = out_reg;

    //mux,  (*) all input : sensitivity list
    always @(*  /*in0, in1, in2, in3, sel*/) begin
        case (sel)
            3'b000:  out_reg = in0;
            3'b001:  out_reg = in1;
            3'b010:  out_reg = in2;
            3'b011:  out_reg = in3;
            3'b100:  out_reg = in4;
            3'b101:  out_reg = in5;
            3'b110:  out_reg = in6;
            3'b111:  out_reg = in7;
            default: out_reg = 4'b0000;
            // Scheme을 계속 확인하라. 불필요한 Latch는 ''반드시'' 제거
            // -> 조합논리는 assign을 지향하는 이유
            // Full Case 처리해야한다.
        endcase
    end

endmodule

module mux_2x1 (
    input  [3:0] in0,
    input  [3:0] in1,
    input        sel,
    output [3:0] out_mux
);

    assign out_mux = (sel) ? in1 : in0;  // in0: msec_sec, in1: min_hour

endmodule

module bcd (
    input      [3:0] bin,
    output reg [7:0] bcd_data  // 값을 유지해야하기 때문에 reg형
);

    always @(bin) begin  // 항상 bin을 감시해라, "begin~end를 실행하라"
        case (bin)
            4'b0000: bcd_data = 8'hC0;
            4'b0001: bcd_data = 8'hF9;
            4'b0010: bcd_data = 8'hA4;
            4'b0011: bcd_data = 8'hB0;

            4'b0100: bcd_data = 8'h99;
            4'b0101: bcd_data = 8'h92;
            4'b0110: bcd_data = 8'h82;
            4'b0111: bcd_data = 8'hF8;

            4'b1000: bcd_data = 8'h80;
            4'b1001: bcd_data = 8'h90;
            4'b1010: bcd_data = 8'h88;  // A
            4'b1011: bcd_data = 8'h83;  // B

            4'b1100: bcd_data = 8'hC6;  // C
            4'b1101: bcd_data = 8'hA1;  // D
            4'b1110: bcd_data = 8'h7F;  // dot on
            4'b1111: bcd_data = 8'hFF;  // all off

            default:
            bcd_data = 8'hFF; // Full case 기술시에는 필요없음, xx로 두는 것은 조심해야됨
        endcase
    end

endmodule

module blink (
    input comp_in,
    input hour,
    input min,
    input sec,
    output reg [2:0] blink_sel
);

    always @(*) begin
        if (comp_in & sec) begin
            blink_sel = 3'b001;
        end else if (comp_in & min) begin
            blink_sel = 3'b010;
        end else if (comp_in & hour) begin
            blink_sel = 3'b100;
        end else blink_sel = 3'b000;
    end

endmodule


module eraze_msec (
    input        sw,
    input  [3:0] i_msec_digit_1,
    input  [3:0] i_msec_digit_10,
    output [3:0] o_msec_digit_1,
    output [3:0] o_msec_digit_10
);

    assign o_msec_digit_1  = (!sw) ? 4'hf : i_msec_digit_1;
    assign o_msec_digit_10 = (!sw) ? 4'hf : i_msec_digit_10;

endmodule

module am_pm (
    input      [1:0] sw,
    input      [4:0] i_hour_data,
    output reg [4:0] o_hour_data,
    output reg       led
);

    always @(*) begin
        if (i_hour_data > 12) begin
            if ((sw[1] == 1'b1) & (sw[0] == 1'b0)) begin
                o_hour_data = i_hour_data - 12;
                led = 1'b1;
            end else begin
                o_hour_data = i_hour_data;
                led = 1'b0;
            end
        end else begin
            o_hour_data = i_hour_data;
            led = 1'b0;
        end
    end

endmodule
