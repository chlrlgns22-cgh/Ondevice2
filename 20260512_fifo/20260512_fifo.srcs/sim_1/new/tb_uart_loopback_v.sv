`timescale 1ns / 1ps

module tb_uart_loopback_v ();

    parameter BAUD_PERIOD = 10 * (100_000_000 / 9600);
    logic [7:0] compare_data;
    logic clk, rst, rx;
    logic tx;

    uart_loopback_sv dut_Verilog (
        .clk(clk),
        .rst(rst),
        .rx (rx),
        .tx (tx)
    );

    always #5 clk = ~clk;

    int i;

    task SENDER_UART(input [7:0] send_data);
        begin
            // pc tx
            // start
            rx = 0;
            // start bit
            #(BAUD_PERIOD);
            //data bit
            for (i = 0; i < 8; i++) begin
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
        compare_data = 8'h38;  // ASCII 8
        @(negedge clk);
        @(negedge clk);

        rst = 0;
        repeat(10) begin
        SENDER_UART(compare_data);

        repeat (10) #(BAUD_PERIOD);
        #1000;
        end
        $stop;
    end


endmodule
