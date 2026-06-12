`timescale 1ns / 1ps

module tb_fsm_led ();
    reg clk;
    reg rst;
    reg [2:0] sw;
    wire [2:0] led;

    fsm_led dut (
        .clk(clk),
        .rst(rst),
        .sw (sw),
        .led(led)
    );

    always #5 clk = ~clk;
    initial begin
        clk = 0;
        rst = 1'b1;
        //reset
        #20;
        rst = 1'b0;

        // state a->b
        // sw== 2'b01;
        sw  = 3'b001;
        // wait : next positive clock
        @(posedge clk);
        @(posedge clk);

        // state b->c
        // sw== 2'b'10;
        sw = 3'b010;
        @(posedge clk);
        @(posedge clk);

        // state c->d
        sw = 3'b100;
        @(posedge clk);
        @(posedge clk);

        //state d->e
        sw = 3'b111;
        @(posedge clk);
        @(posedge clk);

        //state e-> a;
        sw = 3'b000;
        @(posedge clk);
        @(posedge clk);

        //state a->c
        sw = 3'b010;
        @(posedge clk);
        @(posedge clk);

        //state c->d
        sw = 3'b100;
        @(posedge clk);
        @(posedge clk);

        //state d->a
        sw = 3'b000;
        @(posedge clk);
        @(posedge clk);

        //state a->c
        sw = 3'b010;
        @(posedge clk);
        @(posedge clk);

        //state c->d
        sw = 3'b100;
        @(posedge clk);
        @(posedge clk);

        //state d->b
        sw = 3'b001;
        @(posedge clk);
        @(posedge clk);
        $stop;
    end
endmodule
