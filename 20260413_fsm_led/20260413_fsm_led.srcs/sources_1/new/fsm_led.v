`timescale 1ns / 1ps

module fsm_led (
    input clk,
    input rst,
    input [2:0] sw,
    output [2:0] led
);

    parameter STATE_A = 3'b000, STATE_B = 3'b001, STATE_C = 3'b010, STATE_D=3'b011, STATE_E = 3'b100;

    // state register

    //output SL
    reg [2:0] led_reg, led_next;

    reg [2:0] current_state, next_state;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            current_state = STATE_A;
            led_reg <= 3'b000;
        end else begin
            current_state = next_state;
            led_reg <= led_next;
        end

    end
    assign led = led_reg;
    //next state combinational logic
    always @(*) begin
        next_state = current_state;
        case (current_state)
            STATE_A: begin
                //led_next = 3'b000; //moore output
                if (sw == 3'b001) begin
                    next_state = STATE_B;
                    led_next   = 3'b001;  //mealy output
                end else if (sw == 3'b010) begin
                    next_state = STATE_C;
                    led_next   = 3'b010;
                end else begin
                    next_state = current_state;
                end
            end
            STATE_B: begin
                //led_next = 3'b001;
                if (sw == 3'b010) begin
                    next_state = STATE_C;
                    led_next   = 3'b010;
                end else begin
                    next_state = current_state;
                end
            end
            STATE_C: begin
                // led_next = 3'b010;
                if (sw == 3'b100) begin
                    next_state = STATE_D;
                    led_next   = 3'b100;
                end else begin
                    next_state = current_state;
                end
            end
            STATE_D: begin
                //led_next = 3'b100;
                if (sw == 3'b111) begin
                    next_state = STATE_E;
                    led_next   = 3'b111;
                end else if (sw == 3'b000) begin
                    next_state = STATE_A;
                    led_next   = 3'b000;
                end else if (sw == 3'b001) begin
                    next_state = STATE_B;
                    led_next   = 3'b001;
                end else begin
                    next_state = current_state;
                end
            end
            STATE_E: begin
                //led_next = 3'b111;
                if (sw == 3'b000) begin
                    next_state = STATE_A;
                    led_next   = 3'b000;
                end else begin
                    next_state = current_state;
                end
            end
            default: next_state = current_state;
        endcase
    end


    // output combinational logic
    /* assign led = led_reg;
    always @(*) begin
        case (current_state)
            STATE_A: led_reg = 3'b000;
            STATE_B: led_reg = 3'b001;
            STATE_C: led_reg = 3'b010;
            STATE_D: led_reg = 3'b100;
            STATE_E: led_reg = 3'b111;
            default: led_reg = 3'b000;
        endcase
    end*/

endmodule
