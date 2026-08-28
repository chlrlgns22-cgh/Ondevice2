`timescale 1ns / 1ps

module ColorBar (
    input  logic [9:0] x_pixel,
    input  logic [9:0] y_pixel,
    input  logic       de,
    output logic [3:0] port_red,
    output logic [3:0] port_green,
    output logic [3:0] port_blue
);
    localparam WHITE = 12'hfff;
    localparam YELLOW = 12'hff0;
    localparam CYAN = 12'h0ff;
    localparam GREEN = 12'h0f0;
    localparam MAGENTA = 12'hf0f;
    localparam RED = 12'hf00;
    localparam BLUE = 12'h00f;
    localparam BLACK = 12'h000;
    localparam NAVY = 12'h258;
    localparam PURPLE = 12'h52a;
    localparam GRAY = 12'h777;
    localparam LGRAY = 12'haaa;
    localparam DGRAY = 12'h333;

    logic [1:0] row;  //0 상단(0~319), 1: 중단(320~359), 2: 하단(360~479)
    logic [2:0] col7;  // 상단,중단용 7분할 (91p)
    logic [2:0] col_b;  //하단용 분할 
    

    always_comb begin
        if (y_pixel < 320) row = 2'b0;
        else if (y_pixel < 360) row = 2'd1;
        else row = 2'd2;
    end

    always_comb begin
        if (x_pixel < 91) col7 = 3'd0;
        else if (x_pixel < 182) col7 = 3'd1;
        else if (x_pixel < 273) col7 = 3'd2;
        else if (x_pixel < 364) col7 = 3'd3;
        else if (x_pixel < 455) col7 = 3'd4;
        else if (x_pixel < 546) col7 = 3'd5;
        else if (x_pixel < 640) col7 = 3'd6;
    end

    always_comb begin
        if (x_pixel < 115) col_b = 3'd0;
        else if (x_pixel < 230) col_b = 3'd1;
        else if (x_pixel < 345) col_b = 3'd2;
        else if (x_pixel < 455) col_b = 3'd3;
        else if (x_pixel < 491) col_b = 3'd4;
        else if (x_pixel < 522) col_b = 3'd5;
        else if (x_pixel < 546) col_b = 3'd6;
        else if (x_pixel < 640) col_b = 3'd7;
    end

    logic [11:0] rgb;  //인덱스 -> 색 (룩업 테이블)

    always_comb begin
        rgb = BLACK;
        if (de) begin
            case (row)
                2'd0:
                case (col7)
                    3'd0: rgb = WHITE;
                    3'd1: rgb = YELLOW;
                    3'd2: rgb = CYAN;
                    3'd3: rgb = GREEN;
                    3'd4: rgb = MAGENTA;
                    3'd5: rgb = RED;
                    3'd6: rgb = BLUE;
                    default: rgb = BLUE;
                endcase
                2'd1:
                case (col7)
                    3'd0: rgb = BLUE;
                    3'd1: rgb = BLACK;
                    3'd2: rgb = MAGENTA;
                    3'd3: rgb = BLACK;
                    3'd4: rgb = CYAN;
                    3'd5: rgb = BLACK;
                    3'd6: rgb = WHITE;
                    default: rgb = WHITE;
                endcase
                2'd2:
                case (col_b)
                    3'd0: rgb = NAVY;
                    3'd1: rgb = WHITE;
                    3'd2: rgb = PURPLE;
                    3'd3: rgb = DGRAY;
                    3'd4: rgb = BLACK;
                    3'd5: rgb = DGRAY;
                    3'd6: rgb = LGRAY;
                    3'd7: rgb = DGRAY;
                    default: rgb = DGRAY;
                endcase
            endcase
        end
    end

    assign port_red = rgb[11:8];
    assign port_green = rgb[7:4];
    assign port_blue = rgb[3:0];
endmodule
