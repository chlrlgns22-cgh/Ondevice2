`timescale 1ns / 1ps

module fifo_sv (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] push_data,
    input  logic       push,
    input  logic       pop,
    output logic [7:0] pop_data,
    output logic       full,
    output logic       empty
);
    logic [3:0] rptr, wptr;

    reg_file U_REG_FILE (
        .*,
        .wdata(push_data),
        .waddr(wptr),
        .raddr(rptr),
        .we   (~full && push),
        .rdata(pop_data)
    );

    control_unit U_CONTROL_UNIT (
        .*,
        .rst  (rst),
        .push (push),
        .pop  (pop),
        .wptr (wptr),
        .rptr (rptr),
        .full (full),
        .empty(empty)
    );

endmodule

module reg_file (
    input  logic       clk,
    input  logic [7:0] wdata,
    input  logic [3:0] waddr,
    input  logic [3:0] raddr,
    input  logic       we,
    output logic [7:0] rdata
);
    logic [7:0] register_file[0:15];

    always_ff @(posedge clk) begin
        if (we) begin
            register_file[waddr] <= wdata;
        end
    end

    assign rdata = register_file[raddr];
endmodule

module control_unit (
    input        clk,
    input        rst,
    input        push,
    input        pop,
    output [3:0] wptr,
    output [3:0] rptr,
    output       full,
    output       empty
);

    logic [3:0] wptr_reg, wptr_next;
    logic [3:0] rptr_reg, rptr_next;
    logic full_reg, full_next, empty_reg, empty_next;

    assign wptr  = wptr_reg;
    assign rptr  = rptr_reg;
    assign full  = full_reg;
    assign empty = empty_reg;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            wptr_reg  <= 0;
            rptr_reg  <= 0;
            full_reg  <= 1'b0;
            empty_reg <= 1'b1;
        end else begin
            wptr_reg  <= wptr_next;
            rptr_reg  <= rptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
        end
    end


    always_comb begin
        wptr_next  = wptr_reg;
        rptr_next  = rptr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;
        case ({
            pop, push
        })
            2'b01: begin
                if (!full_reg) begin
                    wptr_next  = wptr_reg + 1;
                    empty_next = 0;
                    if (wptr_next == rptr_reg) begin
                        full_next = 1'b1;
                    end
                end
            end
            2'b10: begin
                if (!empty_reg) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 0;
                    if (rptr_next == wptr_reg) begin
                        empty_next = 1'b1;
                    end
                end
            end
            2'b11: begin
                if (full_reg) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                end else if (empty_reg) begin
                    wptr_next  = wptr_reg + 1;
                    empty_next = 1'b0;
                end else begin
                    wptr_next = wptr_reg + 1;
                    rptr_next = rptr_reg + 1;
                end
            end

        endcase


    end
endmodule
