`timescale 1ns / 1ps

module ov7670_setup (
    input  logic       clk,
    input  logic       rst,
    input  logic       ack_out,
    input  logic       busy,
    input  logic       done,
    output logic       cmd_start,
    output logic       cmd_write,
    output logic       cmd_read,
    output logic       cmd_stop,
    output logic [7:0] tx_data,
    output logic       ack_in
);

    typedef enum logic [2:0] {
        IDLE = 3'b000,
        START,
        DEVADDR,
        REGADDR,
        DATA,
        STOP
    } setup_state_e;

    setup_state_e state;

    localparam logic [15:0] rom[0:59] = '{
        16'h1280,  // SW Reset
        16'h3A04,
        16'h1200,
        16'h13E7,
        16'h6F9F,
        16'hB084,
        16'h703A,
        16'h7135,
        16'h7211,
        16'h73F0,
        16'h7B10,
        16'h7C1E,
        16'h7D35,
        16'h7E5A,
        16'h7F69,
        16'h8180,
        16'h8288,
        16'h838F,
        16'h8496,
        16'h85A3,
        16'h86AF,
        16'h87C4,
        16'h88D7,
        16'h89E8,
        16'h0000,
        16'h1000,
        16'h0D40,
        16'h1418,
        16'hA505,
        16'hAB07,
        16'h2495,
        16'h2533,
        16'h26E3,
        16'h9F78,
        16'hA068,
        16'hA103,
        16'hA6D8,
        16'hA7D8,
        16'hA8F0,
        16'hA990,
        16'hAA94,
        16'h1211,  // QVGA
        16'h0C04,
        16'h3E19,
        16'h703A,
        16'h7135,
        16'h7211,
        16'h73F1,
        16'hA202,
        16'h1715,
        16'h1803,
        16'h3200,
        16'h1903,
        16'h1A7B,
        16'h0300,
        16'h1214,  // RGB565 COM7
        16'h4010,  // RGB565 COM15
        16'h13E7,  // AEC + AGC
        16'h5587,  // Brightness
        16'hFFFF  // 종료
    };

    logic [7:0] tx_data_reg;
    logic       cmd_start_reg;
    logic       cmd_write_reg;
    logic       cmd_read_reg;
    logic       cmd_stop_reg;
    logic [7:0] cur_addr;
    logic [7:0] cur_data;
    logic [5:0] rom_idx;

    assign tx_data   = tx_data_reg;
    assign cmd_start = cmd_start_reg;
    assign cmd_write = cmd_write_reg;
    assign cmd_read  = cmd_read_reg;
    assign cmd_stop  = cmd_stop_reg;
    assign ack_in    = 1'b1;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= IDLE;
            cmd_start_reg <= 0;
            cmd_write_reg <= 0;
            cmd_read_reg <= 0;
            cmd_stop_reg <= 0;
            tx_data_reg <= 0;
            rom_idx <= 0;
            cur_addr <= 0;
            cur_data <= 0;
        end else begin
            cmd_start_reg <= 0;
            cmd_write_reg <= 0;
            cmd_read_reg  <= 0;
            cmd_stop_reg  <= 0;
            tx_data_reg   <= 0;
            case (state)
                IDLE: begin
                    state <= START;
                    cur_addr <= rom[rom_idx][15:8];
                    cur_data <= rom[rom_idx][7:0];
                end
                START: begin
                    cmd_start_reg <= 1;
                    if (done) state <= DEVADDR;
                    tx_data_reg <= 8'h42;
                end
                DEVADDR: begin
                    if (done) state <= REGADDR;
                    tx_data_reg   <= cur_addr;
                    cmd_write_reg <= 1;
                end
                REGADDR: begin
                    if (done) state <= DATA;
                    tx_data_reg   <= cur_data;
                    cmd_write_reg <= 1;
                end
                DATA: begin
                    if (done) begin
                        state <= STOP;
                        cmd_write_reg <= 0;
                    end else cmd_write_reg <= 1;
                end
                STOP: begin
                    cmd_stop_reg <= 1;
                    if (cmd_stop_reg && !busy) begin
                        if (cur_addr == 8'hff) begin
                            state <= STOP;
                        end else begin
                            rom_idx <= rom_idx + 1;
                            state   <= IDLE;
                        end
                    end
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
