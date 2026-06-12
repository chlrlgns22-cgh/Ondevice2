`timescale 1ns / 1ps
interface ram_intf (
    input logic clk
);
    logic       we;
    logic [7:0] addr;
    logic [7:0] wdata;
    logic [7:0] rdata;
endinterface  //ram_intf

class transcation;
    rand logic [7:0] addr;
    rand logic [7:0] data;
    logic      [7:0] rdata;
endclass  //transcation

class tester;
    transcation tr;
    virtual ram_intf ram_if;
    function new(virtual ram_intf ram_if);
        this.ram_if = ram_if;
        tr = new();
    endfunction  //new()

    task write();
        ram_if.we    = 1'b1;
        ram_if.addr  = tr.addr;
        ram_if.wdata = tr.data;
        @(posedge ram_if.clk);
        $display("we: %0h, addr: %0h, rdata: %0h", ram_if.we, ram_if.addr,
                 ram_if.rdata);
    endtask  //write

    task read();
        ram_if.we   = 1'b0;
        ram_if.addr = tr.addr;
        @(posedge ram_if.clk);
        tr.rdata = ram_if.rdata;
        $display("we: %0h, addr: %0h, rdata: %0h", ram_if.we, ram_if.addr,
                 ram_if.rdata);
    endtask

    virtual function result(); // virtual을 붙히면 자식 class 에서 재정의 가능 재정의: 이름이 동일한데 기능을 변환
        if (tr.data != tr.rdata) begin
            $display("     Fail! wdata:%0h != rdata:%0h", tr.data, tr.rdata);
        end else begin
            $display("     Pass! wdata:%0h == rdata:%0h", tr.data, tr.rdata);
        end

    endfunction

    virtual task test_run(int loop);
        repeat (loop) begin
            tr.randomize();
            write();
            read();
            result();
        end
    endtask

endclass  //ram_test

class tester_child extends tester;
    int pass, fail;

    function new(virtual ram_intf ram_if);
        super.new(ram_if);
        pass = 0;
        fail = 0;
    endfunction  //new()

    virtual function result();
        if (tr.data != tr.rdata) begin
            $display("     Fail! wdata:%0h != rdata:%0h", tr.data, tr.rdata);
            fail++;
        end else begin
            $display("Pass! wdata:%0h == rdata:%0h", tr.data, tr.rdata);
            pass++;
        end
    endfunction

    function report;
        $display("total test count : %0d", pass + fail);
        $display("fail count : %0d", fail);
        $display("pass count : %0d", pass);
    endfunction

    virtual task test_run(int loop);
        repeat (loop) begin
            tr.randomize();
            write();
            read();
            result();
        end
        report();
    endtask
endclass  //tester_child extends superClass

module tb_ram ();

    logic clk;
    ram_intf ram_if (clk);

    tester_child IU;

    ram ram_dut (
        .clk  (ram_if.clk),
        .we   (ram_if.we),
        .addr (ram_if.addr),
        .wdata(ram_if.wdata),
        .rdata(ram_if.rdata)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        IU  = new(ram_if);
        repeat (5) @(posedge clk);
       
        IU.test_run(1000);

        repeat (5) @(posedge clk);
        $stop;
    end
endmodule
