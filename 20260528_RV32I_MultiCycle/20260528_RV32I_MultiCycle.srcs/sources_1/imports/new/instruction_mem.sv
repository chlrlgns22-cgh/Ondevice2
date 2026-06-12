`timescale 1ns / 1ps

module instruction_mem (
    input  [31:0] instr_addr,
    output [31:0] instr_code
);

    logic [31:0] instr_rom[0:63];
    initial begin
        //// R-type simulation
        //    instr_rom[1]  = 32'h002082B3;  // add  x5,  x1,  x2
        //    instr_rom[2]  = 32'h40328333;  // sub  x6,  x5,  x3
        //    instr_rom[3]  = 32'h0033F3B3;  // and  x7,  x7,  x3
        //    instr_rom[4]  = 32'h00346433;  // or   x8,  x8,  x3
        //    instr_rom[5]  = 32'h0034C4B3;  // xor  x9,  x9,  x3
        //    instr_rom[6]  = 32'h01F41533;  // sll  x10, x8,  x31
        //    instr_rom[7]  = 32'h01E4D5B3;  // srl  x11, x9,  x30
        //    instr_rom[8]  = 32'h41E55633;  // sra  x12, x10, x30
        //    instr_rom[9]  = 32'h0041A6B3;  // slt  x13, x3,  x4
        //    instr_rom[10] = 32'h00323733;  // sltu x14, x4,  x3

        //// I-type simulation
        //instr_rom[1] = 32'hFFF08293;  // addi x5,  x1, -1
        //instr_rom[2] = 32'h00F17313;  // andi x6,  x2, 15
        //instr_rom[3] = 32'h00F16393;  // ori  x7,  x2, 15
        //instr_rom[4] = 32'h0FF44413;  // xori x8,  x8, 255
        //instr_rom[5] = 32'h0051A493;  // slti x9,  x3, 5
        //// 1 << 31 = 0x80000000
        //instr_rom[6] = 32'h01F09513;  // slli x10, x1, 31
        //// 0x80000000 >> 30 = 0x00000002
        //instr_rom[7] = 32'h01E55593;  // srli x11, x10, 30
        //// 0x80000000 >>> 30 = 0xFFFFFFFE
        //instr_rom[8] = 32'h41E55613;  // srai x12, x10, 30

        //// base
        //instr_rom[0] = 32'h01000193; // addi x3,x0,16
        //// data
        //instr_rom[1]  = 32'hFFF00593;  // addi x11,x0,-1
        //instr_rom[2]  = 32'h00010637;  // lui x12,0x10
        //instr_rom[3]  = 32'hFFF60613;  // addi x12,x12,-1
        //// store
        //instr_rom[4]  = 32'h00B18023;  // sb x11,0(x3)
        //instr_rom[5]  = 32'h00C19223;  // sh x12,4(x3)
        //instr_rom[6]  = 32'h00B1A423;  // sw x11,8(x3)
        //// load
        //instr_rom[7]  = 32'h00018403;  // lb  x8,0(x3)
        //instr_rom[8]  = 32'h0001C483;  // lbu x9,0(x3)
        //instr_rom[9]  = 32'h00419503;  // lh  x10,4(x3)
        //instr_rom[10] = 32'h0041D583;  // lhu x11,4(x3)
        //instr_rom[11] = 32'h0081A603;  // lw  x12,8(x3)

        //// B-type
        // beq
        instr_rom[0]  = 32'h00108463;  // beq  x1,x1,+8   taken
        instr_rom[2]  = 32'h00208463;  // beq  x1,x2,+   not taken

        // bne
        instr_rom[3]  = 32'h00209463;  // bne  x1,x2,+8   taken
        instr_rom[5]  = 32'h00109463;  // bne  x1,x1,+4   not taken

        // blt
        instr_rom[6]  = 32'h0020C463;  // blt  x1,x2,+8   taken
        instr_rom[8]  = 32'h0010C463;  // blt  x2,x1,+4   not taken

        // bge
        instr_rom[9]  = 32'h00115463;  // bge  x2,x1,+8   taken
        instr_rom[11] = 32'h0020D463;  // bge x1,x2,+4 not taken

        // bltu
        instr_rom[12] = 32'h0020E463;  // bltu x1,x2,+8   taken
        instr_rom[14] = 32'h0010E463;  // bltu x2,x1,+4   not taken

        // bgeu
        instr_rom[15] = 32'h00117463;  // bgeu x2,x1,+8   taken
        instr_rom[17] = 32'h00217463;  // bgeu x1,x2,+4   not taken
        //// U-TYPE
        //instr_rom[0] = 32'h123452B7;  // lui   x5, 0x12345
        //instr_rom[1] = 32'h00001317;  // auipc x6, 0x00001

        // J-type
        //instr_rom[0] = 32'h008000EF;  // jal  x1, +8
        //instr_rom[2] = 32'h00000013;  // nop
        //instr_rom[3] = 32'h00000013;  // nop
        //instr_rom[4] = 32'h00020267;  // jalr x4, 0(x4)
    end


    // `ifdef TEST_SIMULATION
    //initial begin
    //    instr_rom[0] = 32'h0031_02b3;  // x5  = x2 +  x3
    //    instr_rom[1] = 32'h0041_82b3;  // x5  = x4 +  x3 
    //    instr_rom[2] = 32'h0031_2123;  // sw x2, x3, 2 : rs1, rs2, imm
    //    instr_rom[3] = 32'h0021_2403;  // lw x8, x2, 2 : rd, rs1, imm
    //    instr_rom[4] = 32'h0043_8431;  // addi x8, x7, 4
    //    // BEQ if true then pc = pc-8
    //    instr_rom[5] = 32'hFE84_0CE3;  // BEQ x8, x8, -8 : rs1, rs2, imm, PC = PC +imm
    //end
    //`endif 
    //initial begin
    //    $readmemh("instruction_code.mem",instr_rom);
    ////    $readmemh("instruction_mem_sort.mem",instr_rom);
    //end

    assign instr_code = instr_rom[instr_addr[31:2]];
endmodule


//instr_rom[2]  = 32'h4033_8333; // x6  = x7 -  x3 
//instr_rom[3]  = 32'h4083_8333; // x6  = x7 -  x8 
//instr_rom[4]  = 32'h0021_93b3; // x7  = x3 << x2 
//instr_rom[5]  = 32'h01cf_13b3; // x7  = x30 << x28 
//instr_rom[6]  = 32'h0033_a433; // x8  = x7 < x3 
//instr_rom[7]  = 32'h0071_a433; // x8  = x3 < x7 
//instr_rom[8]  = 32'h0033_b4b3; // x9  = x7 < x3 
//instr_rom[9]  = 32'h0071_b4b3; // x9  = x3 < x7 
//instr_rom[10] = 32'h00fa_c533; // x10 = x21 ^ x15 
//instr_rom[11] = 32'h0028_55b3; // x11 = x16 >> x2 
//instr_rom[12] = 32'h0058_55b3; // x11 = x16 >> x5(7) 
//instr_rom[13] = 32'h4033_d633; // x12 = x27 >> x3 
//instr_rom[14] = 32'h00e8_66b3; // x13 = x16 | x14 
//instr_rom[15] = 32'h011a_f733; // x14 = x21 & x17
