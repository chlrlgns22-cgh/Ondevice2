`timescale 1ns / 1ps

module watch_datapath #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  o_hour_up,
    input  logic                  o_hour_down,
    input  logic                  o_min_up,
    input  logic                  o_min_down,
    input  logic                  o_sec_up,
    input  logic                  o_sec_down,
    output logic [MSEC_WIDTH-1:0] msec,
    output logic [ SEC_WIDTH-1:0] sec,
    output logic [ MIN_WIDTH-1:0] min,
    output logic [HOUR_WIDTH-1:0] hour
);
    logic w_msec_tick, w_sec_tick, w_min_tick, w_hour_tick;

    tick_gen_watch U_TICK_GEN (
        .clk(clk),
        .rst(rst),
        .o_tick(w_msec_tick)
    );

    tick_counter_watch #(
        .TIMES(100),
        .BIT_WIDTH(7)
    ) U_MSEC (
        .clk(clk),
        .rst(rst),
        .i_tick(w_msec_tick),
        .i_up(1'b0),
        .i_down(1'b0),
        .o_tick(w_sec_tick),
        .tick_counter(msec)
    );
    tick_counter_watch #(
        .TIMES(60),
        .BIT_WIDTH(6)
    ) U_SEC (
        .clk(clk),
        .rst(rst),
        .i_tick(w_sec_tick),
        .i_up(o_sec_up),
        .i_down(o_sec_down),
        .o_tick(w_min_tick),
        .tick_counter(sec)
    );
    tick_counter_watch #(
        .TIMES(60),
        .BIT_WIDTH(6)
    ) U_MIN (
        .clk(clk),
        .rst(rst),
        .i_tick(w_min_tick),
        .i_up(o_min_up),
        .i_down(o_min_down),
        .o_tick(w_hour_tick),
        .tick_counter(min)
    );
    tick_counter_watch #(
        .TIMES(24),
        .BIT_WIDTH(5)
    ) U_HOUR (
        .clk(clk),
        .rst(rst),
        .i_tick(w_hour_tick),
        .i_up(o_hour_up),
        .i_down(o_hour_down),
        .o_tick(),
        .tick_counter(hour)
    );

endmodule


module tick_counter_watch #(
    parameter TIMES     = 100,
              BIT_WIDTH = 7
) (
    input  logic                 clk,
    input  logic                 rst,
    input  logic                 i_tick,
    input  logic                 i_up,
    input  logic                 i_down,
    output logic                 o_tick,
    output logic [BIT_WIDTH-1:0] tick_counter
);
    logic [BIT_WIDTH-1:0] counter_logic, counter_next;
    assign tick_counter = counter_logic;

    always @(posedge clk or posedge rst) begin
        if (rst) counter_logic <= 8'h6f;
        else counter_logic <= counter_next;
    end

    always @(*) begin
        counter_next = counter_logic;
        o_tick = 1'b0;
        if (i_tick) begin
            if (counter_logic == TIMES - 1) begin
                counter_next = 0;
                o_tick       = 1'b1;
            end else begin
                counter_next = counter_logic + 1;
            end
        end else if (i_up) begin
            counter_next = (counter_logic == TIMES - 1) ? 0 : counter_logic + 1;
        end else if (i_down) begin
            counter_next = (counter_logic == 0) ? TIMES - 1 : counter_logic - 1;
        end
    end
endmodule


module tick_gen_watch (
    input  logic clk,
    input  logic rst,
    output logic o_tick
);
    // 100MHz → 100Hz (10ms 주기)
    parameter F_COUNT = 100_000_000 / 100;
    logic [$clog2(F_COUNT)-1:0] counter_logic;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_logic <= 0;
            o_tick        <= 1'b0;
        end else begin
            if (counter_logic == F_COUNT - 1) begin
                counter_logic <= 0;
                o_tick        <= 1'b1;
            end else begin
                counter_logic <= counter_logic + 1;
                o_tick        <= 1'b0;
            end
        end
    end
endmodule
