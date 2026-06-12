`timescale 1ns / 1ps

module moore (
    input  clk,
    input  rst,
    input  sw,
    output led
);


    parameter  STATE_A =3'b000, STATE_B=3'b001, STATE_C=3'b010, STATE_D = 3'b011, STATE_E= 3'b100;

    reg [2:0] current_state, next_state;
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
        case (current_state)
            STATE_A:
            if (sw == 1'b1) next_state = STATE_B;
            else next_state = current_state;

            STATE_B:
            if (sw == 1'b0) next_state = STATE_C;
            else next_state = STATE_B;

            STATE_C:
            if (sw == 1'b1) next_state = STATE_D;
            else next_state = STATE_A;

            STATE_D:
            if (sw == 1'b0) next_state = STATE_E;
            else next_state = STATE_B;

            STATE_E:
            if (sw == 1'b0) next_state = STATE_A;
            else next_state = STATE_B;
            default: current_state = next_state;
        endcase

    end

    always @(*) begin
        case (current_state)
            STATE_A: led_reg = 1'b0;
            STATE_B: led_reg = 1'b0;
            STATE_C: led_reg = 1'b0;
            STATE_D: led_reg = 1'b0;
            STATE_E: led_reg = 1'b1;
            default: led_reg = 1'b0;
        endcase
    end
endmodule
