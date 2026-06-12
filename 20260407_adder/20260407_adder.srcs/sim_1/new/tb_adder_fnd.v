`timescale 1ns / 1ps

module tb_adder_fnd ();
    reg clk;
    reg rst;
    reg [7:0] a;
    reg [7:0] b;
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;
    wire led;

    integer i, j;

    adder_fnd U_AF (
        .clk(clk),
        .rst(rst),
        .a(a),
        .b(b),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data),
        .led(led)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        a   = 8'd0;
        b   = 8'd0;
        i   = 0;
        j   = 0;

        #20;
        rst = 0;
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                a = i;
                b = j;
                #200;
            end

        end
        $stop;

    end

endmodule
