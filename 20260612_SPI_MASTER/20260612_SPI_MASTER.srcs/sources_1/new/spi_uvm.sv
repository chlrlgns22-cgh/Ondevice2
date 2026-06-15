`timescale 1ns / 1ps

module spi_uvm (
    input  logic       clk,
    input  logic       rst,
    input  logic       start,
    input  logic       cpol,
    input  logic       cpha,
    input  logic [7:0] clk_div,
    input  logic [7:0] master_tx_data,
    output logic       master_busy,
    output logic [7:0] master_rx_data,
    output logic       master_done,
    input  logic [7:0] slave_tx_data,   // get from IP
    output logic [7:0] slave_rx_data,   // get from Master
    output logic       slave_busy,
    output logic       slave_done
);

    logic sclk, mosi, miso, ss_n;

    spi_master U_UVM_MASTER (
        .clk    (clk),
        .reset  (rst),
        .start  (start),
        .cpol   (cpol),
        .cpha   (cpha),
        .clk_div(clk_div),
        .tx_data(master_tx_data),
        .busy   (master_busy),
        .rx_data(master_rx_data),
        .done   (master_done),
        .sclk   (sclk),
        .mosi   (mosi),
        .miso   (miso),
        .ss_n   (ss_n)
    );


    spi_slave_top U_SPI_SLAVE (
        .clk    (clk),
        .rst    (rst),
        .sclk   (sclk),
        .mosi   (mosi),
        .ss_n   (ss_n),
        .miso   (miso),
        .tx_data(slave_tx_data),  // get from IP
        .rx_data(slave_rx_data),  // get from Master
        .busy   (slave_busy),
        .done   (slave_done)
    );
endmodule
