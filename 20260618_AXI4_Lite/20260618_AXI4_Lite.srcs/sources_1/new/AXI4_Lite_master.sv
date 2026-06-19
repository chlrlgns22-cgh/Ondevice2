`timescale 1ns / 1ps

module AXI4_Lite_master (
    input  logic        clk,
    input  logic        rst,
    // connect with host
    input  logic        transfer,
    input  logic        write,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    output logic        ready,
    output logic [31:0] rdata,
    //  connect with slave
    //  AW
    input  logic        aw_ready,
    output logic        aw_valid,
    output logic [31:0] aw_addr,
    //  W
    input  logic        w_ready,
    output logic        w_valid,
    output logic [31:0] w_data,
    //  B
    input  logic        b_valid,
    input  logic [ 1:0] b_resp,
    output logic        b_ready,
    //  AR
    input  logic        ar_ready,
    output logic        ar_valid,
    output logic [31:0] ar_addr,
    //  R
    input  logic        r_valid,
    input  logic [ 1:0] r_resp,
    input  logic [31:0] r_data,
    output logic        r_ready
);

    typedef enum logic {
        IDLE,
        VALID
    } state_e;
    state_e AW_STATE, W_STATE, B_STATE, AR_STATE, R_STATE;

    logic wr_done, rd_done;
    assign ready = wr_done | rd_done;

    //  AW
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            AW_STATE <= IDLE;
            aw_valid <= 0;
            aw_addr  <= 0;
        end else begin
            case (AW_STATE)
                IDLE: begin
                    if (transfer && write) begin
                        AW_STATE <= VALID;
                        aw_addr  <= addr;
                        aw_valid <= 1;
                    end
                end
                VALID: begin
                    if (aw_ready) begin
                        AW_STATE <= IDLE;
                        aw_valid <= 0;
                    end
                end
            endcase
        end
    end

    //  W
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            W_STATE <= IDLE;
            w_valid <= 0;
            w_data  <= 0;
        end else begin
            case (W_STATE)
                IDLE: begin
                    if (transfer && write) begin
                        W_STATE <= VALID;
                        w_data  <= wdata;
                        w_valid <= 1;
                    end
                end
                VALID: begin
                    if (w_ready) begin
                        W_STATE <= IDLE;
                        w_valid <= 0;
                    end
                end
            endcase
        end
    end

    //  B
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            B_STATE <= IDLE;
            b_ready <= 0;
            wr_done <= 0;
        end else begin
            case (B_STATE)
                IDLE: begin
                    wr_done <= 0;
                    if (w_valid) begin
                        B_STATE <= VALID;
                        b_ready <= 1;
                    end
                end
                VALID: begin
                    if (b_valid) begin
                        B_STATE <= IDLE;
                        b_ready <= 0;
                        wr_done <= 1;
                    end
                end
            endcase
        end
    end

    //  AR
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            AR_STATE <= IDLE;
            ar_valid <= 0;
            ar_addr  <= 0;
        end else begin
            case (AR_STATE)
                IDLE: begin
                    if (transfer && !write) begin
                        AR_STATE <= VALID;
                        ar_addr  <= addr;
                        ar_valid <= 1;
                    end
                end
                VALID: begin
                    if (ar_ready) begin
                        AR_STATE <= IDLE;
                        ar_valid <= 0;
                    end
                end
            endcase
        end
    end

    //  R
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            R_STATE <= IDLE;
            r_ready <= 0;
            rdata   <= 0;
            rd_done <= 0;
        end else begin
            case (R_STATE)
                IDLE: begin
                    rd_done <= 0;
                    if (ar_valid) begin
                        R_STATE <= VALID;
                        r_ready <= 1;
                    end
                end
                VALID: begin
                    if (r_valid) begin
                        R_STATE <= IDLE;
                        r_ready <= 0;
                        rdata   <= r_data;
                        rd_done <= 1;
                    end
                end
            endcase
        end
    end

endmodule