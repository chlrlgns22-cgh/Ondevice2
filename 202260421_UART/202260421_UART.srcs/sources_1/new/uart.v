`timescale 1ns / 1ps

module uart (
    input        clk,
    input        rst,
    input        btnR,
    input  [7:0] tx_data,
    output       tx
);

    wire w_start, w_b_tick;

    button_debounce U_BD_TX_START (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnR),
        .o_btn(w_start)
    );

    uart_tx U_UART_TX (
        .clk     (clk),
        .rst     (rst),
        .tx_start(w_start),   //start trigger
        .tx_data (tx_data),
        .b_tick  (w_b_tick),
        .tx      (tx)
    );

    baud_tick_gen U_BAUD_TICK_GEN (
        .clk     (clk),
        .rst     (rst),
        .o_b_tick(w_b_tick)
    );

endmodule


module uart_tx (
    input        clk,
    input        rst,
    input        tx_start,  //start trigger
    input  [7:0] tx_data,
    input        b_tick,
    output       tx
);
    parameter IDLE = 0, WAIT = 1, START = 2;
    parameter BIT = 3, STOP = 4;

    reg [4:0] c_state, n_state;
    reg tx_reg, tx_next;
    //tx data register
    reg [7:0] data_reg, data_next;
    reg [2:0] bit_count, bit_count_next;

    assign tx = tx_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= IDLE;
            tx_reg <= 1'b1;
            data_reg <= 8'h00;
            bit_count <= 3'b000;
        end else begin
            c_state <= n_state;
            tx_reg <= tx_next;
            data_reg <= data_next;
            bit_count <= bit_count_next;
        end
    end

    always @(*) begin
        n_state   = c_state;  //n_state
        tx_next   = tx_reg;  // tx output
        data_next = data_reg;
        bit_count_next = bit_count;
        //curren state
        case (c_state)
            IDLE: begin
                tx_next = 1'b1;
                if (tx_start == 1'b1) begin
                    data_next = tx_data;
                    n_state   = WAIT;
                end
            end

            WAIT: begin
                if (b_tick == 1'b1) begin
                    n_state = START;
                end
            end

            START: begin
                tx_next = 1'b0;
                if (b_tick == 1'b1) begin
                    n_state = BIT;
                end
            end

            BIT: begin
                tx_next = data_reg[bit_count];
                if (b_tick == 1'b1) begin
                    if (bit_count > 3'd6) begin
                        n_state = STOP;
                    end else bit_count_next = bit_count + 1;
                end
            end

            STOP: begin
                tx_next = 1'b1;
                bit_count_next =3'd0;
                if (b_tick == 1'b1) begin
                    n_state = IDLE;
                end
            end
        endcase
    end

endmodule

module baud_tick_gen (
    input      clk,
    input      rst,
    output reg o_b_tick
);

    parameter F_count = 100_000_000 / 9600;
    parameter WIDTH = $clog2(F_count) - 1;
    reg [WIDTH:0] counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            o_b_tick <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == (F_count - 1)) begin
                counter_reg <= 0;
                o_b_tick <= 1'b1;
            end else o_b_tick <= 1'b0;
        end
    end

endmodule
