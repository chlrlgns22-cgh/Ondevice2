`timescale 1ns / 1ps

module stopwatch_datapath #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input                   clk,
    input                   rst,
    input                   i_run_stop,
    input                   i_clear,
    input                   i_mode,
    output [MSEC_WIDTH-1:0] msec,
    output [ SEC_WIDTH-1:0] sec,
    output [ MIN_WIDTH-1:0] min,
    output [HOUR_WIDTH-1:0] hour
);

    wire w_msec_tick, w_sec_tick, w_min_tick, w_hour_tick;

    // hour
    tick_counter #(
        .TIMES    (24),
        .BIT_WIDTH(HOUR_WIDTH)
    ) U_HOUR_TICK_COUNTER (
        .clk         (clk),
        .rst         (rst),
        .i_tick      (w_hour_tick),  // from min o_tick
        .i_clear     (i_clear),
        .i_mode      (i_mode),
        .time_counter(hour),
        .o_tick      ()
    );
    // min
    tick_counter #(
        .TIMES    (60),
        .BIT_WIDTH(MIN_WIDTH)
    ) U_MIN_TICK_COUNTER (
        .clk         (clk),
        .rst         (rst),
        .i_tick      (w_min_tick),  // from sec o_tick
        .i_clear     (i_clear),
        .i_mode      (i_mode),
        .time_counter(min),
        .o_tick      (w_hour_tick)
    );
    // sec
    tick_counter #(
        .TIMES    (60),
        .BIT_WIDTH(SEC_WIDTH)
    ) U_SEC_TICK_COUNTER (
        .clk         (clk),
        .rst         (rst),
        .i_tick      (w_sec_tick),  // from msec o_tick
        .i_clear     (i_clear),
        .i_mode      (i_mode),
        .time_counter(sec),
        .o_tick      (w_min_tick)
    );
    //msec
    tick_counter #(
        .TIMES    (100),
        .BIT_WIDTH(MSEC_WIDTH)
    ) U_MSEC_TICK_COUNTER (
        .clk         (clk),
        .rst         (rst),
        .i_tick      (w_msec_tick), // from tick_gen o_tick
        .i_clear     (i_clear),
        .i_mode      (i_mode),
        .time_counter(msec),
        .o_tick      (w_sec_tick)
    );
    // 100hz tick gen
    tick_gen_100hz U_TICK_GEN (
        .clk         (clk),
        .rst         (rst),
        .i_run_stop  (i_run_stop),
        .i_clear     (i_clear),
        .o_tick_100hz(w_msec_tick)
    );

endmodule

// tick counter
module tick_counter #(
    parameter TIMES = 100,
    BIT_WIDTH = 7
) (
    input                         clk,
    input                         rst,
    input                         i_tick,
    input                         i_clear,
    input                         i_mode,
    output     [BIT_WIDTH -1 : 0] time_counter,
    output reg                    o_tick
);
    // counter register
    reg [BIT_WIDTH -1:0] counter_reg, counter_next;
    assign time_counter = counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
        end else begin
            counter_reg <= counter_next;
        end
    end

    // next counter, o_tick CL : blocking =
    // input counter_reg, output counter_next, o_tick
    always @(*) begin
        // default
        counter_next = counter_reg;
        o_tick = 1'b0;
        if (i_tick) begin
            if (i_mode) begin
                // up count
                counter_next = counter_reg - 1; // tick이 들어오면 입력에 1 더해서 출력
                if (counter_reg == 0) begin  // 입력이 목표값 도달
                    counter_next = TIMES - 1;  // 
                    o_tick = 1'b1;  // o_tick 발생  
                end
            end else begin
                // down count
                counter_next = counter_reg +1; // tick이 들어오면 입력에 1 더해서 출력
                if (counter_reg == TIMES - 1) begin  // 입력이 목표값 도달
                    counter_next = 0;  // 초기화
                    o_tick = 1'b1;  // o_tick 발생  
                end
            end
        end else if (i_clear) begin
            counter_next = 0;
            o_tick       = 1'b0;
        end
    end

endmodule

// tick generator
module tick_gen_100hz (
    input      clk,
    input      rst,
    input      i_run_stop,
    input      i_clear,
    output reg o_tick_100hz
);

    parameter F_COUNT = 100_000_000 / 100;  // 100MHz to 100Hz, sim -> 100K
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    // SL
    always @(posedge clk, posedge rst) begin
        if (rst) begin  // reset
            counter_reg  <= 0;
            o_tick_100hz <= 1'b0;
        end else begin
            if (i_run_stop) begin
                counter_reg <= counter_reg + 1;  // counting
                // o_tick_100hz <= 1'b0;  // race condition
                if (counter_reg == F_COUNT - 1) begin
                    counter_reg  <= 0;  // reset
                    o_tick_100hz <= 1'b1;  // generating tick
                end else begin
                    o_tick_100hz <= 1'b0;  // for 1 cycle
                end
            end else if (i_clear) begin
                counter_reg  <= 0;
                o_tick_100hz <= 1'b0;
            end
        end
    end

endmodule
