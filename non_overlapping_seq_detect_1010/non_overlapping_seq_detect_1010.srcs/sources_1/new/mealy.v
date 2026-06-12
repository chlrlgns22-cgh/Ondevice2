`timescale 1ns / 1ps


module mealy (
    input  clk,
    input  rst,
    input  sw,
    output led
);

    parameter  STATE_A =2'b00, STATE_B=2'b01, STATE_C=2'b10, STATE_D = 2'b11 ;

    reg [1:0] current_state, next_state;
    reg led_reg;
    assign led = led_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            current_state <= STATE_A;
        end else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        next_state = current_state;
        led_reg = 1'b0;
        case (current_state)
            STATE_A:
            if (sw == 1'b1) begin
                next_state = STATE_B;
                led_reg = 1'b0;
            end else begin
                next_state = current_state;
                led_reg = 1'b00;
            end
            STATE_B:
            if (sw == 1'b0) begin
                next_state = STATE_C;
                led_reg = 1'b00;
            end else begin
                next_state = STATE_B;
                led_reg = 1'b00;
            end
            STATE_C:
            if (sw == 1'b1) begin
                next_state = STATE_D;
                led_reg = 1'b00;
            end else begin
                next_state = STATE_A;
                led_reg = 1'b00;
            end
            STATE_D:
            if (sw == 1'b1) begin
                next_state = STATE_B;
                led_reg = 1'b00;
            end else begin
                next_state = STATE_A;
                led_reg = 1'b01;
            end
        endcase

    end
endmodule
