`timescale 1ps / 1ps

module dht11 (
    input        clk,
    input        rst,
    input        btn_R,
    output [3:0] fnd_com,
    output [7:0] fnd_data,
    inout        dht11
);


endmodule

module dht11_controller (
    input        clk,
    input        rst,
    input        dht11_start,
    input        tick_us,
    output [7:0] humidity,
    output [7:0] temperature,
    output       valid,
    inout        dht11
);
    parameter IDLE = 0, START = 1, WAIT = 2, SYNC_L = 3, SYNC_H = 4;
    parameter DATA_SYNC = 5, DATA_DECISION = 6, DATA_COUNT = 7, STOP = 8;

    reg [3:0] c_state, n_state;
    reg [5:0] bit_cnt_reg, bit_cnt_next;  //receive bit counter
    reg [$clog2(19000)-1:0] tick_cnt_reg, tick_cnt_next;  //general tick count
    reg out_sel_reg, out_sel_next;  //dht11 io 3state control
    reg dht11_reg, dht11_next;  //dht11 output drive

    reg [39:0] data_reg, data_next;

    // dht11 output 3state control
    assign dht11 = (out_sel_reg) ? dht11_reg : 1'bz;

    assign valid =(data_reg[7:0] == (data_reg [39:32] +data_reg [31:24] + data_reg [23:16]+ data_reg[15:8])) ? 1:0;

    assign humidity = data_reg[39:32];
    assign temperature = data_reg[23:16];

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state      <= IDLE;
            bit_cnt_reg  <= 0;
            tick_cnt_reg <= 0;
            out_sel_reg  <= 1'b1;  //default output mode
            dht11_reg    <= 1'b1;  //default high state
            data_reg     <= 0;
        end else begin
            c_state      <= n_state;
            bit_cnt_reg  <= bit_cnt_next;
            tick_cnt_reg <= tick_cnt_next;
            out_sel_reg  <= out_sel_next;
            dht11_reg    <= dht11_next;
            data_reg     <= data_next;
        end
    end

    always @(*) begin
        n_state       = c_state;
        bit_cnt_next  = bit_cnt_reg;
        tick_cnt_next = tick_cnt_reg;
        out_sel_next  = out_sel_reg;
        dht11_next    = dht11_reg;
        data_next     = data_reg;
        case (c_state)
            IDLE: begin
                dht11_next   = 1'b1;
                out_sel_next = 1'b1;
                if (dht11_start) begin
                    bit_cnt_next = 0;
                    tick_cnt_next = 0;
                    n_state = START;
                end
            end
            START: begin
                dht11_next = 1'b0;
                if (tick_us) begin
                    if (tick_cnt_reg > 18_000) begin
                        n_state = WAIT;
                        tick_cnt_next = 0;
                    end else tick_cnt_next = tick_cnt_reg + 1;
                end
            end
            WAIT: begin
                dht11_next = 1'b1;
                if (tick_us) begin
                    if (tick_cnt_reg > 30) begin
                        tick_cnt_next = 0;
                        n_state = SYNC_L;
                    end else tick_cnt_next = tick_cnt_reg + 1;
                end
            end
            SYNC_L: begin
                //output is high impedence "z"
                out_sel_next = 1'b0;
                if (tick_us) begin
                    if ((tick_cnt_reg > 40) && (dht11)) begin
                        tick_cnt_next = 0;
                        n_state = SYNC_H;
                    end else tick_cnt_next = tick_cnt_reg + 1;
                end
            end
            SYNC_H: begin
                if (tick_us) begin
                    if ((tick_cnt_reg > 40) && (!dht11)) begin
                        tick_cnt_next = 0;
                        n_state = DATA_SYNC;
                    end else tick_cnt_next = tick_cnt_reg + 1;
                end
            end
            DATA_SYNC: begin
                if (tick_us) begin
                    if (dht11) begin
                        tick_cnt_next = 0;
                        n_state = DATA_COUNT;
                    end else tick_cnt_next = tick_cnt_reg + 1;
                end
            end
            DATA_COUNT: begin
                if (tick_us) begin
                    if (!dht11) begin
                        tick_cnt_next = 0;
                        n_state = DATA_DECISION;
                    end else tick_cnt_next = tick_cnt_reg + 1;
                end
            end
            DATA_DECISION: begin
                bit_cnt_next = bit_cnt_reg + 1;
                if (bit_cnt_reg == 39) begin
                    n_state = STOP;
                end
            end
            STOP: begin
                if (tick_us) begin
                    if (tick_cnt_reg > 50) begin
                        tick_cnt_next = 0;
                        n_state = IDLE;
                    end else tick_cnt_next = tick_cnt_reg + 1;
                end
            end
        endcase
    end
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
