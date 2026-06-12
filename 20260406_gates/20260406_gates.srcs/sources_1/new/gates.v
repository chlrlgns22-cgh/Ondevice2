`timescale 1ns / 1ps

module gates( //top module
input a,
input b,
output y0, //and output
output y1, //nand
output y2, //or
output y3, //nor
output y4, //xor
output y5, //xnor
output y6  //not
); // ;:end

    assign y0 = a & b; // &operator
    assign y1 = ~(a&b); // ~:not
    assign y2 = (a|b); // OR operator |:vertical bar
    assign y3 = ~(a|b); //nor
    assign y4 = (a^b); //exor operator ^:hat
    assign y5 = ~(a^b); //exnor
    assign y6 = ~a; //~not 

endmodule
