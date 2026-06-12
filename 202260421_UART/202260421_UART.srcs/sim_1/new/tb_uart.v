`timescale 1ns / 1ps

module tb_uart ();

    reg        clk;
    reg        rst;
    reg        btnR;
    reg  [7:0] tx_data;
    wire       tx;

    uart uut (
        .clk(clk),
        .rst(rst),
        .btnR(btnR),
        .tx_data(tx_data),
        .tx(tx)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        repeat (3) @(negedge clk);
        rst = 0;
        @(negedge clk);
        tx_data = 8'h30;
        btnR = 1;
        repeat (10_000) @(negedge clk);
        btnR = 0;
        repeat (200_000) @(negedge clk);

        $stop;
    end



endmodule
