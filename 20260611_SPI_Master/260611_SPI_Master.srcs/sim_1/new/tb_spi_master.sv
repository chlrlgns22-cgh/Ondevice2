`timescale 1ns / 1ps

module tb_spi_master ();

    // global signals
    logic       clk;
    logic       rst;
    // internal signals
    logic       start;
    logic       cpha;
    logic       cpol;
    logic [7:0] clk_div;  // SCLK 속도 계산용
    logic [7:0] tx_data;
    logic       busy;
    logic [7:0] rx_data;
    logic       done;
    // external signals
    logic       miso;
    logic       sclk;
    logic       mosi;
    logic       ss_n;

    logic       loop_wire;

    initial clk = 0;

    always #5 clk = ~clk;

    spi_master dut (
        .*,
        .mosi(loop_wire),
        .miso(loop_wire)
    );

    task spi_set_cpha(bit pha);
        cpha = pha;
        @(posedge clk);
    endtask  //


    task spi_set_cpol(bit pol);
        cpol = pol;
        @(posedge clk);
    endtask

    task spi_send_data(logic [7:0] data);
        tx_data = data;
        start   = 1'b1;
        @(posedge clk);
        start = 1'b0;
        wait (done);
        @(posedge clk);
    endtask  //


    initial begin
        rst = 1;
        repeat (3) @(posedge clk);
        rst = 0;
        @(posedge clk);
        clk_div = 4;  // SCLK = 10Mhz ->(100Mhz / (10Mhz*2)) -1
        @(posedge clk);
        spi_set_cpha(0);
        spi_set_cpol(0);
        spi_send_data(8'haa);
        spi_set_cpol(1);
        spi_send_data(8'haa);
        
        spi_set_cpha(1);
        spi_set_cpol(0);
        spi_send_data(8'haa);
        spi_set_cpol(1);
        spi_send_data(8'haa);

        spi_set_cpha(0);
        spi_set_cpol(0);
        spi_send_data(8'h55);
        spi_set_cpol(1);
        spi_send_data(8'h55);

        spi_set_cpha(1);
        spi_set_cpol(0);
        spi_send_data(8'h55);
        spi_set_cpol(1);
        spi_send_data(8'h55);

        spi_set_cpha(0);
        spi_set_cpol(0);
        spi_send_data(8'hff);
        spi_set_cpol(1);
        spi_send_data(8'hff);

        spi_set_cpha(1);
        spi_set_cpol(0);
        spi_send_data(8'hff);
        spi_set_cpol(1);
        spi_send_data(8'hff);

        spi_set_cpha(0);
        spi_set_cpol(0);
        spi_send_data(8'h00);
        spi_set_cpol(1);
        spi_send_data(8'h00);

        spi_set_cpha(1);
        spi_set_cpol(0);
        spi_send_data(8'h00);
        spi_set_cpol(1);
        spi_send_data(8'h00);

        #20;
        $finish;
    end
endmodule
