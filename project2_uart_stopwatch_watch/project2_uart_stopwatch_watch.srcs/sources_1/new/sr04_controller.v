module sr04_controller (
    input        clk,
    input        rst,
    input        sr04_start,
    input        tick_us,
    input        echo,
    output       trig,
    output [8:0] distance
);

    parameter IDLE = 0, START = 1, WAIT = 2, RESPONSE = 3;

    parameter F_COUNT = 100_000_000 * 15;

    reg [1:0] c_state, n_state;
    reg [15:0] tick_cnt_reg, tick_cnt_next;
    reg [8:0] distance_reg, distance_next;
    reg trig_reg, trig_next;
    reg [$clog2(F_COUNT)-1:0] start_cnt_reg, start_cnt_next;

    assign trig     = trig_reg;
    assign distance = distance_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state       <= IDLE;
            tick_cnt_reg  <= 0;
            trig_reg      <= 1'b0;
            distance_reg  <= 0;
            start_cnt_reg <= 0;
        end else begin
            c_state       <= n_state;
            tick_cnt_reg  <= tick_cnt_next;
            trig_reg      <= trig_next;
            distance_reg  <= distance_next;
            start_cnt_reg <= start_cnt_next;
        end
    end

    always @(*) begin
        n_state        = c_state;
        tick_cnt_next  = tick_cnt_reg;
        trig_next      = trig_reg;
        distance_next  = distance_reg;
        start_cnt_next = start_cnt_reg;

        case (c_state)
            IDLE: begin
                trig_next     = 1'b0;
                tick_cnt_next = 0;
                if (sr04_start) begin
                    if (start_cnt_reg == F_COUNT - 1) begin
                        start_cnt_next = 0;
                        n_state = START;
                    end else begin
                        start_cnt_next = start_cnt_reg + 1;
                    end
                end else begin
                    start_cnt_next = 0;
                end
            end

            START: begin
                trig_next = 1'b1;
                if (tick_us) begin
                    if (tick_cnt_reg >= 12) begin
                        tick_cnt_next = 0;
                        n_state = WAIT;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

            WAIT: begin
                trig_next     = 1'b0;
                tick_cnt_next = 0;
                if (echo) begin
                    n_state = RESPONSE;
                end
            end

            RESPONSE: begin
                trig_next = 1'b0;
                if (echo) begin
                    if (tick_us) begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end else begin
                    distance_next = tick_cnt_reg / 58;
                    tick_cnt_next = 0;
                    n_state = IDLE;
                end
            end
        endcase
    end
endmodule
