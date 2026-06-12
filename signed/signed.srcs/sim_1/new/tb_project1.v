`timescale 1ns / 1ps
//blocking non-blocking

module tb_project1 ();

    reg a, b;
    wire y;

    initial begin
        //blocking
        a = 0;
        b = 1;
        b = a;
        a = b;
        $display("blocking a=%d,b=%d", a, b);

        //nonblocking(NB)
        a = 0;
        b = 1;
        #1;
        b <= a;
        a <= b;
        #1;
        $display("nonblocking a=%d,b=%d", a, b);

    end


endmodule
