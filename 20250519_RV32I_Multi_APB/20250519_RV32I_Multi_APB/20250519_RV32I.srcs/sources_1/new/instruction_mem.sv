`timescale 1ns / 1ps

module instruction_mem (
    input  logic [31:0] instr_addr,
    output logic [31:0] instr_code
);

    logic [31:0] instr_rom[0:127];
`ifdef TEST_SIMULATION
    initial begin
        instr_rom[0] = 32'h0031_02b3;  // x5 = x2 + x3
        instr_rom[1] = 32'h0041_82b3;  // x5 = x4 + x3
        instr_rom[2] = 32'h0031_2123;  // sw x2, x3, 2 : rs1, rs2, imm
        instr_rom[3] = 32'h0021_2403;  // lw x8, x2, 2 : rd, rs1, imm
        instr_rom[4] = 32'h0043_8413;  // addi x8, x7, 4: rd, rs1, imm
        // BEQ : ex) if true then pc = pc -8
        instr_rom[5] = 32'hFE84_0CE3;   // BEQ x8, x8, -8: rs1, rs2, imm, PC = PC + imm
    end
`endif
    initial begin
        $readmemh("APB_BRAM.mem",instr_rom);
    end

    assign instr_code = instr_rom[instr_addr[31:2]];

endmodule
