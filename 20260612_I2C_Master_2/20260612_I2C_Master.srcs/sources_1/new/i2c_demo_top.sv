`timescale 1ns / 1ps

module i2c_demo_top (
    input  logic       clk,
    input  logic       rst,
    input  logic       sw,
    input  logic       btnR,
    output logic       scl,
    inout  wire        sda,
    output logic [3:0] fnd_com,
    output logic [7:0] fnd_data
);
    localparam SLA_R = {7'h12, 1'b1};

    typedef enum logic [3:0] {
        IDLE,
        START_CMD,
        START_WAIT,
        ADDR_CMD,
        ADDR_WAIT,
        READ_CMD,
        READ_WAIT,
        LATCH_DATA,
        STOP_CMD,
        STOP_WAIT
    } i2c_state_e;

    i2c_state_e state;

    logic cmd_start;
    logic cmd_write;
    logic cmd_read;
    logic cmd_stop;
    logic [7:0] tx_data;
    logic [7:0] rx_data;
    logic ack_in;
    logic ack_out;
    logic busy;
    logic done;

    logic [1:0] read_index;
    logic [4:0] hour;
    logic [5:0] min;
    logic [5:0] sec;
    logic [6:0] msec;
    logic unused_led;

    logic read_start;

    button_debounce U_BTNR (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnR),
        .o_btn(read_start)
    );

    i2c_master_top U_I2C_MASTER (
        .clk      (clk),
        .rst      (rst),
        .cmd_start(cmd_start),
        .cmd_write(cmd_write),
        .cmd_read (cmd_read),
        .cmd_stop (cmd_stop),
        .tx_data  (tx_data),
        .rx_data  (rx_data),
        .ack_in   (ack_in),
        .ack_out  (ack_out),
        .busy     (busy),
        .done     (done),
        .scl      (scl),
        .sda      (sda)
    );

    fnd_controller U_MASTER_FND (
        .clk     (clk),
        .rst     (rst),
        .sw      (sw),
        .msec    (msec),
        .sec     (sec),
        .min     (min),
        .hour    (hour),
        .h       (1'b0),
        .m       (1'b0),
        .s       (1'b0),
        .fnd_com (fnd_com),
        .fnd_data(fnd_data),
        .led     (unused_led)
    );

    always_comb begin
        cmd_start = 1'b0;
        cmd_write = 1'b0;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        tx_data   = SLA_R;
        ack_in    = (read_index == 2'd3);

        case (state)
            START_CMD: cmd_start = 1'b1;
            ADDR_CMD:  cmd_write = 1'b1;
            READ_CMD:  cmd_read = 1'b1;
            STOP_CMD:  cmd_stop = 1'b1;
            default: ;
        endcase
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state      <= IDLE;
            read_index <= 2'd0;
            hour       <= 5'd0;
            min        <= 6'd0;
            sec        <= 6'd0;
            msec       <= 7'd0;
        end else begin
            case (state)
                IDLE: begin
                    if (read_start) begin
                        read_index <= 2'd0;
                        state      <= START_CMD;
                    end
                end

                START_CMD: state <= START_WAIT;
                START_WAIT: begin
                    if (done) state <= ADDR_CMD;
                end

                ADDR_CMD: state <= ADDR_WAIT;
                ADDR_WAIT: begin
                    if (done) state <= READ_CMD;
                end

                READ_CMD: state <= READ_WAIT;
                READ_WAIT: begin
                    if (done) state <= LATCH_DATA;
                end

                LATCH_DATA: begin
                    case (read_index)
                        2'd0: hour <= rx_data[4:0];
                        2'd1: min  <= rx_data[5:0];
                        2'd2: sec  <= rx_data[5:0];
                        2'd3: msec <= rx_data[6:0];
                        default: ;
                    endcase

                    if (read_index == 2'd3) begin
                        state <= STOP_CMD;
                    end else begin
                        read_index <= read_index + 1'b1;
                        state      <= READ_CMD;
                    end
                end

                STOP_CMD: state <= STOP_WAIT;
                STOP_WAIT: begin
                    if (done) state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
