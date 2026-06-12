`timescale 1ns / 1ps

module tb_sr04_controller ();

    parameter US_DELAY = 1000, MS_DELAY = 1_000_000;

    reg        clk;
    reg        rst;
    reg        sr04_start;
    reg        tick_us;
    reg        echo;
    wire       trig;
    wire [8:0] distance;

    wire       w_tick_us;

    tick_gen_us dut2 (
        .clk(clk),
        .rst(rst),
        .tick_us(w_tick_us)
    );

    sr04_controller dut (
        .clk       (clk),
        .rst       (rst),
        .sr04_start(sr04_start),
        .tick_us   (w_tick_us),
        .echo      (echo),
        .trig      (trig),
        .distance  (distance)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        sr04_start = 0;
        echo = 0;
        #20;
        rst = 0;
        #10;
        sr04_start = 1'b1;
        @(posedge clk);
        sr04_start = 1'b0;
        #(US_DELAY * 20);
        //@(negedge trig);
        echo = 1;
        #(MS_DELAY * 20);
        echo = 0;
        #(MS_DELAY);


        $stop;
    end


endmodule
