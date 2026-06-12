`timescale 1ns / 1ps

module tb_apb_master ();

    logic        PCLK;
    logic        PRESET;
    logic [31:0] Addr;
    logic [31:0] Wdata;
    logic        R_REQ;
    logic        W_REQ;
    logic [31:0] RDATA;
    logic        READY;
    logic [31:0] PADDR;
    logic [31:0] PWDATA;
    logic        PENABLE;
    logic        PWRITE;
    logic        PSEL0;  //RAM
    logic        PSEL1;  //GPO
    logic        PSEL2;  //GPI
    logic        PSEL3;  //GPIO
    logic        PSEL4;
    logic        PREADY0;
    logic        PREADY1;
    logic        PREADY2;
    logic        PREADY3;
    logic        PREADY4;
    logic [31:0] PRDATA0;
    logic [31:0] PRDATA1;
    logic [31:0] PRDATA2;
    logic [31:0] PRDATA3;
    logic [31:0] PRDATA4;

    apb_master dut (.*);

    always #5 PCLK = ~PCLK;

    initial begin
        PCLK   = 0;
        PRESET = 1;
        @(negedge PCLK);
        @(negedge PCLK);
        PRESET = 0;

        //RAM Write test, 0x1000_0000
        @(posedge PCLK);
        #1;
        Addr  = 32'h1000_0000;
        Wdata = 32'h0A0A_5050;
        W_REQ = 1'b1;
        R_REQ = 0;

        @(PENABLE & PSEL0)
        PREADY0 = 1'b1;
        @(posedge PCLK);
        @(posedge PCLK);

        $stop;
    end

endmodule
