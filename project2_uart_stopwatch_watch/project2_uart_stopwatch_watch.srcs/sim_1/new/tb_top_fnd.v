`timescale 1ns / 1ps

module tb_top_fnd;

    reg         clk;
    reg         rst;
    reg         btnR, btnL, btnU, btnD;
    reg         uart_R, uart_L, uart_U, uart_D, uart_M;
    reg         echo;
    reg  [3:0]  sw;
    tri         dht11_io;

    wire [31:0] watch_data;
    wire [15:0] temp_humidity;
    wire [11:0] distance;
    wire        trig;
    wire [3:0]  fnd_com;
    wire [7:0]  fnd_data;
    wire [2:0]  led;

    // DUT
    top_fnd dut (
        .clk           (clk),
        .rst           (rst),
        .btnR          (btnR),
        .btnL          (btnL),
        .btnU          (btnU),
        .btnD          (btnD),
        .uart_R        (uart_R),
        .uart_L        (uart_L),
        .uart_U        (uart_U),
        .uart_D        (uart_D),
        .uart_M        (uart_M),
        .echo          (echo),
        .sw            (sw),
        .dht11_io      (dht11_io),
        .watch_data    (watch_data),
        .temp_humidity (temp_humidity),
        .distance      (distance),
        .trig          (trig),
        .fnd_com       (fnd_com),
        .fnd_data      (fnd_data),
        .led           (led)
    );

    // 100MHz clock
    always #5 clk = ~clk;

    initial begin
        clk    = 0;
        rst    = 1;

        btnR   = 0;
        btnL   = 0;
        btnU   = 0;
        btnD   = 0;

        uart_R = 0;
        uart_L = 0;
        uart_U = 0;
        uart_D = 0;
        uart_M = 0;

        echo   = 0;
        sw     = 4'b0000;

        #100;
        rst = 0;

        // CASE 1) stopwatch/watch용 FND 출력 확인
        // sw[3]=0 : stopwatch/watch FND
        // sw[1]=0 : watch
        // sw[0]=0 : msec/sec
        sw = 4'b0000;
        #2_000_000;

        // CASE 2) stopwatch/watch용 FND - min/hour
        sw = 4'b0001;   // sw[0]=1
        #2_000_000;

        // CASE 3) stopwatch/watch용 FND - stopwatch 선택
        sw = 4'b0010;   // sw[1]=1, sw[3]=0
        #2_000_000;

        // CASE 4) sensor FND - SR04 표시
        // sw[3]=1, sw[1]=0
        sw = 4'b1000;
        #2_000_000;

        // CASE 5) sensor FND - DHT11 표시
        // sw[3]=1, sw[1]=1
        sw = 4'b1010;
        #2_000_000;

        // CASE 6) watch 수정 상태 blink 확인
        // control_unit_fsm에서 WATCH -> HOUR -> MIN -> SEC 이동하는 방식..
        // btnR / btnL은 debounce가 있어서 일부러 길게 눌렀습니다 참고해주세요
        sw = 4'b1000;   // main FND + watch
        #1_000_000;

        sw = 4'b0000;
        #1_000_000;

        press_btnR;     // WATCH -> HOUR
        #2_000_000;

        press_btnR;     // HOUR -> MIN
        #2_000_000;

        press_btnR;     // MIN -> SEC
        #2_000_000;

        press_btnL;     // SEC -> MIN (뒤로감기)
        #2_000_000;

        press_btnL;     // MIN -> HOUR (뒤로감기)
        #2_000_000;

        $stop;
    end

    task press_btnR;
    begin
        btnR = 1;
        #200_000;   // debounce용으로 충분히 길게
        btnR = 0;
        #200_000;
    end
    endtask

    task press_btnL;
    begin
        btnL = 1;
        #200_000;
        btnL = 0;
        #200_000;
    end
    endtask

endmodule
