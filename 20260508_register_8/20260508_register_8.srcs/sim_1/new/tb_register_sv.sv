`timescale 1ns / 1ps
class transaction;
    rand bit [7:0] d;
    bit      [7:0] q;

    function debug_print(string name);
        $display("%t : [%s], d =%d, q=%d", $time, name, d, q);
    endfunction
endclass

interface reg_interface;
    logic       clk;
    logic       rst;
    logic [7:0] d;
    logic [7:0] q;

endinterface  //reg_interface

class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event event_gen_next;

    function new(mailbox#(transaction) gen2drv_mbox, event event_gen_next);
        this.gen2drv_mbox   = gen2drv_mbox;
        this.event_gen_next = event_gen_next;
    endfunction

    task run(int count);
        repeat (count) begin
            tr = new();
            tr.randomize();
            tr.debug_print("GEN");
            gen2drv_mbox.put(tr);
            @(event_gen_next);
        end
    endtask
endclass

class driver;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event event_mon_next;
    virtual reg_interface reg_vif;

    function new(mailbox#(transaction) gen2drv_mbox, event event_mon_next,
                 virtual reg_interface reg_vif);
        this.gen2drv_mbox = gen2drv_mbox;
        this.event_mon_next = event_mon_next;
        this.reg_vif = reg_vif;
    endfunction

    task preset;
        reg_vif.rst = 1'b1;
        repeat (2) @(posedge reg_vif.clk);
        reg_vif.rst = 1'b0;
    endtask

    task run();
        forever begin
            @(posedge reg_vif.clk);
            #1;
            gen2drv_mbox.get(tr);
            reg_vif.d = tr.d;
            tr.debug_print("DRV");

            @(negedge reg_vif.clk);
            ->event_mon_next;
        end
    endtask
endclass

class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event event_mon_next;
    virtual reg_interface reg_vif;

    function new(mailbox#(transaction) mon2scb_mbox, event event_mon_next,
                 virtual reg_interface reg_vif);
        this.mon2scb_mbox = mon2scb_mbox;
        this.event_mon_next = event_mon_next;
        this.reg_vif = reg_vif;
    endfunction
    task run();
        forever begin
            @(event_mon_next);
            @(posedge reg_vif.clk);
            tr   = new;
            tr.d = reg_vif.d;
            #1;
            tr.q = reg_vif.q;
            tr.debug_print("MON");
            mon2scb_mbox.put(tr);
        end
    endtask
endclass

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event event_gen_next;

    int total_cnt, pass_cnt, fail_cnt;

    function new(mailbox#(transaction) mon2scb_mbox, event event_gen_next);
        this.mon2scb_mbox   = mon2scb_mbox;
        this.event_gen_next = event_gen_next;
    endfunction

    task run();
        forever begin
            mon2scb_mbox.get(tr);
            tr.debug_print("SCB");
            total_cnt++;
            if (tr.d == tr.q) begin
                $display("%t :PASS!!", $time);
                pass_cnt++;
            end else begin
                $display("%t :FAIL!! d=%d, q=%d", $time, tr.d, tr.q);
                fail_cnt++;
            end
            ->event_gen_next;
        end
    endtask
endclass

class environment;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;

    event event_gen_next;
    event event_mon_next;

    function new(virtual reg_interface reg_vif);
        gen2drv_mbox = new;
        mon2scb_mbox = new;
        gen = new(gen2drv_mbox, event_gen_next);
        drv = new(gen2drv_mbox, event_mon_next, reg_vif);
        mon = new(mon2scb_mbox, event_mon_next, reg_vif);
        scb = new(mon2scb_mbox, event_gen_next);
    endfunction

    task run();
        drv.preset();
        fork
            gen.run(100);
            drv.run();
            mon.run();
            scb.run();
        join_any
        $display("%t : ENV fork join_any end", $time);
        #20;
        $display("_________________________________");
        $display("** Register 8bit Verification **");
        $display("**  total test number= %4d   **", scb.total_cnt);
        $display("**  pass test number=  %4d   **", scb.pass_cnt);
        $display("**  fail test number=  %4d   **", scb.fail_cnt);
        $display("_________________________________");
        $stop;
    endtask

endclass

module tb_register_sv ();
    reg_interface reg_if ();
    environment env;

    register_8 dut (
        .clk(reg_if.clk),
        .rst(reg_if.rst),
        .d  (reg_if.d),
        .q  (reg_if.q)
    );

    always #5 reg_if.clk = ~reg_if.clk;
    initial begin
        reg_if.clk = 0;
        env = new(reg_if);
        env.run();
    end
endmodule
