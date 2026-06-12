`timescale 1ns / 1ps

module uart_sv (
    input        clk,
    input        rst,
    input        tx_start,
    input  [7:0] tx_data,
    input        rx,
    output [7:0] rx_data,
    output       rx_done,
    output       tx_busy,
    output       tx
);

    logic w_b_tick;
    uart_rx U_UART_RX (
        .clk    (clk),
        .rst    (rst),
        .b_tick (w_b_tick),
        .rx     (rx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    uart_tx U_UART_TX (
        .clk     (clk),
        .rst     (rst),
        .tx_start(tx_start),  // start trigger
        .tx_data (tx_data),
        .b_tick  (w_b_tick),
        .tx      (tx),
        .tx_busy (tx_busy)
    );

    baud_tick_gen U_BAUD_TICK_GEN (
        .clk     (clk),
        .rst     (rst),
        .o_b_tick(w_b_tick)
    );

endmodule

module uart_rx (
    input        clk,
    input        rst,
    input        b_tick,
    input        rx,
    output [7:0] rx_data,
    output       rx_done
);

    parameter IDLE = 0, START = 1, DATA = 2, STOP = 3;

    logic [1:0] c_state, n_state;
    logic [4:0] b_tick_cnt_reg, b_tick_cnt_next;
    logic [2:0] bit_cnt_reg, bit_cnt_next;
    logic [7:0] data_reg, data_next;
    logic rx_done_reg, rx_done_next;

    assign rx_done = rx_done_reg;
    assign rx_data = data_reg;

    // current register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state        <= IDLE;
            b_tick_cnt_reg <= 0;
            bit_cnt_reg    <= 0;
            data_reg       <= 8'h00;
            rx_done_reg    <= 1'b0;

        end else begin
            c_state        <= n_state;
            b_tick_cnt_reg <= b_tick_cnt_next;
            bit_cnt_reg    <= bit_cnt_next;
            data_reg       <= data_next;
            rx_done_reg    <= rx_done_next;
        end
    end

    // next, output CL
    always @(*) begin
        n_state         = c_state;
        b_tick_cnt_next = b_tick_cnt_reg;
        bit_cnt_next    = bit_cnt_reg;
        data_next       = data_reg;
        rx_done_next    = rx_done_reg;

        case (c_state)
            IDLE: begin
                rx_done_next = 1'b0;
                if (b_tick && (!rx)) begin
                    b_tick_cnt_next = 0;
                    n_state         = START;
                end
            end

            START: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 7) begin
                        n_state = DATA;
                        bit_cnt_next = 0;
                        b_tick_cnt_next = 0;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end

            DATA: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        // data_next[7] = rx 넣고 shift
                        data_next       = {rx, data_reg[7:1]};
                        b_tick_cnt_next = 0;
                        if (bit_cnt_reg == 7) begin
                            b_tick_cnt_next = 0;
                            n_state         = STOP;
                        end else begin
                            bit_cnt_next = bit_cnt_reg + 1;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end

            STOP: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        rx_done_next = 1'b1;
                        n_state = IDLE;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            //default: 
        endcase

    end


endmodule

module uart_tx (
    input        clk,
    input        rst,
    input        tx_start,  // start trigger
    input  [7:0] tx_data,
    input        b_tick,
    output       tx,
    output       tx_busy
);

    parameter IDLE = 0, START = 1, DATA = 2, STOP = 3;

    // state register
    logic [1:0] c_state, n_state;
    logic tx_reg, tx_next;
    logic [7:0] data_reg, data_next;
    logic [2:0] bit_count_reg, bit_count_next;
    logic [3:0] b_tick_cnt_reg, b_tick_cnt_next;
    logic tx_busy_reg, tx_busy_next;

    assign tx = tx_reg;
    assign tx_busy = tx_busy_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state        <= IDLE;
            tx_reg         <= 1'b1;
            data_reg       <= 8'h00;
            bit_count_reg  <= 3'b000;
            b_tick_cnt_reg <= 4'h0;
            tx_busy_reg    <= 1'b0;
        end else begin
            c_state        <= n_state;
            tx_reg         <= tx_next;
            data_reg       <= data_next;
            bit_count_reg  <= bit_count_next;
            b_tick_cnt_reg <= b_tick_cnt_next;
            tx_busy_reg    <= tx_busy_next;
        end
    end

    // next st CL, output
    // input: current, output: next
    always @(*) begin
        n_state         = c_state;  // next state
        tx_next         = tx_reg;  // tx output
        data_next       = data_reg;
        bit_count_next  = bit_count_reg;
        b_tick_cnt_next = b_tick_cnt_reg;
        tx_busy_next    = tx_busy_reg;

        // currentstate
        case (c_state)
            IDLE: begin
                tx_next = 1'b1;
                if (tx_start) begin
                    tx_busy_next = 1'b1;
                    data_next = tx_data;
                    b_tick_cnt_next = 0;
                    n_state = START;
                end
            end

            START: begin
                tx_next = 1'b0;
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 4'h0;
                        n_state = DATA;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                        n_state = START;
                    end
                end
            end

            DATA: begin
                // PIPO
                //tx_next = data_reg[bit_count_reg];
                // PISO
                tx_next = data_reg[0];
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 4'h0;
                        data_next = {1'b0, data_reg[7:1]};
                        bit_count_next = bit_count_reg + 1;
                        if (bit_count_next == 0) begin
                            n_state = STOP;
                        end else begin
                            n_state = DATA;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                        n_state = DATA;
                    end
                end
            end

            STOP: begin
                tx_next = 1'b1;
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 4'h0;
                        tx_busy_next = 1'b0;
                        n_state = IDLE;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                        n_state = STOP;
                    end

                end
            end
        endcase
    end

    /* 수업
        always @(*) begin
        n_state = c_state;  // next state
        tx_next = tx_reg;  // tx output
        data_next = data_reg;
        bit_count_next = bit_count_reg;
        // currentstate
        case (c_state)
            IDLE: begin
                tx_next = 1'b1;
                if (tx_start) begin
                    data_next = tx_data;
                    n_state   = WAIT;
                end
            end
            WAIT: begin
                if (b_tick) n_state = START;
            end
            START: begin
                tx_next = 1'b0;
                if (b_tick) begin
                    bit_count_next = 3'b000; // 송신 이후 7을 초기화
                    n_state = DATA;
                end
            end
            // BIT
            DATA: begin // 이 구조면 7로 가고 초기화가 안됨-> start에서 초기화
                //tx_next = data_reg[bit_count_reg];
                //PISO
                tx_next = data_reg[0];  // to output from bit0 of data_reg
                if (b_tick) begin
                    if (bit_count_next == 7) begin
                        n_state = STOP;
                    end else begin
                        bit_count_next = bit_count_reg + 1;
                        data_next = {1'b0, data_reg[7:1]};  // right shift 1bit data register
                        n_state = DATA;
                    end
                end
            end

            STOP: begin
                tx_next = 1'b1;
                if (b_tick) n_state = IDLE;
            end
        endcase
    end
    */

endmodule

// baud tick * 16
module baud_tick_gen (
    input      clk,
    input      rst,
    output logic o_b_tick
);
    //baud tick 9600bps ( hz) tick_gen
    parameter F_COUNT = 100_000_000 / (9_600 * 16);
    parameter WIDTH = $clog2(F_COUNT) - 1;

    logic [WIDTH : 0] counter_reg;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            o_b_tick    <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                o_b_tick    <= 1'b1;
            end else begin
                o_b_tick <= 1'b0;
            end
        end
    end

endmodule
