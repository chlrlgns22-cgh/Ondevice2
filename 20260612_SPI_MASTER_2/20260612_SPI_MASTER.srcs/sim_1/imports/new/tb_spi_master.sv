`timescale 1ns / 1ps

module tb_spi_master ();

    // global signals
    logic       clk;
    logic       reset;
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
    // logic       miso;
    // logic       mosi;
    logic       sclk;
    logic       ss_n;

    logic       loop_wire;

    initial clk = 0;

    always #5 clk = ~clk;

    spi_master dut (
        .*,
        .mosi(loop_wire),
        .miso(loop_wire)
    );

    task spi_set_mode(bit [1:0] mode);
        {cpol, cpha} = mode;
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
        reset = 1;
        repeat (3) @(posedge clk);
        reset = 0;
        @(posedge clk);
        clk_div = 4;  // SCLK = 10Mhz ->(100Mhz / (10Mhz*2)) -1
        @(posedge clk);

        spi_set_mode(0);
        spi_send_data(8'haa);

        spi_set_mode(1);
        spi_send_data(8'haa);

        spi_set_mode(2);
        spi_send_data(8'haa);

        spi_set_mode(3);
        spi_send_data(8'haa);

        #20;
        $finish;
    end
endmodule
