`timescale 1ns / 1ps

module fnd_controller #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  sw,        
    input  logic [MSEC_WIDTH-1:0] msec,
    input  logic [ SEC_WIDTH-1:0] sec,
    input  logic [ MIN_WIDTH-1:0] min,
    input  logic [HOUR_WIDTH-1:0] hour,
    input  logic                  h,         
    input  logic                  m,         
    input  logic                  s,         
    output logic [           3:0] fnd_com,
    output logic [           7:0] fnd_data,
    output logic                  led        
);

    // ── digit splitter 출력 ──────────────────────────────────
    logic [3:0] w_msec_d1, w_msec_d10;
    logic [3:0] w_sec_d1, w_sec_d10;
    logic [3:0] w_min_d1, w_min_d10;
    logic [3:0] w_hour_d1, w_hour_d10;

    // ── blink 적용 후 ────────────────────────────────────────
    logic [3:0] w_sec_d1_bl, w_sec_d10_bl;
    logic [3:0] w_min_d1_bl, w_min_d10_bl;
    logic [3:0] w_hour_d1_bl, w_hour_d10_bl;

    // ── 내부 와이어 ──────────────────────────────────────────
    logic [2:0] w_digit_sel;
    logic [2:0] w_blink_sel;
    logic [3:0] w_out_msec_sec, w_out_min_hour, w_out_mux;
    logic w_1khz, w_comp, w_sel;
    logic [3:0] w_f;
    logic [3:0] w_111comp;
    assign w_f       = 4'hF;
    assign w_111comp = {3'b111, w_comp};

    // ── digit splitter ───────────────────────────────────────
    digit_splitter #(
        .BIT_WIDTH(7)
    ) U_MSEC_DS (
        .digit_in(msec),
        .digit_1 (w_msec_d1),
        .digit_10(w_msec_d10)
    );
    digit_splitter #(
        .BIT_WIDTH(6)
    ) U_SEC_DS (
        .digit_in(sec),
        .digit_1 (w_sec_d1),
        .digit_10(w_sec_d10)
    );
    digit_splitter #(
        .BIT_WIDTH(6)
    ) U_MIN_DS (
        .digit_in(min),
        .digit_1 (w_min_d1),
        .digit_10(w_min_d10)
    );
    digit_splitter #(
        .BIT_WIDTH(5)
    ) U_HOUR_DS (
        .digit_in(hour),
        .digit_1 (w_hour_d1),
        .digit_10(w_hour_d10)
    );

    // ── dot 깜박임 (msec 50~99 구간 = high) ─────────────────
    comparator U_COMP (
        .i_comp(msec),
        .o_comp(w_comp)
    );

    // ── 편집 항목 blink 선택 ─────────────────────────────────
    blink U_BLINK (
        .comp_in(w_comp),
        .hour(h),
        .min(m),
        .sec(s),
        .blink_sel(w_blink_sel)
    );

    mux_2x1 U_SEC_D1_BL (
        .in0(w_sec_d1),
        .in1(w_f),
        .sel(w_blink_sel[0]),
        .out_mux(w_sec_d1_bl)
    );
    mux_2x1 U_SEC_D10_BL (
        .in0(w_sec_d10),
        .in1(w_f),
        .sel(w_blink_sel[0]),
        .out_mux(w_sec_d10_bl)
    );
    mux_2x1 U_MIN_D1_BL (
        .in0(w_min_d1),
        .in1(w_f),
        .sel(w_blink_sel[1]),
        .out_mux(w_min_d1_bl)
    );
    mux_2x1 U_MIN_D10_BL (
        .in0(w_min_d10),
        .in1(w_f),
        .sel(w_blink_sel[1]),
        .out_mux(w_min_d10_bl)
    );
    mux_2x1 U_HOUR_D1_BL (
        .in0(w_hour_d1),
        .in1(w_f),
        .sel(w_blink_sel[2]),
        .out_mux(w_hour_d1_bl)
    );
    mux_2x1 U_HOUR_D10_BL (
        .in0(w_hour_d10),
        .in1(w_f),
        .sel(w_blink_sel[2]),
        .out_mux(w_hour_d10_bl)
    );

    // ── 8x1 MUX: msec/sec 면 ─────────────────────────────────
    // watch 전용이므로 msec 항상 표시 (eraze_msec 제거)
    mux_8x1 U_MUX_MSEC_SEC (
        .in0(w_msec_d1),
        .in1(w_msec_d10),
        .in2(w_sec_d1_bl),
        .in3(w_sec_d10_bl),
        .in4(w_f),
        .in5(w_f),
        .in6(w_111comp),
        .in7(w_f),
        .sel(w_digit_sel),
        .out_mux(w_out_msec_sec)
    );

    // ── 8x1 MUX: min/hour 면 ─────────────────────────────────
    mux_8x1 U_MUX_MIN_HOUR (
        .in0(w_min_d1_bl),
        .in1(w_min_d10_bl),
        .in2(w_hour_d1_bl),
        .in3(w_hour_d10_bl),
        .in4(w_f),
        .in5(w_f),
        .in6(w_111comp),
        .in7(w_f),
        .sel(w_digit_sel),
        .out_mux(w_out_min_hour)
    );

    // ── sw / 편집 모드에 따른 면 선택 ───────────────────────
    sel_fix U_SEL_FIX (
        .sw(sw),
        .h(h),
        .m(m),
        .s(s),
        .sel_out(w_sel)
    );

    mux_2x1 U_MUX_FACE (
        .in0(w_out_msec_sec),
        .in1(w_out_min_hour),
        .sel(w_sel),
        .out_mux(w_out_mux)
    );

    // ── BCD → FND 세그먼트 ───────────────────────────────────
    bcd U_BCD (
        .bin(w_out_mux),
        .bcd_data(fnd_data)
    );

    // ── 1kHz 분주 & 3비트 카운터 & 2x4 디코더 ───────────────
    clk_div_1khz U_DIV_1KHZ (
        .clk(clk),
        .rst(rst),
        .o_1khz(w_1khz)
    );
    counter_8 U_CNT8 (
        .clk(w_1khz),
        .rst(rst),
        .digit_sel(w_digit_sel)
    );
    decoder_2x4 U_DEC2x4 (
        .decoder_in (w_digit_sel[1:0]),
        .decoder_out(fnd_com)
    );

    assign led = w_sel;

endmodule


// ── 하위 모듈 ────────────────────────────────────────────────

module sel_fix (
    input  logic sw,
    h,
    m,
    s,
    output logic  sel_out
);
    always @(*) begin
        if ((h | m | s) == 1'b0) sel_out = sw;
        else if (h | m) sel_out = 1'b1;
        else sel_out = 1'b0;
    end
endmodule

module comparator (
    input  logic [6:0] i_comp,
    output logic       o_comp
);
    assign o_comp = (i_comp > 7'd49);
endmodule

module clk_div_1khz (
    input  logic clk,
    rst,
    output logic o_1khz
);
    logic [15:0] counter_logic;
    logic        o_1khz_logic;
    assign o_1khz = o_1khz_logic;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_logic <= 16'd0;
            o_1khz_logic  <= 1'b0;
        end else begin
            counter_logic <= counter_logic + 1;
            if (counter_logic == (50_000 - 1)) begin
                counter_logic <= 16'd0;
                o_1khz_logic  <= ~o_1khz_logic;
            end
        end
    end
endmodule

module counter_8 (
    input  logic       clk,
    rst,
    output logic [2:0] digit_sel
);
    logic [2:0] counter_logic;
    assign digit_sel = counter_logic;
    always @(posedge clk or posedge rst) begin
        if (rst) counter_logic <= 3'd0;
        else counter_logic <= counter_logic + 1;
    end
endmodule

module decoder_2x4 (
    input  logic [1:0] decoder_in,
    output logic  [3:0] decoder_out
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
    input  logic [BIT_WIDTH-1:0] digit_in,
    output logic [          3:0] digit_1,
    output logic [          3:0] digit_10
);
    assign digit_1  = digit_in % 10;
    assign digit_10 = (digit_in / 10) % 10;
endmodule

module mux_8x1 (
    input  logic [3:0] in0,
    in1,
    in2,
    in3,
    in4,
    in5,
    in6,
    in7,
    input  logic [2:0] sel,
    output logic [3:0] out_mux
);
    logic [3:0] out_logic;
    assign out_mux = out_logic;
    always @(*) begin
        case (sel)
            3'b000:  out_logic = in0;
            3'b001:  out_logic = in1;
            3'b010:  out_logic = in2;
            3'b011:  out_logic = in3;
            3'b100:  out_logic = in4;
            3'b101:  out_logic = in5;
            3'b110:  out_logic = in6;
            3'b111:  out_logic = in7;
            default: out_logic = 4'b0000;
        endcase
    end
endmodule

module mux_2x1 (
    input  logic [3:0] in0,
    in1,
    input  logic       sel,
    output logic [3:0] out_mux
);
    assign out_mux = sel ? in1 : in0;
endmodule

module bcd (
    input  logic [3:0] bin,
    output logic  [7:0] bcd_data
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
    input  logic       comp_in,
    hour,
    min,
    sec,
    output logic  [2:0] blink_sel
);
    always @(*) begin
        if (comp_in & sec) blink_sel = 3'b001;
        else if (comp_in & min) blink_sel = 3'b010;
        else if (comp_in & hour) blink_sel = 3'b100;
        else blink_sel = 3'b000;
    end
endmodule

