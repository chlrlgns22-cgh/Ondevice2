`timescale 1ns / 1ps

module tb_dht11 ();

    // simulation parameter 정의. 습도 = 60, 온도 = 25
    parameter [7:0] HUMI_INT  = 8'd60;
    parameter [7:0] HUMI_DEC  = 8'd0;
    parameter [7:0] TEMP_INT  = 8'd25;
    parameter [7:0] TEMP_DEC  = 8'd0;
    parameter [7:0] CHECK_SUM = HUMI_INT + HUMI_DEC + TEMP_INT + TEMP_DEC;

    parameter [39:0] DATA_STREAM = {
        HUMI_INT, HUMI_DEC, TEMP_INT, TEMP_DEC, CHECK_SUM
    };

    reg clk;
    reg rst;
    reg dht11_start;

    reg dht_sensor_data;
    reg io_oe;   // 1일때 dht11 인식.

    wire [7:0] humidity;
    wire [7:0] temperature;
    wire       valid;
    wire       dht11;
    wire       w_tick_us;

    integer i;

    assign dht11 = (io_oe) ? dht_sensor_data : 1'bz;

    tick_gen_us dut_tick (
    .clk    (clk),
    .rst    (rst),
    .tick_us(w_tick_us)
    );

    dht11_controller #(
        .F_COUNT(100) 
        ) dut (
        .clk         (clk),
        .rst         (rst),
        .dht11_start (dht11_start),
        .tick_us     (w_tick_us),
        .humidity    (humidity),
        .temperature (temperature),
        .valid       (valid),
        .dht11       (dht11)
    );

    // 100MHz clock
    always #5 clk = ~clk;

    // console 창에 인식 중인 상태 띄우기용.
    initial begin
        $monitor("time=%0t | state=%0d | start_cnt=%0d | bit_cnt=%0d | hum=%0d | temp=%0d | valid=%0b | data=%h",
                 $time, dut.c_state, dut.start_cnt_reg, dut.bit_cnt_reg, humidity, temperature, valid, dut.data_reg);
    end

    initial begin
        clk             = 0;
        rst             = 1;
        dht11_start     = 0;
        io_oe           = 0;
        dht_sensor_data = 1'b1;

        // reset
        #100;
        rst = 0;

        // 유지
        #100;
        dht11_start = 1'b1;

        // controller가 low로 끌어내리는 START 대기
        wait (dht11 == 1'b0);
        dht11_start = 1'b0;

        // controller가 high로 올리는 WAIT 대기
        wait (dht11 == 1'b1);

        #30000;

        // DHT11 response
        // 80us low + 80us high
        io_oe = 1'b1;

        dht_sensor_data = 1'b0;
        #80000;

        dht_sensor_data = 1'b1;
        #80000;
        #20000;

        for (i = 39; i >= 0; i = i - 1) begin
            dht_sensor_data = 1'b0;
            #60000;

            dht_sensor_data = 1'b1;
            if (DATA_STREAM[i] == 1'b1)
                #70000;
            else
                #26000;
        end

        dht_sensor_data = 1'b0;
        #50000;

        io_oe = 0;
        dht_sensor_data = 1'b1;

        #200000;

        // 테스트 결과 콘솔창에 표시.
        if ((humidity == HUMI_INT) &&
            (temperature == TEMP_INT) &&
            (valid == 1'b1)) begin
            $display("======================================");
            $display("TEST PASS");
            $display("humidity    = %0d", humidity);
            $display("temperature = %0d", temperature);
            $display("valid       = %0b", valid);
            $display("======================================");
        end else begin
            $display("======================================");
            $display("TEST FAIL");
            $display("humidity    = %0d (expected %0d)", humidity, HUMI_INT);
            $display("temperature = %0d (expected %0d)", temperature, TEMP_INT);
            $display("valid       = %0b (expected 1)", valid);
            $display("data_reg    = %h", dut.data_reg);
            $display("state       = %0d", dut.c_state);
            $display("======================================");
        end

        $stop;
    end

endmodule