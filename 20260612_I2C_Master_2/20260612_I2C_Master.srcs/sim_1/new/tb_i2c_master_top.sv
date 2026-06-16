`timescale 1ns / 1ps

module tb_i2c_master_top ();
    // assume the slave device address
    localparam SLA = 8'h12;

    logic       clk;
    logic       rst;
    // command port
    logic       cmd_start;
    logic       cmd_write;
    logic       cmd_read;
    logic       cmd_stop;
    // internal port
    logic [7:0] tx_data;
    logic [7:0] rx_data;
    logic       ack_in;  // cpu -> master -> slave
    logic       ack_out;  // slave -> master -> slave
    logic       busy;
    logic       done;
    // external i2c port
    logic       scl;
    wire        sda;

    pullup (scl);
    pullup (sda);

    i2c_master_top dut (.*);
    task i2c_start();
        // start signal
        cmd_start = 1'b1;
        cmd_write = 1'b0;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (done);
        @(posedge clk);
    endtask

    task i2c_write(byte data);
        // SLA write
        tx_data   = data;
        cmd_start = 1'b0;
        cmd_write = 1'b1;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (done);
        @(posedge clk);
    endtask

    task i2c_read();
        // stop signal
        cmd_start = 1'b0;
        cmd_write = 1'b0;
        cmd_read  = 1'b1;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (done);
        @(posedge clk);
    endtask

    task i2c_stop();
        // stop signal
        cmd_start = 1'b0;
        cmd_write = 1'b0;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b1;
        @(posedge clk);
        wait (done);
        @(posedge clk);
    endtask

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;

        i2c_start();
        i2c_write((SLA << 1) | 1'b0);  // 8'h12 << 1 | 1'b0, write
        i2c_write(8'h55);
        i2c_write(8'haa);
        i2c_stop();

        // IDLE
        #100;
        $finish;


    end
endmodule
