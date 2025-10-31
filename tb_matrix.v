`timescale 1ps/1ps

module tb;
    reg clk, rst, Jen;
    reg [31:0] Jin;
    reg [31:0] instructions[512];
    reg [31:0] data_mem[512];
    wire [31:0] Jout;

    wire InstDone0, InstDone1;
    wire [31:0] R0[32], R1[32];
    assign R0[0] = 0; assign R1[0] = 0;

    reg [31:0] inst_reg0, inst_reg1;
    reg [4:0] inst_rs0, inst_rt0, inst_rd0, inst_rs1, inst_rt1, inst_rd1;
    reg [31:0] val_rs0, val_rt0, val_rs1, val_rt1;
    reg [15:0] inst_imm0, inst_imm1;
    reg signed [31:0] inst_imm_sext0, inst_imm_sext1;
    reg [8:0] ipc0, ipc1;
    reg [31:0] ireg0[32], ireg1[32];
    reg [31:0] ireghi0, ireglo0, ireghi1, ireglo1;
    reg [31:0] data_addr0, data_addr1;
    reg signed [31:0] val_signed_rs0, val_signed_rt0, val_signed_rs1, val_signed_rt1;

task write2reg0(input [4:0] rd, input [31:0] val); if (rd != 0) ireg0[rd] = val; endtask
task write2reg1(input [4:0] rd, input [31:0] val); if (rd != 0) ireg1[rd] = val; endtask

    function [31:0] sra(input [31:0] a, input [4:0] b);
        begin
            sra = ({{32{a[31]}}, a} >> b);
        end
    endfunction

    task exec_internal0;
        begin
            inst_reg0 = instructions[ipc0];
            ipc0 += 1;

            inst_rs0 = inst_reg0[25:21];
            inst_rt0 = inst_reg0[20:16];
            inst_rd0 = inst_reg0[15:11];
            inst_imm0 = inst_reg0[15:0];
            inst_imm_sext0 = {{16{inst_imm0[15]}}, inst_imm0};
            val_rs0 = ireg0[inst_rs0];
            val_rt0 = ireg0[inst_rt0];
            val_signed_rs0 = val_rs0;
            val_signed_rt0 = val_rt0;
            case (inst_reg0[31:26])
                6'b000000: begin  // RType
                    case (inst_reg0[5:0])
                        6'b100000: write2reg0(inst_rd0, val_rs0 + val_rt0);  // add
                        6'b100010: write2reg0(inst_rd0, val_rs0 - val_rt0);  // sub
                        6'b100100: write2reg0(inst_rd0, val_rs0 & val_rt0);  // and
                        6'b100101: write2reg0(inst_rd0, val_rs0 | val_rt0);  // or
                        6'b100110: write2reg0(inst_rd0, val_rs0 ^ val_rt0);  // xor
                        6'b000100: write2reg0(inst_rd0, val_rs0 << val_rt0[4:0]);  // sll
                        6'b000110: write2reg0(inst_rd0, val_rs0 >> val_rt0[4:0]);  // srl
                        6'b000111: write2reg0(inst_rd0, sra(val_rs0, val_rt0[4:0]));  // sra
                        6'b000000:
                        write2reg0(inst_rd0, val_rt0 << inst_reg0[10:6]);  // sll (imm) rd=rt<<shamt
                        6'b011010: begin  // div HI=rs%rt; LO=rs/rt
                            ireghi0 = val_rs0 % val_rt0;
                            ireglo0 = val_rs0 / val_rt0;
                        end
                        6'b010000: write2reg0(inst_rd0, ireghi0);  // mfhi rd=HI
                        6'b010010: write2reg0(inst_rd0, ireglo0);  // mflo rd=LO
                        6'b001000: ipc0 = val_rs0;  // jr : ipc=rs
                        default $display("NOT IMPLEMENTED : rtype[func: %b]", inst_reg0[5:0]);
                    endcase
                end
                6'b001000: write2reg0(inst_rt0, val_rs0 + inst_imm_sext0);  // addi
                6'b101011: begin  // sw *(int*)(offset+rs)=rt
                    // $display("wat", val_rs, " ", val_rt, " ", inst_imm_sext);
                    data_addr0 = val_rs0 + inst_imm_sext0;
                    if (data_addr0 & 3 !== 0)
                        $display(
                            "WARNING : Unaligned data address (%x)",
                            data_addr0,
                            "  %x => %x %x",
                            inst_rs0,
                            val_rs0,
                            inst_imm_sext0
                        );
                    $display("stor %x", (data_addr0 >> 2) & 511);
                    data_mem[(data_addr0>>2)&511] = val_rt0;
                end
                6'b100011: begin  // lw rt=*(int*)(offset+rs)
                    data_addr0 = val_rs0 + inst_imm_sext0;
                    if (data_addr0 & 3 !== 0)
                        $display(
                            "WARNING : Unaligned data address (%x)",
                            data_addr0,
                            "  %x => %x %x",
                            inst_rs0,
                            val_rs0,
                            inst_imm_sext0
                        );
                    $display("load %x", (data_addr0 >> 2) & 511);
                    write2reg0(inst_rt0, data_mem[(data_addr0>>2)&511]);
                end
                6'b000101: begin  // bne if(rs!=rt) pc+=offset
                    $display("wat", val_rs0, " != ", val_rt0, " ", inst_imm_sext0);
                    ipc0 += val_rs0 != val_rt0 ? inst_imm_sext0 : 0;
                end
                6'b000100: begin  // beq if(rs==rt) pc+=offset
                    $display("wat", val_rs0, " == ", val_rt0, " ", inst_imm_sext0);
                    ipc0 += val_rs0 == val_rt0 ? inst_imm_sext0 : 0;
                end
                6'b001010: write2reg0(inst_rt0, val_rs0 < inst_imm_sext0 ? 1 : 0);  // slti rt=rs<imm
                6'b000010: ipc0 = inst_imm0;  // j pc=target
                6'b000011: begin  // jal ra=pc pc=target
                    write2reg0(31, ipc0);
                    ipc0 = inst_imm0;
                end
                6'b011100: begin  // mul rd = rs * rt
                    // instruction format is a bit convoluted!
                    write2reg0(inst_rd0, val_signed_rs0 * val_signed_rt0);
                end
                6'b100000: begin  // cpuid rs = 0
                    write2reg0(inst_rs0, 0);
                end
                6'b101010: begin  // sync
                    // sync
                end
                default $display("NOT IMPLEMENTED : [opcode: %b]", inst_reg0[31:26]);
            endcase
            // c inst_reg[31:26]
        end
    endtask

    task exec_internal1;
        begin
            inst_reg1 = instructions[ipc1];
            ipc1 += 1;

            inst_rs1 = inst_reg1[25:21];
            inst_rt1 = inst_reg1[20:16];
            inst_rd1 = inst_reg1[15:11];
            inst_imm1 = inst_reg1[15:0];
            inst_imm_sext1 = {{16{inst_imm1[15]}}, inst_imm1};
            val_rs1 = ireg1[inst_rs1];
            val_rt1 = ireg1[inst_rt1];
            val_signed_rs1 = val_rs1;
            val_signed_rt1 = val_rt1;
            case (inst_reg1[31:26])
                6'b000000: begin  // RType
                    case (inst_reg1[5:0])
                        6'b100000: write2reg1(inst_rd1, val_rs1 + val_rt1);  // add
                        6'b100010: write2reg1(inst_rd1, val_rs1 - val_rt1);  // sub
                        6'b100100: write2reg1(inst_rd1, val_rs1 & val_rt1);  // and
                        6'b100101: write2reg1(inst_rd1, val_rs1 | val_rt1);  // or
                        6'b100110: write2reg1(inst_rd1, val_rs1 ^ val_rt1);  // xor
                        6'b000100: write2reg1(inst_rd1, val_rs1 << val_rt1[4:0]);  // sll
                        6'b000110: write2reg1(inst_rd1, val_rs1 >> val_rt1[4:0]);  // srl
                        6'b000111: write2reg1(inst_rd1, sra(val_rs1, val_rt1[4:0]));  // sra
                        6'b000000:
                        write2reg1(inst_rd1, val_rt1 << inst_reg1[10:6]);  // sll (imm) rd=rt<<shamt
                        6'b011010: begin  // div HI=rs%rt; LO=rs/rt
                            ireghi1 = val_rs1 % val_rt1;
                            ireglo1 = val_rs1 / val_rt1;
                        end
                        6'b010000: write2reg1(inst_rd1, ireghi1);  // mfhi rd=HI
                        6'b010010: write2reg1(inst_rd1, ireglo1);  // mflo rd=LO
                        6'b001000: ipc1 = val_rs1;  // jr : ipc=rs
                        default $display("NOT IMPLEMENTED : rtype[func: %b]", inst_reg1[5:0]);
                    endcase
                end
                6'b001000: write2reg1(inst_rt1, val_rs1 + inst_imm_sext1);  // addi
                6'b101011: begin  // sw *(int*)(offset+rs)=rt
                    // $display("wat", val_rs, " ", val_rt, " ", inst_imm_sext);
                    data_addr1 = val_rs1 + inst_imm_sext1;
                    if (data_addr1 & 3 !== 0)
                        $display(
                            "WARNING : Unaligned data address (%x)",
                            data_addr1,
                            "  %x => %x %x",
                            inst_rs1,
                            val_rs1,
                            inst_imm_sext1
                        );
                    $display("stor %x", (data_addr1 >> 2) & 511);
                    data_mem[(data_addr1>>2)&511] = val_rt1;
                end
                6'b100011: begin  // lw rt=*(int*)(offset+rs)
                    data_addr1 = val_rs1 + inst_imm_sext1;
                    if (data_addr1 & 3 !== 0)
                        $display(
                            "WARNING : Unaligned data address (%x)",
                            data_addr1,
                            "  %x => %x %x",
                            inst_rs1,
                            val_rs1,
                            inst_imm_sext1
                        );
                    $display("load %x", (data_addr1 >> 2) & 511);
                    write2reg1(inst_rt1, data_mem[(data_addr1>>2)&511]);
                end
                6'b000101: begin  // bne if(rs!=rt) pc+=offset
                    $display("wat", val_rs1, " != ", val_rt1, " ", inst_imm_sext1);
                    ipc1 += val_rs1 != val_rt1 ? inst_imm_sext1 : 0;
                end
                6'b000100: begin  // beq if(rs==rt) pc+=offset
                    $display("wat", val_rs1, " == ", val_rt1, " ", inst_imm_sext1);
                    ipc1 += val_rs1 == val_rt1 ? inst_imm_sext1 : 0;
                end
                6'b001010: write2reg1(inst_rt1, val_rs1 < inst_imm_sext1 ? 1 : 0);  // slti rt=rs<imm
                6'b000010: ipc1 = inst_imm1;  // j pc=target
                6'b000011: begin  // jal ra=pc pc=target
                    write2reg1(31, ipc1);
                    ipc1 = inst_imm1;
                end
                6'b011100: begin  // mul rd = rs * rt
                    // instruction format is a bit convoluted!
                    write2reg1(inst_rd1, val_signed_rs1 * val_signed_rt1);
                end
                6'b100000: begin  // cpuid rs = 0
                    write2reg1(inst_rs1, 1);
                end
                6'b101010: begin  // sync
                    // sync
                end
                default $display("NOT IMPLEMENTED : [opcode: %b]", inst_reg1[31:26]);
            endcase
            // c inst_reg[31:26]
        end
    endtask


    main _main (
        .clk(clk),
        .rst(rst),
        .Jen(Jen),
        .Jin(Jin),
        .Jout(Jout),
        .InstDone0(InstDone0),
        .InstDone1(InstDone1),
        .R1_0(R0[1]),
        .R2_0(R0[2]),
        .R3_0(R0[3]),
        .R4_0(R0[4]),
        .R5_0(R0[5]),
        .R6_0(R0[6]),
        .R7_0(R0[7]),
        .R8_0(R0[8]),
        .R9_0(R0[9]),
        .R10_0(R0[10]),
        .R11_0(R0[11]),
        .R12_0(R0[12]),
        .R13_0(R0[13]),
        .R14_0(R0[14]),
        .R15_0(R0[15]),
        .R16_0(R0[16]),
        .R17_0(R0[17]),
        .R18_0(R0[18]),
        .R19_0(R0[19]),
        .R20_0(R0[20]),
        .R21_0(R0[21]),
        .R22_0(R0[22]),
        .R23_0(R0[23]),
        .R24_0(R0[24]),
        .R25_0(R0[25]),
        .R26_0(R0[26]),
        .R27_0(R0[27]),
        .R28_0(R0[28]),
        .R29_0(R0[29]),
        .R30_0(R0[30]),
        .R31_0(R0[31]),
        .R1_1(R1[1]),
        .R2_1(R1[2]),
        .R3_1(R1[3]),
        .R4_1(R1[4]),
        .R5_1(R1[5]),
        .R6_1(R1[6]),
        .R7_1(R1[7]),
        .R8_1(R1[8]),
        .R9_1(R1[9]),
        .R10_1(R1[10]),
        .R11_1(R1[11]),
        .R12_1(R1[12]),
        .R13_1(R1[13]),
        .R14_1(R1[14]),
        .R15_1(R1[15]),
        .R16_1(R1[16]),
        .R17_1(R1[17]),
        .R18_1(R1[18]),
        .R19_1(R1[19]),
        .R20_1(R1[20]),
        .R21_1(R1[21]),
        .R22_1(R1[22]),
        .R23_1(R1[23]),
        .R24_1(R1[24]),
        .R25_1(R1[25]),
        .R26_1(R1[26]),
        .R27_1(R1[27]),
        .R28_1(R1[28]),
        .R29_1(R1[29]),
        .R30_1(R1[30]),
        .R31_1(R1[31])
    );

    initial begin
        clk = 0;
        forever #1 clk = ~clk;
    end

    int i;
    int last_instr;
    int j;
    int fail_flag0;
    int fail_flag1;
    int k;
    int l;
    initial begin
        for (i = 0; i < 512; i++) instructions[i] = 0;
        for (i = 0; i < 512; i++) data_mem[i] = 0;
        for (i = 0; i < 32; i++) begin 
            ireg0[i] = 0;
            ireg1[i] = 0;
        end
        ireghi0 = 0;
        ireglo0 = 0;
        ipc0 = 0;
        ireghi1 = 0;
        ireglo1 = 0;
        ipc1 = 0;

	    instructions[0] = 32'b001000_00000_00011_0000000000000000;  // addi $3, $0, 0
	    instructions[1] = 32'b001000_00000_00100_0000000100000000;  // addi $4, $0, 256

	    instructions[2] = 32'b101011_00011_00011_0000000000000000;  // sw $3, 0($3)
	    instructions[3] = 32'b001000_00011_00011_0000000000000100;  // addi $3, $3, 4
	    instructions[4] = 32'b000101_00011_00100_1111111111111101;  // bne $3, $4, -3

	    instructions[5] = 32'b001000_00000_00011_0000000000000000;  // addi $3, $0, 0
	    instructions[6] = 32'b101011_00011_00011_0000000100000000;  // sw $3, 256($3)
        instructions[7] = 32'b001000_00011_00011_0000000000000100;  // addi $3, $3, 4
        instructions[8] = 32'b000101_00011_00100_1111111111111101;  // bne $3, $4, -3
        
        instructions[9] = 32'b100000_00100_000000000000000000000;  // cpuid $4
        instructions[10] = 32'b000101_00100_00000_0000000000011110;  // bne $4 , $0, 30 todo
        
        // core 0
        instructions[11] = 32'b001000_00000_00011_0000000000000000;     // addi $3, $0, 0   --> i
        instructions[12] = 32'b001000_00000_00100_0000000000000100;     // addi $4, $0, 4
        instructions[13] = 32'b001000_00000_00101_0000000000000000;     // addi $5, $0, 0   --> j
        instructions[14] = 32'b001000_00000_00110_0000000000001000;     // addi $6, $0, 8
        instructions[15] = 32'b001000_00000_00111_0000000000000000;     // addi $7, $0, 0   --> k

        instructions[16] = 32'b001000_00000_01000_0000000000001000;     // addi $8, $0, 8
        instructions[17] = 32'b001000_00000_01001_0000000000000000;     // addi $9, $0, 0   --> sum

        instructions[18] = 32'b001000_00000_01010_0000000000001000;     // addi $10, $0, 8  (useless)
        instructions[19] = 32'b000000_00000_00011_01010_00011_000000;   // sll $10, $3, 3   --> $10 = 8i
        instructions[20] = 32'b000000_01010_00111_01010_00000_100000;   // add $10, $10, $7 --> $10 = 8i + k
        instructions[21] = 32'b000000_00000_01010_01010_00010_000000;   // sll $10, $10, 2
        instructions[22] = 32'b100011_01010_01010_0000000000000000;     // lw $10, 0($10)

        instructions[23] = 32'b001000_00000_01011_0000000000001000;     // addi $11, $0, 8  (useless)
        instructions[24] = 32'b000000_00000_00111_01011_00011_000000;   // sll $11, $7, 3   --> $11 = 8k
        instructions[25] = 32'b000000_01011_00101_01011_00000_100000;   // add $11, $11, $5 --> $11 = 8k + j
        instructions[26] = 32'b000000_00000_01011_01011_00010_000000;   // sll $11, $11, 2
        instructions[27] = 32'b100011_01011_01011_0000000000000000;     // lw $11, 0($11)

        instructions[28] = 32'b011100_01010_01011_01010_00000000000;    // mul $10, $10, $11
        instructions[29] = 32'b000000_01001_01010_01001_00000_100000;   // add $9, $9, $10  --> sum += mul_result
        instructions[30] = 32'b001000_00111_00111_0000000000000001;     // addi $7, $7, 1   --> k++
        instructions[31] = 32'b000101_01000_00111_1111111111110010;     // bne $8, $7, -14  --> if k = 8 : done this mul

        instructions[32] = 32'b001000_00000_01010_0000000000001000;     // addi $10, $0, 8
        instructions[33] = 32'b000000_00000_00011_01010_00011_000000;   // sll $10, $3, 3   --> $10 = 8i
        instructions[34] = 32'b000000_01010_00101_01010_00000_100000;   // add $10, $10, $5 --> $10 = 
        instructions[35] = 32'b00000000000010100101000010000000;// sll $10, $10, 2
        instructions[36] = 32'b10101101010010010000001000000000;// sw $9, 512($10)
        instructions[37] = 32'b00100000101001010000000000000001;// addi $5, $5, 1
        instructions[38] = 32'b00010100110001011111111111101000;// bne $5, $6, -24
        instructions[39] = 32'b00100000011000110000000000000001;// addi $3, $3, 1
        instructions[40] = 32'b00010100100000111111111111100100;// bne $4, $3, -28
        instructions[41] = 32'b00001000000000000000000000101010; // j end ..................
    //core 1
	// instructions[41] = 32'b00100000000000110000000000000100;// addi $3, $0, 4
    // instructions[42] = 32'b00100000000001000000000000001000;// addi $4, $0, 8
    // instructions[43] = 32'b00100000000001010000000000000000;// addi $5, $0, 0
    // instructions[44] = 32'b00100000000001100000000000001000;// addi $6, $0, 8
    // instructions[45] = 32'b00100000000001110000000000000000;// addi $7, $0, 0
    // instructions[46] = 32'b00100000000010000000000000001000;// addi $8, $0, 8
    // instructions[47] = 32'b00100000000010010000000000000000;// addi $9, $0, 0
    // instructions[48] = 32'b00100000000010100000000000001000;// addi $10, $0, 8
    // instructions[49] = 32'b01110001010000110101000000000000;// mul $10, $10, $3
    // instructions[50] = 32'b00000001010001110101000000100000;// add $10, $10, $7
    // instructions[51] = 32'b10001101010010100000000000000000;// lw $10, 0($10)
    // instructions[52] = 32'b01110001010000100101000000000000;// mul $10, $10, $4
    // instructions[53] = 32'b00100000000010110000000000001000;// addi $11, $0, 8
    // instructions[54] = 32'b01110001011001110101100000000000;// mul $11, $11, $7
    // instructions[55] = 32'b00000001011001010101100000100000;// add $11, $11, $5
    // instructions[56] = 32'b01110001011000100101100000000000;// mul $11, $11, $4
    // instructions[57] = 32'b10001101011010110000000000000000;// lw $11, 0($11)
    // instructions[58] = 32'b01110001010010110101000000000000;// mul $10, $10, $11
    // instructions[59] = 32'b00000001001010100100100000100000;// add $9, $9, $10
    // instructions[60] = 32'b00100000111001110000000000000001;// addi $7, $7,1
    // instructions[61] = 32'b00010101000001111111111111110010;// bne $8, $7, -14
    // instructions[62] = 32'b00100000000010100000000000001000;// addi $10, $0, 8
    // instructions[63] = 32'b01110001010000110101000000000000;// mul $10, $10, $3
    // instructions[64] = 32'b00000001010001010101000000100000;// add $10, $10, $5
    // // mul $10, $10, $3
    // instructions[65] = 32'b10101101010010010000001000000000;// sw $9, address3($10)  address3 = address2 + 64*4
    // instructions[66] = 32'b00100000101001010000000000000001;// addi $5, $5, 1
    // instructions[67] = 32'b00010100110001011111111111101001;// bne $5, $6, -23
    // instructions[68] = 32'b00100000011000110000000000000001;// addi $3, $3, 1
    // instructions[69] = 32'b00010100100000111111111111100101;// bne $4, $3, -27
    // end :
        last_instr = 42;
        rst = 1;
        #8 rst = 0;
        Jen = 1;
        for (i = 0; i < 512; i++) begin  // D mem
            Jin = data_mem[511-i];
            #2;
        end
        for (i = 0; i < 512; i++) begin
            Jin = instructions[511-i];
            #2;
        end
        Jen = 0;
        rst = 1;
        #2 rst = 0; 
        fail_flag0 = 0;
        fail_flag1= 0;
    end

    initial begin//core 0
        #2060;
        for (i = 0; ipc0 != last_instr && !fail_flag0; i++) begin
            if (!fail_flag0) begin
                exec_internal0();
                #2;
                $display("ipc", ipc0);
                $display("Expectation at core 0 : ", " [1]%x", ireg0[1], " [2]%x", ireg0[2], " [3]%x",
                             ireg0[3], " [4]%x", ireg0[4], " [5]%x", ireg0[5]," [6]%x", ireg0[6]," [7]%x", ireg0[7]," [8]%x", ireg0[8]," [9]%x", ireg0[9]," [10]%x", ireg0[10]," [11]%x", ireg0[11]," [12]%x", ireg0[12]," [13]%x", ireg0[13]," [14]%x", ireg0[14]," [15]%x", ireg0[15]," [16]%x", ireg0[16]," [17]%x", ireg0[17]," [18]%x", ireg0[18]," [19]%x", ireg0[19]," [20]%x", ireg0[20]," [21]%x", ireg0[21]," [22]%x", ireg0[22]," [23]%x", ireg0[23]," [24]%x", ireg0[24]," [25]%x", ireg0[25]," [26]%x", ireg0[26]," [27]%x", ireg0[27]," [28]%x", ireg0[28]," [29]%x", ireg0[29], " [30]%x", ireg0[30], " [31]%x", ireg0[31]);
                $display("Reality : ", " [1]%x", R0[1], " [2]%x", R0[2], " [3]%x",
                             R0[3], " [4]%x", R0[4], " [5]%x", R0[5]," [6]%x", R0[6]," [7]%x", R0[7]," [8]%x", R0[8]," [9]%x", R0[9]," [10]%x", R0[10]," [11]%x", R0[11]," [12]%x", R0[12]," [13]%x", R0[13]," [14]%x", R0[14]," [15]%x", R0[15]," [16]%x", R0[16]," [17]%x", R0[17]," [18]%x", R0[18]," [19]%x", R0[19]," [20]%x", R0[20]," [21]%x", R0[21]," [22]%x", R0[22]," [23]%x", R0[23]," [24]%x", R0[24]," [25]%x", R0[25]," [26]%x", R0[26]," [27]%x", R0[27]," [28]%x", R0[28]," [29]%x", R0[29], " [30]%x", R0[30], " [31]%x", R0[31]);

                while ((InstDone0 !== 1) ) #2;  
                
                for (j = 1; j < 32; j++) begin 
                    if (R0[j] !== ireg0[j]) begin 
                        fail_flag0 = 1;
                        $display("expect = %x, real = %x, index = %x",ireg0[j], R0[j] ,j);
                    end
                end
                if (fail_flag0) begin
                    $display("Expectation at core 0 : ", " [1]%x", ireg0[1], " [2]%x", ireg0[2], " [3]%x",
                             ireg0[3], " [4]%x", ireg0[4], " [5]%x", ireg0[5]," [6]%x", ireg0[6]," [7]%x", ireg0[7]," [8]%x", ireg0[8]," [9]%x", ireg0[9]," [10]%x", ireg0[10]," [11]%x", ireg0[11]," [12]%x", ireg0[12]," [13]%x", ireg0[13]," [14]%x", ireg0[14]," [15]%x", ireg0[15]," [16]%x", ireg0[16]," [17]%x", ireg0[17]," [18]%x", ireg0[18]," [19]%x", ireg0[19]," [20]%x", ireg0[20]," [21]%x", ireg0[21]," [22]%x", ireg0[22]," [23]%x", ireg0[23]," [24]%x", ireg0[24]," [25]%x", ireg0[25]," [26]%x", ireg0[26]," [27]%x", ireg0[27]," [28]%x", ireg0[28]," [29]%x", ireg0[29], " [30]%x", ireg0[30], " [31]%x", ireg0[31]);
                    $display("Reality : ", " [1]%x", R0[1], " [2]%x", R0[2], " [3]%x",
                             R0[3], " [4]%x", R0[4], " [5]%x", R0[5]," [6]%x", R0[6]," [7]%x", R0[7]," [8]%x", R0[8]," [9]%x", R0[9]," [10]%x", R0[10]," [11]%x", R0[11]," [12]%x", R0[12]," [13]%x", R0[13]," [14]%x", R0[14]," [15]%x", R0[15]," [16]%x", R0[16]," [17]%x", R0[17]," [18]%x", R0[18]," [19]%x", R0[19]," [20]%x", R0[20]," [21]%x", R0[21]," [22]%x", R0[22]," [23]%x", R0[23]," [24]%x", R0[24]," [25]%x", R0[25]," [26]%x", R0[26]," [27]%x", R0[27]," [28]%x", R0[28]," [29]%x", R0[29], " [30]%x", R0[30], " [31]%x", R0[31]);
                    $display("FAILED");
                end
            end
        end
        $display("tamoom shod!");
        $display("fail_flag: %x",fail_flag0);
        if (!fail_flag0) begin
            $display("mem : ", "[1f9] : ", data_mem[505], "[1fa] : ", data_mem[506], "[1fb] : ",
                     data_mem[507], "[1fc] : ", data_mem[508], "[1fd] : ", data_mem[509],
                     "[1fe] : ", data_mem[510], "[1ff] : ", data_mem[511]);
            $display("ACCEPTED CORE 0, steps : %d", i);
            if(ipc1 == last_instr)
                $finish(0);
        end
    end

    //initial begin
    //    forever #10 $display("Time=%0t", $time);
    //end

    // initial begin// core 1
    //     #2060;
    //     for (k = 0; ipc1 != last_instr && !fail_flag1; k++) begin
    //         if (!fail_flag1) begin
    //             $display("ipc1 : ", ipc1);
    //             exec_internal1();
    //             #2;
    //             while ((InstDone1 !== 1) ) #2;  

    //             for (l= 1; l < 32; l++) if (R1[l] !== ireg1[l]) fail_flag1 = 1;
    //             if (fail_flag1) begin
    //                 // $display("Expectation at core 0 : ", " [1]%x", ireg0[1], " [2]%x", ireg0[2], " [3]%x",
    //                 //          ireg0[3], " [4]%x", ireg0[4], " [5]%x", ireg0[5]," [29]%x", ireg0[29], " [30]%x", ireg0[30], " [31]%x", ireg0[31]);
    //                 // $display("Reality : ", " [1]%x", R0[1], " [2]%x", R0[2], " [3]%x", R0[3],
    //                 //          " [4]%x", R0[4], " [5]%x", R0[5] , " [29]%x", R0[29], " [30]%x", R0[30], " [31]%x", R0[31]);
    //                 $display("FAILED");
    //             end
    //         end
    //     end
    //     if (!fail_flag1) begin
    //         // $display("mem : ", "[1f9] : ", data_mem[505], "[1fa] : ", data_mem[506], "[1fb] : ",
    //         //          data_mem[507], "[1fc] : ", data_mem[508], "[1fd] : ", data_mem[509],
    //         //          "[1fe] : ", data_mem[510], "[1ff] : ", data_mem[511]);
    //         $display("ACCEPTED CORE 1, steps : %d",k);
    //         if (ipc0 == last_instr)
    //             $finish(0);
    //     end
    // end
endmodule
