`timescale 1ns / 1ps `timescale 1ns / 1ps
parameter BAUD_PERIOD = 10 * (100_000_000 / 9600);

class transaction;
    rand bit [7:0] compare_data;
    bit      [7:0] rx_data;
    bit      [7:0] tx_data;
    bit            rx;
    bit            tx;
    bit            rx_done;
    bit            uart_R;
    bit            uart_L;
    bit            uart_U;
    bit            uart_D;
    bit            uart_M;
    bit            uart_S;

    constraint decoder_percent {
        compare_data dist {
            8'h52 := 5,
            8'h4C := 5,
            8'h55 := 5,
            8'h44 := 5,
            8'h4D := 5,
            8'h53 := 5,
            [0 : 255] :/ 70
        };
    }

endclass

interface uart_top_interface;
    logic       clk;
    logic       rst;
    logic       rx;
    logic       tx;
    logic [7:0] rx_data;
    logic       rx_done;
    logic       uart_R;
    logic       uart_L;
    logic       uart_U;
    logic       uart_D;
    logic       uart_M;
    logic       uart_S;
endinterface

class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) gen2scb_mbox;
    event event_gen_next;

    function new(mailbox#(transaction) gen2drv_mbox,
                 mailbox#(transaction) gen2scb_mbox, event event_gen_next);
        this.gen2drv_mbox   = gen2drv_mbox;
        this.gen2scb_mbox   = gen2scb_mbox;
        this.event_gen_next = event_gen_next;
    endfunction

    task run(int count);
        repeat (count) begin
            tr = new;
            tr.randomize();
            gen2drv_mbox.put(tr);
            gen2scb_mbox.put(tr);
            @(event_gen_next);
        end
    endtask
endclass

class driver;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event event_gen_next;
    virtual uart_top_interface uart_vif;
    int i;

    function new(mailbox#(transaction) gen2drv_mbox, event event_gen_next,  
                 virtual uart_top_interface uart_vif);
        this.gen2drv_mbox   = gen2drv_mbox;
        this.event_gen_next = event_gen_next;
        this.uart_vif       = uart_vif;
    endfunction

    task preset();
        uart_vif.rst = 1;
        uart_vif.rx  = 1;

        repeat (2) @(posedge uart_vif.clk);
        uart_vif.rst = 0;
        @(negedge uart_vif.clk);
        assert (uart_vif.rx) $display("[DRV Assert] reset pass : rx=1");
        else $display("[DRV Assert] reset fail : rx = %d", uart_vif.rx);
    endtask

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            begin
                // pc tx
                // start
                uart_vif.rx = 0;
                // start bit
                #(BAUD_PERIOD);
                //data bit
                for (i = 0; i < 8; i++) begin
                    // rx, send_data [0] ~ [7]
                    uart_vif.rx = tr.compare_data[i];
                    #(BAUD_PERIOD);
                end
                uart_vif.rx = 1;
                #(BAUD_PERIOD);
                #1;
                ->event_gen_next;
            end
        end

    endtask
endclass

class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual uart_top_interface uart_vif;
    int i;
    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual uart_top_interface uart_vif);
        this.mon2scb_mbox = mon2scb_mbox;
        this.uart_vif     = uart_vif;
    endfunction

    task get_tx();
        begin
            // pc tx
            // start
            // start bit
            #(BAUD_PERIOD / 2);  // 중앙 샘플링 용도
            //data bit
            for (i = 0; i < 8; i++) begin
                // rx, send_data [0] ~ [7]
                #(BAUD_PERIOD);
                tr.tx_data[i] = uart_vif.tx;
            end
            #(BAUD_PERIOD);
            #((BAUD_PERIOD/2)-15);

        end
    endtask

    task run();
        forever begin
            @(posedge uart_vif.rx_done);
            @(negedge uart_vif.clk);
            @(negedge uart_vif.clk);
            tr = new;
            tr.uart_R = uart_vif.uart_R;
            tr.uart_L = uart_vif.uart_L;
            tr.uart_U = uart_vif.uart_U;
            tr.uart_D = uart_vif.uart_D;
            tr.uart_M = uart_vif.uart_M;
            tr.uart_S = uart_vif.uart_S;
            tr.rx_data = uart_vif.rx_data;
            get_tx();
            mon2scb_mbox.put(tr);
        end
    endtask
endclass

