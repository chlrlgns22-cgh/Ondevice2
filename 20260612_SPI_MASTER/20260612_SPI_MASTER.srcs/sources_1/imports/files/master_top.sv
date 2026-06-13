`timescale 1ns / 1ps
// ============================================================
//  master_top.sv  (SystemVerilog)
//  Master 최상위 모듈
//
//  sw = 0 : FND에 SS.ms 표시
//  sw = 1 : FND에 HH.MM 표시
// ============================================================

module master_top (
    input  logic       clk,
    input  logic       rst,

    // ── 버튼 ────────────────────────────────────────────────
    input  logic       btnR,   // HOUR  요청
    input  logic       btnL,   // MIN   요청
    input  logic       btnU,   // SEC   요청
    input  logic       btnD,   // MSEC  요청

    // ── 스위치 ──────────────────────────────────────────────
    input  logic       sw,     // 0: SS.ms, 1: HH.MM

    // ── SPI 핀 (Slave board와 연결) ─────────────────────────
    output logic       sclk,
    output logic       mosi,
    input  logic       miso,
    output logic       ss_n,

    // ── FND (4자리) ─────────────────────────────────────────
    output logic [7:0] fnd_data,
    output logic [3:0] fnd_com,
    output logic       led
);

    master_watch_ip #(
        .CLK_DIV (8'd4)
    ) U_MASTER_WATCH_IP (
        .clk     (clk),
        .rst     (rst),
        .btnR    (btnR),
        .btnL    (btnL),
        .btnU    (btnU),
        .btnD    (btnD),
        .sclk    (sclk),
        .mosi    (mosi),
        .miso    (miso),
        .ss_n    (ss_n),
        .sw      (sw),
        .fnd_data(fnd_data),
        .fnd_com (fnd_com),
        .led     (led)
    );

endmodule
