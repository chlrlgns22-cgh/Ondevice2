`timescale 1ns / 1ps

module tb_moore ();

    reg clk, rst, sw;
    wire led;

    moore uut (
        .clk(clk),
        .rst(rst),
        .sw (sw),
        .led(led)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1'b1;
        #20;
        rst = 1'b0;


        //a->a
        sw  = 1'b0;
        @(negedge clk);

        //a->b
        sw = 1'b1;
        @(negedge clk);

        //b->b
        sw = 1'b1;
        @(negedge clk);

        //b->c
        sw = 1'b0;
        @(negedge clk);

        //c->a
        sw = 1'b0;
        @(negedge clk);

        //a->b
        sw = 1'b1;
        @(negedge clk);

        //b->c
        sw = 1'b0;
        @(negedge clk);

        //c->d
        sw = 1'b1;
        @(negedge clk);

        //d->b led=0
        sw = 1'b1;
        @(negedge clk);

        //b->c
        sw = 1'b0;
        @(negedge clk);

        //c->d
        sw = 1'b1;
        @(negedge clk);

        //d->a
        sw = 1'b0;
        @(negedge clk);
        @(negedge clk);
        $stop;
    end

endmodule
