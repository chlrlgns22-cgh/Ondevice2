`timescale 1ns / 1ps
// ============================================================
//  master_watch_ip.sv  (SystemVerilog)
//
//  역할:
//    버튼을 누르면 해당 명령어를 Slave(watch)에 전송하고
//    수신한 시각 데이터를 Master FND에 표시한다.
//
//  버튼 → 명령어 매핑:
//    btnR → 8'hA1 (HOUR  요청)
//    btnL → 8'hA2 (MIN   요청)
//    btnU → 8'hA3 (SEC   요청)
//    btnD → 8'hA4 (MSEC  요청)
//
//  동작 순서 (버튼 1회 누름):
//    버튼 감지 → SEND_CMD(명령어 전송) → WAIT_CMD(완료 대기)
//             → SEND_DUMMY(더미 전송)  → WAIT_DUMMY(수신 대기)
//             → LATCH(레지스터 저장)   → IDLE
//
//  파라미터:
//    CLK_DIV : SPI SCLK 분주값 (SCLK = clk / (2*(CLK_DIV+1)))
// ============================================================

module master_watch_ip #(
    parameter CLK_DIV = 8'd4  // 100MHz → SCLK 10MHz
) (
    input logic clk,
    input logic rst,

    // ── 버튼 입력 (디바운스 전 raw) ─────────────────────────
    input logic btnR,  // HOUR  요청
    input logic btnL,  // MIN   요청
    input logic btnU,  // SEC   요청
    input logic btnD,  // MSEC  요청

    // ── SPI 물리 핀 (Slave와 연결) ──────────────────────────
    output logic sclk,
    output logic mosi,
    input  logic miso,
    output logic ss_n,

    // ── Master FND 출력 ─────────────────────────────────────
    input  logic       sw,        // 0: msec/sec 표시, 1: min/hour 표시
    output logic [7:0] fnd_data,
    output logic [3:0] fnd_com,
    output logic       led
);

    // ──────────────────────────────────────────────────────────
    //  버튼 디바운스
    // ──────────────────────────────────────────────────────────
    logic w_btnR, w_btnL, w_btnU, w_btnD;

    button_debounce U_BTNR (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnR),
        .o_btn(w_btnR)
    );
    button_debounce U_BTNL (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnL),
        .o_btn(w_btnL)
    );
    button_debounce U_BTNU (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnU),
        .o_btn(w_btnU)
    );
    button_debounce U_BTND (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnD),
        .o_btn(w_btnD)
    );

    // ──────────────────────────────────────────────────────────
    //  FSM 상태 정의
    // ──────────────────────────────────────────────────────────
    typedef enum logic [2:0] {
        IDLE       = 3'd0,  // 버튼 입력 대기
        SEND_CMD   = 3'd1,  // 명령어 전송 시작
        WAIT_CMD   = 3'd2,  // 명령어 전송 완료 대기
        SEND_DUMMY = 3'd3,  // 더미 바이트 전송 시작
        WAIT_DUMMY = 3'd4,  // 더미 전송 완료 대기 (rx_data 수신)
        LATCH      = 3'd5   // 수신값 레지스터 저장
    } master_state_e;

    master_state_e       state;

    // ──────────────────────────────────────────────────────────
    //  현재 요청 명령어 및 종류 저장
    // ──────────────────────────────────────────────────────────
    logic          [7:0] r_cmd;  // 전송할 명령어 래치
    logic          [1:0] r_cmd_type;  // 0=HOUR, 1=MIN, 2=SEC, 3=MSEC

    // ──────────────────────────────────────────────────────────
    //  수신 데이터 레지스터 (watch 시각, 마지막 수신값 유지)
    // ──────────────────────────────────────────────────────────
    logic          [4:0] r_hour;  // 0~23
    logic          [5:0] r_min;  // 0~59
    logic          [5:0] r_sec;  // 0~59
    logic          [6:0] r_msec;  // 0~99

    // ──────────────────────────────────────────────────────────
    //  SPI Master 연결 신호
    // ──────────────────────────────────────────────────────────
    logic                spi_start;
    logic          [7:0] spi_tx_data;
    logic                spi_busy;
    logic                spi_done;
    logic          [7:0] spi_rx_data;

    spi_master U_SPI_MASTER (
        .clk    (clk),
        .reset  (rst),
        .start  (spi_start),
        .cpol   (1'b0),
        .cpha   (1'b0),
        .clk_div(CLK_DIV),
        .tx_data(spi_tx_data),
        .busy   (spi_busy),
        .rx_data(spi_rx_data),
        .done   (spi_done),
        .sclk   (sclk),
        .mosi   (mosi),
        .miso   (miso),
        .ss_n   (ss_n)
    );

    // ──────────────────────────────────────────────────────────
    //  메인 FSM
    // ──────────────────────────────────────────────────────────
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state       <= IDLE;
            r_cmd       <= 8'h00;
            r_cmd_type  <= 2'd0;
            spi_start   <= 1'b0;
            spi_tx_data <= 8'h00;
            r_hour      <= 5'd0;
            r_min       <= 6'd0;
            r_sec       <= 6'd0;
            r_msec      <= 7'd0;
        end else begin
            spi_start <= 1'b0;  // 매 사이클 기본 클리어 (1클럭 펄스)

            case (state)
                // ── 버튼 입력 감지 ─────────────────────────────
                //    우선순위: R > L > U > D
                IDLE: begin
                    if (w_btnR) begin
                        r_cmd      <= 8'hA1;
                        r_cmd_type <= 2'd0;  // HOUR
                        state      <= SEND_CMD;
                    end else if (w_btnL) begin
                        r_cmd      <= 8'hA2;
                        r_cmd_type <= 2'd1;  // MIN
                        state      <= SEND_CMD;
                    end else if (w_btnU) begin
                        r_cmd      <= 8'hA3;
                        r_cmd_type <= 2'd2;  // SEC
                        state      <= SEND_CMD;
                    end else if (w_btnD) begin
                        r_cmd      <= 8'hA4;
                        r_cmd_type <= 2'd3;  // MSEC
                        state      <= SEND_CMD;
                    end
                end

                // ── 명령어 전송 시작 ───────────────────────────
                SEND_CMD: begin
                    if (!spi_busy) begin
                        spi_tx_data <= r_cmd;
                        spi_start   <= 1'b1;
                        state       <= WAIT_CMD;
                    end
                end

                // ── 명령어 전송 완료 대기 ──────────────────────
                WAIT_CMD: begin
                    if (spi_done) begin
                        state <= SEND_DUMMY;
                    end
                end

                // ── 더미 바이트 전송 (MISO에서 watch 값 수신) ──
                SEND_DUMMY: begin
                    if (!spi_busy) begin
                        spi_tx_data <= 8'h00;
                        spi_start   <= 1'b1;
                        state       <= WAIT_DUMMY;
                    end
                end

                // ── 더미 전송 완료 → 래치로 이동 ──────────────
                WAIT_DUMMY: begin
                    if (spi_done) begin
                        state <= LATCH;
                    end
                end

                // ── 수신 데이터를 해당 레지스터에 저장 ────────
                LATCH: begin
                    case (r_cmd_type)
                        2'd0: r_hour <= spi_rx_data[4:0];  // HOUR
                        2'd1: r_min <= spi_rx_data[5:0];  // MIN
                        2'd2: r_sec <= spi_rx_data[5:0];  // SEC
                        2'd3: r_msec <= spi_rx_data[6:0];  // MSEC
                    endcase
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

    // ──────────────────────────────────────────────────────────
    //  Master FND Controller
    //  수신한 시각 데이터를 FND에 표시
    //  편집 기능 없으므로 h/m/s = 0 고정
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
