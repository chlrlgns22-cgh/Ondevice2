`timescale 1ns / 1ps
parameter BAUD_PERIOD = 10 * (100_000_000 / 9600);

class transaction;
    rand bit [7:0] compare_data;
    bit      [7:0] rx_data;
    bit      [7:0] tx_data;
    bit            rx;
    bit            tx;
    bit            rx_done;

endclass


interface uart_interface;
    logic       clk;
    logic       rst;
    logic       rx;
    logic       tx;
    logic [7:0] rx_data;
    logic       rx_done;
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
    virtual uart_interface uart_vif;
    int i;

    function new(mailbox#(transaction) gen2drv_mbox, event event_gen_next,
                 virtual uart_interface uart_vif);
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
    virtual uart_interface uart_vif;
    int i;
    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual uart_interface uart_vif);
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
        end
    endtask

    task run();
        forever begin
            @(posedge uart_vif.rx_done);
            #5;
            tr = new;
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
    int
        total_rx_cnt,
        total_tx_cnt,
        pass_rx_data,
        fail_rx_data,
        pass_tx_data,
        fail_tx_data;

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
            end else begin
                $display("%t : Fail!! tx_data = %d, rx_data = %d", $time,
                         tr.tx_data, tr.rx_data);
                fail_tx_data++;
            end
        end
    endtask
endclass

class environment;
    generator              gen;
    driver                 drv;
    monitor                mon;
    scoreboard             scb;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) gen2scb_mbox;
    mailbox #(transaction) mon2scb_mbox;
    event                  event_gen_next;
    virtual uart_interface uart_vif;

    function new(virtual uart_interface uart_vif);
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
        #20;
        $display("uart Constraint random test end");
        $display("________________________________________");
        $display("uart Constraint random test Verification");
        $display("**      TOTAL rx_test num = %5d     **", scb.total_rx_cnt);
        $display("**      pass  rx_test num = %5d     **", scb.pass_rx_data);
        $display("**      fail  rx_test num = %5d     **", scb.fail_rx_data);
        $display("**      TOTAL tx_test num = %5d     **", scb.total_tx_cnt);
        $display("**      pass  tx_test num = %5d     **", scb.pass_tx_data);
        $display("**      fail  tx_test num = %5d     **", scb.fail_tx_data);
        $display("________________________________________");
        $stop;
    endtask
endclass

module tb_uart_loopback_sv ();
    uart_interface uart_if ();
    environment env;

    uart_loopback_sv dut_uart_loopback (
        .clk(uart_if.clk),
        .rst(uart_if.rst),
        .rx(uart_if.rx),
        .tx(uart_if.tx),
        .rx_data(uart_if.rx_data),
        .rx_done(uart_if.rx_done)
    );

    always #5 uart_if.clk = ~uart_if.clk;
    initial begin
        uart_if.clk = 0;
        env = new(uart_if);
        env.run();
    end
endmodule

// task SENDER_UART(input [7:0] send_data);
//         begin
//             // pc tx
//             // start
//             rx = 0;
//             // start bit
//             #(BAUD_PERIOD);
//             //data bit
//             for (i = 0; i < 8; i++) begin
//                 // rx, send_data [0] ~ [7]
//                 rx = send_data[i];
//                 #(BAUD_PERIOD);
//             end
//             rx = 1;
//             #(BAUD_PERIOD);
//         end
// 
//     endtask
