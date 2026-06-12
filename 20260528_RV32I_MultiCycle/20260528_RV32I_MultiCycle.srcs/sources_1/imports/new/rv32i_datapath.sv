`timescale 1ns / 1ps
`include "define.vh"

module datapath (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] instr_code,
    input  logic        rf_we,
    input  logic        branch,
    input  logic        jal,
    input  logic        jalr,
    input  logic        alusrc_sel,
    input  logic [ 3:0] alu_control,
    input  logic [ 2:0] rfsrc_sel,
    input  logic [31:0] drdata,
    input  logic        pc_en,
    output logic [31:0] instr_addr,
    output logic [31:0] daddr,
    output logic [31:0] dwdata

);
    logic [31:0] rs1, rs2, alu_result, wb_out, pc_imm, pc_4;
    logic [31:0] rs1_out, rs2_out, rs2_wdata;
    logic [31:0] alu_result_out, imm_extend_out, drdata_out;
    logic [31:0] imm_extend, alu_rs2_mux;

    assign daddr  = alu_result_out;
    assign dwdata = rs2_wdata;

    //    mux_2x1 U_REG_FILE_SRC_MUX (
    //        .in0    (alu_result),
    //        .in1    (drdata),
    //        .sel    (rfsrc_sel),
    //        .out_mux(rfsrc_mux_out)
    //    );
    register_32bit U_MEM_RS2 (
        .clk(clk),
        .rst(rst),
        .in (drdata),
        .out(drdata_out)
    );

    mux_wb U_WB_MUX (
        .in0   (alu_result),
        .in1   (drdata_out),
        .in2   (imm_extend),
        .in3   (pc_imm),
        .in4   (pc_4),
        .sel   (rfsrc_sel),
        .wb_out(wb_out)
    );

    register_file U_REG_FILE (
        .clk   (clk),
        .raddr1(instr_code[19:15]),
        .raddr2(instr_code[24:20]),
        .rf_we (rf_we),
        .waddr (instr_code[11:7]),
        .wdata (wb_out),
        .rdata1(rs1),
        .rdata2(rs2)
    );

    register_32bit U_DEC_RS1 (
        .clk(clk),
        .rst(rst),
        .in (rs1),
        .out(rs1_out)
    );

    register_32bit U_DEC_RS2 (
        .clk(clk),
        .rst(rst),
        .in (rs2),
        .out(rs2_out)
    );

    alu U_ALU (
        .alu_control(alu_control),
        .rs1        (rs1_out),      // rs 1
        .rs2        (alu_rs2_mux),  // rs 2
        .alu_result (alu_result),   // rd
        .b_taken    (b_taken)
    );

    register_32bit U_EXE_ALU (
        .clk(clk),
        .rst(rst),
        .in (alu_result),
        .out(alu_result_out)
    );

    register_32bit U_EXE_RS2 (
        .clk(clk),
        .rst(rst),
        .in (rs2_out),
        .out(rs2_wdata)
    );

    mux_2x1 U_ALU_MUX_RS2 (
        .in0    (rs2_out),
        .in1    (imm_extend_out),
        .sel    (alusrc_sel),
        .out_mux(alu_rs2_mux)
    );

    imm_extend U_IMM_EXTEND (
        .instr_code(instr_code),
        .imm_extend(imm_extend)
    );

    register_32bit U_DEC_IMM (
        .clk(clk),
        .rst(rst),
        .in (imm_extend),
        .out(imm_extend_out)
    );

    program_counter U_PC (
        .clk       (clk),
        .rst       (rst),
        .b_taken   (b_taken),
        .branch    (branch),
        .jal       (jal),
        .jalr      (jalr),
        .pc_in     (instr_addr),  // for next count
        .rs1       (rs1),
        .imm_extend(imm_extend),
        .pc_en     (pc_en),
        .pc_out    (instr_addr),  // current count
        .pc_imm    (pc_imm),
        .pc_4      (pc_4)
    );


endmodule

module program_counter (
    input         clk,
    input         rst,
    input         b_taken,
    input         branch,
    input         jal,
    input         jalr,
    input  [31:0] pc_in,
    input  [31:0] rs1,
    input  [31:0] imm_extend,
    input         pc_en,
    output [31:0] pc_out,
    output [31:0] pc_imm,
    output [31:0] pc_4
);
    logic [31:0] pc_reg, pc_next, pc_jalr, pc_reg_out;

    assign pc_out = pc_reg_out;
    assign pc_imm = imm_extend + pc_jalr;
    assign pc_4   = pc_in + 32'd4;

    mux_2x1 U_PC_JALR_MUX (
        .in0(pc_in),
        .in1(rs1),
        .sel(jalr),
        .out_mux(pc_jalr)
    );

    mux_2x1 U_PC_SRC_MUX (
        .in0(pc_4),
        .in1(pc_imm),
        .sel((jal | jalr) | (branch & b_taken)),
        .out_mux(pc_next)
    );
    // register
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            pc_reg <= 0;
        end else begin
            if (pc_en) pc_reg_out <= pc_reg;
            else pc_reg_out <= pc_out;
        end
    end

    register_32bit U_EXE_PC_NEXT (
        .clk(clk),
        .rst(rst),
        .in (pc_next),
        .out(pc_reg)
    );

endmodule

module mux_wb (
    input  logic [31:0] in0,
    input  logic [31:0] in1,
    input  logic [31:0] in2,
    input  logic [31:0] in3,
    input  logic [31:0] in4,
    input  logic [ 2:0] sel,
    output logic [31:0] wb_out
);

    always_comb begin
        wb_out = 32'd0;
        case (sel)
            3'b000: wb_out = in0;  //load alu
            3'b001: wb_out = in1;  //load data memory
            3'b010: wb_out = in2;  //load lui : load Upper Imm
            3'b011: wb_out = in3;  //load Add Upper Imm
            3'b100: wb_out = in4;  //load JAL/JALR : PC+4
        endcase
    end

