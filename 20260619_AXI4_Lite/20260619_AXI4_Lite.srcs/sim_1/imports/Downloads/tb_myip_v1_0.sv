`timescale 1ns / 1ps
//==============================================================
// Testbench : tb_myip_v1_0
// DUT       : myip_v1_0  (S00_AXI = myip_v1_0_S00_AXI 가 실제 구동됨)
//
// 주의: myip_v1_0 내부의 axi_master(U_MASTER)는 transfer/addr/wdata/write
//       포트가 전부 미연결(open)이라 항상 idle 상태이며, top의
//       s00_axi_* 출력 포트는 myip_v1_0_S00_AXI_inst가 단독으로 드라이브한다.
//       따라서 본 TB는 외부 AXI4-Lite 마스터 BFM으로 top 포트를 직접
//       구동하여 실질적으로 myip_v1_0_S00_AXI의 동작을 검증한다.
//==============================================================
module tb_myip_v1_0;

    // ---------------- Parameters ----------------
    localparam integer C_S00_AXI_DATA_WIDTH = 32;
    localparam integer C_S00_AXI_ADDR_WIDTH = 4;
    localparam CLK_PERIOD = 10; // 100MHz

    // ---------------- DUT I/F ----------------
    logic                                  s00_axi_aclk;
    logic                                  s00_axi_aresetn;
    logic [C_S00_AXI_ADDR_WIDTH-1:0]       s00_axi_awaddr;
    logic [2:0]                            s00_axi_awprot;
    logic                                  s00_axi_awvalid;
    logic                                  s00_axi_awready;
    logic [C_S00_AXI_DATA_WIDTH-1:0]       s00_axi_wdata;
    logic [(C_S00_AXI_DATA_WIDTH/8)-1:0]   s00_axi_wstrb;
    logic                                  s00_axi_wvalid;
    logic                                  s00_axi_wready;
    logic [1:0]                            s00_axi_bresp;
    logic                                  s00_axi_bvalid;
    logic                                  s00_axi_bready;
    logic [C_S00_AXI_ADDR_WIDTH-1:0]       s00_axi_araddr;
    logic [2:0]                            s00_axi_arprot;
    logic                                  s00_axi_arvalid;
    logic                                  s00_axi_arready;
    logic [C_S00_AXI_DATA_WIDTH-1:0]       s00_axi_rdata;
    logic [1:0]                            s00_axi_rresp;
    logic                                  s00_axi_rvalid;
    logic                                  s00_axi_rready;

    // ---------------- Scoreboard ----------------
    int pass_cnt = 0;
    int fail_cnt = 0;

    // ---------------- DUT instantiation ----------------
    myip_v1_0 #(
        .C_S00_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S00_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) DUT (
        .s00_axi_aclk   (s00_axi_aclk),
        .s00_axi_aresetn(s00_axi_aresetn),
        .s00_axi_awaddr (s00_axi_awaddr),
        .s00_axi_awprot (s00_axi_awprot),
        .s00_axi_awvalid(s00_axi_awvalid),
        .s00_axi_awready(s00_axi_awready),
        .s00_axi_wdata  (s00_axi_wdata),
        .s00_axi_wstrb  (s00_axi_wstrb),
        .s00_axi_wvalid (s00_axi_wvalid),
        .s00_axi_wready (s00_axi_wready),
        .s00_axi_bresp  (s00_axi_bresp),
        .s00_axi_bvalid (s00_axi_bvalid),
        .s00_axi_bready (s00_axi_bready),
        .s00_axi_araddr (s00_axi_araddr),
        .s00_axi_arprot (s00_axi_arprot),
        .s00_axi_arvalid(s00_axi_arvalid),
        .s00_axi_arready(s00_axi_arready),
        .s00_axi_rdata  (s00_axi_rdata),
        .s00_axi_rresp  (s00_axi_rresp),
        .s00_axi_rvalid (s00_axi_rvalid),
        .s00_axi_rready (s00_axi_rready)
    );

    // ---------------- Clock ----------------
    initial s00_axi_aclk = 0;
    always #(CLK_PERIOD/2) s00_axi_aclk = ~s00_axi_aclk;

    // ---------------- Reset ----------------
    task automatic do_reset();
        s00_axi_aresetn = 0;
        s00_axi_awaddr  = '0;
        s00_axi_awprot  = '0;
        s00_axi_awvalid = 0;
        s00_axi_wdata   = '0;
        s00_axi_wstrb   = '0;
        s00_axi_wvalid  = 0;
        s00_axi_bready  = 0;
        s00_axi_araddr  = '0;
        s00_axi_arprot  = '0;
        s00_axi_arvalid = 0;
        s00_axi_rready  = 0;
        repeat (5) @(posedge s00_axi_aclk);
        s00_axi_aresetn = 1;
        repeat (2) @(posedge s00_axi_aclk);
    endtask

    //==============================================================
    // AXI4-Lite Master BFM tasks
    //==============================================================

    // AW와 W를 같은 사이클에 동시 진입시키는 표준 쓰기
    task automatic axi_write(
        input  [C_S00_AXI_ADDR_WIDTH-1:0]     addr,
        input  [C_S00_AXI_DATA_WIDTH-1:0]     data,
        input  [(C_S00_AXI_DATA_WIDTH/8)-1:0] strb = '1
    );
        @(posedge s00_axi_aclk);
        s00_axi_awaddr  <= addr;
        s00_axi_awvalid <= 1'b1;
        s00_axi_wdata   <= data;
        s00_axi_wstrb   <= strb;
        s00_axi_wvalid  <= 1'b1;
        s00_axi_bready  <= 1'b1;

        // AWREADY 대기 (동시에 WREADY도 같이 옴)
        wait (s00_axi_awready === 1'b1);
        @(posedge s00_axi_aclk);
        s00_axi_awvalid <= 1'b0;
        s00_axi_wvalid  <= 1'b0;

        // BVALID 대기
        wait (s00_axi_bvalid === 1'b1);
        if (s00_axi_bresp !== 2'b00) begin
            $display("[%0t] FAIL: WRITE addr=0x%0h unexpected BRESP=%0d", $time, addr, s00_axi_bresp);
            fail_cnt++;
        end
        @(posedge s00_axi_aclk);
        s00_axi_bready <= 1'b0;
    endtask

    // AW가 W보다 먼저 도착하는 케이스(순서 의존성 테스트용)
    task automatic axi_write_aw_first(
        input [C_S00_AXI_ADDR_WIDTH-1:0]     addr,
        input [C_S00_AXI_DATA_WIDTH-1:0]     data
    );
        @(posedge s00_axi_aclk);
        s00_axi_awaddr  <= addr;
        s00_axi_awvalid <= 1'b1;
        s00_axi_bready  <= 1'b1;
        @(posedge s00_axi_aclk);
        // 2클럭 뒤에 W를 보냄
        @(posedge s00_axi_aclk);
        s00_axi_wdata  <= data;
        s00_axi_wstrb  <= '1;
        s00_axi_wvalid <= 1'b1;

        wait (s00_axi_awready === 1'b1);
        @(posedge s00_axi_aclk);
        s00_axi_awvalid <= 1'b0;

        wait (s00_axi_wready === 1'b1);
        @(posedge s00_axi_aclk);
        s00_axi_wvalid <= 1'b0;

        wait (s00_axi_bvalid === 1'b1);
        @(posedge s00_axi_aclk);
        s00_axi_bready <= 1'b0;
    endtask

    task automatic axi_read(
        input  [C_S00_AXI_ADDR_WIDTH-1:0] addr,
        output [C_S00_AXI_DATA_WIDTH-1:0] data
    );
        @(posedge s00_axi_aclk);
        s00_axi_araddr  <= addr;
        s00_axi_arvalid <= 1'b1;
        s00_axi_rready  <= 1'b1;

        wait (s00_axi_arready === 1'b1);
        @(posedge s00_axi_aclk);
        s00_axi_arvalid <= 1'b0;

        wait (s00_axi_rvalid === 1'b1);
        data = s00_axi_rdata;
        if (s00_axi_rresp !== 2'b00) begin
            $display("[%0t] FAIL: READ addr=0x%0h unexpected RRESP=%0d", $time, addr, s00_axi_rresp);
            fail_cnt++;
        end
        @(posedge s00_axi_aclk);
        s00_axi_rready <= 1'b0;
    endtask

    task automatic check_equal(string name, logic [31:0] act, logic [31:0] exp);
        if (act === exp) begin
            $display("[%0t] PASS: %s = 0x%08h", $time, name, act);
            pass_cnt++;
        end else begin
            $display("[%0t] FAIL: %s exp=0x%08h act=0x%08h", $time, name, exp, act);
            fail_cnt++;
        end
    endtask

    //==============================================================
    // Test sequence
    //==============================================================
    logic [31:0] rdata;

    initial begin
        $display("==================================================");
        $display(" myip_v1_0 AXI4-Lite Testbench start");
        $display("==================================================");

        do_reset();

        // ---- Test 1: Reset 직후 레지스터 0 확인 ----
        axi_read(4'h0, rdata);
        check_equal("reg0 after reset", rdata, 32'h0000_0000);

        // ---- Test 2: 단일 레지스터 Write/Read (WSTRB all 1) ----
        axi_write(4'h0, 32'hDEAD_BEEF);
        axi_read(4'h0, rdata);
        check_equal("reg0 readback", rdata, 32'hDEAD_BEEF);

        axi_write(4'h4, 32'hCAFE_F00D);
        axi_read(4'h4, rdata);
        check_equal("reg1 readback", rdata, 32'hCAFE_F00D);

        axi_write(4'h8, 32'h1234_5678);
        axi_read(4'h8, rdata);
        check_equal("reg2 readback", rdata, 32'h1234_5678);

        axi_write(4'hC, 32'hA5A5_5A5A);
        axi_read(4'hC, rdata);
        check_equal("reg3 readback", rdata, 32'hA5A5_5A5A);

        // ---- Test 3: 이전 레지스터 값 유지(독립성) 확인 ----
        axi_read(4'h0, rdata);
        check_equal("reg0 unaffected by reg3 write", rdata, 32'hDEAD_BEEF);

        // ---- Test 4: WSTRB 부분 바이트 쓰기 ----
        axi_write(4'h0, 32'h0000_0000);                 // reg0 클리어
        axi_write(4'h0, 32'hFFFF_FFFF, 4'b0001);         // byte0만 갱신
        axi_read(4'h0, rdata);
        check_equal("reg0 WSTRB byte0 only", rdata, 32'h0000_00FF);

        axi_write(4'h0, 32'h0000_0000);                  // reg0 클리어
        axi_write(4'h0, 32'hFFFF_FFFF, 4'b1010);          // byte1,3만 갱신
        axi_read(4'h0, rdata);
        check_equal("reg0 WSTRB byte1+3 only", rdata, 32'hFF00_FF00);

        // ---- Test 5: 연속 Write (Back-to-back) ----
        axi_write(4'h0, 32'h1111_1111);
        axi_write(4'h4, 32'h2222_2222);
        axi_write(4'h8, 32'h3333_3333);
        axi_write(4'hC, 32'h4444_4444);
        axi_read(4'h0, rdata); check_equal("burst-like reg0", rdata, 32'h1111_1111);
        axi_read(4'h4, rdata); check_equal("burst-like reg1", rdata, 32'h2222_2222);
        axi_read(4'h8, rdata); check_equal("burst-like reg2", rdata, 32'h3333_3333);
        axi_read(4'hC, rdata); check_equal("burst-like reg3", rdata, 32'h4444_4444);

        // ---- Test 6: 연속 Read (Back-to-back) ----
        axi_read(4'h0, rdata); check_equal("repeat read reg0 #1", rdata, 32'h1111_1111);
        axi_read(4'h0, rdata); check_equal("repeat read reg0 #2", rdata, 32'h1111_1111);

        // ---- Test 7: AW가 W보다 먼저 도착하는 케이스 ----
        axi_write_aw_first(4'h4, 32'h9999_8888);
        axi_read(4'h4, rdata);
        check_equal("AW-first write reg1", rdata, 32'h9999_8888);

        // ---- Test 8: Reset 중 진행중 트랜잭션 무시 확인 ----
        fork
            begin
                axi_write(4'h0, 32'hABCD_EF01);
            end
            begin
                #(CLK_PERIOD*2);
                s00_axi_aresetn = 0;
                repeat (5) @(posedge s00_axi_aclk);
                s00_axi_aresetn = 1;
            end
        join_any
        disable fork;
        repeat (3) @(posedge s00_axi_aclk);
        // 리셋 이후 정상 동작 재확인
        do_reset();
        axi_write(4'h0, 32'h5555_AAAA);
        axi_read(4'h0, rdata);
        check_equal("post-reset-during-txn sanity write", rdata, 32'h5555_AAAA);

        // ---------------- Summary ----------------
        $display("==================================================");
        $display(" TEST SUMMARY : PASS=%0d  FAIL=%0d", pass_cnt, fail_cnt);
        if (fail_cnt == 0)
            $display(" RESULT: ALL TESTS PASSED");
        else
            $display(" RESULT: %0d TEST(S) FAILED", fail_cnt);
        $display("==================================================");

        #(CLK_PERIOD*5);
        $finish;
    end

    // ---------------- Timeout watchdog ----------------
    initial begin
        #(CLK_PERIOD*2000);
        $display("[%0t] ERROR: TESTBENCH TIMEOUT", $time);
        $finish;
    end

endmodule
