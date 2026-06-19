`timescale 1ns / 1ps

module tb_AXI4_Lite_master;

    logic        clk;
    logic        rst;
    logic        transfer;
    logic        write;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic        ready;
    logic [31:0] rdata;
    logic        aw_ready;
    logic        aw_valid;
    logic [31:0] aw_addr;
    logic        w_ready;
    logic        w_valid;
    logic [31:0] w_data;
    logic        b_valid;
    logic [ 1:0] b_resp;
    logic        b_ready;
    logic        ar_ready;
    logic        ar_valid;
    logic [31:0] ar_addr;
    logic        r_valid;
    logic [ 1:0] r_resp;
    logic [31:0] r_data;
    logic        r_ready;

    AXI4_Lite_master DUT (
        .clk      (clk),
        .rst      (rst),
        .transfer (transfer),
        .write    (write),
        .addr     (addr),
        .wdata    (wdata),
        .ready    (ready),
        .rdata    (rdata),
        .aw_ready (aw_ready),
        .aw_valid (aw_valid),
        .aw_addr  (aw_addr),
        .w_ready  (w_ready),
        .w_valid  (w_valid),
        .w_data   (w_data),
        .b_valid  (b_valid),
        .b_resp   (b_resp),
        .b_ready  (b_ready),
        .ar_ready (ar_ready),
        .ar_valid (ar_valid),
        .ar_addr  (ar_addr),
        .r_valid  (r_valid),
        .r_resp   (r_resp),
        .r_data   (r_data),
        .r_ready  (r_ready)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // 초기화
        rst      = 1;
        transfer = 0;
        write    = 0;
        addr     = 0;
        wdata    = 0;
        aw_ready = 0;
        w_ready  = 0;
        b_valid  = 0;
        b_resp   = 0;
        ar_ready = 0;
        r_valid  = 0;
        r_resp   = 0;
        r_data   = 0;

        repeat(3) @(posedge clk);
        rst = 0;
        repeat(2) @(posedge clk);

        //----------------------------------------------
        // Write 트랜잭션
        //----------------------------------------------
        transfer = 1; write = 1;
        addr = 32'hAAAA_0000; wdata = 32'h1234_5678;
        @(posedge clk);
        transfer = 0;

        // AW handshake
        repeat(2) @(posedge clk);
        aw_ready = 1;
        @(posedge clk);
        aw_ready = 0;

        // W handshake
        repeat(1) @(posedge clk);
        w_ready = 1;
        @(posedge clk);
        w_ready = 0;

        // B response
        repeat(2) @(posedge clk);
        b_valid = 1; b_resp = 2'b00;
        @(posedge clk);
        b_valid = 0;

        repeat(5) @(posedge clk);

        //----------------------------------------------
        // Read 트랜잭션
        //----------------------------------------------
        transfer = 1; write = 0;
        addr = 32'hBBBB_0000;
        @(posedge clk);
        transfer = 0;

        // AR handshake
        repeat(2) @(posedge clk);
        ar_ready = 1;
        @(posedge clk);
        ar_ready = 0;

        // R response
        repeat(2) @(posedge clk);
        r_valid = 1; r_resp = 2'b00; r_data = 32'hABCD_EF10;
        @(posedge clk);
        r_valid = 0;

        repeat(5) @(posedge clk);
        $finish;
    end

endmodule