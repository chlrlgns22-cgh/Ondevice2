`timescale 1 ns / 1 ps

	module axi_spi_master_v1_0_S00_AXI #
	(
		// User parameters ends
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		parameter integer C_S_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here
		// SPI Master 제어 포트
		output wire       spi_start,
		output wire       spi_cpol,
		output wire       spi_cpha,
		output wire [7:0] spi_clk_div,
		output wire [7:0] spi_tx_data,
		input  wire       spi_busy,
		input  wire [7:0] spi_rx_data,
		input  wire       spi_done,
		// User ports ends

		input wire  S_AXI_ACLK,
		input wire  S_AXI_ARESETN,
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		input wire [2 : 0] S_AXI_AWPROT,
		input wire  S_AXI_AWVALID,
		output wire  S_AXI_AWREADY,
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		input wire  S_AXI_WVALID,
		output wire  S_AXI_WREADY,
		output wire [1 : 0] S_AXI_BRESP,
		output wire  S_AXI_BVALID,
		input wire  S_AXI_BREADY,
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		input wire [2 : 0] S_AXI_ARPROT,
		input wire  S_AXI_ARVALID,
		output wire  S_AXI_ARREADY,
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		output wire [1 : 0] S_AXI_RRESP,
		output wire  S_AXI_RVALID,
		input wire  S_AXI_RREADY
	);

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 1;

	// 레지스터 맵
	// 0x00 CR  : [0]=start(펄스) [1]=cpol [2]=cpha
	// 0x04 TDR : [7:0]=tx_data
	// 0x08 RDR : [7:0]=rx_data (읽기전용)
	// 0x0C SR  : [0]=busy [1]=done (읽기전용)
	// + CR[15:8] = clk_div
	reg [C_S_AXI_DATA_WIDTH-1:0] spi_cr;   // CR
	reg [C_S_AXI_DATA_WIDTH-1:0] spi_tdr;  // TDR
	reg [C_S_AXI_DATA_WIDTH-1:0] spi_rdr;  // RDR
	reg [C_S_AXI_DATA_WIDTH-1:0] spi_sr;   // SR

	wire slv_reg_rden;
	wire slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;
	integer byte_index;
	reg aw_en;

	reg spi_start_r;
	reg done_latch;  // done 래치 (SR 읽을 때 클리어)

	// SPI 신호 연결
	assign spi_start   = spi_start_r;
	assign spi_cpol    = spi_cr[1];
	assign spi_cpha    = spi_cr[2];
	assign spi_clk_div = spi_cr[15:8];
	assign spi_tx_data = spi_tdr[7:0];

	assign S_AXI_AWREADY = axi_awready;
	assign S_AXI_WREADY  = axi_wready;
	assign S_AXI_BRESP   = axi_bresp;
	assign S_AXI_BVALID  = axi_bvalid;
	assign S_AXI_ARREADY = axi_arready;
	assign S_AXI_RDATA   = axi_rdata;
	assign S_AXI_RRESP   = axi_rresp;
	assign S_AXI_RVALID  = axi_rvalid;

	// AWREADY
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	      aw_en <= 1'b1;
	    end
	  else
	    begin
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          axi_awready <= 1'b1;
	          aw_en <= 1'b0;
	        end
	        else if (S_AXI_BREADY && axi_bvalid)
	            begin
	              aw_en <= 1'b1;
	              axi_awready <= 1'b0;
	            end
	      else
	        begin
	          axi_awready <= 1'b0;
	        end
	    end
	end

	// AWADDR 래치
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	    end
	  else
	    begin
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          axi_awaddr <= S_AXI_AWADDR;
	        end
	    end
	end

	// WREADY
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end
	  else
	    begin
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
	        begin
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end
	end

	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	// 레지스터 쓰기
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      spi_cr      <= 0;
	      spi_tdr     <= 0;
	      spi_start_r <= 1'b0;
	    end
	  else
	    begin
	      spi_start_r <= 1'b0;  // start는 1클럭 펄스
	      if (slv_reg_wren)
	        begin
	          case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	            2'h0: begin  // CR
	              spi_cr      <= S_AXI_WDATA;
	              spi_start_r <= S_AXI_WDATA[0];  // bit0=start 펄스
	            end
	            2'h1: begin  // TDR
	              spi_tdr <= S_AXI_WDATA;
	            end
	            default: ;
	          endcase
	        end
	    end
	end

	// done 래치 (spi_done 펄스 → 래치, SR 읽으면 클리어)
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      done_latch <= 1'b0;
	    end
	  else
	    begin
	      if (spi_done)
	        done_latch <= 1'b1;
	      else if (slv_reg_rden && axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h3)
	        done_latch <= 1'b0;  // SR 읽으면 클리어
	    end
	end

	// SR, RDR 업데이트 (하드웨어에서 갱신)
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      spi_sr  <= 0;
	      spi_rdr <= 0;
	    end
	  else
	    begin
	      spi_sr  <= {{30{1'b0}}, done_latch, spi_busy};  // done_latch 사용
	      if (spi_done)
	        spi_rdr <= {{24{1'b0}}, spi_rx_data};
	    end
	end

	// BVALID
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end
	  else
	    begin
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0;
	        end
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid)
	            begin
	              axi_bvalid <= 1'b0;
	            end
	        end
	    end
	end

	// ARREADY
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 32'b0;
	    end
	  else
	    begin
	      if (~axi_arready && S_AXI_ARVALID)
	        begin
	          axi_arready <= 1'b1;
	          axi_araddr  <= S_AXI_ARADDR;
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end
	end

	// RVALID
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end
	  else
	    begin
	      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	        begin
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0;
	        end
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          axi_rvalid <= 1'b0;
	        end
	    end
	end

	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;

	// 레지스터 읽기
	always @(*)
	begin
	  case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	    2'h0:    reg_data_out <= spi_cr;
	    2'h1:    reg_data_out <= spi_tdr;
	    2'h2:    reg_data_out <= spi_rdr;
	    2'h3:    reg_data_out <= spi_sr;
	    default: reg_data_out <= 0;
	  endcase
	end

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rdata <= 0;
	    end
	  else
	    begin
	      if (slv_reg_rden)
	        begin
	          axi_rdata <= reg_data_out;
	        end
	    end
	end

	endmodule