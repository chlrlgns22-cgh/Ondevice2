`timescale 1ns / 1ps

module button_debounce (
    input  logic clk,
    input  logic rst,
    input  logic i_btn,
    output logic o_btn
);
    //clock divider
    //100MHz -> 100KHz
    parameter F_COUNT = 100_000_000 / 100_000;
    logic [$clog2(F_COUNT)-1:0] r_counter;
    logic clk_100khz;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            r_counter  <= 0;
            clk_100khz <= 1'b0;
        end else begin
            r_counter <= r_counter + 1;
            if (r_counter == (F_COUNT - 1)) begin
                r_counter  <= 0;
                clk_100khz <= 1'b1;
            end else begin
                clk_100khz <= 1'b0;
            end
        end
    end


    //synchronizer
    logic [7:0] sync_logic, sync_next;
    logic debounce;
    logic  edge_logic;

    always @(posedge clk_100khz, posedge rst) begin
        if (rst) begin
            sync_logic <= 0;
        end else begin
            sync_logic <= sync_next;
        end
    end

    always @(*) begin
        sync_next = {i_btn, sync_logic[7:1]};
        // sync_next= {sync_logic[6:0], i_btn};
    end

    assign debounce = &sync_logic;


    //rsising edge detect
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            edge_logic <= 1'b0;
        end else begin
            edge_logic <= debounce;
        end
    end

    assign o_btn = debounce & (~edge_logic);
endmodule


