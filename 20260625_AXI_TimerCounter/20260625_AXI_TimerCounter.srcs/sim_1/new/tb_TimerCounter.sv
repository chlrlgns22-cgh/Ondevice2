`timescale 1ns / 1ps

module tb_TimerCounter ();

    logic        clk;
    logic        rst_n;
    //  internal signals
    logic        cnt_en;
    logic        intr_en;
    logic [31:0] psc;
    logic [31:0] arr;
    logic        cnt_valid;
    logic [31:0] o_cnt;
    logic [31:0] i_cnt;
    logic        intr;


    TimerCounter dut (
        .clk(clk),
        .rst_n(rst_n),
        //  internal signals
        .cnt_en(cnt_en),
        .intr_en(intr_en),
        .psc(psc),
        .arr(arr),
        .cnt_valid(cnt_valid),
        .i_cnt(i_cnt),
        .o_cnt(o_cnt),
        .intr(intr)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task automatic TIM_SetPSC(logic [31:0] prescale);
        psc <= prescale;
    endtask  //automatic

    task automatic TIM_SetARR(logic [31:0] autoReload);
        arr <= autoReload;
    endtask  //automatic

    task automatic TIM_EnTimer();
        cnt_en <= 1'b1;
    endtask  //automatic

    task automatic TIM_DisTimer();
        cnt_en <= 1'b0;
    endtask  //automatic

    task automatic TIM_EnIntr();
        intr_en <= 1'b1;
    endtask  //automatic

    task automatic TIM_DisIntr();
        intr_en <= 1'b0;
    endtask  //automatic

    task automatic TIM_SetCNT(logic [31:0] CNT);
        i_cnt = CNT;
        cnt_valid = 1'b1;
        @(posedge clk);
        cnt_valid = 1'b0;
    endtask  //automatic

    initial begin
        rst_n = 0;
        i_cnt = 0;
        cnt_valid = 0;
        repeat (3) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        TIM_SetPSC(100 - 1);  // output 1MHz
        TIM_SetARR(1000 - 1);  // TimerCounter 0~999
        TIM_EnTimer();
        TIM_DisIntr();
        wait (o_cnt == 999);
        @(posedge clk);
        wait (o_cnt == 0);
        @(posedge clk);
        TIM_EnIntr();
        wait (o_cnt == 999);
        @(posedge clk);
        wait (o_cnt == 100);
        @(posedge clk);
        TIM_SetCNT(0);
        wait (o_cnt == 0);
        TIM_DisTimer();

        #10000;
        $finish;
    end
endmodule