endmodule

module mux_2x1 (
    input  [31:0] in0,
    input  [31:0] in1,
    input         sel,
    output [31:0] out_mux
);

    assign out_mux = (sel) ? in1 : in0;

endmodule

module imm_extend (
    input  logic [31:0] instr_code,
    output logic [31:0] imm_extend
);

    always_comb begin
        imm_extend = 32'd0;
        case (instr_code[6:0])
            `S_TYPE:
            imm_extend = {
                {20{instr_code[31]}}, instr_code[31:25], instr_code[11:7]
            };
            `IL_TYPE, `I_TYPE, `JL_TYPE: begin
                imm_extend = {{20{instr_code[31]}}, instr_code[31:20]};
            end
            `B_TYPE: begin
                imm_extend = {
                    // 12,11,10:5,4:1
                    {20{instr_code[31]}},  // 20
                    instr_code[7],  // 1
                    instr_code[30:25],  // 6
                    instr_code[11:8],  // 4
                    1'b0  // 1
                };
            end
            `UL_TYPE, `UA_TYPE: imm_extend = {instr_code[31:12], 12'h000};
            `J_TYPE: begin
                imm_extend = {
                    // 20, 10:1, 11, 19:12
                    {12{instr_code[31]}},  // 12
                    instr_code[19:12],  // 8
                    instr_code[20],  // 1
                    instr_code[30:21],  // 10
                    1'b0  // 1
                };
            end
        endcase
    end

endmodule

module alu (
    input logic [3:0] alu_control,
    input logic [31:0] rs1,
    input logic [31:0] rs2,
    output logic [31:0] alu_result,
    output logic b_taken
);

    always_comb begin
        alu_result = 0;
        case (alu_control)
            // R-tpye RD = RS1 + Rs2
            // I-type RD = RS1 + IMM(RS2) 
            `ADD:  alu_result = rs1 + rs2;
            `SUB:  alu_result = rs1 - rs2;
            `SLL:  alu_result = rs1 << rs2;
            `SLT:  alu_result = ($signed(rs1) < $signed(rs2)) ? 1 : 0;
            `SLTU: alu_result = (rs1 < rs2) ? 1 : 0;
            `XOR:  alu_result = rs1 ^ rs2;
            `SRL:  alu_result = rs1 >> rs2;
            `SRA:  alu_result = $signed(rs1) >>> rs2[4:0];
            `OR:   alu_result = rs1 | rs2;
            `AND:  alu_result = rs1 & rs2;
        endcase
    end

    //always_comb begin
    //    b_taken = 1'b0;
    //    case (alu_control[2:0])
    //        `BEQ:  b_taken = (rs1 == rs2) ? 1'b1 : 1'b0;
    //        `BNE:  b_taken = (rs1 != rs2) ? 1'b1 : 1'b0;
    //        `BLT:  b_taken = ($signed(rs1) < $signed(rs2)) ? 1'b1 : 1'b0;
    //        `BGE:  b_taken = ($signed(rs1) >= $signed(rs2)) ? 1'b1 : 1'b0;
    //        `BLTU: b_taken = (rs1 < rs2) ? 1'b1 : 1'b0;
    //        `BGEU: b_taken = (rs1 >= rs2) ? 1'b1 : 1'b0;
    //    endcase
    //end
    always_comb begin
        b_taken = 1'b0;
        case (alu_control[2:0])
            `BEQ: begin
                if (rs1 == rs2) b_taken = 1'b1;
                else b_taken = 1'b0;
            end
            `BNE: begin
                if (rs1 != rs2) b_taken = 1'b1;
                else b_taken = 1'b0;
            end
            `BLT: begin
                if ($signed(rs1) < $signed(rs2)) b_taken = 1'b1;
                else b_taken = 1'b0;
            end
            `BGE: begin
                if ($signed(rs1) >= $signed(rs2)) b_taken = 1'b1;
                else b_taken = 1'b0;
            end
            `BLTU: begin
                if (rs1 < rs2) b_taken = 1'b1;
                else b_taken = 1'b0;
            end
            `BGEU: begin
                if (rs1 >= rs2) b_taken = 1'b1;
                else b_taken = 1'b0;
            end
        endcase
    end
endmodule


module register_file (
    input  logic        clk,
    input  logic [ 4:0] raddr1,  // rs1  
    input  logic [ 4:0] raddr2,  // rs2
    input  logic        rf_we,   //register file write enable
    input  logic [ 4:0] waddr,   // rd   
    input  logic [31:0] wdata,   // rd write data
    output logic [31:0] rdata1,  // rs1 read data
    output logic [31:0] rdata2   // rs2 read data
);
    logic [31:0] register_file[1:31];
    //`ifdef TEST_SIMULATION
    integer i = 0;
    initial begin
        for (i = 1; i < 32; i++) register_file[i] = i;
    end
    //`endif
    always_ff @(posedge clk) begin
        if (rf_we) begin
            register_file[waddr] <= wdata;
        end
    end

    assign rdata1 = (raddr1 != 0) ? register_file[raddr1] : 32'h0000_0000;
    assign rdata2 = (raddr2 != 0) ? register_file[raddr2] : 32'h0000_0000;
endmodule

module register_32bit (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] in,
    output logic [31:0] out
);
    logic [31:0] reg_data;
    assign out = reg_data;

    always_ff @(posedge clk, posedge rst) begin : blockName
        if (rst) begin
            reg_data <= 0;
        end else begin
            reg_data <= in;
        end
    end


endmodule
