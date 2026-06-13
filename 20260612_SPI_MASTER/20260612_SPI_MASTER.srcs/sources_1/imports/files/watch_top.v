`timescale 1ns / 1ps
// ============================================================
//  watch_top.v  (Verilog)
//  최상위 모듈: watch + SPI slave IP 통합
// ============================================================

module top_slave (
    input  wire       clk,
    input  wire       rst,
    input  wire       btnR,
    input  wire       btnL,
    input  wire       btnU,
    input  wire       btnD,
    input  wire       sw,       // 0: msec/sec 표시, 1: min/hour 표시

    // 로컬 FND
    output wire [7:0] fnd_data,
    output wire [3:0] fnd_com,
    output wire       led,

    // SPI 핀 (Master와 연결)
    input  wire       sclk,
    input  wire       mosi,
    input  wire       ss_n,
    output wire       miso,

    // SPI 상태 (선택적)
    output wire       spi_busy,
    output wire       spi_done
);

    parameter MSEC_WIDTH = 7, SEC_WIDTH = 6, MIN_WIDTH = 6, HOUR_WIDTH = 5;

    // ── watch_datapath 출력 와이어 ──────────────────────────
    wire [MSEC_WIDTH-1:0] w_msec;
    wire [SEC_WIDTH-1:0]  w_sec;
    wire [MIN_WIDTH-1:0]  w_min;
    wire [HOUR_WIDTH-1:0] w_hour;

    // ── 디바운스된 버튼 ─────────────────────────────────────
    wire w_btnR, w_btnL, w_btnU, w_btnD;

    button_debounce U_BTNR (
        .clk  (clk), .rst(rst), .i_btn(btnR), .o_btn(w_btnR)
    );
    button_debounce U_BTNL (
        .clk  (clk), .rst(rst), .i_btn(btnL), .o_btn(w_btnL)
    );
    button_debounce U_BTNU (
        .clk  (clk), .rst(rst), .i_btn(btnU), .o_btn(w_btnU)
    );
    button_debounce U_BTND (
        .clk  (clk), .rst(rst), .i_btn(btnD), .o_btn(w_btnD)
    );

    // ── Control Unit ────────────────────────────────────────
    wire w_c_hour, w_c_min, w_c_sec;
    wire w_hour_up, w_hour_down;
    wire w_min_up,  w_min_down;
    wire w_sec_up,  w_sec_down;

    control_unit_watch U_CTRL_UNIT (
        .clk        (clk),
        .rst        (rst),
        .btnR       (w_btnR),
        .btnL       (w_btnL),
        .btnU       (w_btnU),
        .btnD       (w_btnD),
        .o_hour     (w_c_hour),
        .o_min      (w_c_min),
        .o_sec      (w_c_sec),
        .o_hour_up  (w_hour_up),
        .o_hour_down(w_hour_down),
        .o_min_up   (w_min_up),
        .o_min_down (w_min_down),
        .o_sec_up   (w_sec_up),
        .o_sec_down (w_sec_down)
    );

    // ── Watch Datapath ───────────────────────────────────────
    watch_datapath U_WATCH_DATAPATH (
        .clk        (clk),
        .rst        (rst),
        .i_hour_up  (w_hour_up),
        .i_hour_down(w_hour_down),
        .i_min_up   (w_min_up),
        .i_min_down (w_min_down),
        .i_sec_up   (w_sec_up),
        .i_sec_down (w_sec_down),
        .msec       (w_msec),
        .sec        (w_sec),
        .min        (w_min),
        .hour       (w_hour)
    );

    // ── FND Controller ───────────────────────────────────────
    fnd_controller U_FND_CTRL (
        .clk     (clk),
        .rst     (rst),
        .sw      (sw),
        .msec    (w_msec),
        .sec     (w_sec),
        .min     (w_min),
        .hour    (w_hour),
        .h       (w_c_hour),
        .m       (w_c_min),
        .s       (w_c_sec),
        .fnd_com (fnd_com),
        .fnd_data(fnd_data),
        .led     (led)
    );

    // ── SPI IP ───────────────────────────────────────────────
    // watch 현재 시각을 SPI Master 요청에 따라 전송
    watch_spi_ip U_WATCH_SPI_IP (
        .clk    (clk),
        .rst    (rst),
        .i_msec (w_msec),
        .i_sec  (w_sec),
        .i_min  (w_min),
        .i_hour (w_hour),
        .sclk   (sclk),
        .mosi   (mosi),
        .ss_n   (ss_n),
        .miso   (miso),
        .busy   (spi_busy),
        .done   (spi_done)
    );

endmodule
