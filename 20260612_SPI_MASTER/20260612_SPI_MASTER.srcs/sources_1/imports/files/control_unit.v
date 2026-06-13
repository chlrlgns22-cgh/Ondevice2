`timescale 1ns / 1ps
// ============================================================
//  control_unit.v  (Verilog)
//  Watch 전용 FSM: NORMAL → HOUR → MIN → SEC → NORMAL
// ============================================================

module control_unit_watch (
    input  wire clk,
    input  wire rst,
    input  wire btnR,    // 다음 항목으로 이동
    input  wire btnL,    // 이전 항목으로 이동
    input  wire btnU,    // 선택 항목 증가
    input  wire btnD,    // 선택 항목 감소

    output reg  o_hour,
    output reg  o_min,
    output reg  o_sec,

    output wire o_hour_up,
    output wire o_hour_down,
    output wire o_min_up,
    output wire o_min_down,
    output wire o_sec_up,
    output wire o_sec_down
);

    parameter [1:0] NORMAL = 2'd0,
                    HOUR   = 2'd1,
                    MIN    = 2'd2,
                    SEC    = 2'd3;

    reg [1:0] c_state, n_state;

    // ── 상태 레지스터 ────────────────────────────────────────
    always @(posedge clk or posedge rst) begin
        if (rst) c_state <= NORMAL;
        else     c_state <= n_state;
    end

    // ── 다음 상태 / 출력 조합 논리 ──────────────────────────
    always @(*) begin
        n_state = c_state;
        o_hour  = 1'b0;
        o_min   = 1'b0;
        o_sec   = 1'b0;

        case (c_state)
            NORMAL: begin
                if      (btnR) n_state = HOUR;
                else if (btnL) n_state = SEC;
            end
            HOUR: begin
                o_hour = 1'b1;
                if      (btnR) n_state = MIN;
                else if (btnL) n_state = NORMAL;
            end
            MIN: begin
                o_min = 1'b1;
                if      (btnR) n_state = SEC;
                else if (btnL) n_state = HOUR;
            end
            SEC: begin
                o_sec = 1'b1;
                if      (btnR) n_state = NORMAL;
                else if (btnL) n_state = MIN;
            end
            default: n_state = NORMAL;
        endcase
    end

    // ── UP / DOWN 제어 신호 ──────────────────────────────────
    assign o_hour_up   = o_hour & btnU;
    assign o_hour_down = o_hour & btnD;
    assign o_min_up    = o_min  & btnU;
    assign o_min_down  = o_min  & btnD;
    assign o_sec_up    = o_sec  & btnU;
    assign o_sec_down  = o_sec  & btnD;

endmodule