class scoreboard;
    transaction tr;
    mailbox #(transaction) gen2scb_mbox;
    mailbox #(transaction) mon2scb_mbox;
    bit [7:0] compare_data;
    bit compare_uart_R;
    bit compare_uart_L;
    bit compare_uart_U;
    bit compare_uart_D;
    bit compare_uart_M;
    bit compare_uart_S;

    int
        total_rx_cnt,
        total_tx_cnt,
        pass_rx_data,
        fail_rx_data,
        pass_tx_data,
        fail_tx_data,
        uart_R_cnt,
        uart_L_cnt,
        uart_U_cnt,
        uart_D_cnt,
        uart_M_cnt,
        uart_S_cnt;

    function new(mailbox#(transaction) gen2scb_mbox,
                 mailbox#(transaction) mon2scb_mbox);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen2scb_mbox = gen2scb_mbox;
    endfunction

    task run();
        forever begin
            gen2scb_mbox.get(tr);
            compare_data = tr.compare_data;
            mon2scb_mbox.get(tr);
            begin
                case (compare_data)
                    8'h52: compare_uart_R = 1'b1;
                    8'h4C: compare_uart_L = 1'b1;
                    8'h55: compare_uart_U = 1'b1;
                    8'h44: compare_uart_D = 1'b1;
                    8'h4D: compare_uart_M = 1'b1;
                    8'h53: compare_uart_S = 1'b1;
                    default: begin
                        compare_uart_R = 1'b0;
                        compare_uart_L = 1'b0;
                        compare_uart_U = 1'b0;
                        compare_uart_D = 1'b0;
                        compare_uart_M = 1'b0;
                        compare_uart_S = 1'b0;
                    end
                endcase
            end
            total_rx_cnt++;
            total_tx_cnt++;
            if (tr.rx_data == compare_data) begin
                $display("%t : PASS!! rx_data = %d, compare_data = %d", $time,
                         tr.rx_data, compare_data);
                pass_rx_data++;
            end else begin
                $display("%t : Fail!! rx_data = %d, compare_data = %d", $time,
                         tr.rx_data, compare_data);
                fail_rx_data++;
            end
            if (tr.tx_data == tr.rx_data) begin
                $display("%t : PASS!! tx_data = %d, rx_data = %d", $time,
                         tr.tx_data, tr.rx_data);
                pass_tx_data++;
                if (tr.uart_R) begin
                    if (compare_uart_R == tr.uart_R) begin
                        $display("Decode Result : uart_R");
                        uart_R_cnt++;
                    end
                end
                if (tr.uart_L) begin
                    if (compare_uart_L == tr.uart_L) begin
                        $display("Decode Result : uart_L");
                        uart_L_cnt++;
                    end
                end
                if (tr.uart_U) begin
                    if (compare_uart_U == tr.uart_U) begin
                        $display("Decode Result : uart_U");
                        uart_U_cnt++;
                    end
                end
                if (tr.uart_D) begin
                    if (compare_uart_D == tr.uart_D) begin
                        $display("Decode Result : uart_D");
                        uart_D_cnt++;
                    end
                end
                if (tr.uart_M) begin
                    if (compare_uart_M == tr.uart_M) begin
                        $display("Decode Result : uart_M");
                        uart_M_cnt++;
                    end
                end
                if (tr.uart_S) begin
                    if (compare_uart_S == tr.uart_S) begin
                        $display("Decode Result : uart_S");
                        uart_S_cnt++;
                    end
                end
            end else begin
                $display("%t : Fail!! tx_data = %d, rx_data = %d", $time,
                         tr.tx_data, tr.rx_data);
                fail_tx_data++;
            end
        end
    endtask
endclass

class environment;
    generator                  gen;
    driver                     drv;
    monitor                    mon;
    scoreboard                 scb;
    mailbox #(transaction)     gen2drv_mbox;
    mailbox #(transaction)     gen2scb_mbox;
    mailbox #(transaction)     mon2scb_mbox;
    event                      event_gen_next;
    virtual uart_top_interface uart_vif;

    function new(virtual uart_top_interface uart_vif);
        gen2drv_mbox = new;
        gen2scb_mbox = new;
        mon2scb_mbox = new;

        gen = new(gen2drv_mbox, gen2scb_mbox, event_gen_next);
        drv = new(gen2drv_mbox, event_gen_next, uart_vif);
        mon = new(mon2scb_mbox, uart_vif);
        scb = new(gen2scb_mbox, mon2scb_mbox);

        this.uart_vif = uart_vif;
    endfunction

    task run();
        drv.preset();
        fork
            gen.run(100);
            drv.run();
            mon.run();
            scb.run();
        join_any
        repeat(10) #(BAUD_PERIOD); //for get_tx delay
        $display("uart Constraint random test end");
        $display("________________________________________");
        $display("uart Constraint random test Verification");
        $display("**      TOTAL rx_test num = %5d     **", scb.total_rx_cnt);
        $display("**      pass  rx_test num = %5d     **", scb.pass_rx_data);
        $display("**      fail  rx_test num = %5d     **", scb.fail_rx_data);
        $display("**      TOTAL tx_test num = %5d     **", scb.total_tx_cnt);
        $display("**      pass  tx_test num = %5d     **", scb.pass_tx_data);
        $display("**      fail  tx_test num = %5d     **", scb.fail_tx_data);
        $display("**      total uart_R  num = %5d     **", scb.uart_R_cnt);
        $display("**      total uart_L  num = %5d     **", scb.uart_L_cnt);
        $display("**      total uart_U  num = %5d     **", scb.uart_U_cnt);
        $display("**      total uart_D  num = %5d     **", scb.uart_D_cnt);
        $display("**      total uart_M  num = %5d     **", scb.uart_M_cnt);
        $display("**      total uart_S  num = %5d     **", scb.uart_S_cnt);
        $display("________________________________________");
        $stop;
    endtask
endclass


module tb_top_uart_sv ();
    uart_top_interface uart_if ();
    environment env;

    top_uart_sv dut_top_uart (
        .clk(uart_if.clk),
        .rst(uart_if.rst),
        .rx(uart_if.rx),
        .tx(uart_if.tx),
        .rx_data(uart_if.rx_data),
        .rx_done(uart_if.rx_done),
        .uart_R(uart_if.uart_R),
        .uart_L(uart_if.uart_L),
        .uart_U(uart_if.uart_U),
        .uart_D(uart_if.uart_D),
        .uart_M(uart_if.uart_M),
        .uart_S(uart_if.uart_S)
    );

    always #5 uart_if.clk = ~uart_if.clk;
    initial begin
        uart_if.clk = 0;
        env = new(uart_if);
        env.run();
    end
endmodule
