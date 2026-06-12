`timescale 1ns / 1ps

module top_sr04_controller (
    input        clk,
    input        rst,
    input        btn_R,
    input        echo,
    output       trig,
    output [3:0] fnd_com,
    output [7:0] fnd_data
);

    wire w_sr04_start;
    wire w_tick_us;
    wire [8:0] w_distance;
    ila_0 U_ILA0 (
        .clk   (clk),
        .probe0(w_sr04_start),
        .probe1(w_distance)
    );

    button_debounce U_BD_SR04_START (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btn_R),
        .o_btn(w_sr04_start)
    );

    sr04_controller U_SR04_CONTROLLER (
        .clk       (clk),
        .rst       (rst),
        .sr04_start(w_sr04_start),
        .tick_us   (w_tick_us),
        .echo      (echo),
        .trig      (trig),
        .distance  (w_distance)
    );

    tick_gen_us U_TICK_GEN_US (
        .clk    (clk),
        .rst    (rst),
        .tick_us(w_tick_us)
    );

    fnd_controller U_FND_CTRL (
        .clk     (clk),
        .rst     (rst),
        .fnd_in  ({5'b00000, w_distance}),
        .fnd_com (fnd_com),
        .fnd_data(fnd_data)
    );



endmodule
module sr04_controller (
    input            clk,
    input            rst,
    input            sr04_start,
    input            tick_us,
    input            echo,
    output           trig,
    output reg [8:0] distance
);
    parameter [1:0] IDLE = 2'b00, START = 2'b01, WAIT = 2'b10, RESPONSE = 2'b11;
    reg [1:0] c_state, n_state;
    reg [15:0] tick_cnt_reg, tick_cnt_next;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= IDLE;
            tick_cnt_reg <= 0;
        end else begin
            c_state <= n_state;
            tick_cnt_reg <= tick_cnt_next;
        end
    end

    always @(*) begin
        n_state = c_state;
        tick_cnt_next = tick_cnt_reg;
        if (rst) distance = 0;
        case (c_state)
            IDLE:
            if (sr04_start == 1'b1) begin
                n_state = START;
            end
            START: begin
                if (tick_us == 1) begin
                    if (tick_cnt_reg >= 11) begin
                        n_state = WAIT;
                        tick_cnt_next = 0;
                    end else tick_cnt_next = tick_cnt_reg + 1;
                end
            end
            WAIT:
            if (tick_us == 1) begin
                if (echo == 1'b1) begin
                    n_state = RESPONSE;
                end else tick_cnt_next = tick_cnt_reg + 1;
            end
            RESPONSE:
            if (tick_us == 1) begin
                if (echo == 1'b0) begin
                    n_state  = IDLE;
                    distance = tick_cnt_reg / 58;
                end else tick_cnt_next = tick_cnt_reg + 1;
            end
        endcase
    end

    assign trig = (c_state == START);
endmodule


module tick_gen_us (
    input      clk,
    input      rst,
    output reg tick_us
);
    parameter F_COUNT = 100_000_000 / 1_000_000;
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            tick_us <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                tick_us <= 1'b1;
            end else tick_us <= 1'b0;
        end
    end
endmodule

