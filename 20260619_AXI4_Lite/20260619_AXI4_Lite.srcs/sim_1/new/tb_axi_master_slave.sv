`timescale 1ns / 1ps

module tb_axi_master_slave ();


    logic        ACLK;
    logic        ARESETn;
    logic [31:0] AWADDR;
    logic        AWVALID;
    logic        AWREADY;
    logic [31:0] WDATA;
    logic        WVALID;
    logic        WREADY;
    logic [ 1:0] BRESP;
    logic        BVALID;
    logic        BREADY;
    logic [31:0] ARADDR;
    logic        ARVALID;
    logic        ARREADY;
    logic [31:0] RDATA;
    logic        RVALID;
    logic        RREADY;
    logic [ 1:0] RRESP;
    // internal signals
    logic        transfer;
    logic        ready;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic        write;


    axi_master dut_master (.*);

    axi_slave dut_slave (.*);

    initial ACLK = 0;
    always #5 ACLK = ~ACLK;

    task automatic axi_write(logic [31:0] address, logic [31:0] data);
        @(posedge ACLK);
        addr = address;
        wdata = data;
        write = 1'b1;
        transfer = 1'b1;
        @(posedge ACLK);
        transfer = 1'b0;
        wait (ready);
        @(posedge ACLK);
        $display("[%0t] AXI WRITE Addr=%0h, WDATA=%0h", $time, addr, wdata);
    endtask  //automatic

    task automatic axi_read(logic [31:0] address);
        @(posedge ACLK);
        addr = address;
        write = 1'b0;
        transfer = 1'b1;
        @(posedge ACLK);
        transfer = 1'b0;
        wait (ready);
        @(posedge ACLK);
        $display("[%0t] AXI READ Addr=%0h, RDATA=%0h", $time, addr, rdata);
    endtask  //automatic
    
    initial begin
        ARESETn = 0;
        repeat (3) @(posedge ACLK);
        ARESETn = 1;
        @(posedge ACLK);
        axi_write(32'h00, 32'h1111_1111);
        axi_write(32'h04, 32'h2222_2222);
        axi_write(32'h08, 32'h3333_3333);
        axi_write(32'h0c, 32'h4444_4444);

        axi_read(32'h00);
        axi_read(32'h04);
        axi_read(32'h08);
        axi_read(32'h0c);

        #100;
        $finish;
    end
endmodule
