`timescale 1ns / 1ps

module tb_sr04_controller();

    parameter CLK_PERIOD = 10;
    parameter US_DELAY   = 1000;
    parameter MS_DELAY   = 1_000_000;
    parameter SEC_DELAY  = 1_000_000_000;

    reg         clk;
    reg         rst;
    reg         sr04_start;
    reg         echo;
    wire        trig;
    wire [8:0]  distance;
    wire        w_tick_us;

    tick_gen_us dut2 (
        .clk        (clk),
        .rst        (rst),
        .tick_us    (w_tick_us)
    );

    sr04_controller dut (
        .clk        (clk),
        .rst        (rst),
        .sr04_start (sr04_start),
        .tick_us    (w_tick_us),
        .echo       (echo),
        .trig       (trig),
        .distance   (distance)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
        clk        = 0;
        rst        = 1;
        sr04_start = 0;
        echo       = 0;

        #100;
        rst = 0;

        // CASE 1 : 약 20cm
        // echo high = 1160us로 설정. 이유: 1160 / 56 = 20
        // 최종 출력으로 20cm가 출력되어야 함.
        @(posedge clk);
        sr04_start = 1;

        force dut.start_cnt_reg = dut.F_COUNT - 1;
        @(posedge clk);
        release dut.start_cnt_reg;
        
        @(posedge clk);
        sr04_start = 0;

        // trig가 끝날 때까지 기다림
        @(negedge trig);

        // 약간 대기 후 echo 발생
        #(US_DELAY * 20);
        echo = 1;
        #(US_DELAY * 1160);
        echo = 0;

        #(MS_DELAY * 70);


        // CASE 2 : timeout
        @(posedge clk);
        sr04_start = 1;

        #(SEC_DELAY * 15);

        sr04_start = 0;

        // echo 안 줌
        #(MS_DELAY * 35);

        $stop;
    end

endmodule