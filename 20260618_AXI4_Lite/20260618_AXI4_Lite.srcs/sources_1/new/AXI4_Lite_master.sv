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

    typedef enum {
        IDLE,
        VALID
    } state_e;
    state_e AW, W, B, AR, R;

    //  AW
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            AW <= IDLE;
        end else begin
            case (AW)
                IDLE: begin
                    if (transfer && write) begin
                        AW <= VALID;
                        aw_addr <= addr;
                        aw_valid <= 1;
                    end
                end
                VALID: begin
                    if (aw_ready) begin
                        AW <= IDLE;
                        aw_valid <= 0;
                    end
                end
            endcase
        end
    end

    //  W
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            W <= IDLE;
        end else begin
            case (W)
                IDLE: begin
                    if (transfer && write) begin
                        W <= VALID;
                        w_data <= wdata;
                        w_valid <= 1;
                    end
                end
                VALID: begin
                    if (w_ready) begin
                        W <= IDLE;
                        aw_valid <= 0;
                    end
                end
            endcase
        end
    end

    //  B
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            B <= IDLE;
        end else begin
            case (B)
                IDLE: begin
                    if (w_valid) begin
                        B <= VALID;
                        b_ready <= 0;
                        ready <= 0;
                    end
                end
                VALID: begin
                    if (b_valid) begin
                        W <= IDLE;
                        ready <= 1;
                    end
                end
            endcase
        end
    end

    //  AR
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            AR <= IDLE;
        end else begin
            case (AR)
                IDLE: begin
                    if (transfer && write) begin
                        AR <= VALID;
                        ar_addr <= addr;
                        ar_valid <= 1;
                    end
                end
                VALID: begin
                    if (ar_ready) begin
                        AR <= IDLE;
                        aw_valid <= 0;
                    end
                end
            endcase
        end
    end

    //  R
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            R <= IDLE;
        end else begin
            case (R)
                IDLE: begin
                    if (ar_valid) begin
                        R <= VALID;
                        r_ready <= 1;
                    end
                end
                VALID: begin
                    if (r_valid) begin
                        R <= IDLE;
                        r_ready <= 0;
                        rdata <= r_data;
                        ready <= 1;
                    end
                end
            endcase
        end
    end
endmodule
