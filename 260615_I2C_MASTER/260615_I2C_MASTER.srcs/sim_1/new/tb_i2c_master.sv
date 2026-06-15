`timescale 1ns / 1ps

module tb_i2c_master ();
    localparam SLA = 8'h12;

    logic       clk;
    logic       reset;
    // command port
    logic       cmd_start;
    logic       cmd_write;
    logic       cmd_read;
    logic       cmd_stop;
    // internal port
    logic [7:0] tx_data;
    logic [7:0] rx_data;
    logic       ack_in;  // read 시 master가 보낼 ACK(0)/NACK(1)
    logic       ack_out;  // write 시 slave로부터 받은 ACK(0)/NACK(1)
    logic       busy;
    logic       done;
    // external i2c port
    logic       scl;
    wire        sda;

    pullup (scl);
    pullup (sda);

    initial clk = 0;
    always #5 clk = ~clk;

    I2C_Master_top dut (.*);

    task i2c_start();
        cmd_start = 1'b1;
        cmd_write = 1'b0;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (done);
        @(posedge clk);
    endtask

    task i2c_write(byte data);
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
        cmd_start = 1'b0;
        cmd_write = 1'b0;
        cmd_read  = 1'b1;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (done);
        @(posedge clk);
    endtask

    task i2c_stop();
        cmd_start = 1'b0;
        cmd_write = 1'b0;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b1;
        @(posedge clk);
        wait (done);
        @(posedge clk);
    endtask

    initial begin
        reset = 1;
        repeat (5) @(posedge clk);
        reset = 0;
        @(posedge clk);

        i2c_start();
        i2c_write(SLA << 1 | 1'b0);
        i2c_write(8'h55);
        i2c_write(8'haa);
        i2c_stop();

        // //start signal
        // cmd_start = 1'b1;
        // cmd_write = 1'b0;
        // cmd_read  = 1'b0;
        // cmd_stop  = 1'b0;
        // @(posedge clk);
        // wait (done);
        // @(posedge clk);
        //
        // tx_data   = (SLA << 1) | 1'b0;  // 8'h12 << 1 / 1'b0, write
        // cmd_start = 1'b0;
        // cmd_write = 1'b1;
        // cmd_read  = 1'b0;
        // cmd_stop  = 1'b0;
        // @(posedge clk);
        // wait (done);
        // @(posedge clk);
        //
        // // data write
        // tx_data   = 8'h55;
        // cmd_start = 1'b0;
        // cmd_write = 1'b1;
        // cmd_read  = 1'b0;
        // cmd_stop  = 1'b0;
        // @(posedge clk);
        // wait (done);
        // @(posedge clk);
        //
        // //stop signal
        // // data write
        // tx_data   = 8'h55;
        // cmd_start = 1'b0;
        // cmd_write = 1'b0;
        // cmd_read  = 1'b0;
        // cmd_stop  = 1'b1;
        // @(posedge clk);
        // wait (done);
        // @(posedge clk);

        // IDLE
        #100;
        $finish;
    end
endmodule
