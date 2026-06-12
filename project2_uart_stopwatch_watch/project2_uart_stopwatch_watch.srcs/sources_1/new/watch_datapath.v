`timescale 1ns / 1ps

module watch_datapath #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input                     clk,
    input                     rst,
    input                     i_hour_up,
    input                     i_hour_down,
    input                     i_min_up,
    input                     i_min_down,
    input                     i_sec_up,
    input                     i_sec_down,
    output [MSEC_WIDTH-1:0] msec,
    output [ SEC_WIDTH - 1:0] sec,
    output [ MIN_WIDTH - 1:0] min,
    output [HOUR_WIDTH - 1:0] hour
);
    wire w_msec_tick, w_sec_tick, w_min_tick, w_hour_tick;

    tick_counter_watch #(
        .TIMES(24),
        .IDLE(12),
        .BIT_WIDTH(5)
    ) U_HOUR_TICK_COUNTER (
        .clk         (clk),
        .rst         (rst),
        .i_tick      (w_hour_tick),
        .i_up        (i_hour_up),
        .i_down      (i_hour_down),
        .o_tick      (),
        .tick_counter(hour)
    );
    tick_counter_watch #(
        .TIMES(60),
        .IDLE(0),
        .BIT_WIDTH(6)
    ) U_MIN_TICK_COUNTER (
        .clk         (clk),
        .rst         (rst),
        .i_tick      (w_min_tick),
        .i_up        (i_min_up),
        .i_down      (i_min_down),
        .o_tick      (w_hour_tick),
        .tick_counter(min)
    );
    tick_counter_watch #(
        .TIMES(60),
        .IDLE(0),
        .BIT_WIDTH(6)
    ) U_SEC_TICK_COUNTER (
        .clk         (clk),
        .rst         (rst),
        .i_tick      (w_sec_tick),
        .i_up        (i_sec_up),
        .i_down      (i_sec_down),
        .o_tick      (w_min_tick),
        .tick_counter(sec)
    );
    tick_counter_watch #(
        .TIMES(100),
        .BIT_WIDTH(7)
    ) U_MSEC_TICK_COUNTER (
        .clk         (clk),
        .rst         (rst),
        .i_tick      (w_msec_tick),
        .o_tick      (w_sec_tick),
        .tick_counter(msec)
    );

    tick_gen_watch U_TICK_GEN (
        .clk(clk),
        .rst(rst),
        .o_tick(w_msec_tick)
    );

endmodule


module tick_counter_watch #(
    parameter TIMES = 100,
    IDLE = 12,
    BIT_WIDTH = 7
) (
    input                       clk,
    input                       rst,
    input                       i_tick,
    input                       i_up,
    input                       i_down,
    output reg                  o_tick,
    output     [BIT_WIDTH -1:0] tick_counter
);

    // register
    reg [BIT_WIDTH -1:0] counter_reg, counter_next;
    assign tick_counter = counter_reg;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= IDLE;
        end else begin
            counter_reg <= counter_next;
        end
    end

    // next, output CL: input counter_reg, ouput: counter_next
    always @(*) begin
        counter_next = counter_reg;
        o_tick = 1'b0;
        if (i_tick) begin
            counter_next = counter_reg + 1;
            if (counter_reg == TIMES - 1) begin
                counter_next = 0;
                o_tick       = 1'b1;
            end
        end else if (i_up) begin
            counter_next = counter_reg + 1;
            if (counter_reg == TIMES - 1) begin
                counter_next = 0;
            end
        end else if (i_down) begin
            counter_next = counter_reg - 1;
            if (counter_reg == 0) begin
                counter_next = TIMES - 1;
            end
        end
    end

endmodule



// 100Hz tick generator
module tick_gen_watch (
    input      clk,
    input      rst,
    output reg o_tick
);

    parameter F_COUNT = 100_000_000 / 100;  // sim을 위해 100K
    reg [$clog2(F_COUNT)-1:0] counter_reg;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            o_tick <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                o_tick = 1'b1;
            end else begin
                o_tick <= 1'b0;
            end
        end
    end

endmodule
