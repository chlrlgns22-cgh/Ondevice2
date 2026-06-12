`timescale 1ns / 1ps

`include "define.vh"

module control_unit (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] instr_code,
    input  logic        READY,        // from APB Master
    output logic        pc_en,
    output logic        rf_we,
    output logic        branch,
    output logic        jal,
    output logic        jalr,
    output logic        alusrc_sel,
    output logic [ 3:0] alu_control,
    output logic [ 2:0] rfsrc_sel,
    output logic [ 2:0] mem_mode,
    output logic        W_REQ,
    output logic        R_REQ

);
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [6:0] opcode;

    assign funct3 = instr_code[14:12];
    assign funct7 = instr_code[31:25];
    assign opcode = instr_code[6:0];

    // [DEBUG] 
    typedef enum logic [6:0] {
        DBG_R_TYPE  = `R_TYPE,
        DBG_S_TYPE  = `S_TYPE,
        DBG_B_TYPE  = `B_TYPE,
        DBG_IL_TYPE = `IL_TYPE,
        DBG_I_TYPE  = `I_TYPE,
        DBG_UL_TYPE = `UL_TYPE,
        DBG_UA_TYPE = `UA_TYPE,
        DBG_J_TYPE  = `J_TYPE,
        DBG_JL_TYPE = `JL_TYPE
    } opcode_dbg_e;
    opcode_dbg_e opcode_dbg;
    assign opcode_dbg = opcode_dbg_e'(opcode);

    typedef enum logic [3:0] {
        DBG_ADD  = `ADD,
        DBG_SUB  = `SUB,
        DBG_SLL  = `SLL,
        DBG_SLT  = `SLT,
        DBG_SLTU = `SLTU,
        DBG_XOR  = `XOR,
        DBG_SRL  = `SRL,
        DBG_SRA  = `SRA,
        DBG_OR   = `OR,
        DBG_AND  = `AND
    } r_type_dbg_e;
    r_type_dbg_e r_type_dbg;

    typedef enum logic [3:0] {
        DBG_BEQ  = `BEQ,
        DBG_BNE  = `BNE,
        DBG_BLT  = `BLT,
        DBG_BGE  = `BGE,
        DBG_BLTU = `BLTU,
        DBG_BGEU = `BGEU
    } b_type_dbg_e;
    b_type_dbg_e b_type_dbg;
    assign r_type_dbg = r_type_dbg_e'(alu_control);
    assign b_type_dbg = b_type_dbg_e'(alu_control);

    typedef enum logic [2:0] {
        FETCH,
        DECODE,
        EXECUTE,
        MEM,
        WB
    } state_e;

    state_e c_state, n_state;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= FETCH;
        end else begin
            c_state <= n_state;
        end
    end

    // state next
    always_comb begin
        n_state = c_state;
        case (c_state)
            FETCH: begin
                n_state = DECODE;
            end
            DECODE: begin
                n_state = EXECUTE;
            end
            EXECUTE: begin
                case (opcode)
                    `R_TYPE, `I_TYPE, `B_TYPE, `UA_TYPE, `UL_TYPE, `J_TYPE, `JL_TYPE: begin
                        n_state = FETCH;
                    end
                    `S_TYPE, `IL_TYPE: begin
                        n_state = MEM;
                    end
                endcase
            end
            MEM: begin
                if (opcode == `S_TYPE) begin
                    if (READY) begin
                        n_state = FETCH;
                    end
                end else begin
                    n_state = WB;
                end
            end
            WB: begin
                if (READY) begin
                    n_state = FETCH;
                end
            end
        endcase
    end

    always_comb begin
        pc_en       = 0;
        rf_we       = 0;
        branch      = 0;
        jal         = 0;
        jalr        = 0;
        alusrc_sel  = 0;
        alu_control = 0;
        rfsrc_sel   = 3'b0;
        mem_mode    = 3'b0;
        W_REQ       = 0;
        R_REQ       = 0;
        case (c_state)
            FETCH: pc_en = 1;
            EXECUTE: begin
                case (opcode)
                    `R_TYPE: begin
                        rf_we       = 1;
                        alusrc_sel  = 0;
                        rfsrc_sel   = 3'b0;
                        alu_control = {funct7[5], funct3};
                    end
                    `I_TYPE: begin
                        rf_we      = 1;
                        alusrc_sel = 1;
                        rfsrc_sel  = 3'b0;
                        if (funct3 == 3'b101) alu_control = {funct7[5], funct3};
                        else alu_control = {1'b0, funct3};
                    end
                    `B_TYPE: begin
                        branch      = 1;
                        alusrc_sel  = 1'b0;  // RS1 , RS2
                        alu_control = {1'b0, funct3};
                    end
                    `J_TYPE, `JL_TYPE: begin
                        rf_we = 1;
                        jal   = 1;
                        if (opcode == `J_TYPE) begin
                            jalr = 0;
                        end else begin  // JL type
                            jalr = 1;
                        end
                        rfsrc_sel = 3'b100;
                    end
                    `UA_TYPE, `UL_TYPE: begin
                        rf_we = 1'b1;
                        if (opcode == `UL_TYPE) rfsrc_sel = 3'b010;
                        else rfsrc_sel = 3'b011;
                    end
                    `S_TYPE, `IL_TYPE: begin
                        alusrc_sel  = 1'b1;
                        alu_control = `ADD;
                    end
                endcase
            end
            MEM: begin
                mem_mode   = funct3;
                alusrc_sel = 1'b1;
                if (opcode == `S_TYPE) W_REQ = 1'b1;
                else R_REQ = 1'b1;
            end
            WB: begin
                rf_we     = 1'b1;
                rfsrc_sel = 1;  // from data memory
            end
        endcase
    end
    // single cycle
    //
    //    always_comb begin
    //        rf_we       = 0;
    //        branch      = 0;
    //        jal         = 0;
    //        jalr        = 0;
    //        alusrc_sel  = 0;
    //        alu_control = 0;
    //        rfsrc_sel   = 3'b0;
    //        mem_mode    = 3'b0;
    //        dwe         = 0;
    //        case (opcode)
    //            `R_TYPE: begin
    //                rf_we       = 1'b1;
    //                branch      = 0;
    //                jal         = 0;
    //                jalr        = 0;
    //                alusrc_sel  = 0;
    //                alu_control = {funct7[5], funct3};
    //                rfsrc_sel   = 0;
    //                mem_mode    = 3'b0;
    //                dwe         = 0;
    //            end
    //            `S_TYPE: begin
    //                rf_we       = 1'b0;
    //                branch      = 0;
    //                jal         = 0;
    //                jalr        = 0;
    //                alusrc_sel  = 1'b1;
    //                alu_control = `ADD;
    //                rfsrc_sel   = 0;
    //                mem_mode    = funct3;
    //                dwe         = 1'b1;
    //            end
    //            `IL_TYPE: begin
    //                rf_we       = 1'b1;
    //                branch      = 0;
    //                jal         = 0;
    //                jalr        = 0;
    //                alusrc_sel  = 1'b1;  // rs1 + imm
    //                alu_control = `ADD;
    //                rfsrc_sel   = 1;  // from data memory
    //                mem_mode    = funct3;
    //                dwe         = 1'b0;
    //            end
    //            `I_TYPE: begin
    //                rf_we      = 1'b1;
    //                branch     = 0;
    //                jal        = 0;
    //                jalr       = 0;
    //                alusrc_sel = 1'b1;  // rs1 + imm
    //                if (funct3 == 3'b101) alu_control = {funct7[5], funct3};
    //                else alu_control = {1'b0, funct3};
    //                rfsrc_sel = 0;  // alu result 
    //                mem_mode  = 0;
    //                dwe       = 1'b0;
    //            end
    //            `B_TYPE: begin
    //                rf_we       = 1'b0;
    //                branch      = 1;
    //                jal         = 0;
    //                jalr        = 0;
    //                alusrc_sel  = 1'b0;  // RS1 , RS2
    //                alu_control = {1'b0, funct3};
    //                rfsrc_sel   = 0;
    //                mem_mode    = 0;
    //                dwe         = 0;
    //            end
    //            `UL_TYPE, `UA_TYPE: begin
    //                rf_we       = 1'b1;
    //                branch      = 0;
    //                jal         = 0;
    //                jalr        = 0;
    //                alusrc_sel  = 1'b0;  // RS1 , RS2
    //                alu_control = 4'b0;
    //                if (opcode == `UL_TYPE) rfsrc_sel = 3'b010;
    //                else rfsrc_sel = 3'b011;
    //                mem_mode = 0;
    //                dwe      = 0;
    //            end
    //            `J_TYPE, `JL_TYPE: begin
    //                rf_we  = 1'b1;
    //                branch = 0;
    //                jal    = 1;
    //                if (opcode == `J_TYPE) begin
    //                    jalr = 0;
    //                end else begin  // JL type
    //                    jalr = 1;
    //                end
    //                alusrc_sel  = 1'b0;  // RS1 , RS2
    //                alu_control = 4'b0;
    //                rfsrc_sel   = 3'b100;
    //                mem_mode    = 0;
    //                dwe         = 0;
    //            end
    //
    //        endcase
    //    end
endmodule
