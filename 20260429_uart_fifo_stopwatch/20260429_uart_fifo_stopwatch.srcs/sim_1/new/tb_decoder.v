`timescale 1ns / 1ps

module tb_decoder ();
    reg clk;
    reg rst;
    reg rx_done;
    reg [7:0] push_data;
    wire R;

    top_ascii dut (
        .clk(clk),
        .rst(rst),
        .rx_done(rx_done),
        .push_data(push_data),
        .R(R)
    );

    always #5 clk = ~clk;

    initial begin
        rst = 1;
        clk = 0;
        push_data = 0;
        rx_done = 0;
        #10;
        rst = 0;
        #16;
        push_data = 8'h52;
        rx_done   = 1'b1;
        #10;
        rx_done = 1'b0;
        #100;
        $stop;
    end

endmodule

