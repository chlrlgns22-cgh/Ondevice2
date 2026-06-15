`timescale 1ns / 1ps

module i2c_demo_counter (
    input  logic clk,
    input  logic reset,
    input  logic sw,
    output logic scl,
    output logic sda
);
    typedef enum logic [2:0] {
        IDLE  = 0,
        START,
        ADDR,
        WRITE,
        STOP
    } i2c_state_e;

    i2c_state_e state;
    localparam SLA_W = {7'h12, 1'b0};


    // command port
    logic       cmd_start;
    logic       cmd_write;
    logic       cmd_read;
    logic       cmd_stop;
    // internal port
    logic [7:0] tx_data;
    logic [7:0] rx_data;
    logic       ack_in;  // read 시 master가 보낼 ACK(0)/NACK(1)
    logic       ack_out;  // write 시 slave로부터 받은 ACK(0)/NACK(1)
    logic       busy;
    logic       done;

    logic [1:0] dff;
    logic       sw_r;
    logic [7:0] counter;

    assign sw_r = dff[1];


    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            dff <= 0;
        end
        dff <= sw;
        dff[1] <= dff[0];
    end


    I2C_Master_top U_I2C_Master (
        .clk(clk),
        .reset(reset),
        // command port
        .cmd_start(cmd_start),
        .cmd_write(cmd_write),
        .cmd_read(cmd_read),
        .cmd_stop(cmd_stop),
        // internal port
        .tx_data(tx_data),
        .rx_data(rx_data),
        .ack_in(ack_in),  // read 시 master가 보낼 ACK(0)/NACK(1)
        .ack_out(ack_out),  // write 시 slave로부터 받은 ACK(0)/NACK(1)
        .busy(busy),
        .done(done),
        // external i2c port
        .scl(scl),
        .sda(sda)
    );

    always_ff @(posedge clk, posedge reset) begin : blockName
        if (reset) begin
            state     <= IDLE;
            counter   <= 0;
            cmd_start <= 1'b0;
            cmd_write <= 1'b0;
            cmd_read  <= 1'b0;
            cmd_stop  <= 1'b0;
            tx_data   <= 0;
        end else begin
            case (state)
                IDLE: begin
                    cmd_start <= 1'b0;
                    cmd_write <= 1'b0;
                    cmd_read  <= 1'b0;
                    cmd_stop  <= 1'b0;
                    if (sw_r) begin
                        state <= START;
                    end
                end
                START: begin
                    cmd_start <= 1'b1;
                    cmd_write <= 1'b0;
                    cmd_read  <= 1'b0;
                    cmd_stop  <= 1'b0;
                    if (done) begin
                        state <= ADDR;
                    end
                end
                ADDR: begin
                    cmd_start <= 1'b0;
                    cmd_write <= 1'b1;
                    cmd_read  <= 1'b0;
                    cmd_stop  <= 1'b0;
                    tx_data   <= SLA_W;
                    if (done) begin
                        state <= WRITE;
                    end
                end
                WRITE: begin
                    cmd_start <= 1'b0;
                    cmd_write <= 1'b1;
                    cmd_read  <= 1'b0;
                    cmd_stop  <= 1'b0;
                    tx_data   <= counter;
                    if (done) begin
                        state <= STOP;
                    end
                end
                STOP: begin
                    cmd_start <= 1'b0;
                    cmd_write <= 1'b0;
                    cmd_read  <= 1'b0;
                    cmd_stop  <= 1'b1;
                    tx_data   <= counter;
                    if (done) begin
                        state   <= IDLE;
                        counter <= counter + 1;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
