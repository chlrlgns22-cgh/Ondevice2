`timescale 1ns / 1ps

module spi_slave_top (
    input  logic       clk,
    input  logic       rst,
    // from master
    input  logic       sclk,
    input  logic       mosi,
    input  logic       ss_n,
    output logic       miso,
    // connect with IP
    input  logic [7:0] tx_data,  // get from IP
    output logic [7:0] rx_data,  // get from Master
    output logic       busy,
    output logic       done
);

    typedef enum logic [1:0] {
        IDLE = 2'b01,
        DATA,
        DONE
    } slave_state_e;

    slave_state_e state;

    logic [2:0] bit_cnt;
    logic [7:0] rx_shift_reg;
    logic [7:0] tx_shift_reg;
    logic sclk_d1, sclk_d2;
    logic ss_n_d1, ss_n_d2;
    logic mosi_d1;


    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            sclk_d1 <= 1'b0;
            sclk_d2 <= 1'b0;
            ss_n_d1 <= 1'b0;
            ss_n_d2 <= 1'b0;
            mosi_d1 <= 1'b0;
        end else begin
            sclk_d1 <= sclk;
            sclk_d2 <= sclk_d1;
            ss_n_d1 <= ss_n;
            ss_n_d2 <= ss_n_d1;
            mosi_d1 <= mosi;
        end
    end

    logic sclk_rising  = sclk_d1 & ~sclk_d2;
    logic sclk_falling = ~sclk_d1 & sclk_d2;
    logic ss_active    = ~ss_n_d2;

    assign busy    = (state != IDLE);
    assign rx_data = rx_shift_reg;
    assign miso    = tx_shift_reg[7];

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state        <= IDLE;
            bit_cnt      <= 0;
            done         <= 1'b0;
            rx_shift_reg <= 0;
            tx_shift_reg <= 0;
        end else begin
            done <= 1'b0;
            if (!ss_active) begin
                state        <= IDLE;
                bit_cnt      <= 0;
                tx_shift_reg <= tx_data;
            end else begin
                case (state)
                    IDLE: begin
                        if (sclk_rising) begin
                            state        <= DATA;
                            bit_cnt      <= 3'd1;
                            rx_shift_reg <= {7'd0, mosi_d1};
                        end
                    end
                    DATA: begin
                        if (sclk_rising) begin
                            rx_shift_reg <= {rx_shift_reg[6:0], mosi_d1};
                            if (bit_cnt == 7) begin
                                state   <= DONE;
                                done    <= 1'b1;
                                bit_cnt <= 0;
                            end else begin
                                bit_cnt <= bit_cnt + 1;
                            end
                        end else if (sclk_falling) begin
                            tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                        end
                    end
                    DONE: begin
                        state <= IDLE;
                    end
                    default: state <= IDLE;
                endcase
            end
        end
    end
endmodule
