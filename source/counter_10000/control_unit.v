`timescale 1ns / 1ps

module control_unit (
    input      clk,
    input      rst,
    input      i_mode,
    input      i_clear,
    input      i_run_stop,
    output     o_mode,
    output reg o_run_stop,
    output reg o_clear
);
    parameter [1:0] STOP = 0, RUN = 1, CLEAR = 2, MODE = 3;
    reg [1:0] c_state, n_state;
    reg mode_reg, mode_next;
    //state register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state  <= STOP;
            mode_reg <= 1'b0;  //up_count
        end else begin
            c_state  <= n_state;
            mode_reg <= mode_next;  // mode memory
        end
    end

    assign o_mode = mode_reg;

    //next , output CL
    always @(*) begin
        n_state = c_state;
        mode_next = mode_reg;
        o_clear = 1'b0;
        o_run_stop = 1'b0;
        case (c_state)
            STOP: begin
                o_clear = 1'b0;
                o_run_stop = 1'b0;
                if (i_run_stop) begin
                    n_state = RUN;
                end else if (i_clear) begin
                    n_state = CLEAR;
                end else if (i_mode) begin
                    n_state = MODE;
                end else n_state = c_state;
            end
            RUN: begin
                o_run_stop = 1'b1;
                if (i_run_stop) begin
                    n_state = STOP;
                end
            end
            CLEAR: begin
                o_clear = 1'b1;
                n_state = STOP;
            end
            MODE: begin
                mode_next = ~mode_reg;
                n_state   = STOP;
            end
        endcase
    end

    // output 
endmodule
