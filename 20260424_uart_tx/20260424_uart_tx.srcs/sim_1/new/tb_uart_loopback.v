`timescale 1ns / 1ps

module tb_uart_loopback ();
    parameter BAUD_DELAY = 2_000;
    parameter BAUD_PERIOD = 10 * (100_000_000 / 9600) - BAUD_DELAY;
    reg [7:0] compare_data;
    reg clk, rst, rx;
    wire tx;

    uart_loopback dut (
        .clk(clk),
        .rst(rst),
        .rx (rx),
        .tx (tx)
    );

    always #5 clk = ~clk;

    integer i;

    task SENDER_UART(input [7:0] send_data);
        begin
            // pc tx
            // start
            rx = 0;
            // start bit
            #(BAUD_PERIOD);
            //data bit
            for (i = 0; i < 8; i = i + 1) begin
                // rx, send_data [0] ~ [7]
                rx = send_data[i];
                #(BAUD_PERIOD);
            end
            rx = 1;
            #(BAUD_PERIOD);
        end

    endtask

    initial begin
        clk = 0;
        rst = 1;
        rx = 1;
        compare_data = 8'h30;  // ASCII 8
        @(negedge clk);
        @(negedge clk);

        rst = 0;

        SENDER_UART(compare_data);
        SENDER_UART(compare_data);
        SENDER_UART(compare_data);
        SENDER_UART(compare_data);
        SENDER_UART(compare_data);
        SENDER_UART(compare_data);
        SENDER_UART(compare_data);
        SENDER_UART(compare_data);

        #(BAUD_PERIOD);
        #1000;

        $stop;
    end


endmodule
