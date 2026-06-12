`timescale 1ns / 1ps

module ascii_sender (
    input             clk,
    input             rst,
    input             start,
    input      [ 1:0] select,     //select=1 => watch /select= 0 => stopwatch
    input      [31:0] data,
    output     [ 7:0] push_data,
    output reg        push
);

    integer i;
    parameter IDLE = 0, WATCH = 1, STOPWATCH = 2, SR04 = 3, DHT11 = 4;
    reg [2:0] c_state, n_state;
    reg [21:0] bit_cnt_reg, bit_cnt_next;
    reg [7:0] data_reg[20:0], data_reg_next[20:0];
    assign push_data = data_reg_next[bit_cnt_reg];

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state     <= IDLE;
            bit_cnt_reg <= 0;
            for (i = 0; i < 21; i = i + 1) begin
                data_reg[i] <= 8'h00;
            end

        end else begin
            c_state     <= n_state;
            bit_cnt_reg <= bit_cnt_next;
            for (i = 0; i < 21; i = i + 1) data_reg[i] <= data_reg_next[i];
        end
    end


    always @(*) begin
        n_state      = c_state;
        bit_cnt_next = bit_cnt_reg;
        push         = 1'b0;
        for (i = 0; i < 21; i = i + 1) begin
            data_reg_next[i] = data_reg[i];
        end
        case (c_state)
            IDLE: begin
                n_state = IDLE;
                if (select == 2'b00 && start) begin
                    n_state = WATCH;
                    bit_cnt_next = 0;
                end else if (select == 2'b01 && start) begin
                    n_state = STOPWATCH;
                    bit_cnt_next = 0;
                end else if (select == 2'b10 && start) begin
                    n_state = SR04;
                    bit_cnt_next = 0;
                end else if (select == 2'b11 && start) begin
                    n_state = DHT11;
                    bit_cnt_next = 0;
                end
            end
            WATCH: begin
                push = 1'b1;
                if (bit_cnt_reg == 21) begin
                    bit_cnt_next = 0;
                    push = 1'b0;
                    n_state = IDLE;

                end else begin
                    case (bit_cnt_reg)
                        0: data_reg_next[bit_cnt_reg] = 8'h57;  // W
                        1: data_reg_next[bit_cnt_reg] = 8'h41;  // A
                        2: data_reg_next[bit_cnt_reg] = 8'h54;  // T
                        3: data_reg_next[bit_cnt_reg] = 8'h43;  // C
                        4: data_reg_next[bit_cnt_reg] = 8'h48;  // H
                        5: data_reg_next[bit_cnt_reg] = 8'h3A;  // :
                        6:
                        case (data[31:28])  // digit_10 hour
                            4'b0000: data_reg_next[bit_cnt_reg] = 8'h30;  // 0
                            4'b0001: data_reg_next[bit_cnt_reg] = 8'h31;  // 1
                            4'b0010: data_reg_next[bit_cnt_reg] = 8'h32;  // 2
                            4'b0011: data_reg_next[bit_cnt_reg] = 8'h33;  // 3
                            4'b0100: data_reg_next[bit_cnt_reg] = 8'h34;  // 4
                            4'b0101: data_reg_next[bit_cnt_reg] = 8'h35;  // 5
                            4'b0110: data_reg_next[bit_cnt_reg] = 8'h36;  // 6
                            4'b0111: data_reg_next[bit_cnt_reg] = 8'h37;  // 7
                            4'b1000: data_reg_next[bit_cnt_reg] = 8'h38;  // 8
                            4'b1001: data_reg_next[bit_cnt_reg] = 8'h39;  // 9
                        endcase
                        7:
                        case (data[27:24])  // digit_1 hour
                            4'b0000: data_reg_next[bit_cnt_reg] = 8'h30;  // 0
                            4'b0001: data_reg_next[bit_cnt_reg] = 8'h31;  // 1
                            4'b0010: data_reg_next[bit_cnt_reg] = 8'h32;  // 2
                            4'b0011: data_reg_next[bit_cnt_reg] = 8'h33;  // 3
                            4'b0100: data_reg_next[bit_cnt_reg] = 8'h34;  // 4
                            4'b0101: data_reg_next[bit_cnt_reg] = 8'h35;  // 5
                            4'b0110: data_reg_next[bit_cnt_reg] = 8'h36;  // 6
                            4'b0111: data_reg_next[bit_cnt_reg] = 8'h37;  // 7
                            4'b1000: data_reg_next[bit_cnt_reg] = 8'h38;  // 8
                            4'b1001: data_reg_next[bit_cnt_reg] = 8'h39;  // 9
                        endcase
                        8: data_reg_next[bit_cnt_reg] = 8'h3A;  // :
                        9:
                        case (data[23:20])  //digit_10 minute
                            4'b0000: data_reg_next[bit_cnt_reg] = 8'h30;  // 0
                            4'b0001: data_reg_next[bit_cnt_reg] = 8'h31;  // 1
                            4'b0010: data_reg_next[bit_cnt_reg] = 8'h32;  // 2
                            4'b0011: data_reg_next[bit_cnt_reg] = 8'h33;  // 3
                            4'b0100: data_reg_next[bit_cnt_reg] = 8'h34;  // 4
                            4'b0101: data_reg_next[bit_cnt_reg] = 8'h35;  // 5
                            4'b0110: data_reg_next[bit_cnt_reg] = 8'h36;  // 6
                            4'b0111: data_reg_next[bit_cnt_reg] = 8'h37;  // 7
                            4'b1000: data_reg_next[bit_cnt_reg] = 8'h38;  // 8
                            4'b1001: data_reg_next[bit_cnt_reg] = 8'h39;  // 9
                        endcase
                        10:
                        case (data[19:16])  //digit_1 minute
                            4'b0000: data_reg_next[bit_cnt_reg] = 8'h30;  // 0
                            4'b0001: data_reg_next[bit_cnt_reg] = 8'h31;  // 1
                            4'b0010: data_reg_next[bit_cnt_reg] = 8'h32;  // 2
                            4'b0011: data_reg_next[bit_cnt_reg] = 8'h33;  // 3
                            4'b0100: data_reg_next[bit_cnt_reg] = 8'h34;  // 4
                            4'b0101: data_reg_next[bit_cnt_reg] = 8'h35;  // 5
                            4'b0110: data_reg_next[bit_cnt_reg] = 8'h36;  // 6
                            4'b0111: data_reg_next[bit_cnt_reg] = 8'h37;  // 7
                            4'b1000: data_reg_next[bit_cnt_reg] = 8'h38;  // 8
                            4'b1001: data_reg_next[bit_cnt_reg] = 8'h39;  // 9
                        endcase
                        11: data_reg_next[bit_cnt_reg] = 8'h3A;  // :
                        12:
                        case (data[15:12])  // digit_10 sec
                            4'b0000: data_reg_next[bit_cnt_reg] = 8'h30;  // 0
                            4'b0001: data_reg_next[bit_cnt_reg] = 8'h31;  // 1
                            4'b0010: data_reg_next[bit_cnt_reg] = 8'h32;  // 2
                            4'b0011: data_reg_next[bit_cnt_reg] = 8'h33;  // 3
                            4'b0100: data_reg_next[bit_cnt_reg] = 8'h34;  // 4
                            4'b0101: data_reg_next[bit_cnt_reg] = 8'h35;  // 5
                            4'b0110: data_reg_next[bit_cnt_reg] = 8'h36;  // 6
                            4'b0111: data_reg_next[bit_cnt_reg] = 8'h37;  // 7
                            4'b1000: data_reg_next[bit_cnt_reg] = 8'h38;  // 8
                            4'b1001: data_reg_next[bit_cnt_reg] = 8'h39;  // 9
                        endcase
                        13:
                        case (data[11:8])  // digit_1 sec
                            4'b0000: data_reg_next[bit_cnt_reg] = 8'h30;  // 0
                            4'b0001: data_reg_next[bit_cnt_reg] = 8'h31;  // 1
                            4'b0010: data_reg_next[bit_cnt_reg] = 8'h32;  // 2
                            4'b0011: data_reg_next[bit_cnt_reg] = 8'h33;  // 3
                            4'b0100: data_reg_next[bit_cnt_reg] = 8'h34;  // 4
                            4'b0101: data_reg_next[bit_cnt_reg] = 8'h35;  // 5
                            4'b0110: data_reg_next[bit_cnt_reg] = 8'h36;  // 6
                            4'b0111: data_reg_next[bit_cnt_reg] = 8'h37;  // 7
                            4'b1000: data_reg_next[bit_cnt_reg] = 8'h38;  // 8
                            4'b1001: data_reg_next[bit_cnt_reg] = 8'h39;  // 9
                        endcase
                        14: data_reg_next[bit_cnt_reg] = 8'h3A;  // :
                        15:
                        case (data[7:4])  //digit_10 msec
                            4'b0000: data_reg_next[bit_cnt_reg] = 8'h30;  // 0
                            4'b0001: data_reg_next[bit_cnt_reg] = 8'h31;  // 1
                            4'b0010: data_reg_next[bit_cnt_reg] = 8'h32;  // 2
                            4'b0011: data_reg_next[bit_cnt_reg] = 8'h33;  // 3
                            4'b0100: data_reg_next[bit_cnt_reg] = 8'h34;  // 4
                            4'b0101: data_reg_next[bit_cnt_reg] = 8'h35;  // 5
                            4'b0110: data_reg_next[bit_cnt_reg] = 8'h36;  // 6
                            4'b0111: data_reg_next[bit_cnt_reg] = 8'h37;  // 7
                            4'b1000: data_reg_next[bit_cnt_reg] = 8'h38;  // 8
                            4'b1001: data_reg_next[bit_cnt_reg] = 8'h39;  // 9
                        endcase
                        16:
                        case (data[3:0])  //digit_10 msec
                            4'b0000: data_reg_next[bit_cnt_reg] = 8'h30;  // 0
                            4'b0001: data_reg_next[bit_cnt_reg] = 8'h31;  // 1
                            4'b0010: data_reg_next[bit_cnt_reg] = 8'h32;  // 2
                            4'b0011: data_reg_next[bit_cnt_reg] = 8'h33;  // 3
                            4'b0100: data_reg_next[bit_cnt_reg] = 8'h34;  // 4
                            4'b0101: data_reg_next[bit_cnt_reg] = 8'h35;  // 5
                            4'b0110: data_reg_next[bit_cnt_reg] = 8'h36;  // 6
                            4'b0111: data_reg_next[bit_cnt_reg] = 8'h37;  // 7
                            4'b1000: data_reg_next[bit_cnt_reg] = 8'h38;  // 8
                            4'b1001: data_reg_next[bit_cnt_reg] = 8'h39;  // 9
                        endcase
                        17: data_reg_next[bit_cnt_reg] = 8'h00;
                        18: data_reg_next[bit_cnt_reg] = 8'h00;
                        19: data_reg_next[bit_cnt_reg] = 8'h00;
                        20: data_reg_next[bit_cnt_reg] = 8'h00;
                    endcase
                    bit_cnt_next = bit_cnt_reg + 1;
                end
            end
            STOPWATCH: begin
                push = 1'b1;
                if (bit_cnt_reg == 21) begin
                    bit_cnt_next = 0;
                    push = 1'b0;
                    n_state = IDLE;
                end else begin
                    case (bit_cnt_reg)
                        0: data_reg_next[bit_cnt_reg] = 8'h53;  // S
                        1: data_reg_next[bit_cnt_reg] = 8'h54;  // T
                        2: data_reg_next[bit_cnt_reg] = 8'h4F;  // O
                        3: data_reg_next[bit_cnt_reg] = 8'h50;  // P
                        4: data_reg_next[bit_cnt_reg] = 8'h57;  // W
                        5: data_reg_next[bit_cnt_reg] = 8'h41;  // A
                        6: data_reg_next[bit_cnt_reg] = 8'h54;  // T
                        7: data_reg_next[bit_cnt_reg] = 8'h43;  // C
                        8: data_reg_next[bit_cnt_reg] = 8'h48;  // H
                        9: data_reg_next[bit_cnt_reg] = 8'h3A;  // :
                        10:
                        case (data[31:28])  // digit_10 hour
                            4'b0000: data_reg_next[bit_cnt_reg] = 8'h30;  // 0
                            4'b0001: data_reg_next[bit_cnt_reg] = 8'h31;  // 1
                            4'b0010: data_reg_next[bit_cnt_reg] = 8'h32;  // 2
                            4'b0011: data_reg_next[bit_cnt_reg] = 8'h33;  // 3
                            4'b0100: data_reg_next[bit_cnt_reg] = 8'h34;  // 4
                            4'b0101: data_reg_next[bit_cnt_reg] = 8'h35;  // 5
                            4'b0110: data_reg_next[bit_cnt_reg] = 8'h36;  // 6
                            4'b0111: data_reg_next[bit_cnt_reg] = 8'h37;  // 7
                            4'b1000: data_reg_next[bit_cnt_reg] = 8'h38;  // 8
                            4'b1001: data_reg_next[bit_cnt_reg] = 8'h39;  // 9
                        endcase
                        11:
                        case (data[27:24])  // digit_1 hour
                            4'b0000: data_reg_next[bit_cnt_reg] = 8'h30;  // 0
                            4'b0001: data_reg_next[bit_cnt_reg] = 8'h31;  // 1
                            4'b0010: data_reg_next[bit_cnt_reg] = 8'h32;  // 2
                            4'b0011: data_reg_next[bit_cnt_reg] = 8'h33;  // 3
                            4'b0100: data_reg_next[bit_cnt_reg] = 8'h34;  // 4
                            4'b0101: data_reg_next[bit_cnt_reg] = 8'h35;  // 5
                            4'b0110: data_reg_next[bit_cnt_reg] = 8'h36;  // 6
                            4'b0111: data_reg_next[bit_cnt_reg] = 8'h37;  // 7
                            4'b1000: data_reg_next[bit_cnt_reg] = 8'h38;  // 8
                            4'b1001: data_reg_next[bit_cnt_reg] = 8'h39;  // 9
                        endcase
                        12: data_reg_next[bit_cnt_reg] = 8'h3A;  // :
                        13:
                        case (data[23:20])  //digit_10 minute
                            4'b0000: data_reg_next[bit_cnt_reg] = 8'h30;  // 0
                            4'b0001: data_reg_next[bit_cnt_reg] = 8'h31;  // 1
                            4'b0010: data_reg_next[bit_cnt_reg] = 8'h32;  // 2
                            4'b0011: data_reg_next[bit_cnt_reg] = 8'h33;  // 3
                            4'b0100: data_reg_next[bit_cnt_reg] = 8'h34;  // 4
                            4'b0101: data_reg_next[bit_cnt_reg] = 8'h35;  // 5
                            4'b0110: data_reg_next[bit_cnt_reg] = 8'h36;  // 6
                            4'b0111: data_reg_next[bit_cnt_reg] = 8'h37;  // 7
                            4'b1000: data_reg_next[bit_cnt_reg] = 8'h38;  // 8
                            4'b1001: data_reg_next[bit_cnt_reg] = 8'h39;  // 9
                        endcase
                        14:
                        case (data[19:16])  //digit_1 minute
                            4'b0000: data_reg_next[bit_cnt_reg] = 8'h30;  // 0
                            4'b0001: data_reg_next[bit_cnt_reg] = 8'h31;  // 1
                            4'b0010: data_reg_next[bit_cnt_reg] = 8'h32;  // 2
                            4'b0011: data_reg_next[bit_cnt_reg] = 8'h33;  // 3
                            4'b0100: data_reg_next[bit_cnt_reg] = 8'h34;  // 4
                            4'b0101: data_reg_next[bit_cnt_reg] = 8'h35;  // 5
                            4'b0110: data_reg_next[bit_cnt_reg] = 8'h36;  // 6
                            4'b0111: data_reg_next[bit_cnt_reg] = 8'h37;  // 7
                            4'b1000: data_reg_next[bit_cnt_reg] = 8'h38;  // 8
                            4'b1001: data_reg_next[bit_cnt_reg] = 8'h39;  // 9
                        endcase
                        15: data_reg_next[bit_cnt_reg] = 8'h3A;  // :
                        16:
                        case (data[15:12])  // digit_10 sec
                            4'b0000: data_reg_next[bit_cnt_reg] = 8'h30;  // 0
                            4'b0001: data_reg_next[bit_cnt_reg] = 8'h31;  // 1
                            4'b0010: data_reg_next[bit_cnt_reg] = 8'h32;  // 2
                            4'b0011: data_reg_next[bit_cnt_reg] = 8'h33;  // 3
                            4'b0100: data_reg_next[bit_cnt_reg] = 8'h34;  // 4
                            4'b0101: data_reg_next[bit_cnt_reg] = 8'h35;  // 5
                            4'b0110: data_reg_next[bit_cnt_reg] = 8'h36;  // 6
                            4'b0111: data_reg_next[bit_cnt_reg] = 8'h37;  // 7
                            4'b1000: data_reg_next[bit_cnt_reg] = 8'h38;  // 8
                            4'b1001: data_reg_next[bit_cnt_reg] = 8'h39;  // 9
                        endcase
                        17:
                        case (data[11:8])  // digit_1 sec
                            4'b0000: data_reg_next[bit_cnt_reg] = 8'h30;  // 0
                            4'b0001: data_reg_next[bit_cnt_reg] = 8'h31;  // 1
                            4'b0010: data_reg_next[bit_cnt_reg] = 8'h32;  // 2
                            4'b0011: data_reg_next[bit_cnt_reg] = 8'h33;  // 3
                            4'b0100: data_reg_next[bit_cnt_reg] = 8'h34;  // 4
                            4'b0101: data_reg_next[bit_cnt_reg] = 8'h35;  // 5
                            4'b0110: data_reg_next[bit_cnt_reg] = 8'h36;  // 6
                            4'b0111: data_reg_next[bit_cnt_reg] = 8'h37;  // 7
                            4'b1000: data_reg_next[bit_cnt_reg] = 8'h38;  // 8
                            4'b1001: data_reg_next[bit_cnt_reg] = 8'h39;  // 9
                        endcase
                        18: data_reg_next[bit_cnt_reg] = 8'h3A;  // :
                        19:
                        case (data[7:4])  //digit_10 msec
                            4'b0000: data_reg_next[bit_cnt_reg] = 8'h30;  // 0
                            4'b0001: data_reg_next[bit_cnt_reg] = 8'h31;  // 1
                            4'b0010: data_reg_next[bit_cnt_reg] = 8'h32;  // 2
                            4'b0011: data_reg_next[bit_cnt_reg] = 8'h33;  // 3
                            4'b0100: data_reg_next[bit_cnt_reg] = 8'h34;  // 4
                            4'b0101: data_reg_next[bit_cnt_reg] = 8'h35;  // 5
                            4'b0110: data_reg_next[bit_cnt_reg] = 8'h36;  // 6
                            4'b0111: data_reg_next[bit_cnt_reg] = 8'h37;  // 7
                            4'b1000: data_reg_next[bit_cnt_reg] = 8'h38;  // 8
                            4'b1001: data_reg_next[bit_cnt_reg] = 8'h39;  // 9
                        endcase
                        20:
                        case (data[3:0])  //digit_10 msec
                            4'b0000: data_reg_next[bit_cnt_reg] = 8'h30;  // 0
                            4'b0001: data_reg_next[bit_cnt_reg] = 8'h31;  // 1
                            4'b0010: data_reg_next[bit_cnt_reg] = 8'h32;  // 2
                            4'b0011: data_reg_next[bit_cnt_reg] = 8'h33;  // 3
                            4'b0100: data_reg_next[bit_cnt_reg] = 8'h34;  // 4
                            4'b0101: data_reg_next[bit_cnt_reg] = 8'h35;  // 5
                            4'b0110: data_reg_next[bit_cnt_reg] = 8'h36;  // 6
                            4'b0111: data_reg_next[bit_cnt_reg] = 8'h37;  // 7
                            4'b1000: data_reg_next[bit_cnt_reg] = 8'h38;  // 8
                            4'b1001: data_reg_next[bit_cnt_reg] = 8'h39;  // 9
                        endcase
                    endcase
                    bit_cnt_next = bit_cnt_reg + 1;
                end
            end
            SR04: begin
                push = 1'b1;
                if (bit_cnt_reg == 21) begin
                    bit_cnt_next = 0;
                    push = 1'b0;
                    n_state = IDLE;
                end else begin
                    case (bit_cnt_reg)
                        0: data_reg_next[bit_cnt_reg] = 8'h44;  // D
                        1: data_reg_next[bit_cnt_reg] = 8'h49;  // I
                        2: data_reg_next[bit_cnt_reg] = 8'h53;  // S
                        3: data_reg_next[bit_cnt_reg] = 8'h54;  // T
                        4: data_reg_next[bit_cnt_reg] = 8'h41;  // A
                        5: data_reg_next[bit_cnt_reg] = 8'h4e;  // N
                        6: data_reg_next[bit_cnt_reg] = 8'h43;  // C
                        7: data_reg_next[bit_cnt_reg] = 8'h45;  // E
                        8: data_reg_next[bit_cnt_reg] = 8'h3A;  // :
                        9:
                        case (data[11:8])  // digit_1 sec
                            4'b0000: data_reg_next[bit_cnt_reg] = 8'h30;  // 0
                            4'b0001: data_reg_next[bit_cnt_reg] = 8'h31;  // 1
                            4'b0010: data_reg_next[bit_cnt_reg] = 8'h32;  // 2
                            4'b0011: data_reg_next[bit_cnt_reg] = 8'h33;  // 3
                            4'b0100: data_reg_next[bit_cnt_reg] = 8'h34;  // 4
                            4'b0101: data_reg_next[bit_cnt_reg] = 8'h35;  // 5
                            4'b0110: data_reg_next[bit_cnt_reg] = 8'h36;  // 6
                            4'b0111: data_reg_next[bit_cnt_reg] = 8'h37;  // 7
                            4'b1000: data_reg_next[bit_cnt_reg] = 8'h38;  // 8
                            4'b1001: data_reg_next[bit_cnt_reg] = 8'h39;  // 9
                        endcase
                        10:
                        case (data[7:4])  //digit_10 msec
                            4'b0000: data_reg_next[bit_cnt_reg] = 8'h30;  // 0
                            4'b0001: data_reg_next[bit_cnt_reg] = 8'h31;  // 1
                            4'b0010: data_reg_next[bit_cnt_reg] = 8'h32;  // 2
                            4'b0011: data_reg_next[bit_cnt_reg] = 8'h33;  // 3
                            4'b0100: data_reg_next[bit_cnt_reg] = 8'h34;  // 4
                            4'b0101: data_reg_next[bit_cnt_reg] = 8'h35;  // 5
                            4'b0110: data_reg_next[bit_cnt_reg] = 8'h36;  // 6
                            4'b0111: data_reg_next[bit_cnt_reg] = 8'h37;  // 7
                            4'b1000: data_reg_next[bit_cnt_reg] = 8'h38;  // 8
                            4'b1001: data_reg_next[bit_cnt_reg] = 8'h39;  // 9
                        endcase
                        11:
                        case (data[3:0])  //digit_10 msec
                            4'b0000: data_reg_next[bit_cnt_reg] = 8'h30;  // 0
                            4'b0001: data_reg_next[bit_cnt_reg] = 8'h31;  // 1
                            4'b0010: data_reg_next[bit_cnt_reg] = 8'h32;  // 2
                            4'b0011: data_reg_next[bit_cnt_reg] = 8'h33;  // 3
                            4'b0100: data_reg_next[bit_cnt_reg] = 8'h34;  // 4
                            4'b0101: data_reg_next[bit_cnt_reg] = 8'h35;  // 5
                            4'b0110: data_reg_next[bit_cnt_reg] = 8'h36;  // 6
                            4'b0111: data_reg_next[bit_cnt_reg] = 8'h37;  // 7
                            4'b1000: data_reg_next[bit_cnt_reg] = 8'h38;  // 8
                            4'b1001: data_reg_next[bit_cnt_reg] = 8'h39;  // 9
                        endcase
                        12: data_reg_next[bit_cnt_reg] = 8'h00;  // null
                        13: data_reg_next[bit_cnt_reg] = 8'h00;  // null
                        14: data_reg_next[bit_cnt_reg] = 8'h00;  // null
                        15: data_reg_next[bit_cnt_reg] = 8'h00;  // null
                        16: data_reg_next[bit_cnt_reg] = 8'h00;  // null
                        17: data_reg_next[bit_cnt_reg] = 8'h00;  // null
                        18: data_reg_next[bit_cnt_reg] = 8'h00;  // null
                        19: data_reg_next[bit_cnt_reg] = 8'h00;  // null
                        20: data_reg_next[bit_cnt_reg] = 8'h00;  // null
                    endcase
                    bit_cnt_next = bit_cnt_reg + 1;
                end
            end
            DHT11: begin
                push = 1'b1;
                if (bit_cnt_reg == 21) begin
                    bit_cnt_next = 0;
                    push = 1'b0;
                    n_state = IDLE;
                end else begin
                    case (bit_cnt_reg)
                        0: data_reg_next[bit_cnt_reg] = 8'h74;  // T
                        1: data_reg_next[bit_cnt_reg] = 8'h65;  // E
                        2: data_reg_next[bit_cnt_reg] = 8'h6d;  // M
                        3: data_reg_next[bit_cnt_reg] = 8'h70;  // P
                        4: data_reg_next[bit_cnt_reg] = 8'h2f;  // /
                        5: data_reg_next[bit_cnt_reg] = 8'h68;  // H
                        6: data_reg_next[bit_cnt_reg] = 8'h75;  // U
                        7: data_reg_next[bit_cnt_reg] = 8'h6d;  // M
                        8: data_reg_next[bit_cnt_reg] = 8'h69;  // I
                        9: data_reg_next[bit_cnt_reg] = 8'h64;  // D
                        10: data_reg_next[bit_cnt_reg] = 8'h69;  // I
                        11: data_reg_next[bit_cnt_reg] = 8'h74;  // T
                        12: data_reg_next[bit_cnt_reg] = 8'h79;  // Y
                        13: data_reg_next[bit_cnt_reg] = 8'h3A;  // :
                        14:
                        case (data[15:12])  // digit_10 temp
                            4'b0000: data_reg_next[bit_cnt_reg] = 8'h30;  // 0
                            4'b0001: data_reg_next[bit_cnt_reg] = 8'h31;  // 1
                            4'b0010: data_reg_next[bit_cnt_reg] = 8'h32;  // 2
                            4'b0011: data_reg_next[bit_cnt_reg] = 8'h33;  // 3
                            4'b0100: data_reg_next[bit_cnt_reg] = 8'h34;  // 4
                            4'b0101: data_reg_next[bit_cnt_reg] = 8'h35;  // 5
                            4'b0110: data_reg_next[bit_cnt_reg] = 8'h36;  // 6
                            4'b0111: data_reg_next[bit_cnt_reg] = 8'h37;  // 7
                            4'b1000: data_reg_next[bit_cnt_reg] = 8'h38;  // 8
                            4'b1001: data_reg_next[bit_cnt_reg] = 8'h39;  // 9
                        endcase
                        15:
                        case (data[11:8])  // digit_1 temp
                            4'b0000: data_reg_next[bit_cnt_reg] = 8'h30;  // 0
                            4'b0001: data_reg_next[bit_cnt_reg] = 8'h31;  // 1
                            4'b0010: data_reg_next[bit_cnt_reg] = 8'h32;  // 2
                            4'b0011: data_reg_next[bit_cnt_reg] = 8'h33;  // 3
                            4'b0100: data_reg_next[bit_cnt_reg] = 8'h34;  // 4
                            4'b0101: data_reg_next[bit_cnt_reg] = 8'h35;  // 5
                            4'b0110: data_reg_next[bit_cnt_reg] = 8'h36;  // 6
                            4'b0111: data_reg_next[bit_cnt_reg] = 8'h37;  // 7
                            4'b1000: data_reg_next[bit_cnt_reg] = 8'h38;  // 8
                            4'b1001: data_reg_next[bit_cnt_reg] = 8'h39;  // 9
                        endcase
                        16: data_reg_next[bit_cnt_reg] = 8'h2f;  // /
                        17:
                        case (data[7:4])  // digit_10 humidity
                            4'b0000: data_reg_next[bit_cnt_reg] = 8'h30;  // 0
                            4'b0001: data_reg_next[bit_cnt_reg] = 8'h31;  // 1
                            4'b0010: data_reg_next[bit_cnt_reg] = 8'h32;  // 2
                            4'b0011: data_reg_next[bit_cnt_reg] = 8'h33;  // 3
                            4'b0100: data_reg_next[bit_cnt_reg] = 8'h34;  // 4
                            4'b0101: data_reg_next[bit_cnt_reg] = 8'h35;  // 5
                            4'b0110: data_reg_next[bit_cnt_reg] = 8'h36;  // 6
                            4'b0111: data_reg_next[bit_cnt_reg] = 8'h37;  // 7
                            4'b1000: data_reg_next[bit_cnt_reg] = 8'h38;  // 8
                            4'b1001: data_reg_next[bit_cnt_reg] = 8'h39;  // 9
                        endcase
                        18:
                        case (data[3:0])  // digit_1 humidity
                            4'b0000: data_reg_next[bit_cnt_reg] = 8'h30;  // 0
                            4'b0001: data_reg_next[bit_cnt_reg] = 8'h31;  // 1
                            4'b0010: data_reg_next[bit_cnt_reg] = 8'h32;  // 2
                            4'b0011: data_reg_next[bit_cnt_reg] = 8'h33;  // 3
                            4'b0100: data_reg_next[bit_cnt_reg] = 8'h34;  // 4
                            4'b0101: data_reg_next[bit_cnt_reg] = 8'h35;  // 5
                            4'b0110: data_reg_next[bit_cnt_reg] = 8'h36;  // 6
                            4'b0111: data_reg_next[bit_cnt_reg] = 8'h37;  // 7
                            4'b1000: data_reg_next[bit_cnt_reg] = 8'h38;  // 8
                            4'b1001: data_reg_next[bit_cnt_reg] = 8'h39;  // 9
                        endcase
                        19: data_reg_next[bit_cnt_reg] = 8'h00;  // null
                        20: data_reg_next[bit_cnt_reg] = 8'h00;  // null
                    endcase
                    bit_cnt_next = bit_cnt_reg + 1;
                end
            end
        endcase
    end

endmodule

