`timescale 1ns / 1ps
// ============================================================
//  master_watch_ip_all.sv  (SystemVerilog)
//
//  btnR 한 번 → HOUR/MIN/SEC/MSEC 4개를 연속으로 SPI 수신
//  → Master FND에 Slave 시각값 전체 표시
//
//  SPI 동작 흐름 (8회 연속 전송):
//    TX1: CMD=0xA1 / RX1: 이전값(무시)
//    TX2: CMD=0xA2 / RX2: HOUR  값 래치
//    TX3: CMD=0xA3 / RX3: MIN   값 래치
//    TX4: CMD=0xA4 / RX4: SEC   값 래치
//    TX5: 0x00    / RX5: MSEC  값 래치
//    (TX6~8 불필요 - 5번 전송으로 hour/min/sec/msec 모두 수신)
//
//  이유: SPI는 풀듀플렉스라 CMD를 보내는 클럭에서 수신하는 값은
//  슬레이브가 이전 CMD에 대해 준비한 값임.
//  watch_spi_ip는 rx_cmd를 보고 다음 사이클에 tx_data를 세팅하므로:
//    TX1(A1) → slave가 A1 보고 tx=HOUR 준비
//    TX2(A2) → slave가 A2 보고 tx=MIN 준비 / RX2=HOUR 수신
//    TX3(A3) → slave가 A3 보고 tx=SEC 준비 / RX3=MIN 수신
//    TX4(A4) → slave가 A4 보고 tx=MSEC 준비 / RX4=SEC 수신
//    TX5(00) → RX5=MSEC 수신
//
//  FND 표시:
//    sw=0 : SSSS.ms (sec.msec)
//    sw=1 : HH:MM   (hour:min)
// ============================================================

module master_watch_ip_all #(
    parameter CLK_DIV = 8'd24   // SCLK = 100MHz / (2*(24+1)) ≈ 2MHz
) (
    input  logic        clk,
    input  logic        rst,

    // ── 버튼 (btnR 하나로 전체 요청) ─────────────────────────
    input  logic        btnR,

    // ── SPI 물리 핀 ─────────────────────────────────────────
    output logic        sclk,
    output logic        mosi,
    input  logic        miso,
    output logic        ss_n,

    // ── Master FND 출력 ──────────────────────────────────────
    input  logic        sw,
    output logic [7:0]  fnd_data,
    output logic [3:0]  fnd_com,
    output logic        led
);

    // ──────────────────────────────────────────────────────────
    //  버튼 디바운스
    // ──────────────────────────────────────────────────────────
    logic w_btnR;
    button_debounce U_BTNR (.clk(clk), .rst(rst), .i_btn(btnR), .o_btn(w_btnR));

    // ──────────────────────────────────────────────────────────
    //  FSM 상태 정의
    // ──────────────────────────────────────────────────────────
    typedef enum logic [3:0] {
        IDLE      = 4'd0,
        TX1_START = 4'd1,   // send CMD=0xA1
        TX1_WAIT  = 4'd2,
        TX2_START = 4'd3,   // send CMD=0xA2, recv HOUR
        TX2_WAIT  = 4'd4,
        TX3_START = 4'd5,   // send CMD=0xA3, recv MIN
        TX3_WAIT  = 4'd6,
        TX4_START = 4'd7,   // send CMD=0xA4, recv SEC
        TX4_WAIT  = 4'd8,
        TX5_START = 4'd9,   // send 0x00,     recv MSEC
        TX5_WAIT  = 4'd10,
        LATCH     = 4'd11
    } state_e;

    state_e state;

    // ──────────────────────────────────────────────────────────
    //  수신 데이터 레지스터
    // ──────────────────────────────────────────────────────────
    logic [4:0] r_hour;
    logic [5:0] r_min;
    logic [5:0] r_sec;
    logic [6:0] r_msec;

    // ──────────────────────────────────────────────────────────
    //  SPI Master 인터페이스
    // ──────────────────────────────────────────────────────────
    logic       spi_start;
    logic [7:0] spi_tx_data;
    logic       spi_busy;
    logic       spi_done;
    logic [7:0] spi_rx_data;

    spi_master U_SPI_MASTER (
        .clk     (clk),
        .reset   (rst),
        .start   (spi_start),
        .cpol    (1'b0),
        .cpha    (1'b0),
        .clk_div (CLK_DIV),
        .tx_data (spi_tx_data),
        .busy    (spi_busy),
        .rx_data (spi_rx_data),
        .done    (spi_done),
        .sclk    (sclk),
        .mosi    (mosi),
        .miso    (miso),
        .ss_n    (ss_n)
    );

    // ──────────────────────────────────────────────────────────
    //  메인 FSM  (btnR 한 번 → 5회 연속 SPI)
    // ──────────────────────────────────────────────────────────
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state       <= IDLE;
            spi_start   <= 1'b0;
            spi_tx_data <= 8'h00;
            r_hour      <= 5'd0;
            r_min       <= 6'd0;
            r_sec       <= 6'd0;
            r_msec      <= 7'd0;
        end else begin
            spi_start <= 1'b0;   // 기본값: 1클럭 펄스

            case (state)
                // ── 대기 ──────────────────────────────────────
                IDLE: begin
                    if (w_btnR) state <= TX1_START;
                end

                // ── TX1: CMD=0xA1 송신 → slave가 HOUR 준비 ──
                TX1_START: begin
                    if (!spi_busy) begin
                        spi_tx_data <= 8'hA1;
                        spi_start   <= 1'b1;
                        state       <= TX1_WAIT;
                    end
                end
                TX1_WAIT: if (spi_done) state <= TX2_START;
                // RX1은 이전 쓰레기값 → 버림

                // ── TX2: CMD=0xA2 송신 / RX=HOUR 수신 ──────
                TX2_START: begin
                    if (!spi_busy) begin
                        spi_tx_data <= 8'hA2;
                        spi_start   <= 1'b1;
                        state       <= TX2_WAIT;
                    end
                end
                TX2_WAIT: begin
                    if (spi_done) begin
                        r_hour <= spi_rx_data[4:0];
                        state  <= TX3_START;
                    end
                end

                // ── TX3: CMD=0xA3 송신 / RX=MIN 수신 ───────
                TX3_START: begin
                    if (!spi_busy) begin
                        spi_tx_data <= 8'hA3;
                        spi_start   <= 1'b1;
                        state       <= TX3_WAIT;
                    end
                end
                TX3_WAIT: begin
                    if (spi_done) begin
                        r_min <= spi_rx_data[5:0];
                        state <= TX4_START;
                    end
                end

                // ── TX4: CMD=0xA4 송신 / RX=SEC 수신 ───────
                TX4_START: begin
                    if (!spi_busy) begin
                        spi_tx_data <= 8'hA4;
                        spi_start   <= 1'b1;
                        state       <= TX4_WAIT;
                    end
                end
                TX4_WAIT: begin
                    if (spi_done) begin
                        r_sec <= spi_rx_data[5:0];
                        state <= TX5_START;
                    end
                end

                // ── TX5: 0x00 더미 송신 / RX=MSEC 수신 ─────
                TX5_START: begin
                    if (!spi_busy) begin
                        spi_tx_data <= 8'h00;
                        spi_start   <= 1'b1;
                        state       <= TX5_WAIT;
                    end
                end
                TX5_WAIT: begin
                    if (spi_done) begin
                        r_msec <= spi_rx_data[6:0];
                        state  <= LATCH;
                    end
                end

                // ── LATCH: FND 출력 확정 후 IDLE 복귀 ───────
                LATCH: begin
                    // r_hour/min/sec/msec가 이미 래치됨
                    // fnd_controller는 combinational이므로
                    // 다음 클럭부터 FND에 반영됨
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

    // ──────────────────────────────────────────────────────────
    //  FND Controller
    // ──────────────────────────────────────────────────────────
    fnd_controller U_MASTER_FND (
        .clk     (clk),
        .rst     (rst),
        .sw      (sw),
        .msec    (r_msec),
        .sec     (r_sec),
        .min     (r_min),
        .hour    (r_hour),
        .h       (1'b0),
        .m       (1'b0),
        .s       (1'b0),
        .fnd_com (fnd_com),
        .fnd_data(fnd_data),
        .led     (led)
    );

endmodule
