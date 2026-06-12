`timescale 1ns / 1ps

class transaction;
    rand bit [7:0] a;  //bit: 2상태 자료형
    rand bit [7:0] b;
    rand bit       mode;  //0=sum ,1=sub
    bit      [7:0] s;
    bit            c;
endclass  //transaction

interface adder_interface ();
    logic [7:0] a;
    logic [7:0] b;
    logic       mode;
    logic [7:0] s;
    logic       c;
endinterface

class generator;
    transaction tr;
    virtual adder_interface adder_vif;

    function new(
        virtual adder_interface adder_vinterf
    );  //new function 이 불릴때 받아주기 위한 argument 이름(중간이름)
        adder_vif = adder_vinterf;
        tr = new;  //generator가 생성될때 tr도 같이 생성
    endfunction

    task run(int repeat_count);
        repeat (repeat_count) begin
            tr.randomize();  //randomize = rand 키워드 변수를 random값 생성 함수
            adder_vif.a = tr.a;
            adder_vif.b = tr.b;
            adder_vif.mode = tr.mode;
            #10;
        end
    endtask


endclass  //generator

module tb_alu ();

    adder_interface adder_if ();
    generator gen;
    adder dut (
        .a   (adder_if.a),
        .b   (adder_if.b),
        .mode(adder_if.mode),  //0= sum/ 1:sub
        .s   (adder_if.s),
        .c   (adder_if.c)
    );

    initial begin
        gen = new(adder_if);
        gen.run(10);
        $stop;
    end
endmodule
