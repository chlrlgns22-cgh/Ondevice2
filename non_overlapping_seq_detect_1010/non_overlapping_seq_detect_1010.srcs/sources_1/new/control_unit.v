`timescale 1ns / 1ps

module control_unit (
    input clk,
    input rst,
    input btnD,  //mode
    input btnL,  //clear
    input btnR,  //run_stop
    output reg run_stop,
    output reg clear,
    output reg mode
);

    parameter [1:0] STATE_stop = 2'b00;
    parameter [1:0] STATE_run = 2'b01;
    parameter [1:0] STATE_mode = 2'b10;
    parameter [1:0] STATE_clear = 2'b11;
    reg [1:0] current_state, next_state;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            current_state <= STATE_stop;
            run_stop <= 1'b0;
            clear <= 1'b0;
            mode <= 1'b0;
        end else current_state <= next_state;
    end

    always @(*) begin
        case (current_state)
            STATE_stop:
            if (btnR == 1) next_state = STATE_run;
            else if (btnD == 1) next_state = STATE_mode;
            else if (btnL == 1) next_state = STATE_clear;
            else next_state = current_state;

            STATE_run:
            if (btnR == 1) next_state = STATE_stop;
            else next_state = current_state;

            STATE_mode: next_state = STATE_stop;

            STATE_clear: next_state = STATE_stop;
        endcase
    end

    always @(*) begin
        case (current_state)
            STATE_stop: begin
                run_stop = 1'b0;
                clear = 1'b0;
            end
            STATE_run: run_stop = 1'b1;

            STATE_mode: mode = ~mode;

            STATE_clear: clear = 1'b1;
        endcase
    end
endmodule
