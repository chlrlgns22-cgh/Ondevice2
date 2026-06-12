`timescale 1ns / 1ps

`include "define.vh"

module control_unit (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] instr_code,
    output logic        rf_we,
    output logic        branch,
    output logic        jal,
    output logic        jalr,
    output logic        alusrc_sel,
    output logic [ 3:0] alu_control,
    output logic [ 2:0] rfsrc_sel,
    output logic [ 2:0] mem_mode,
    output logic        dwe,
    output logic        pc_en
);
    logic [6:0] funct7;
    logic [2:0] funct3;
    logic [6:0] opcode;

    assign funct3 = instr_code[14:12];
    assign funct7 = instr_code[31:25];
    assign opcode = instr_code[6:0];

    // [DEBUG]
    typedef enum logic [6:0] {
        DBG_R_TYPE  = `R_TYPE,
        DBG_S_TYPE  = `S_TYPE,
        DBG_IL_TYPE = `IL_TYPE,
        DBG_I_TYPE  = `I_TYPE,
        DBG_B_TYPE  = `B_TYPE,
        DBG_UL_TYPE = `UL_TYPE,
        DBG_UA_TYPE = `UA_TYPE,
        DBG_J_TYPE  = `J_TYPE,
        DBG_JL_TYPE = `JL_TYPE
    } opcode_dbg_e;
    opcode_dbg_e opcode_dbg;
    assign opcode_dbg = opcode_dbg_e'(opcode);

    parameter FETCH = 1, DECODE = 2, EXCUTE = 3, MEM = 4, WB = 5;
    logic [2:0] c_state, n_state;

    always_ff @(posedge clk, posedge rst) begin : blockName
        if (rst) begin
            c_state     <= FETCH;
            rf_we       <= 1'b0;
            branch      <= 1'b0;
            jal         <= 1'b0;
            jalr        <= 1'b0;
            alusrc_sel  <= 1'b0;
            alu_control <= 0;
            rfsrc_sel   <= 3'b0;
            mem_mode    <= 3'b0;
            dwe         <= 1'b0;
        end else begin
            c_state <= n_state;
        end
    end

    always_comb begin
        pc_en       = 0;
        n_state     = c_state;
        rf_we       = 1'b0;
        branch      = 1'b0;
        jal         = 1'b0;
        jalr        = 1'b0;
        alusrc_sel  = 1'b0;
        alu_control = 0;
        rfsrc_sel   = 3'b0;
        mem_mode    = 3'b0;
        dwe         = 1'b0;
        case (c_state)
            FETCH: begin
                pc_en   = 1;
                n_state = DECODE;
            end
            DECODE: begin
                pc_en   = 0;
                n_state = EXCUTE;
            end
            EXCUTE: begin
                case (opcode)
                    `R_TYPE: begin
                        branch      = 0;
                        jal         = 0;
                        jalr        = 0;
                        alusrc_sel  = 0;
                        alu_control = {funct7[5], funct3};
                        rfsrc_sel   = 0;
                        n_state     = FETCH;
                    end
                    `S_TYPE: begin
                        branch      = 0;
                        jal         = 0;
                        jalr        = 0;
                        alusrc_sel  = 1'b1;
                        alu_control = `ADD;
                        rfsrc_sel   = 0;
                        n_state     = MEM;
                    end
                    `IL_TYPE: begin
                        branch      = 0;
                        jal         = 0;
                        jalr        = 0;
                        alusrc_sel  = 1'b1;  //rs1 + imm
                        alu_control = `ADD;
                        n_state     = MEM;
                    end
                    `I_TYPE: begin
                        branch     = 0;
                        jal        = 0;
                        jalr       = 0;
                        alusrc_sel = 1'b1;  //rs1 + imm
                        if (funct3 == 3'b101) begin
                            alu_control = {funct7[5], funct3};
                        end else begin
                            alu_control = {1'b0, funct3};
                        end
                        rfsrc_sel = 0;  //alu result
                        n_state   = FETCH;
                    end
                    `B_TYPE: begin
                        branch      = 1;
                        jal         = 0;
                        jalr        = 0;
                        alusrc_sel  = 0;
                        alu_control = {1'b0, funct3};
                        rfsrc_sel   = 0;
                        n_state     = FETCH;
                    end
                    `UL_TYPE, `UA_TYPE: begin
                        branch      = 0;
                        jal         = 0;
                        jalr        = 0;
                        alusrc_sel  = 1'b0;
                        alu_control = 4'b0;
                        if (opcode == `UL_TYPE) rfsrc_sel = 3'b010;
                        else rfsrc_sel = 3'b011;
                        n_state = FETCH;
                    end
                    `J_TYPE, `JL_TYPE: begin
                        branch = 0;
                        jal    = 1;
                        if (opcode == `J_TYPE) jalr = 0;
                        else jalr = 1;
                        alusrc_sel  = 1'b0;
                        alu_control = 4'b0;
                        rfsrc_sel   = 3'b100;
                        n_state     = FETCH;
                    end
                endcase
            end
            MEM: begin
                case (opcode)
                    `S_TYPE: begin
                        mem_mode = funct3;
                        dwe      = 1'b1;
                        n_state  = FETCH;
                    end
                    `IL_TYPE: begin
                        mem_mode = funct3;
                        dwe      = 0;
                        n_state  = WB;
                    end
                endcase
            end
            WB: begin
                rf_we = 1'b1;
                rfsrc_sel = 1;
                n_state = FETCH;
            end
        endcase
    end
endmodule
