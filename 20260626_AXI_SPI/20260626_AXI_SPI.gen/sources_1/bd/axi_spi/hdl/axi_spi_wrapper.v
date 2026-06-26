//Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
//Date        : Fri Jun 26 22:23:31 2026
//Host        : DESKTOP-7CFQ9ND running 64-bit major release  (build 9200)
//Command     : generate_target axi_spi_wrapper.bd
//Design      : axi_spi_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module axi_spi_wrapper
   (GPIOA,
    GPIOB,
    GPIOC,
    GPIOD,
    GPIOE,
    m_miso,
    m_mosi,
    m_sclk,
    m_ss_n,
    reset,
    rx,
    s_miso,
    s_mosi,
    s_sclk,
    s_ss_n,
    sys_clock,
    tx,
    usb_uart_rxd,
    usb_uart_txd);
  inout [7:0]GPIOA;
  inout [7:0]GPIOB;
  inout [7:0]GPIOC;
  inout [7:0]GPIOD;
  inout [7:0]GPIOE;
  input m_miso;
  output m_mosi;
  output m_sclk;
  output m_ss_n;
  input reset;
  input rx;
  output s_miso;
  input s_mosi;
  input s_sclk;
  input s_ss_n;
  input sys_clock;
  output tx;
  input usb_uart_rxd;
  output usb_uart_txd;

  wire [7:0]GPIOA;
  wire [7:0]GPIOB;
  wire [7:0]GPIOC;
  wire [7:0]GPIOD;
  wire [7:0]GPIOE;
  wire m_miso;
  wire m_mosi;
  wire m_sclk;
  wire m_ss_n;
  wire reset;
  wire rx;
  wire s_miso;
  wire s_mosi;
  wire s_sclk;
  wire s_ss_n;
  wire sys_clock;
  wire tx;
  wire usb_uart_rxd;
  wire usb_uart_txd;

  axi_spi axi_spi_i
       (.GPIOA(GPIOA),
        .GPIOB(GPIOB),
        .GPIOC(GPIOC),
        .GPIOD(GPIOD),
        .GPIOE(GPIOE),
        .m_miso(m_miso),
        .m_mosi(m_mosi),
        .m_sclk(m_sclk),
        .m_ss_n(m_ss_n),
        .reset(reset),
        .rx(rx),
        .s_miso(s_miso),
        .s_mosi(s_mosi),
        .s_sclk(s_sclk),
        .s_ss_n(s_ss_n),
        .sys_clock(sys_clock),
        .tx(tx),
        .usb_uart_rxd(usb_uart_rxd),
        .usb_uart_txd(usb_uart_txd));
endmodule
