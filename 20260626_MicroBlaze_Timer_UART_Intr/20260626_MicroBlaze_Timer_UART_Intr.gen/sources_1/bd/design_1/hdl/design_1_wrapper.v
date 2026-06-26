//Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
//Date        : Fri Jun 26 14:36:39 2026
//Host        : DESKTOP-7CFQ9ND running 64-bit major release  (build 9200)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (GPIOA,
    GPIOB,
    GPIOC,
    GPIOD,
    reset,
    rx,
    sys_clock,
    tx,
    usb_uart_rxd,
    usb_uart_txd);
  inout [7:0]GPIOA;
  inout [7:0]GPIOB;
  inout [7:0]GPIOC;
  inout [7:0]GPIOD;
  input reset;
  input rx;
  input sys_clock;
  output tx;
  input usb_uart_rxd;
  output usb_uart_txd;

  wire [7:0]GPIOA;
  wire [7:0]GPIOB;
  wire [7:0]GPIOC;
  wire [7:0]GPIOD;
  wire reset;
  wire rx;
  wire sys_clock;
  wire tx;
  wire usb_uart_rxd;
  wire usb_uart_txd;

  design_1 design_1_i
       (.GPIOA(GPIOA),
        .GPIOB(GPIOB),
        .GPIOC(GPIOC),
        .GPIOD(GPIOD),
        .reset(reset),
        .rx(rx),
        .sys_clock(sys_clock),
        .tx(tx),
        .usb_uart_rxd(usb_uart_rxd),
        .usb_uart_txd(usb_uart_txd));
endmodule
