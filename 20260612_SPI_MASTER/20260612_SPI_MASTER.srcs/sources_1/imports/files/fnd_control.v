`timescale 1ns / 1ps
// ============================================================
//  fnd_control.v  (Verilog)
//  Watch 전용 FND 컨트롤러
//  sw=0: msec/sec 표시  |  sw=1: min/hour 표시
//  편집 모드(h/m/s 활성)에서는 해당 자리 깜박임
// ============================================================

module fnd_controller #(
    parameter MSEC_WIDTH = 7,
              SEC_WIDTH  = 6,
              MIN_WIDTH  = 6,
              HOUR_WIDTH = 5
) (
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   sw,   // 0: msec/sec, 1: min/hour
    input  wire [MSEC_WIDTH-1:0]  msec,
    input  wire [ SEC_WIDTH-1:0]  sec,
    input  wire [ MIN_WIDTH-1:0]  min,
    input  wire [HOUR_WIDTH-1:0]  hour,
    input  wire                   h,    // HOUR 편집 중
    input  wire                   m,    // MIN  편집 중
    input  wire                   s,    // SEC  편집 중
    output wire [3:0]             fnd_com,
    output wire [7:0]             fnd_data,
    output wire                   led   // 1: min/hour 면 표시 중
);

    // ── digit splitter 출력 ──────────────────────────────────
    wire [3:0] w_msec_d1,  w_msec_d10;
    wire [3:0] w_sec_d1,   w_sec_d10;
    wire [3:0] w_min_d1,   w_min_d10;
    wire [3:0] w_hour_d1,  w_hour_d10;

    // ── blink 적용 후 ────────────────────────────────────────
    wire [3:0] w_sec_d1_bl,  w_sec_d10_bl;
    wire [3:0] w_min_d1_bl,  w_min_d10_bl;
    wire [3:0] w_hour_d1_bl, w_hour_d10_bl;

    // ── 내부 와이어 ──────────────────────────────────────────
    wire [2:0] w_digit_sel;
    wire [2:0] w_blink_sel;
    wire [3:0] w_out_msec_sec, w_out_min_hour, w_out_mux;
    wire       w_1khz, w_comp, w_sel;
    wire [3:0] w_f;
    wire [3:0] w_111comp;
    assign w_f       = 4'hF;
    assign w_111comp = {3'b111, w_comp};

    // ── digit splitter ───────────────────────────────────────
    digit_splitter #(.BIT_WIDTH(7)) U_MSEC_DS  (.digit_in(msec), .digit_1(w_msec_d1),  .digit_10(w_msec_d10));
    digit_splitter #(.BIT_WIDTH(6)) U_SEC_DS   (.digit_in(sec),  .digit_1(w_sec_d1),   .digit_10(w_sec_d10));
    digit_splitter #(.BIT_WIDTH(6)) U_MIN_DS   (.digit_in(min),  .digit_1(w_min_d1),   .digit_10(w_min_d10));
    digit_splitter #(.BIT_WIDTH(5)) U_HOUR_DS  (.digit_in(hour), .digit_1(w_hour_d1),  .digit_10(w_hour_d10));

    // ── dot 깜박임 (msec 50~99 구간 = high) ─────────────────
    comparator U_COMP (.i_comp(msec), .o_comp(w_comp));

    // ── 편집 항목 blink 선택 ─────────────────────────────────
    blink U_BLINK (.comp_in(w_comp), .hour(h), .min(m), .sec(s), .blink_sel(w_blink_sel));

    mux_2x1 U_SEC_D1_BL  (.in0(w_sec_d1),   .in1(w_f), .sel(w_blink_sel[0]), .out_mux(w_sec_d1_bl));
    mux_2x1 U_SEC_D10_BL (.in0(w_sec_d10),  .in1(w_f), .sel(w_blink_sel[0]), .out_mux(w_sec_d10_bl));
    mux_2x1 U_MIN_D1_BL  (.in0(w_min_d1),   .in1(w_f), .sel(w_blink_sel[1]), .out_mux(w_min_d1_bl));
    mux_2x1 U_MIN_D10_BL (.in0(w_min_d10),  .in1(w_f), .sel(w_blink_sel[1]), .out_mux(w_min_d10_bl));
    mux_2x1 U_HOUR_D1_BL (.in0(w_hour_d1),  .in1(w_f), .sel(w_blink_sel[2]), .out_mux(w_hour_d1_bl));
    mux_2x1 U_HOUR_D10_BL(.in0(w_hour_d10), .in1(w_f), .sel(w_blink_sel[2]), .out_mux(w_hour_d10_bl));

    // ── 8x1 MUX: msec/sec 면 ─────────────────────────────────
    // watch 전용이므로 msec 항상 표시 (eraze_msec 제거)
    mux_8x1 U_MUX_MSEC_SEC (
        .in0(w_msec_d1),   .in1(w_msec_d10),
        .in2(w_sec_d1_bl), .in3(w_sec_d10_bl),
        .in4(w_f),         .in5(w_f),
        .in6(w_111comp),   .in7(w_f),
        .sel(w_digit_sel), .out_mux(w_out_msec_sec)
    );

    // ── 8x1 MUX: min/hour 면 ─────────────────────────────────
    mux_8x1 U_MUX_MIN_HOUR (
        .in0(w_min_d1_bl),  .in1(w_min_d10_bl),
        .in2(w_hour_d1_bl), .in3(w_hour_d10_bl),
        .in4(w_f),          .in5(w_f),
        .in6(w_111comp),    .in7(w_f),
        .sel(w_digit_sel),  .out_mux(w_out_min_hour)
    );

    // ── sw / 편집 모드에 따른 면 선택 ───────────────────────
    sel_fix U_SEL_FIX (.sw(sw), .h(h), .m(m), .s(s), .sel_out(w_sel));

    mux_2x1 U_MUX_FACE (
        .in0(w_out_msec_sec), .in1(w_out_min_hour),
        .sel(w_sel), .out_mux(w_out_mux)
    );

    // ── BCD → FND 세그먼트 ───────────────────────────────────
    bcd U_BCD (.bin(w_out_mux), .bcd_data(fnd_data));

    // ── 1kHz 분주 & 3비트 카운터 & 2x4 디코더 ───────────────
    clk_div_1khz  U_DIV_1KHZ  (.clk(clk), .rst(rst), .o_1khz(w_1khz));
    counter_8     U_CNT8      (.clk(w_1khz), .rst(rst), .digit_sel(w_digit_sel));
    decoder_2x4   U_DEC2x4    (.decoder_in(w_digit_sel[1:0]), .decoder_out(fnd_com));

    assign led = w_sel;

endmodule


// ── 하위 모듈 ────────────────────────────────────────────────

module sel_fix (
    input  wire sw, h, m, s,
    output reg  sel_out
);
    always @(*) begin
        if      ((h | m | s) == 1'b0) sel_out = sw;
        else if (h | m)                sel_out = 1'b1;
        else                           sel_out = 1'b0;
    end
endmodule

module comparator (
    input  wire [6:0] i_comp,
    output wire       o_comp
);
    assign o_comp = (i_comp > 7'd49);
endmodule

module clk_div_1khz (
    input  wire clk, rst,
    output wire o_1khz
);
    reg [15:0] counter_reg;
    reg        o_1khz_reg;
    assign o_1khz = o_1khz_reg;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_reg <= 16'd0;
            o_1khz_reg  <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == (50_000 - 1)) begin
                counter_reg <= 16'd0;
                o_1khz_reg  <= ~o_1khz_reg;
            end
        end
    end
endmodule

module counter_8 (
    input  wire       clk, rst,
    output wire [2:0] digit_sel
);
    reg [2:0] counter_reg;
    assign digit_sel = counter_reg;
    always @(posedge clk or posedge rst) begin
        if (rst) counter_reg <= 3'd0;
        else     counter_reg <= counter_reg + 1;
    end
endmodule

module decoder_2x4 (
    input  wire [1:0] decoder_in,
    output reg  [3:0] decoder_out
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

module digit_splitter #(
    parameter BIT_WIDTH = 7
) (
    input  wire [BIT_WIDTH-1:0] digit_in,
    output wire [3:0]           digit_1,
    output wire [3:0]           digit_10
);
    assign digit_1  = digit_in % 10;
    assign digit_10 = (digit_in / 10) % 10;
endmodule

module mux_8x1 (
    input  wire [3:0] in0, in1, in2, in3, in4, in5, in6, in7,
    input  wire [2:0] sel,
    output wire [3:0] out_mux
);
    reg [3:0] out_reg;
    assign out_mux = out_reg;
    always @(*) begin
        case (sel)
            3'b000: out_reg = in0;
            3'b001: out_reg = in1;
            3'b010: out_reg = in2;
            3'b011: out_reg = in3;
            3'b100: out_reg = in4;
            3'b101: out_reg = in5;
            3'b110: out_reg = in6;
            3'b111: out_reg = in7;
            default: out_reg = 4'b0000;
        endcase
    end
endmodule

module mux_2x1 (
    input  wire [3:0] in0, in1,
    input  wire       sel,
    output wire [3:0] out_mux
);
    assign out_mux = sel ? in1 : in0;
endmodule

module bcd (
    input  wire [3:0] bin,
    output reg  [7:0] bcd_data
);
    always @(bin) begin
        case (bin)
            4'h0: bcd_data = 8'hC0;
            4'h1: bcd_data = 8'hF9;
            4'h2: bcd_data = 8'hA4;
            4'h3: bcd_data = 8'hB0;
            4'h4: bcd_data = 8'h99;
            4'h5: bcd_data = 8'h92;
            4'h6: bcd_data = 8'h82;
            4'h7: bcd_data = 8'hF8;
            4'h8: bcd_data = 8'h80;
            4'h9: bcd_data = 8'h90;
            4'hA: bcd_data = 8'h88;
            4'hB: bcd_data = 8'h83;
            4'hC: bcd_data = 8'hC6;
            4'hD: bcd_data = 8'hA1;
            4'hE: bcd_data = 8'h7F;  // dot on
            4'hF: bcd_data = 8'hFF;  // all off
            default: bcd_data = 8'hFF;
        endcase
    end
endmodule

module blink (
    input  wire       comp_in, hour, min, sec,
    output reg  [2:0] blink_sel
);
    always @(*) begin
        if      (comp_in & sec)  blink_sel = 3'b001;
        else if (comp_in & min)  blink_sel = 3'b010;
        else if (comp_in & hour) blink_sel = 3'b100;
        else                     blink_sel = 3'b000;
    end
endmodule
