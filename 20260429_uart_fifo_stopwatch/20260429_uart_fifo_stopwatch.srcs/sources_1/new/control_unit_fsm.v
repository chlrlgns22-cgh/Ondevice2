`timescale 1ns / 1ps

module control_unit_fsm (
    input clk,
    input rst,
    input btnR,  // runstop
    input btnL,  // clear
    input btnD,  // mode
    input btnU,  // re-define
    input [1:0] sw,  // sw[3],sw[1] 00:stopwatch 01:watch 10: sr04 11:dht11
    input uart_R,  //uart_input       
    input uart_L,  //uart_input
    input uart_U,  //uart_input
    input uart_D,  //uart_input
    input uart_M,  //uart_input
    output reg o_run_stop,  // stopwatch output
    output reg o_clear,
    output o_mode,
    output reg o_record,
    output o_view,
    output reg o_hour,  // watch output
    output reg o_min,
    output reg o_sec,
    output o_hour_up,
    output o_hour_down,
    output o_min_up,
    output o_min_down,
    output o_sec_up,
    output o_sec_down,
    output reg sr04_start,  //sr04_input   
    output reg dht11_start,  //dht11_input
    output [1:0] select
);
    // state define
    parameter [3:0] STOPWATCH = 0, RUNSTOP = 1, CLEAR = 2, MODE = 3,
                    WATCH = 4, HOUR = 5, MIN = 6, SEC = 7, SR04=8, DHT11=9;
    reg [3:0] c_state, n_state;
    reg mode_reg, mode_next, view_reg, view_next, run_stop_next;

    // current state register
    assign o_mode = mode_reg;
    assign o_view = view_reg;
    assign select = sw;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state    <= WATCH;
            mode_reg   <= 1'b0;  // up count
            view_reg   <= 1'b0;  // non view
            o_run_stop <= 1'b0;
        end else begin
            c_state    <= n_state;
            mode_reg   <= mode_next;  // next CL출력을 받음
            view_reg   <= view_next;
            o_run_stop <= run_stop_next;
        end
    end


    // next, output CL
    always @(*) begin
        // default 처리
        n_state = c_state;
        // stopwatch
        run_stop_next = o_run_stop;
        o_clear = 1'b0;
        o_record = 1'b0;
        view_next = view_reg;
        mode_next = mode_reg;
        // watch
        o_hour = 1'b0;
        o_min = 1'b0;
        o_sec = 1'b0;
        sr04_start = 1'b0;
        dht11_start = 1'b0;


        case (c_state)
            // stopwatch
            STOPWATCH: begin
                o_clear = 1'b0;
                if (sw == 2'b11) begin
                    n_state = DHT11;
                end else if (sw == 2'b00) begin  // priority : switch
                    n_state = WATCH;
                end else if (btnR || uart_R) begin
                    run_stop_next = 1'b1;
                    n_state = RUNSTOP;
                end else if (btnL || uart_L) begin
                    n_state = CLEAR;
                end else if (btnD || uart_D) begin
                    n_state = MODE;
                end else if (btnU || uart_U) begin
                    view_next = ~view_reg;  // mealy output
                    n_state   = STOPWATCH;
                end
            end

            RUNSTOP: begin
                if (sw == 2'b11) begin
                    n_state = DHT11;
                end else if (sw == 2'b00) begin
                    n_state = WATCH;
                end else if (btnR || uart_R) begin
                    run_stop_next = 1'b0;
                    n_state = STOPWATCH;
                end else if (btnD || uart_D) begin
                    o_record = 1'b1;  // mealy output
                    n_state  = RUNSTOP;
                end else if (btnU || uart_U) begin
                    view_next = ~view_reg;
                    n_state   = RUNSTOP;
                end
            end

            CLEAR: begin
                o_clear = 1'b1;
                n_state = STOPWATCH;
                if (sw == 1'b0) begin
                    n_state = WATCH;
                end
            end

            MODE: begin
                mode_next = ~mode_reg;  // mode feedback 받아서 not 연결
                // omode = ~omode;
                n_state   = STOPWATCH;
                if (sw == 1'b0) begin
                    n_state = WATCH;
                end
            end

            // watch
            WATCH: begin
                o_hour = 1'b0;
                o_min  = 1'b0;
                o_sec  = 1'b0;
                if (sw == 2'b10) begin
                    n_state = SR04;
                end else if (sw == 2'b01) begin
                    n_state = STOPWATCH;
                end else if (btnR || uart_R) begin
                    n_state = HOUR;
                end else if (btnL || uart_L) begin
                    n_state = SEC;
                end
            end

            HOUR: begin
                o_hour = 1'b1;
                o_min  = 1'b0;
                o_sec  = 1'b0;
                if (sw == 2'b10) begin
                    n_state = SR04;
                end else if (sw == 2'b01) begin
                    n_state = STOPWATCH;
                end else if (btnR || uart_R) begin
                    n_state = MIN;
                end else if (btnL || uart_L) begin
                    n_state = WATCH;
                end
            end

            MIN: begin
                o_hour = 1'b0;
                o_min  = 1'b1;
                o_sec  = 1'b0;
                if (sw == 2'b10) begin
                    n_state = SR04;
                end else if (sw == 2'b01) begin
                    n_state = STOPWATCH;
                end else if (btnR || uart_R) begin
                    n_state = SEC;
                end else if (btnL || uart_L) begin
                    n_state = HOUR;
                end
            end

            SEC: begin
                o_hour = 1'b0;
                o_min  = 1'b0;
                o_sec  = 1'b1;
                if (sw == 2'b10) begin
                    n_state = SR04;
                end else if (sw == 2'b01) begin
                    n_state = STOPWATCH;
                end else if (btnR || uart_R) begin
                    n_state = WATCH;
                end else if (btnL || uart_L) begin
                    n_state = MIN;
                end
            end
            SR04: begin
                sr04_start = 1'b1;
                if (sw == 2'b11) begin
                    n_state = DHT11;
                    sr04_start = 1'b0;
                end else if (sw == 2'b00) begin
                    n_state = WATCH;
                    sr04_start = 1'b0;
                end
            end
            DHT11: begin
                dht11_start = 1'b1;
                if (sw == 2'b10) begin
                    n_state = SR04;
                    dht11_start = 1'b0;
                end else if (sw == 2'b01) begin
                    n_state = STOPWATCH;
                    dht11_start = 1'b0;
                end
            end
        endcase
    end

    // watch ctrl sig
    assign o_hour_up   = (o_hour & btnU);
    assign o_hour_down = (o_hour & btnD);
    assign o_min_up    = (o_min  & btnU);
    assign o_min_down  = (o_min  & btnD);
    assign o_sec_up    = (o_sec  & btnU);
    assign o_sec_down  = (o_sec  & btnD);


endmodule
