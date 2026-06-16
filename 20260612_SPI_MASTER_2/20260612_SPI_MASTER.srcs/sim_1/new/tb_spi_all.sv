`timescale 1ns / 1ps
// ============================================================
//  tb_spi_all.sv
//  master_top_all (btnR→연속 HOUR/MIN/SEC/MSEC 수신)
//    <-> top_watch (Slave)
//  Vivado xsim 파형 확인용
//
//  필요 RTL:
//    - master_top_all.sv + master_watch_ip_all.sv
//    - spi_master.sv (wire 수정본)
//    - button_debounce.sv, fnd_controller.sv
//    - watch_top.v (top_watch): watch_datapath, control_unit_watch,
//        fnd_controller, watch_spi_ip, spi_slave_top, button_debounce
//
//  파형에서 볼 것:
//    sclk / mosi / miso / ss_n
//    U_MASTER.U_MASTER_WATCH_IP_ALL.state  (FSM: TX1~TX5→LATCH)
//    U_MASTER.U_MASTER_WATCH_IP_ALL.r_hour/r_min/r_sec/r_msec
//    U_SLAVE.w_hour / w_min / w_sec / w_msec  (Slave 내부 시각값)
// ============================================================

module tb_spi_all;

    logic clk;
    logic rst;

    // Master 버튼
    logic btnR;
    logic sw;

    // SPI 4선
    logic sclk;
    logic mosi;
    logic miso;
    logic ss_n;

    // FND (관찰용)
    logic [7:0] m_fnd_data, s_fnd_data;
    logic [3:0] m_fnd_com,  s_fnd_com;
    logic m_led, s_led;

    // ── 100MHz clock ─────────────────────────────────────────
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ── DUT: Master (btnR→전체 연속 수신) ────────────────────
    master_top_all U_MASTER (
        .clk     (clk),
        .rst     (rst),
        .btnR    (btnR),
        .sw      (sw),
        .sclk    (sclk),
        .mosi    (mosi),
        .miso    (miso),
        .ss_n    (ss_n),
        .fnd_data(m_fnd_data),
        .fnd_com (m_fnd_com),
        .led     (m_led)
    );

    // ── DUT: Slave (watch_top) ────────────────────────────────
    watch_top U_SLAVE (
        .clk     (clk),
        .rst     (rst),
        .btnR    (1'b0),
        .btnL    (1'b0),
        .btnU    (1'b0),
        .btnD    (1'b0),
        .sw      (1'b0),
        .fnd_data(s_fnd_data),
        .fnd_com (s_fnd_com),
        .led     (s_led),
        .sclk    (sclk),
        .mosi    (mosi),
        .ss_n    (ss_n),
        .miso    (miso)
    );

    // ── 자극 ─────────────────────────────────────────────────
    initial begin
        rst  = 1'b1;
        btnR = 1'b0;
        sw   = 1'b1;   // HH.MM 표시

        repeat (5) @(posedge clk);
        rst = 1'b0;

        // ── btnR 100us hold → 연속 SPI 5회 시작 ──────────────
        // button_debounce: 100kHz 8단 동기화 → 약 80us 필요
        #200;
        btnR = 1'b1;
        #100_000;   // 100us
        btnR = 1'b0;

        // ── 5회 SPI 전송 완료 대기 ─────────────────────────────
        // 1회 전송: CLK_DIV=24 → SCLK=2MHz → 8bit × 500ns = 4us
        // 5회 × 4us + 여유 = 약 30us
        // button_debounce delay 포함해서 여유롭게 대기
        #200_000;   // 200us

        $display("=== SPI ALL RESULT ===");
        $display("r_hour = %0d", U_MASTER.U_MASTER_WATCH_IP_ALL.r_hour);
        $display("r_min  = %0d", U_MASTER.U_MASTER_WATCH_IP_ALL.r_min);
        $display("r_sec  = %0d", U_MASTER.U_MASTER_WATCH_IP_ALL.r_sec);
        $display("r_msec = %0d", U_MASTER.U_MASTER_WATCH_IP_ALL.r_msec);
        $display("Slave  hour=%0d min=%0d sec=%0d msec=%0d",
            U_SLAVE.w_hour, U_SLAVE.w_min, U_SLAVE.w_sec, U_SLAVE.w_msec);

        $finish;
    end

    // ── 파형 덤프 ────────────────────────────────────────────
    initial begin
        $dumpfile("spi_all_wave.vcd");
        $dumpvars(0, tb_spi_all);
    end

endmodule