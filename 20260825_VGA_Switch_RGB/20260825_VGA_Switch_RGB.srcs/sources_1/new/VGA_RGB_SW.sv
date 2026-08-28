`timescale 1ns / 1ps

module VGA_RGB_SW (
    input  logic       de,
    input  logic [9:0] x_pixel,
    input  logic [9:0] y_pixel,
    output logic [3:0] port_red,
    output logic [3:0] port_green,
    output logic [3:0] port_blue
);

    always_comb begin
        port_red   = 0;
        port_green = 0;
        port_blue  = 0;

        if (de) begin
            if (y_pixel <= 319) begin  // 상단
                if (x_pixel <= 91) begin
                    port_red   = 15;
                    port_green = 15;
                    port_blue  = 15;
                end else if (x_pixel <= 183) begin
                    port_red   = 15;
                    port_green = 15;
                    port_blue  = 0;
                end else if (x_pixel <= 275) begin
                    port_red   = 0;
                    port_green = 15;
                    port_blue  = 15;
                end else if (x_pixel <= 367) begin
                    port_red   = 0;
                    port_green = 15;
                    port_blue  = 0;
                end else if (x_pixel <= 459) begin
                    port_red   = 15;
                    port_green = 0;
                    port_blue  = 15;
                end else if (x_pixel <= 551) begin
                    port_red   = 15;
                    port_green = 0;
                    port_blue  = 0;
                end else begin
                    port_red   = 0;
                    port_green = 0;
                    port_blue  = 15;
                end
            end else if (y_pixel <= 359) begin  // 중단
                if (x_pixel <= 91) begin
                    port_red   = 0;
                    port_green = 0;
                    port_blue  = 15;
                end else if (x_pixel <= 183) begin
                    port_red   = 0;
                    port_green = 0;
                    port_blue  = 0;
                end else if (x_pixel <= 275) begin
                    port_red   = 15;
                    port_green = 0;
                    port_blue  = 15;
                end else if (x_pixel <= 367) begin
                    port_red   = 0;
                    port_green = 0;
                    port_blue  = 0;
                end else if (x_pixel <= 459) begin
                    port_red   = 0;
                    port_green = 15;
                    port_blue  = 15;
                end else if (x_pixel <= 551) begin
                    port_red   = 0;
                    port_green = 0;
                    port_blue  = 0;
                end else begin
                    port_red   = 15;
                    port_green = 15;
                    port_blue  = 15;
                end
            end else begin  // 하단
                if (x_pixel <= 105) begin
                    port_red   = 0;
                    port_green = 0;
                    port_blue  = 7;
                end else if (x_pixel <= 211) begin
                    port_red   = 15;
                    port_green = 15;
                    port_blue  = 15;
                end else if (x_pixel <= 317) begin
                    port_red   = 7;
                    port_green = 0;
                    port_blue  = 15;
                end else if (x_pixel <= 459) begin
                    port_red   = 0;
                    port_green = 0;
                    port_blue  = 0;
                end else if (x_pixel <= 495) begin
                    port_red   = 4;
                    port_green = 4;
                    port_blue  = 4;
                end else if (x_pixel <= 531) begin
                    port_red   = 8;
                    port_green = 8;
                    port_blue  = 8;
                end else begin
                    port_red   = 0;
                    port_green = 0;
                    port_blue  = 0;
                end
            end
        end
    end
endmodule
