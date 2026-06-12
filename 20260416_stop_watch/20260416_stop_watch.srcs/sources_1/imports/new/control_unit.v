`timescale 1ns / 1ps

module control_unit_fsm (
    input            clk,
    input            rst,
    input            btnR,        // runstop    
    input            btnL,        // clear
    input            btnD,        // mode
    input            btnU,        // re-define
    input            sw,
    // stopwatch output
    output reg       o_run_stop,
    output reg       o_clear,
    output           o_mode,
    // watch output
    output reg       o_hour,
    output reg       o_min,
    output reg       o_sec,

    output           o_hour_up,
    output           o_hour_down,
    output           o_min_up,
    output           o_min_down,
    output           o_sec_up,
    output           o_sec_down
);
    // state define
    parameter [2:0] STOP = 0, RUN = 1, CLEAR = 2, MODE = 3,
                    NORMAL = 4, HOUR = 5, MIN = 6, SEC = 7;
    reg [2:0] c_state, n_state;
    reg mode_reg, mode_next;

    // current state register
    assign o_mode = mode_reg;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state  <= NORMAL;
            mode_reg <= 1'b0;  // up count
        end else begin
            c_state  <= n_state;
            mode_reg <= mode_next;  // next CL출력을 받음
        end
    end


    // next, output CL
    always @(*) begin
        // default 처리
        n_state = c_state;
        // stopwatch
        o_run_stop = 1'b0;
        o_clear = 1'b0;
        mode_next = mode_reg;
        // watch
        o_hour  = 1'b0;
        o_min   = 1'b0;
        o_sec   = 1'b0;
        
        case (c_state)
            // stopwatch
            STOP: begin
                o_run_stop = 1'b0;
                o_clear = 1'b0;
                if(sw == 1'b0) begin // priority : switch
                    n_state = NORMAL;
                end else if (btnR) begin
                    n_state = RUN;
                end else if (btnL) begin
                    n_state = CLEAR;
                end else if (btnD) begin
                    n_state = MODE;
                end
            end

            RUN: begin
                o_run_stop = 1'b1; // tick_gen의 if = true -> tick 생성 시작 
                if(sw == 1'b0) begin
                    n_state = NORMAL;
                end else if (btnR) begin
                    n_state = STOP;
                end
            end

            CLEAR: begin
                o_clear = 1'b1;
                n_state = STOP;
                if(sw == 1'b0) begin
                    n_state = NORMAL;
                end
            end

            MODE: begin
                mode_next = ~mode_reg;  // mode feedback 받아서 not 연결
                // omode = ~omode;
                n_state   = STOP;
                if(sw == 1'b0) begin
                    n_state = NORMAL;
                end
            end

            // watch
            NORMAL: begin
                o_hour = 1'b0;
                o_min  = 1'b0;
                o_sec  = 1'b0;
                if(sw == 1'b1) begin
                    n_state = STOP;
                end else if (btnR) begin
                    n_state = HOUR;
                end else if (btnL) begin
                    n_state = SEC;
                end
            end

            HOUR: begin
                o_hour = 1'b1;
                o_min  = 1'b0;
                o_sec  = 1'b0;
                if(sw == 1'b1) begin
                    n_state = STOP;
                end else if (btnR) begin
                    n_state = MIN;
                end else if (btnL) begin
                    n_state = NORMAL;
                end
            end

            MIN: begin
                o_hour = 1'b0;
                o_min  = 1'b1;
                o_sec  = 1'b0;
                if(sw == 1'b1) begin
                    n_state = STOP;
                end else if (btnR) begin
                    n_state = SEC;
                end else if (btnL) begin
                    n_state = HOUR;
                end
            end

            SEC: begin
                o_hour = 1'b0;
                o_min  = 1'b0;
                o_sec  = 1'b1;
                if(sw == 1'b1) begin
                    n_state = STOP;
                end else if (btnR) begin
                    n_state = NORMAL;
                end else if (btnL) begin
                    n_state = MIN;
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
