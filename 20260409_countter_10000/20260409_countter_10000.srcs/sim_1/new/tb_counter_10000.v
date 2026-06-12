`timescale 1ns / 1ps

module tb_counter_10000 ();
    reg        clk;
    reg        rst;
    reg        btnL; //clear
    reg        btnR; //run_stop
    reg        btnD; //mode
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;

    counter_10000 uut (
        .clk     (clk),
        .rst     (rst),
        .btnL    (btnL),
        .btnR    (btnR),
        .btnD    (btnD),
        .fnd_com (fnd_com),
        .fnd_data(fnd_data)
    );

    always #5 clk = ~clk;

    initial begin
        clk  = 0;
        rst  = 1;
        btnL = 1'b0;
        btnR = 1'b0;
        btnD = 1'b0;

        repeat (3) @(negedge clk);
        rst = 0;

        #100_000;
      
        // STOP -> RUN
        btnR=1'b1;
        repeat (10000) @(negedge clk);
        btnR=1'b0;
        #110_000_000;
     
        //RUN -> STOP
        btnR=1'b1;
        repeat (10000) @(negedge clk);
        btnR=1'b0;
     
        //STOP -> MODE ->STOP
        btnD=1'b1;
        repeat (10000) @(negedge clk);
        btnD=1'b0;
        #110_000_0;

        // STOP -> RUN
        btnR=1'b1;
        repeat (10000) @(negedge clk);
        btnR=1'b0;
        #110_000_000;
     
        //RUN -> STOP
        btnR=1'b1;
        repeat (10000) @(negedge clk);
        btnR=1'b0;
        #110_000_0;
 
        //STOP -> CLEAR -> STOP
        btnL=1'b1;
        repeat (10000) @(negedge clk);
        btnL=1'b0;
        #110_000_0;

        $stop;
    end
endmodule
