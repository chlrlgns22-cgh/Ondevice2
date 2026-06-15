`timescale 1ns / 1ps

module i2c_slave_watch_top #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5,
    SLAVE_ADDR = 7'h12
) (
    input  logic       clk,
    input  logic       rst,
    input  logic       btnR,
    input  logic       btnL,
    input  logic       btnU,
    input  logic       btnD,
    input  logic       sw,
    input  logic       scl,
    inout  wire        sda,
    output logic [3:0] fnd_com,
    output logic [7:0] fnd_data
);
    logic sda_i;
    logic sda_o;
    logic done;
    logic read_start;
    logic read_next;
    logic [7:0] tx_data;
    logic [7:0] rx_data;

    logic [MSEC_WIDTH-1:0] msec;
    logic [ SEC_WIDTH-1:0] sec;
    logic [ MIN_WIDTH-1:0] min;
    logic [HOUR_WIDTH-1:0] hour;

    logic btnR_d;
    logic btnL_d;
    logic btnU_d;
    logic btnD_d;
    logic h;
    logic m;
    logic s;
    logic o_hour_up;
    logic o_hour_down;
    logic o_min_up;
    logic o_min_down;
    logic o_sec_up;
    logic o_sec_down;
    logic unused_led;

    assign sda_i = sda;
    assign sda   = sda_o ? 1'bz : 1'b0;

    i2c_slave #(
        .SLAVE_ADDR(SLAVE_ADDR)
    ) U_I2C_SLAVE (
        .clk    (clk),
        .rst    (rst),
        .scl    (scl),
        .sda_i  (sda_i),
        .sda_o  (sda_o),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .done   (done),
        .read_start(read_start),
        .read_next(read_next)
    );

    i2c_watch_control_unit U_CTRL_UNIT (
        .*,
        .btnR(btnR_d),
        .btnL(btnL_d),
        .btnU(btnU_d),
        .btnD(btnD_d)
    );

    watch_datapath U_WATCH_DATAPATH (.*);

    fnd_controller U_FND_CONTROLLER (
        .*,
        .sw (sw),
        .led(unused_led)
    );

    button_debounce U_BTNR (
        .*,
        .i_btn(btnR),
        .o_btn(btnR_d)
    );

    button_debounce U_BTNL (
        .*,
        .i_btn(btnL),
        .o_btn(btnL_d)
    );

    button_debounce U_BTNU (
        .*,
        .i_btn(btnU),
        .o_btn(btnU_d)
    );

    button_debounce U_BTND (
        .*,
        .i_btn(btnD),
        .o_btn(btnD_d)
    );

endmodule

module i2c_slave #(
    parameter SLAVE_ADDR = 7'h12
) (
    input  logic       clk,
    input  logic       rst,
    input  logic       scl,
    input  logic       sda_i,
    output logic       sda_o,
    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       done,
    output logic       read_start,
    output logic       read_next
);
    typedef enum logic [2:0] {
        IDLE,
        ADDR,
        ADDR_ACK,
        RX_DATA,
        RX_ACK,
        TX_DATA,
        TX_ACK,
        WAIT_STOP
    } i2c_state_e;

    i2c_state_e state;

    logic scl_d1;
    logic scl_d2;
    logic sda_d1;
    logic sda_d2;
    logic scl_rising;
    logic scl_falling;
    logic sda_rising;
    logic sda_falling;
    logic start_detected;
    logic stop_detected;

    logic [7:0] rx_shift_reg;
    logic [7:0] tx_shift_reg;
    logic [2:0] bit_cnt;
    logic address_match;
    logic is_read;
    logic ack_clocked;
    logic master_ack;
    logic sda_release;

    assign scl_rising    = scl_d1 & ~scl_d2;
    assign scl_falling   = ~scl_d1 & scl_d2;
    assign sda_rising    = sda_d1 & ~sda_d2;
    assign sda_falling   = ~sda_d1 & sda_d2;
    assign start_detected = sda_falling & scl_d2;
    assign stop_detected  = sda_rising & scl_d2;
    assign sda_o          = sda_release;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            scl_d1 <= 1'b1;
            scl_d2 <= 1'b1;
            sda_d1 <= 1'b1;
            sda_d2 <= 1'b1;
        end else begin
            scl_d1 <= scl;
            scl_d2 <= scl_d1;
            sda_d1 <= sda_i;
            sda_d2 <= sda_d1;
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state         <= IDLE;
            sda_release   <= 1'b1;
            rx_data       <= 8'h00;
            done          <= 1'b0;
            read_start    <= 1'b0;
            read_next     <= 1'b0;
            rx_shift_reg  <= 8'h00;
            tx_shift_reg  <= 8'h00;
            bit_cnt       <= 3'd0;
            address_match <= 1'b0;
            is_read       <= 1'b0;
            ack_clocked   <= 1'b0;
            master_ack    <= 1'b1;
        end else begin
            done       <= 1'b0;
            read_start <= 1'b0;
            read_next  <= 1'b0;

            if (start_detected) begin
                state         <= ADDR;
                sda_release   <= 1'b1;
                rx_shift_reg  <= 8'h00;
                bit_cnt       <= 3'd0;
                address_match <= 1'b0;
                ack_clocked   <= 1'b0;
            end else if (stop_detected) begin
                state       <= IDLE;
                sda_release <= 1'b1;
                bit_cnt     <= 3'd0;
                ack_clocked <= 1'b0;
            end else begin
                case (state)
                    IDLE: begin
                        sda_release <= 1'b1;
                    end

                    ADDR: begin
                        if (scl_rising) begin
                            rx_shift_reg <= {rx_shift_reg[6:0], sda_d2};
                            if (bit_cnt == 3'd7) begin
                                address_match <=
                                    (rx_shift_reg[6:0] == SLAVE_ADDR);
                                is_read     <= sda_d2;
                                if ((rx_shift_reg[6:0] == SLAVE_ADDR) &&
                                    sda_d2) begin
                                    read_start <= 1'b1;
                                end
                                bit_cnt     <= 3'd0;
                                ack_clocked <= 1'b0;
                                state       <= ADDR_ACK;
                            end else begin
                                bit_cnt <= bit_cnt + 1'b1;
                            end
                        end
                    end

                    ADDR_ACK: begin
                        if (scl_falling && !ack_clocked) begin
                            sda_release <= ~address_match;
                        end else if (scl_rising) begin
                            ack_clocked <= 1'b1;
                        end else if (scl_falling && ack_clocked) begin
                            ack_clocked <= 1'b0;
                            bit_cnt     <= 3'd0;
                            if (!address_match) begin
                                sda_release <= 1'b1;
                                state       <= WAIT_STOP;
                            end else if (is_read) begin
                                tx_shift_reg <= tx_data;
                                sda_release  <= tx_data[7];
                                state        <= TX_DATA;
                            end else begin
                                sda_release  <= 1'b1;
                                rx_shift_reg <= 8'h00;
                                state        <= RX_DATA;
                            end
                        end
                    end

                    RX_DATA: begin
                        if (scl_rising) begin
                            rx_shift_reg <= {rx_shift_reg[6:0], sda_d2};
                            if (bit_cnt == 3'd7) begin
                                rx_data     <= {rx_shift_reg[6:0], sda_d2};
                                done        <= 1'b1;
                                bit_cnt     <= 3'd0;
                                ack_clocked <= 1'b0;
                                state       <= RX_ACK;
                            end else begin
                                bit_cnt <= bit_cnt + 1'b1;
                            end
                        end
                    end

                    RX_ACK: begin
                        if (scl_falling && !ack_clocked) begin
                            sda_release <= 1'b0;
                        end else if (scl_rising) begin
                            ack_clocked <= 1'b1;
                        end else if (scl_falling && ack_clocked) begin
                            sda_release  <= 1'b1;
                            rx_shift_reg <= 8'h00;
                            ack_clocked  <= 1'b0;
                            state        <= RX_DATA;
                        end
                    end

                    TX_DATA: begin
                        if (scl_rising) begin
                            if (bit_cnt == 3'd7) begin
                                bit_cnt     <= 3'd0;
                                ack_clocked <= 1'b0;
                                state       <= TX_ACK;
                            end else begin
                                bit_cnt <= bit_cnt + 1'b1;
                            end
                        end else if (scl_falling) begin
                            tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                            sda_release  <= tx_shift_reg[6];
                        end
                    end

                    TX_ACK: begin
                        if (scl_falling && !ack_clocked) begin
                            sda_release <= 1'b1;
                        end else if (scl_rising) begin
                            master_ack  <= sda_d2;
                            ack_clocked <= 1'b1;
                            done        <= 1'b1;
                            if (!sda_d2) begin
                                read_next <= 1'b1;
                            end
                        end else if (scl_falling && ack_clocked) begin
                            ack_clocked <= 1'b0;
                            if (!master_ack) begin
                                tx_shift_reg <= tx_data;
                                sda_release  <= tx_data[7];
                                state        <= TX_DATA;
                            end else begin
                                sda_release <= 1'b1;
                                state       <= WAIT_STOP;
                            end
                        end
                    end

                    WAIT_STOP: begin
                        sda_release <= 1'b1;
                    end

                    default: begin
                        state       <= IDLE;
                        sda_release <= 1'b1;
                    end
                endcase
            end
        end
    end

endmodule
