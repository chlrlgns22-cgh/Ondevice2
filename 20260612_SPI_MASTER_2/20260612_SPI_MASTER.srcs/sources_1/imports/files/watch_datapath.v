`timescale 1ns / 1ps
// ============================================================
//  watch_datapath.v  (Verilog)
//  msec → sec → min → hour 카운터 체인 + 시각 수동 조정
// ============================================================

module watch_datapath #(
    parameter MSEC_WIDTH = 7,
              SEC_WIDTH  = 6,
              MIN_WIDTH  = 6,
              HOUR_WIDTH = 5
) (
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   i_hour_up,
    input  wire                   i_hour_down,
    input  wire                   i_min_up,
    input  wire                   i_min_down,
    input  wire                   i_sec_up,
    input  wire                   i_sec_down,
    output wire [MSEC_WIDTH-1:0]  msec,
    output wire [ SEC_WIDTH-1:0]  sec,
    output wire [ MIN_WIDTH-1:0]  min,
    output wire [HOUR_WIDTH-1:0]  hour
);
    wire w_msec_tick, w_sec_tick, w_min_tick, w_hour_tick;

    tick_gen_watch U_TICK_GEN (
        .clk(clk), .rst(rst), .o_tick(w_msec_tick)
    );

    tick_counter_watch #(.TIMES(100), .BIT_WIDTH(7)) U_MSEC (
        .clk(clk), .rst(rst),
        .i_tick(w_msec_tick), .i_up(1'b0), .i_down(1'b0),
        .o_tick(w_sec_tick),  .tick_counter(msec)
    );
    tick_counter_watch #(.TIMES(60), .BIT_WIDTH(6)) U_SEC (
        .clk(clk), .rst(rst),
        .i_tick(w_sec_tick), .i_up(i_sec_up), .i_down(i_sec_down),
        .o_tick(w_min_tick), .tick_counter(sec)
    );
    tick_counter_watch #(.TIMES(60), .BIT_WIDTH(6)) U_MIN (
        .clk(clk), .rst(rst),
        .i_tick(w_min_tick), .i_up(i_min_up), .i_down(i_min_down),
        .o_tick(w_hour_tick), .tick_counter(min)
    );
    tick_counter_watch #(.TIMES(24), .BIT_WIDTH(5)) U_HOUR (
        .clk(clk), .rst(rst),
        .i_tick(w_hour_tick), .i_up(i_hour_up), .i_down(i_hour_down),
        .o_tick(), .tick_counter(hour)
    );

endmodule


module tick_counter_watch #(
    parameter TIMES     = 100,
              BIT_WIDTH = 7
) (
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   i_tick,
    input  wire                   i_up,
    input  wire                   i_down,
    output reg                    o_tick,
    output wire [BIT_WIDTH-1:0]   tick_counter
);
    reg [BIT_WIDTH-1:0] counter_reg, counter_next;
    assign tick_counter = counter_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) counter_reg <= 0;
        else     counter_reg <= counter_next;
    end

    always @(*) begin
        counter_next = counter_reg;
        o_tick = 1'b0;
        if (i_tick) begin
            if (counter_reg == TIMES - 1) begin
                counter_next = 0;
                o_tick       = 1'b1;
            end else begin
                counter_next = counter_reg + 1;
            end
        end else if (i_up) begin
            counter_next = (counter_reg == TIMES - 1) ? 0 : counter_reg + 1;
        end else if (i_down) begin
            counter_next = (counter_reg == 0) ? TIMES - 1 : counter_reg - 1;
        end
    end
endmodule


module tick_gen_watch (
    input  wire clk,
    input  wire rst,
    output reg  o_tick
);
    // 100MHz → 100Hz (10ms 주기)
    parameter F_COUNT = 100_000_000 / 100;
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            o_tick      <= 1'b0;
        end else begin
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                o_tick      <= 1'b1;
            end else begin
                counter_reg <= counter_reg + 1;
                o_tick      <= 1'b0;
            end
        end
    end
endmodule
