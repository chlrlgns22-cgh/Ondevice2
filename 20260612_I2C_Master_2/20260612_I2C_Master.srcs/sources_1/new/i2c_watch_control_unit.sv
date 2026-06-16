`timescale 1ns / 1ps

module i2c_watch_control_unit #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input logic clk,
    input logic rst,
    // ============ FPGA signal ==========
    input logic btnR,
    input logic btnL,
    input logic btnU,
    input logic btnD,

    //============= DATAPATH control signal=======
    output logic h,
    output logic m,
    output logic s,

    output logic o_hour_up,
    output logic o_hour_down,
    output logic o_min_up,
    output logic o_min_down,
    output logic o_sec_up,
    output logic o_sec_down,

    //============== DATAPATH signal=============
    input  logic [MSEC_WIDTH-1:0] msec,
    input  logic [ SEC_WIDTH-1:0] sec,
    input  logic [ MIN_WIDTH-1:0] min,
    input  logic [HOUR_WIDTH-1:0] hour,
    //================ I2C =============
    input  logic                  done,
    input  logic                  read_start,
    input  logic                  read_next,
    input  logic [           7:0] rx_data,
    output logic [           7:0] tx_data
);

    // ======================= FPGA ===========================
    parameter [1:0] NORMAL = 2'd0, HOUR = 2'd1, MIN = 2'd2, SEC = 2'd3;

    logic [1:0] c_state, n_state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) c_state <= NORMAL;
        else c_state <= n_state;
    end

    always_comb begin
        n_state = c_state;
        h = 1'b0;
        m = 1'b0;
        s = 1'b0;

        case (c_state)
            NORMAL: begin
                if (btnR) n_state = HOUR;
                else if (btnL) n_state = SEC;
            end
            HOUR: begin
                h = 1'b1;
                if (btnR) n_state = MIN;
                else if (btnL) n_state = NORMAL;
            end
            MIN: begin
                m = 1'b1;
                if (btnR) n_state = SEC;
                else if (btnL) n_state = HOUR;
            end
            SEC: begin
                s = 1'b1;
                if (btnR) n_state = NORMAL;
                else if (btnL) n_state = MIN;
            end
            default: n_state = NORMAL;
        endcase
    end

    assign o_hour_up   = h & btnU;
    assign o_hour_down = h & btnD;
    assign o_min_up    = m  & btnU;
    assign o_min_down  = m  & btnD;
    assign o_sec_up    = s  & btnU;
    assign o_sec_down  = s  & btnD;

    // ==================== I2C ====================

    logic [1:0] tx_sel;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_data <= 8'h00;
            tx_sel  <= 2'd0;
        end else if (read_start) begin
            tx_data <= {3'b000, hour};
            tx_sel  <= 2'd1;
        end else if (read_next) begin
            case (tx_sel)
                2'd1: tx_data <= {2'b00, min};
                2'd2: tx_data <= {2'b00, sec};
                2'd3: tx_data <= {1'b0, msec};
                default: tx_data <= {3'b000, hour};
            endcase
            tx_sel <= tx_sel + 1'b1;
        end
    end

endmodule
