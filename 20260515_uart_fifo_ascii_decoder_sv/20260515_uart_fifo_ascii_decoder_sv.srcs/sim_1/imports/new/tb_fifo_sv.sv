`timescale 1ns / 1ps

class transaction_fifo;
    rand bit [7:0] push_data;
    rand bit       push;
    rand bit       pop;
    bit      [7:0] pop_data;
    bit            full;
    bit            empty;

    constraint push_pop {
        push dist {
            1 := 75,
            0 := 25
        };
        pop dist {
            1 := 50,
            0 := 50
        };
    }


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


class generator_fifo;
    transaction_fifo tr;
    mailbox #(transaction_fifo) gen2drv_mbox;
    event event_gen_next;

    function new(mailbox#(transaction_fifo) gen2drv_mbox, event event_gen_next);
        this.gen2drv_mbox   = gen2drv_mbox;
        this.event_gen_next = event_gen_next;
    endfunction

    task run(int count);
        repeat (count) begin
            tr = new;
            tr.randomize();
            gen2drv_mbox.put(tr);
            tr.debug_print("GEN");
            @(event_gen_next);
        end
    endtask
endclass

class driver_fifo;
    transaction_fifo tr;
    mailbox #(transaction_fifo) gen2drv_mbox;
    event event_gen_next;
    virtual fifo_interface fifo_vif;

    function new(mailbox#(transaction_fifo) gen2drv_mbox, event event_gen_next,
                 virtual fifo_interface fifo_vif);
        this.gen2drv_mbox = gen2drv_mbox;
        this.event_gen_next = event_gen_next;
        this.fifo_vif = fifo_vif;
    endfunction

    task preset();
        fifo_vif.rst       = 1;
        fifo_vif.push_data = 0;
        fifo_vif.push      = 0;
        fifo_vif.pop       = 0;

        repeat (2) @(posedge fifo_vif.clk);
        fifo_vif.rst = 0;

        @(negedge fifo_vif.clk);
        //assertion check full, empty
        assert (fifo_vif.empty) $display("[DRV Assert] reset pass : empty!");
        else $display("[DRV Assert] reset fail : empty = %d", fifo_vif.empty);

        assert (!fifo_vif.full) $display("[DRV Assert] reset pass : full!");
        else $display("[DRV Assert] reset fail : full = %d", fifo_vif.full);
    endtask

    task push_only(int count);
        $display("%t : fifo push only test", $time);
        repeat (count) begin
            gen2drv_mbox.get(tr);
            @(posedge fifo_vif.clk);
            #1;
            fifo_vif.push      = 1;
            fifo_vif.push_data = tr.push_data;
            fifo_vif.pop       = 0;
            $display(
                "%t : [DRV] push = %d, pop = %d, push_data = %d, pop_data = %d, full = %d, empty = %d",
                $time, fifo_vif.push, fifo_vif.pop, fifo_vif.push_data,
                fifo_vif.pop_data, fifo_vif.full, fifo_vif.empty);
            ->event_gen_next;
        end
    endtask

    task pop_only(int count);
        $display("%t : fifo pop only test", $time);
        repeat (count) begin
            gen2drv_mbox.get(tr);
            @(posedge fifo_vif.clk);
            #1;
            fifo_vif.push = 0;
            fifo_vif.pop  = 1;
            $display(
                "%t : [DRV] push = %d, pop = %d, push_data = %d, pop_data = %d, full = %d, empty = %d",
                $time, fifo_vif.push, fifo_vif.pop, fifo_vif.push_data,
                fifo_vif.pop_data, fifo_vif.full, fifo_vif.empty);
            ->event_gen_next;
        end
    endtask

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            tr.debug_print("DRV");
            @(posedge fifo_vif.clk);
            #1;
            fifo_vif.push      = tr.push;
            fifo_vif.push_data = tr.push_data;
            fifo_vif.pop       = tr.pop;
        end
    endtask

endclass

class monitor_fifo;
    transaction_fifo tr;
    mailbox #(transaction_fifo) mon2scb_mbox;
    virtual fifo_interface fifo_vif;

    function new(mailbox#(transaction_fifo) mon2scb_mbox,
                 virtual fifo_interface fifo_vif);
        this.mon2scb_mbox = mon2scb_mbox;
        this.fifo_vif = fifo_vif;
    endfunction
    task run();
        forever begin
            @(negedge fifo_vif.clk);
            tr           = new;
            tr.push      = fifo_vif.push;
            tr.push_data = fifo_vif.push_data;
            tr.pop       = fifo_vif.pop;
            tr.pop_data  = fifo_vif.pop_data;
            tr.full      = fifo_vif.full;
            tr.empty     = fifo_vif.empty;
            mon2scb_mbox.put(tr);
            tr.debug_print("MON");
        end
    endtask
endclass

class scoreboard_fifo;
    transaction_fifo tr;
    mailbox #(transaction_fifo) mon2scb_mbox;
    event event_gen_next;
    bit [7:0] fifo_queue[$:16];
    bit [7:0] compare_data;
    int total_cnt, pass_cnt, fail_cnt;
    function new(mailbox#(transaction_fifo) mon2scb_mbox, event event_gen_next);
        this.mon2scb_mbox   = mon2scb_mbox;
        this.event_gen_next = event_gen_next;
    endfunction

    task run();
        $display("fifo Constraint random test");
        forever begin
            mon2scb_mbox.get(tr);
            tr.debug_print("SCB");
            total_cnt++;
            if (tr.push && (!tr.full)) begin
                fifo_queue.push_front(tr.push_data);
            end
            if (tr.pop && (!tr.empty)) begin
                // pass / fail decision
                compare_data = fifo_queue.pop_back();
                if (tr.pop_data == compare_data) begin
                    $display(
                        "%t : PASS!! pop = %d, empty = %d, pop_data = %d, compare_data = %d",
                        $time, tr.pop, tr.empty, tr.pop_data, compare_data);
                    pass_cnt++;
                end else begin
                    fail_cnt++;
                    $display("%t : FAIL pop = %d, pop_data = %d, empty =%d",
                             $time, tr.pop, tr.pop_data, tr.empty);
                end
            end
            ->event_gen_next;

        end
    endtask
endclass

class environment_fifo;
    generator_fifo              gen;
    driver_fifo                 drv;
    monitor_fifo                mon;
    scoreboard_fifo             scb;
    mailbox #(transaction_fifo) gen2drv_mbox;
    mailbox #(transaction_fifo) mon2scb_mbox;
    event                  event_gen_next;
    virtual fifo_interface fifo_vif;
    int                    run_count;

    function new(virtual fifo_interface fifo_vif);
        gen2drv_mbox = new;
        mon2scb_mbox = new;

        gen = new(gen2drv_mbox, event_gen_next);
        drv = new(gen2drv_mbox, event_gen_next, fifo_vif);
        mon = new(mon2scb_mbox, fifo_vif);
        scb = new(mon2scb_mbox, event_gen_next);

        this.fifo_vif = fifo_vif;
    endfunction

    task run();
        // reset test by fifo assertion
        drv.preset();
        //push only test for full signal "1"

        run_count = 16;
        fork
            gen.run(run_count);
            drv.push_only(run_count);
        join
        $display("[ENV] push only test end");
        #10;
        $display(
                "%t : [DRV] push = %d, pop = %d, push_data = %d, pop_data = %d, full = %d, empty = %d",
                $time, fifo_vif.push, fifo_vif.pop, fifo_vif.push_data,
                fifo_vif.pop_data, fifo_vif.full, fifo_vif.empty);
        if (fifo_vif.full) $display("PASS : push only test");
        else $display("FAIL : push only test");
        #10;
        fork
            gen.run(run_count);
            drv.pop_only(run_count);
        join
        $display("[ENV] pop only test end");
        #10;
        $display(
                "%t : [DRV] push = %d, pop = %d, push_data = %d, pop_data = %d, full = %d, empty = %d",
                $time, fifo_vif.push, fifo_vif.pop, fifo_vif.push_data,
                fifo_vif.pop_data, fifo_vif.full, fifo_vif.empty);
        if (fifo_vif.empty) $display("PASS : pop only test");
        else $display("FAIL : pop only test");
        #10;
        fork
            gen.run(100);
            drv.run();
            mon.run();
            scb.run();
        join_any
        #5;
        $display("fifo Constraint random test end");
        $display("________________________________________");
        $display("fifo Constraint random test Verification");
        $display("**       TOTAL test num = %5d       **", scb.total_cnt);
        $display("**       pass  test num = %5d       **", scb.pass_cnt);
        $display("**       fail  test num = %5d       **", scb.fail_cnt);
        $display("________________________________________");
        $stop;
    endtask
endclass

module tb_fifo_sv ();
    fifo_interface fifo_if ();
    environment_fifo env;

    fifo_sv dut_fifo_sv (
        .clk      (fifo_if.clk),
        .rst      (fifo_if.rst),
        .push_data(fifo_if.push_data),
        .push     (fifo_if.push),
        .pop      (fifo_if.pop),
        .pop_data (fifo_if.pop_data),
        .full     (fifo_if.full),
        .empty    (fifo_if.empty)
    );

    always #5 fifo_if.clk = ~fifo_if.clk;
    initial begin
        fifo_if.clk = 0;
        env = new(fifo_if);
        env.run();
    end
endmodule
