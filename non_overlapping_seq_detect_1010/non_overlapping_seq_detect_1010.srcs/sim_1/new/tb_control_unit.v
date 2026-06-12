`timescale 1ns / 1ps

module tb_control_unit ();
    reg  clk;
    reg  rst;
    reg  btnD;  //mode
    reg  btnL;  //clear
    reg  btnR;  //run_stop
    wire run_stop;
    wire clear;
    wire mode;

    control_unit uut (
        .clk(clk),
        .rst(rst),
        .btnD(btnD),  //mode
        .btnL(btnL),  //clear
        .btnR(btnR),  //run_stop
        .run_stop(run_stop),
        .clear(clear),
        .mode(mode)
    );

    always #5 clk = ~clk;

    initial begin
        rst = 1;
        clk = 0;
        btnD=1'b0;
        btnL=1'b0;
        btnR=1'b0;
        #20;
        rst  = 0;

        btnR = 1'b1;
        @(posedge clk);
        btnR = 1'b0;
        @(posedge clk);
        @(posedge clk);
        btnR = 1'b1;
        @(posedge clk);
        btnR = 1'b0;
        @(posedge clk);

        btnD = 1'b1;
        @(posedge clk);
        btnD = 1'b0;
        @(posedge clk);

        btnL = 1'b1;
        @(posedge clk);
        btnL = 1'b0;
        @(posedge clk);
        @(posedge clk);

        $stop;
    end
endmodule
