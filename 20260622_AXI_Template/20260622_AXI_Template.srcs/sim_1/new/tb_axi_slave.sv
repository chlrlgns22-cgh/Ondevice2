`timescale 1ns / 1ps

module tb_axi_slave ();

    parameter integer C_S00_AXI_DATA_WIDTH = 32;
    parameter integer C_S00_AXI_ADDR_WIDTH = 4;

    logic                                  s00_axi_aclk;
    logic                                  s00_axi_aresetn;
    logic [    C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr;
    logic [                         2 : 0] s00_axi_awprot;
    logic                                  s00_axi_awvalid;
    logic                                  s00_axi_awready;
    logic [    C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata;
    logic [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb;
    logic                                  s00_axi_wvalid;
    logic                                  s00_axi_wready;
    logic [                         1 : 0] s00_axi_bresp;
    logic                                  s00_axi_bvalid;
    logic                                  s00_axi_bready;
    logic [    C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr;
    logic [                         2 : 0] s00_axi_arprot;
    logic                                  s00_axi_arvalid;
    logic                                  s00_axi_arready;
    logic [    C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata;
    logic [                         1 : 0] s00_axi_rresp;
    logic                                  s00_axi_rvalid;
    logic                                  s00_axi_rready;
    logic [    C_S00_AXI_DATA_WIDTH-1 : 0] rdata_r;


    axi_template_v1_0 #(C_S00_AXI_DATA_WIDTH, C_S00_AXI_ADDR_WIDTH) dut (.*);

    always #5 s00_axi_aclk = ~s00_axi_aclk;

    task automatic axi_write(logic [31:0] addr, logic [31:0] data);
        @(posedge s00_axi_aclk);
        s00_axi_awaddr  <= addr;
        s00_axi_awvalid <= 1'b1;
        s00_axi_wdata   <= data;
        s00_axi_wvalid  <= 1'b1;
        s00_axi_wstrb   <= 4'b1111;
        s00_axi_bready  <= 1'b1;
        wait (s00_axi_awready & s00_axi_wready);
        @(posedge s00_axi_aclk);
        s00_axi_wvalid  <= 1'b0;
        s00_axi_awvalid <= 1'b0;
        wait (s00_axi_bvalid);
        @(posedge s00_axi_aclk);
        s00_axi_bready <= 0;
        
        @(posedge s00_axi_aclk);
        $display("[%t] WRITE: addr = 0x%h, wdata = 0x%h", $time, addr, data);
    endtask  //automatic

    task automatic axi_read(logic [31:0] addr);
        @(posedge s00_axi_aclk);
        s00_axi_araddr  <= addr;
        s00_axi_arvalid <= 1'b1;
        s00_axi_rready  <= 1'b1;
        wait (s00_axi_arready);
        @(posedge s00_axi_aclk);
        s00_axi_arvalid <= 1'b0;

        wait (s00_axi_rvalid);
        @(posedge s00_axi_aclk);
        rdata_r <= s00_axi_rdata;
        s00_axi_rready <= 1'b0;
        @(posedge s00_axi_aclk);

        $display("[%t] READ: addr = 0x%h, rdata = 0x%h", $time, addr, rdata_r);
    endtask

    initial begin
        s00_axi_aclk    = 0;
        s00_axi_aresetn = 0;
        s00_axi_awaddr  = 0;
        s00_axi_awprot  = 0;
        s00_axi_awvalid = 0;
        s00_axi_wdata   = 0;
        s00_axi_wstrb   = 0;
        s00_axi_wvalid  = 0;
        s00_axi_bvalid  = 0;
        s00_axi_bready  = 0;
        s00_axi_araddr  = 0;
        s00_axi_arprot  = 0;
        s00_axi_arvalid = 0;
        s00_axi_rready  = 0;
        repeat (3) @(posedge s00_axi_aclk);
        s00_axi_aresetn = 1;
        repeat (2) @(posedge s00_axi_aclk);
        axi_write(32'h0000_0000, 32'hDEAD_BEEF);
        axi_write(32'h0000_0004, 32'hCAFE_BABE);
        axi_write(32'h0000_0008, 32'h1234_5678);
        axi_write(32'h0000_000C, 32'hAAAA_BBBB);

        repeat (2) @(posedge s00_axi_aclk);
        axi_read(32'h0000_0000);
        axi_read(32'h0000_0004);
        axi_read(32'h0000_0008);
        axi_read(32'h0000_000C);

        repeat (2) @(posedge s00_axi_aclk);
        #100;
        $finish;

    end
endmodule
