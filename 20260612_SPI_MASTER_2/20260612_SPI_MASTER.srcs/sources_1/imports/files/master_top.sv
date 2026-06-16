`timescale 1ns / 1ps
// ============================================================
//  master_top_all.sv
//  btnR 한 번 → HOUR/MIN/SEC/MSEC 연속 수신 → FND 전체 표시
//  (master_watch_ip_all 사용)
//
//  watch_top (slave) 과 SPI 4선으로 연결
//  기존 master_top.sv 의 핀 배치와 동일 → 같은 XDC 사용 가능
// ============================================================

module master_top_all (
    input  logic       clk,
    input  logic       rst,

    // ── 버튼 (btnR만 사용, 나머지는 미사용) ─────────────────
    input  logic       btnR,

    // ── 스위치 ──────────────────────────────────────────────
    input  logic       sw,     // 0: SEC.ms 표시, 1: HH.MM 표시

    // ── SPI 핀 ──────────────────────────────────────────────
    output logic       sclk,
    output logic       mosi,
    input  logic       miso,
    output logic       ss_n,

    // ── FND ─────────────────────────────────────────────────
    output logic [7:0] fnd_data,
    output logic [3:0] fnd_com,
    output logic       led
);

    master_watch_ip_all #(
        .CLK_DIV(8'd24)
    ) U_MASTER_WATCH_IP_ALL (
        .clk     (clk),
        .rst     (rst),
        .btnR    (btnR),
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
