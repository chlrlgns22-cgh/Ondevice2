`timescale 1ns / 1ps

module dedicated_cpu_counter (
    input        clk,
    input        rst,
    output [7:0] out
);

    logic w_eq9, w_asrc_sel, w_areg_load, w_out_sel;

    datapath U_DATAPATH (
        .clk(clk),
        .rst(rst),
        .asrc_sel(w_asrc_sel),
        .areg_load(w_areg_load),
        .out_sel(w_out_sel),
        .eq9(w_eq9),
        .out(out)
    );

    control_unit U_CONTROL_UNIT (
        .clk(clk),
        .rst(rst),
        .eq9(w_eq9),
        .asrc_sel(w_asrc_sel),
        .areg_load(w_areg_load),
        .out_sel(w_out_sel)
    );
endmodule

module datapath (
    input              clk,
    input              rst,
    input              asrc_sel,
    input              areg_load,
    input              out_sel,
    output             eq9,
    output logic [7:0] out
);

    logic [7:0] mux_out, reg_out, alu_result;
    assign out = (out_sel) ? reg_out : 8'h00;

    mux_2x1 U_MUX_2x1 (
        .in0(8'h00),
        .in1(alu_result),
        .sel(asrc_sel),
        .mux_out(mux_out)
    );

    a_reg U_A_REG (
        .clk(clk),
        .rst(rst),
        .load(areg_load),
        .data_in(mux_out),
        .data_out(reg_out)
    );

    alu U_ALU (
        .a(reg_out),
        .b(8'h01),
        .alu_result(alu_result)
    );

    comp_eq9 U_COMP_EQ9 (
        .in     (reg_out),
        .compare(8'h09),
        .eq_9   (eq9)
    );
endmodule

module control_unit (
    input        clk,
    input        rst,
    input        eq9,
    output logic asrc_sel,
    output logic areg_load,
    output logic out_sel
);

    typedef enum {
        S0 = 0,
        S1,
        S2
    } state_t;
    state_t n_state, c_state;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= S0;
        end else begin
            c_state <= n_state;
        end
    end

    always_comb begin
        n_state = c_state;
        case (c_state)
            S0: begin
                n_state   = S1;
                asrc_sel  = 0;
                areg_load = 1;
                out_sel   = 0;
            end
            S1: begin
                if (eq9) begin
                    n_state = S2;
                    asrc_sel  = 0;
                    areg_load = 0;
                    out_sel   = 0;
                end else begin
                asrc_sel  = 1;
                areg_load = 1;
                out_sel   = 0;
                end
            end
            S2: begin
                out_sel   = 0;
                areg_load = 0;
                out_sel   = 1;
            end
        endcase
    end

endmodule

module mux_2x1 (
    input        [7:0] in0,
    input        [7:0] in1,
    input              sel,
    output logic [7:0] mux_out
);
    always_comb begin
        if (sel) begin
            mux_out = in1;
        end else mux_out = in0;
    end
endmodule

module comp_eq9 (
    input  [7:0] in,
    input  [7:0] compare,
    output       eq_9
);

    assign eq_9 = (in == compare);
endmodule

module alu (
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] alu_result
);

    assign alu_result = a + b;

endmodule

module a_reg (
    input  logic       clk,
    input  logic       rst,
    input  logic       load,
    input  logic [7:0] data_in,
    output logic [7:0] data_out
);

    logic [7:0] data_reg;

    assign data_out = data_reg;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            data_reg <= 8'h00;
        end else begin
            if (load) begin
                data_reg <= data_in;
            end
        end
    end


endmodule
