`timescale 1ns / 1ps

module tb_top_uart ();

    reg clk;
    reg rst;
    reg rx;
    reg select;
    reg [31:0] data;
    wire uart_R;
    wire uart_L;
    wire uart_U;
    wire uart_D;
    wire uart_M;
    wire uart_S;
    wire tx;


    top_uart dut (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .select(select),  //select=1 => watch /select= 0 => stopwatch
        .data(data),  //data of stopwatch or watch
        .uart_R(uart_R),
        .uart_L(uart_L),
        .uart_U(uart_U),
        .uart_D(uart_D),
        .uart_M(uart_M),
        .uart_S(uart_S),
        .tx(tx)
    );

    always #5 clk = ~clk;

    // 초기화 및 시나리오
    initial begin
        // 1. 초기값 설정
        clk = 1'b0;
        rst = 1'b1;
        rx = 1'b1;  // idle
        select = 1'b0;  // default stopwatch
        data = {
            4'd1, 4'd7, 4'd2, 4'd9, 4'd3, 4'd8, 4'd7, 4'd9
        };  // 32'h17293879

        repeat (10) @(posedge clk);  // 100 ns 정도 rst 유지
        rst = 1'b0;

        // 2. 1비트 = 10416 클럭 (9600 bps, 100MHz)

        // --- R (0x52 = 0101_0010) ---
        rx  = 1'b0;
        repeat (10416) @(posedge clk);  // start
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit0
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit1
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit2
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit3
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit4
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit5
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit6
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit7
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // stop
        repeat (200000) @(posedge clk);  // idle gap

        // --- L (0x4C = 0100_1100) ---
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // start
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit0
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit1
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit2
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit3
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit4
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit5
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit6
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit7
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // stop
        repeat (200000) @(posedge clk);

        // --- U (0x55 = 0101_0101) ---
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // start
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit0
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit1
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit2
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit3
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit4
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit5
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit6
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit7
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // stop
        repeat (200000) @(posedge clk);

        // --- D (0x44 = 0100_0100) ---
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // start
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit0
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit1
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit2
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit3
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit4
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit5
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit6
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit7
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // stop
        repeat (200000) @(posedge clk);

        // --- M (0x4D = 0100_1101) ---
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // start
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit0
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit1
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit2
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit3
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit4
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit5
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit6
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit7
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // stop
        repeat (200000) @(posedge clk);
        // --- S (0x53 = 0101_0011) ---
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // start
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit0
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit1
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit2
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit3
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit4
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit5
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit6
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit7
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // stop

        // stop bit
        rx = 1'b1;
        repeat (10416) @(posedge clk);

        repeat (4000000) @(posedge clk);

        // --- S (0x53 = 0101_0011) ---
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // start
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit0
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit1
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit2
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit3
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit4
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit5
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit6
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit7
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // stop

        repeat (4000000) @(posedge clk);

        // --- S (0x53 = 0101_0011) ---
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // start
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit0
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit1
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit2
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit3
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit4
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit5
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit6
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit7
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // stop

        repeat (4000000) @(posedge clk);

        select = 1;
        // --- S (0x53 = 0101_0011) ---
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // start
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit0
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit1
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit2
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit3
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit4
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit5
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit6
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit7
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // stop

        repeat (4000000) @(posedge clk);

        // --- S (0x53 = 0101_0011) ---
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // start
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit0
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit1
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit2
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit3
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit4
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit5
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit6
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit7
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // stop

        repeat (4000000) @(posedge clk);

        // --- S (0x53 = 0101_0011) ---
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // start
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit0
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit1
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit2
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit3
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit4
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit5
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit6
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit7
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // stop

        repeat (4000000) @(posedge clk);

        // --- S (0x53 = 0101_0011) ---
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // start
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit0
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit1
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit2
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit3
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit4
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit5
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // bit6
        rx = 1'b0;
        repeat (10416) @(posedge clk);  // bit7
        rx = 1'b1;
        repeat (10416) @(posedge clk);  // stop

        repeat (4000000) @(posedge clk);

        $stop;
    end

endmodule
