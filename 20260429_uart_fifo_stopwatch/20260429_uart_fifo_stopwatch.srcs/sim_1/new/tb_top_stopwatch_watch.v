`timescale 1ns / 1ps

module tb_top_stopwatch_watch ();

    parameter ONE_SEC  = 100_000;  // 1 ms in sim, based on 10 ns clock period
    parameter TWO_SEC  = 200_000;
    parameter FOUR_SEC = 400_000;
    parameter FND_DIV_COUNT = 2;

    reg clk, rst, btnR, btnL, btnD, btnU;
    reg [2:0] sw;
    wire [7:0] fnd_data;
    wire [3:0] fnd_com;
    wire [2:0] led;

    top_stopwatch_watch dut (
        .clk     (clk),
        .rst     (rst),
        .btnR    (btnR),
        .btnL    (btnL),
        .btnU    (btnU),
        .btnD    (btnD),
        .sw      (sw),
        .fnd_data(fnd_data),
        .fnd_com (fnd_com),
        .led     (led)
    );

    // real 1 centisecond -> sim 10 us
    defparam dut.U_BTNR.F_COUNT = 1000;
    defparam dut.U_BTNL.F_COUNT = 1000;
    defparam dut.U_BTNU.F_COUNT = 1000;
    defparam dut.U_BTND.F_COUNT = 1000;
    defparam dut.U_STOPWATCH_DATAPATH.U_TICK_GEN.F_COUNT = 1000;
    defparam dut.U_WATCH_DATAPATH.U_TICK_GEN.F_COUNT = 1000;
    defparam dut.U_FND_CTRL.U_DIV_1KHZ.F_COUNT = FND_DIV_COUNT;

    always #5 clk = ~clk;

    initial begin
        clk  = 1'b0;
        rst  = 1'b1;
        btnR = 1'b0;
        btnL = 1'b0;
        btnD = 1'b0;
        btnU = 1'b0;
        sw   = 3'b000;
        #10;
        rst  = 1'b0;
        #10;

        // watch -> stopwatch
        sw[1] = 1'b1;
        repeat (ONE_SEC) @(negedge clk);

        // 1. run : 4 sec
        btnR = 1'b1;
        repeat (10_000) @(negedge clk);
        btnR = 1'b0;
        repeat (10_000) @(negedge clk);

        // 2. record : run 2 sec point
        repeat (TWO_SEC) @(negedge clk);
        btnD = 1'b1;
        repeat (10_000) @(negedge clk);
        btnD = 1'b0;
        repeat (10_000) @(negedge clk);

        // finish first run to 4 sec total
        repeat (TWO_SEC) @(negedge clk);

        // 3. stop
        btnR = 1'b1;
        repeat (10_000) @(negedge clk);
        btnR = 1'b0;
        repeat (10_000) @(negedge clk);

        // 4. stop 1 sec later -> view 1 sec
        repeat (ONE_SEC) @(negedge clk);
        btnU = 1'b1;
        repeat (10_000) @(negedge clk);
        btnU = 1'b0;
        repeat (ONE_SEC) @(negedge clk);
        btnU = 1'b1;
        repeat (10_000) @(negedge clk);
        btnU = 1'b0;
        repeat (10_000) @(negedge clk);

        // 5. clear 1 sec later
        repeat (ONE_SEC) @(negedge clk);
        btnL = 1'b1;
        repeat (10_000) @(negedge clk);
        btnL = 1'b0;
        repeat (10_000) @(negedge clk);

        // 6. mode 1 sec later
        repeat (ONE_SEC) @(negedge clk);
        btnD = 1'b1;
        repeat (10_000) @(negedge clk);
        btnD = 1'b0;
        repeat (10_000) @(negedge clk);

        // run 1 sec later
        repeat (ONE_SEC) @(negedge clk);
        btnR = 1'b1;
        repeat (10_000) @(negedge clk);
        btnR = 1'b0;
        repeat (10_000) @(negedge clk);

        // 9. run 2 sec later -> view 1 sec, record clear check
        repeat (TWO_SEC) @(negedge clk);
        btnU = 1'b1;
        repeat (10_000) @(negedge clk);
        btnU = 1'b0;
        repeat (ONE_SEC) @(negedge clk);
        btnU = 1'b1;
        repeat (10_000) @(negedge clk);
        btnU = 1'b0;
        repeat (10_000) @(negedge clk);

        // 10. sw[0] high 1 sec -> low
        sw[0] = 1'b1;
        repeat (ONE_SEC) @(negedge clk);
        sw[0] = 1'b0;
        repeat (ONE_SEC) @(negedge clk);

        // 11. sw[1] low 1 sec -> high
        sw[1] = 1'b0;
        repeat (ONE_SEC) @(negedge clk);
        sw[1] = 1'b1;
        repeat (ONE_SEC) @(negedge clk);

        $stop;
    end

endmodule
