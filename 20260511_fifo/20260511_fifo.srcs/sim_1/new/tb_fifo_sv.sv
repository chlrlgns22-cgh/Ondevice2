`timescale 1ns / 1ps

class transaction;
    rand bit [7:0] push_data;
    rand bit       push;
    rand bit       pop;
    bit      [7:0] pop_data;
    bit            full;
    bit            empty;

    function debug_print(string name);
        begin
            $display(
                "%t : [%s] push = %d, pop = %d, push_data = %d, pop_data= %d, full=%d, empty=%d ",
                $time, name, push, pop, push_data, pop_data, full, empty);
        end
    endfunction
endclass

interface fifo_interface;
    logic       clk;
    logic       rst;
    logic [7:0] push_data;
    logic       push;
    logic       pop;
    logic [7:0] pop_data;
    logic       full;
    logic       empty;
endinterface


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
            tr = new;
            tr.randomize();
            gen2drv_mbox.put(tr);
            @(event_gen_next);
        end
    endtask
endclass

class driver;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual fifo_interface fifo_vif;

    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual fifo_interface fifo_vif);
        this.gen2drv_mbox = gen2drv_mbox;
        this.fifo_vif = fifo_vif;
    endfunction

    task preset();
        fifo_vif.rst = 1;
        repeat (2) @(posedge fifo_vif.clk);
        fifo_vif.rst = 0;

        @(negedge fifo_vif.clk);
        //assertion check full, empty
        assert (fifo_vif.empty) $display("[DRV Assert] reset pass : empty!");
        else $display("[DRV Assert] reset fail : empty = %d", fifo_vif.empty);

        assert (!fifo_vif.full) $display("[DRV Assert] reset pass : full!");
        else $display("[DRV Assert] reset fail : full = %d", fifo_vif.full);

    endtask

  //  task push_only();
  //      $display("fifo push only test");
  //      repeat (20) begin
  //          gen.run(1);
  //          gen2drv_mbox.get(tr);
  //          @(posedge fifo_vif.clk);
  //          #1;
  //          fifo_vif.push = 1;
  //          fifo_vif.push_data = tr.push_data;
  //          fifo_vif.pop = 0;
  //      end
  //  endtask

endclass

class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual fifo_interface fifo_vif;

    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual fifo_interface fifo_vif);
        this.mon2scb_mbox = mon2scb_mbox;
        this.fifo_vif = fifo_vif;
    endfunction
endclass

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event event_gen_next;
    int total_cnt = 0, pass_cnt = 0, fail_cnt = 0;

    byte mem[256];

    function new(mailbox#(transaction) mon2scb_mbox, event event_gen_next);
        this.mon2scb_mbox   = mon2scb_mbox;
        this.event_gen_next = event_gen_next;
    endfunction

endclass

class environment;
    generator              gen;
    driver                 drv;
    monitor                mon;
    scoreboard             scb;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    event                  event_gen_next;


    function new(virtual fifo_interface fifo_vif);
        gen2drv_mbox = new;
        mon2scb_mbox = new;

        gen = new(gen2drv_mbox, event_gen_next);
        drv = new(gen2drv_mbox, fifo_vif);
        mon = new(mon2scb_mbox, fifo_vif);
        scb = new(mon2scb_mbox, event_gen_next);
    endfunction

    task run();
        // fifo interface preset
        drv.preset();
        #20;
        $stop;
    endtask
endclass

module tb_fifo_sv ();
    fifo_interface fifo_if ();
    environment env;
    fifo_sv dut (
        .clk(fifo_if.clk),
        .rst(fifo_if.rst),
        .push_data(fifo_if.push_data),
        .push(fifo_if.push),
        .pop(fifo_if.pop),
        .pop_data(fifo_if.pop_data),
        .full(fifo_if.full),
        .empty(fifo_if.empty)
    );

    always #5 fifo_if.clk = ~fifo_if.clk;
    initial begin
        fifo_if.clk = 0;
        env = new(fifo_if);
        env.run();
    end
endmodule
