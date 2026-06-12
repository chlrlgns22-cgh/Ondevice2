`timescale 1ns / 1ps

//module tb_fork_join ();
//
//    initial begin
//        #1 $display("%t : start fork - join", $time);
//
//        fork
//            //task A
//            #10 A_thread();
//            fork
//                //task B
//                #20 B_thread();
//                #50 B_thread();
//            join
//            //task C
//            #30 C_thread();
//        join_any
//        #10 $display("%t : end fork - join", $time);
//    end
//
//    task A_thread();
//        $display("%t : A thread", $time);
//    endtask
//
//
//    task B_thread();
//        $display("%t : B thread", $time);
//    endtask
//
//
//    task C_thread();
//        $display("%t : C thread", $time);
//    endtask
//endmodule


module tb_fork_join ();

    initial begin
        #1 $display("%t : start fork - join", $time);

        fork
            //task A
            A_thread();
            fork
                //task B
                B_thread();
            join
            //task C
            C_thread();
        join_any
        #10 $display("%t : end fork - join", $time);
        disable fork;
        $stop;
    end

    task A_thread();
        repeat (5) $display("%t : A thread", $time);
    endtask


    task B_thread();
        forever begin
            $display("%t : B thread", $time);
            #5;
        end
    endtask


    task C_thread();
        forever begin
            $display("%t : C thread", $time);
            #10;
        end
    endtask
endmodule
