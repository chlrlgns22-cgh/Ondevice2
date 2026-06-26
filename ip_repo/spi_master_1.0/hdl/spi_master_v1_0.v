`timescale 1 ns / 1 ps

	module axi_spi_master_v1_0 #
	(
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here
		// SPI 외부 핀 (Master)
		output wire m_sclk,
		output wire m_mosi,
		input  wire m_miso,
		output wire m_ss_n,
		output wire m_intr,    // done 인터럽트
		// User ports ends

		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
	);

	// AXI <-> SPI Master 내부 연결
	wire       spi_start;
	wire       spi_cpol;
	wire       spi_cpha;
	wire [7:0] spi_clk_div;
	wire [7:0] spi_tx_data;
	wire       spi_busy;
	wire [7:0] spi_rx_data;
	wire       spi_done;

	// AXI4-Lite 슬레이브 인스턴스
	axi_spi_master_v1_0_S00_AXI # (
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) axi_spi_master_v1_0_S00_AXI_inst (
		.spi_start   (spi_start),
		.spi_cpol    (spi_cpol),
		.spi_cpha    (spi_cpha),
		.spi_clk_div (spi_clk_div),
		.spi_tx_data (spi_tx_data),
		.spi_busy    (spi_busy),
		.spi_rx_data (spi_rx_data),
		.spi_done    (spi_done),
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready)
	);

	assign m_intr = spi_done;

	// SPI Master 인스턴스 (.sv 모듈)
	spi_master U_SPI_MASTER (
		.clk     (s00_axi_aclk),
		.reset   (~s00_axi_aresetn),  // active high reset
		.start   (spi_start),
		.cpol    (spi_cpol),
		.cpha    (spi_cpha),
		.clk_div (spi_clk_div),
		.tx_data (spi_tx_data),
		.busy    (spi_busy),
		.rx_data (spi_rx_data),
		.done    (spi_done),
		.sclk    (m_sclk),
		.mosi    (m_mosi),
		.miso    (m_miso),
		.ss_n    (m_ss_n)
	);

	endmodule