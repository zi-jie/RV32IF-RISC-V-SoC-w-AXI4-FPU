module Controller (
    input logic clk,
    input logic rst,
    // input logic [26:0] inst,          // 27bits instruction
    input logic [4:0] opcode,  // 5-bit opcode input
    input logic [2:0] funct3,  // 3-bit funct3 input
    input logic [4:0] rs1_index, // Index of the source register 1
    input logic [4:0] rs2_index, // Index of the source register 2
    input logic [4:0] rd_index, // Index of the destination register
    input logic [1:0] func7,       // 
    input logic [1:0] imm,       // inst[27], inst[21]
    input logic [3:0] imm_csr,   // inst[28], inst[26], inst[22], inst[20]: machine level
    input logic valid_inst,       // valid inst or NOP TODO:
    
    input logic interrupt_taken, // interrupt taken
    input logic [31:0] EX_out,    // for CSR inst

    input logic alu_out_0,            // alu_out[0]: for branch success

    input logic [1:0] MM_alu_out_01,  // for DM_BWEB
    
    // output logic [31:0] F_im_BWEB,    // Instruction Memory write enable
    // output logic F_im_CEB,            // Instruction Memory chip enable
    // output logic F_im_WEB,            // Instruction Memory write enable

    // HW3 new
    output logic D_WFI,                 // Wait for interrupt signal
    output logic D_MRET,                // return from traps

    output logic D_rs1_data_sel,      // Register file read source 1 select
    output logic D_rs2_data_sel,      // Register file read source 2 select
    output logic D_frs1_data_sel,     // Floating-point register file read source 1 select
    output logic D_frs2_data_sel,     // Floating-point register file read source 2 select

    output logic [1:0] E_rs1_data_sel,      // Execute stage source 1 data select
    output logic [1:0] E_rs2_data_sel,      // Execute stage source 2 data select
    output logic [1:0] E_frs1_data_sel,     // Execute stage floating-point source 1 data select
    output logic [1:0] E_frs2_data_sel,     // Execute stage floating-point source 2 data select
    output logic E_alu_op1_sel,       // ALU operand 1 select
    output logic E_alu_op2_sel,       // ALU operand 2 select
    output logic E_jb_op2_sel,        // Jump/branch operand 2 select
    output logic E_FPU_add,           // Floating-point add/sub select
    output logic E_out_sel,     // ALU / FPU / CSR
    
    output logic [4:0] E_op,          // Execute operation
    output logic [2:0] E_f3,                // Function code (funct3)
    output logic [1:0] E_f7,                // Function code (funct7)
    // output logic [4:0] E_rd,                // Destination register index
    // output logic [4:0] E_rs1,               // Source register 1 index
    // output logic [4:0] E_rs2,               // Source register 2 index
    // output logic [1:0] E_imm,               // Immediate value FIXME

    output logic [31:0] M_dm_BWEB,    // Data Memory write enable
    output logic M_dm_CEB,            // Data Memory chip enable
    output logic M_dm_WEB,            // Data Memory write enable
    output logic M_rs2_data_sel,     // 1: CSR, 0: others

    output logic W_wb_en,             // Reg Write-back enable
    output logic W_f_wb_en,           // F-reg write-back enable
    output logic [4:0] W_rd_index,    // Write-back register index
    output logic [4:0] W_op,
    output logic [4:0] W_rs1,
    output logic [2:0] W_f3,
    output logic [1:0] W_wb_data_sel,       // Write-back data select

    output logic [1:0] W_imm,
    output logic [3:0] W_imm_csr,      // imm_csr
    output logic W_valid_inst,        // for inst register
    // output logic [31:0] W_rs1_uimm_data, // for CSR inst

    input  logic IM_stall,
    input  logic DM_stall,
    output logic [1:0] DM_next_RW,    // Data Memory next read/write/IDLE
    output logic stall,               // Stall signal
    output logic jb                   // Jump or branch success
);

// Wire declarations for decoding instruction fields
// logic [4:0] opcode;
// logic [4:0] rd_index, rs1_index, rs2_index;
// logic [2:0] funct3;
// logic [1:0] funct7;
// logic [1:0] imm;
// Pipeline registers for control signals
logic [4:0] E_rd;             // Destination register index
logic [4:0] E_rs1, M_rs1;            // Source register 1 index
logic [4:0] E_rs2;
logic [1:0] E_imm;
logic [3:0] E_imm_csr;
logic [4:0] M_op; 
logic [2:0] M_f3;
logic [4:0] M_rd, W_rd;
logic [1:0] M_imm;
logic [3:0] M_imm_csr;
logic E_valid_inst, M_valid_inst;

// logic [31:0] M_rs1_uimm_data; // for CSR inst
// logic [31:0] W_rs1_uimm_data;

// HW3 new: CSR forwardng
logic [4:0] M_rs2; // for CSR inst
logic is_M_use_rs2; // for CSR inst
logic is_W_csr_rd; // for CSR inst
// logic M_rs2_data_sel; // for CSR inst

// D stage local signal
logic is_D_use_rs1, is_D_use_rs2, is_D_use_frs1, is_D_use_frs2, is_W_use_rd, is_W_use_frd;
// E stage local signal
logic is_E_use_rs1, is_E_use_rs2, is_E_use_frs1, is_E_use_frs2, is_M_use_rd, is_M_use_frd;
logic is_E_rs1_W_rd_overlap, is_E_rs1_M_rd_overlap, is_E_rs2_W_rd_overlap, is_E_rs2_M_rd_overlap;
logic is_E_frs1_W_rd_overlap, is_E_frs1_M_rd_overlap, is_E_frs2_W_rd_overlap, is_E_frs2_M_rd_overlap;

// Decode (M stage)
// assign opcode = inst[6:2];
// assign rd_index     = inst[11:7];
// assign funct3 = inst[14:12];
// assign rs1_index    = inst[19:15];
// assign rs2_index    = inst[24:20];
// assign funct7 = {inst[30], inst[25]};
// assign imm    = {inst[27], inst[21]};

// stall signal: load rd_index == rs1_index or rs2_index / load frd == frs1 or frs2 / CSR rd == rs1 or rs2
// assign stall = ((E_op == 5'b00000 && (E_rd == rs1_index || E_rd == rs2_index)) 
//                || (E_op == 5'b00001 && (E_rd == rs1_index || E_rd == rs2_index))
//                || (E_op == 5'b11100 && (E_rd == rs1_index || E_rd == rs2_index))) ? 1'b1 : 1'b0;
always_comb begin // stall = (E == load) & is_DE_overlap
    if ((E_op == 5'b00000 && (E_rd == rs1_index || E_rd == rs2_index)) 
        || (E_op == 5'b00001 && (E_rd == rs1_index || E_rd == rs2_index))
        || (E_op == 5'b11100 && E_f3 != 3'b000 && (E_rd == rs1_index || E_rd == rs2_index))) // CSR & is_DE_overlap
        // || ((E_op == 5'b11100 && E_f3 != 3'b000) && (E_rd == rs1_index || E_rd == rs2_index))) // CSR not MRET, WFI 
        stall = 1'b1;
    else 
        stall = 1'b0;
end
// next_pc_sel (jb) jump or branch success
// assign jb = (E_op == 5'b11011 || E_op == 5'b11001 || (E_op == 5'b11000 && alu_out_0 == 1)) ? 1'b1 : 1'b0;
always_comb begin
    if (E_op == 5'b11011 || E_op == 5'b11001 || (E_op == 5'b11000 && alu_out_0 == 1'b1)) 
        jb = 1'b1;
    else 
        jb = 1'b0;
end

// To Master1 (DM): read(load):2, write(store): 1, else: 0 
// assign DM_next_RW = (E_op == 5'b00000 || E_op == 5'b00001) ? 2'd2 : 
//                     (E_op == 5'b01000 || E_op == 5'b01001) ? 2'd1 : 2'd0;
always_comb begin
    if (E_op == 5'b00000 || E_op == 5'b00001)      DM_next_RW = 2'd2; 
    else if (E_op == 5'b01000 || E_op == 5'b01001) DM_next_RW = 2'd1; 
    else                                           DM_next_RW = 2'd0;
end

// always_comb begin
//     if (E_op == 5'b01000 || E_op == 5'b01001)      DM_next_RW = 2'd1; // Write: S, FSW
//     else                                           DM_next_RW = 2'd2; // Else Read
// end

// always_comb begin
//     if (E_op == 5'b00000 || E_op == 5'b00001)      DM_next_RW = 2'd2; 
//     else                                           DM_next_RW = 2'd1;
// end

// // F stage control signals
// assign F_im_BWEB = 32'hffff; // active low
// assign F_im_CEB  = 1'b0;  // active low
// assign F_im_WEB  = 1'b1;  // read: active high

// D stage local signals
assign is_D_use_rs1 = opcode == 5'b01100 || opcode == 5'b01000 || opcode == 5'b11000 // R, S, B type
                      || opcode == 5'b00000 || opcode == 5'b00100 || opcode == 5'b11001 // I type
                      || opcode == 5'b00001 || opcode == 5'b01001; // FLW, FSW
assign is_D_use_rs2 = (opcode == 5'b01100 || opcode == 5'b01000 || opcode == 5'b11000); // R, S, B type
assign is_W_use_rd = W_op == 5'b01100 || W_op == 5'b00000 || W_op == 5'b00100 || W_op == 5'b11001 // R, I type
                     || W_op == 5'b00101 || W_op ==5'b01101 || W_op == 5'b11011  // U, J type
                     || (W_op == 5'b11100 && W_f3 != 3'b000); // CSR type

assign is_D_use_frs1 = opcode == 5'b10100; // FADD, FSUB
assign is_D_use_frs2 = opcode == 5'b10100 || opcode == 5'b01001; // FADD, FSUB, FSW
assign is_W_use_frd = W_op == 5'b00001 || W_op == 5'b10100; // FLW

// D stage control signals
// assign D_rs1_data_sel = (is_D_use_rs1 && is_W_use_rd) && (rs1_index == W_rd) && (|W_rd) ? 1'b1 : 1'b0;
assign D_rs1_data_sel = (is_D_use_rs1 && is_W_use_rd) && (rs1_index == W_rd) && (|W_rd) ? 1'b1 : 1'b0;
assign D_rs2_data_sel = (is_D_use_rs2 && is_W_use_rd) && (rs2_index == W_rd) && (|W_rd) ? 1'b1 : 1'b0;
assign D_frs1_data_sel = (is_D_use_frs1 && is_W_use_frd) && (rs1_index == W_rd) && (|W_rd) ? 1'b1 : 1'b0;
assign D_frs2_data_sel = (is_D_use_frs2 && is_W_use_frd) && (rs2_index == W_rd) && (|W_rd) ? 1'b1 : 1'b0;

// HW3 new: CSR forwardng
// M stage CSR control signals
assign is_M_use_rs2 = M_op == 5'b01100 || M_op == 5'b01000 || M_op == 5'b11000; // R, S, B type

// W stage CSR control signals
assign is_W_csr_rd = W_op == 5'b11100 && W_f3 != 3'b000; // CSR type

assign M_rs2_data_sel = is_M_use_rs2 && is_W_use_rd && (M_rs2 == W_rd) && (|W_rd) ? 1'b1 : 1'b0;

// HW3 new: WFT, MRET
always_comb begin
    if (interrupt_taken) begin
        D_WFI  = 1'b0;
        D_MRET = 1'b0;
    end else if (opcode == 5'b11100 && funct3 == 3'b000) begin
        if (imm[0]) begin   // imm[0] -> inst[21]  
            D_WFI  = 1'b0;
            D_MRET = 1'b1;
        end else begin
            D_WFI  = 1'b1;
            D_MRET = 1'b0;
        end
    end else begin
        D_WFI  = 1'b0;
        D_MRET = 1'b0;
    end
end


// E stage local signals
assign is_E_use_rs1 = E_op == 5'b01100 || E_op == 5'b01000 || E_op == 5'b11000 // R, S, B type
                     || E_op == 5'b00000 || E_op == 5'b00100 || E_op == 5'b11001 // I type
                     || E_op == 5'b00001 || E_op == 5'b01001; // FLW, FSW
assign is_E_use_rs2 = E_op == 5'b01100 || E_op == 5'b01000 || E_op == 5'b11000; // R, S, B type
assign is_M_use_rd = M_op == 5'b01100 || M_op == 5'b00000 || M_op == 5'b00100 || M_op == 5'b11001 // R, I type
                     || M_op == 5'b00101 || M_op == 5'b01101 || M_op == 5'b11011;  // U, J type

// assign is_M_use_rd = M_op == 5'b01100 || M_op == 5'b00000 || M_op == 5'b00100 || M_op == 5'b11001 // R, I type
//                      || M_op == 5'b00101 || M_op == 5'b01101 || M_op == 5'b11011  // U, J type
//                      || M_op == 5'b11100; // CSR type

assign is_E_rs1_W_rd_overlap = is_E_use_rs1 && is_W_use_rd && (E_rs1 == W_rd) && (|W_rd) ? 1'b1 : 1'b0;
assign is_E_rs1_M_rd_overlap = is_E_use_rs1 && is_M_use_rd && (E_rs1 == M_rd) && (|M_rd) ? 1'b1 : 1'b0;

assign is_E_rs2_W_rd_overlap = is_E_use_rs2 && is_W_use_rd && (E_rs2 == W_rd) && (|W_rd) ? 1'b1 : 1'b0;
assign is_E_rs2_M_rd_overlap = is_E_use_rs2 && is_M_use_rd && (E_rs2 == M_rd) && (|M_rd) ? 1'b1 : 1'b0;

assign is_E_use_frs1 = E_op == 5'b10100 ; // FADD, FSUB
assign is_E_use_frs2 = E_op == 5'b10100 || E_op == 5'b01001; // FADD, FSUB, FSW
assign is_M_use_frd = M_op == 5'b00001 || M_op == 5'b10100; // FLW, FADD/FSUB

assign is_E_frs1_W_rd_overlap = is_E_use_frs1 && is_W_use_frd && (E_rs1 == W_rd) && (|W_rd) ? 1'b1 : 1'b0;
assign is_E_frs1_M_rd_overlap = is_E_use_frs1 && is_M_use_frd && (E_rs1 == M_rd) && (|M_rd) ? 1'b1 : 1'b0;

assign is_E_frs2_W_rd_overlap = is_E_use_frs2 && is_W_use_frd && (E_rs2 == W_rd) && (|W_rd) ? 1'b1 : 1'b0;
assign is_E_frs2_M_rd_overlap = is_E_use_frs2 && is_M_use_frd && (E_rs2 == M_rd) && (|M_rd) ? 1'b1 : 1'b0;

// E stage control signals
assign E_rs1_data_sel = is_E_rs1_M_rd_overlap ? 2'd1 : 
                        is_E_rs1_W_rd_overlap ? 2'd0 : 2'd2;
assign E_rs2_data_sel = is_E_rs2_M_rd_overlap ? 2'd1 : 
                        is_E_rs2_W_rd_overlap ? 2'd0 : 2'd2;
assign E_frs1_data_sel = is_E_frs1_M_rd_overlap ? 2'd1 : 
                         is_E_frs1_W_rd_overlap ? 2'd0 : 2'd2;
assign E_frs2_data_sel = is_E_frs2_M_rd_overlap ? 2'd1 : 
                         is_E_frs2_W_rd_overlap ? 2'd0 : 2'd2;
assign E_alu_op1_sel  = (E_op == 5'b00101 || E_op == 5'b11011 || E_op == 5'b11001) ? 1'b1 : 1'b0; // pc (JALR, JAL, AUIPC)
assign E_alu_op2_sel  = (E_op == 5'b01100 || E_op == 5'b11000) ? 1'b0 : 1'b1; // rs2_index (R, B)
assign E_jb_op2_sel   = (E_op[1:0] == 2'b01) ? 1'b0 : 1'b1; // rs1 (JALR) or pc (JAL, B)
assign E_FPU_add      = (E_imm[1]) ? 1'b0 : 1'b1; // FPU sub or add
// assign E_out_sel      = (E_op == 5'b11100) ? 2 :    // CSR: 2, FADD/FSUB: 1, others: 0  
//                         (E_op == 5'b10100) ? 1 : 0; 
assign E_out_sel      = (E_op == 5'b10100) ? 1'b1 : 1'b0;    // FADD/FSUB: 1, others: 0  

// M stage control signals
// assign M_dm_BWEB = (M_op == 5'b01000) ? 32'h0000 : 32'hffff; // write(store): active low. 
always_comb begin
    if (M_op == 5'b01000 || M_op == 5'b01001) begin
        case (M_f3)
            3'b000: begin 
            if (MM_alu_out_01 == 2'b11)
                M_dm_BWEB = 32'h00ffffff;
            else if (MM_alu_out_01 == 2'b10)
                M_dm_BWEB = 32'hff00ffff;
            else if (MM_alu_out_01 == 2'b01)
                M_dm_BWEB = 32'hffff00ff;
            else 
                M_dm_BWEB = 32'hffffff00; // SB
            end
            3'b001: begin 
                if (MM_alu_out_01 == 2'b10)
                    M_dm_BWEB = 32'h0000ffff;
                else
                    M_dm_BWEB = 32'hffff0000; // SH
            end
            3'b010: M_dm_BWEB = 32'h00000000; // SW
            default: M_dm_BWEB = 32'hffffffff;
        endcase
    end
    else 
        M_dm_BWEB = 32'hffff;
end
// always_comb begin
//     if (M_op == 5'b01000 || M_op == 5'b01001) begin
//         case (M_f3)
//             3'b000: M_dm_BWEB = 32'hffffff00; // SB
//             3'b001: M_dm_BWEB = 32'hffff0000; // SH
//             3'b010: M_dm_BWEB = 32'h00000000; // SW
//             default: M_dm_BWEB = 32'hffffffff;
//         endcase
//     end
//     else 
//         M_dm_BWEB = 32'hffff;
// end

assign M_dm_CEB  = 1'b0; // active low 
// assign M_dm_WEB  = (M_op == 5'b01000) ? 1'b0 : 1'b1;      // write(store): active low. read: active high
always_comb begin
    if (M_op == 5'b01000 || M_op == 5'b01001) // FSW
        M_dm_WEB = 1'b0; // store: active low
    else 
        M_dm_WEB = 1'b1;
end

// W stage control signals
assign W_wb_en = (W_op == 5'b01000 || W_op == 5'b11000 || W_op == 5'b00001 || W_op == 5'b01001 || W_op == 5'b10100 // S, B, F type: don't write back
                 || (W_op == 5'b11100 && W_f3 == 3'b000)) ? 1'b0 : 1'b1; // CSR(MRET, WFI): don't write back
assign W_f_wb_en = (W_op == 5'b00001 || W_op == 5'b10100) ? 1'b1 : 1'b0; // FLW, FADD/FSUB: write back
assign W_rd_index = W_rd; 
// assign W_frd_index = ; same as W_rd_index
assign W_wb_data_sel =  (W_op == 5'b11100) ? 2'd2: // CSR: 2, Load/FLW: 1, ALU/FPU result: 0
                        (W_op == 5'b00000 || W_op == 5'b00001) ? 2'd0 : 2'd1; // (load & FLW) or ALU/FPU result
// assign W_f3 (already has)

// Control signals pipeline registers
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        E_op <= 5'b00000;
        E_f3 <= 3'b000;
        E_rd <= 5'b00000;
        E_rs1 <= 5'b00000;
        E_rs2 <= 5'b00000;
        E_f7 <= 2'b00;
        E_imm <= 2'b00;
        E_imm_csr <= 4'b0000;
        E_valid_inst <= 1'b0;

        M_op <= 3'b000;
        M_f3 <= 3'b000;
        M_rd <= 5'b00000;
        M_rs1 <= 5'b00000;
        M_rs2 <= 5'b00000;

        M_imm <= 2'b00;
        M_imm_csr <= 4'b0000;
        M_valid_inst <= 1'b0;
        // M_rs1_uimm_data <= 32'h00000000;

        W_op <= 3'b000;
        W_f3 <= 3'b000;
        W_rd <= 5'b00000;
        W_rs1 <= 5'b00000;
        W_imm <= 2'b00;  
        W_imm_csr <= 4'b0000;
        W_valid_inst <= 1'b0;
        // W_rs1_uimm_data <= 32'h00000000;
    // end else if (D_WFI && ~IM_stall && ~DM_stall) begin // EX(NOP), MEM, WB stages keep going, IF, ID stages stall
    //     E_op <= 5'b00100;
    //     E_f3 <= 3'b000;
    //     E_rd <= 5'b00000;
    //     E_rs1 <= 5'b00000;
    //     E_rs2 <= 5'b00000;
    //     E_f7 <= 2'b00;
    //     E_imm <= 2'b00;
    //     E_imm_csr <= 4'b0000;
    //     E_valid_inst <= 1'b0;

    //     M_op <= E_op;
    //     M_f3 <= E_f3;
    //     M_rd <= E_rd;
    //     M_rs1 <= E_rs1;
    //     M_rs2 <= E_rs2;
    //     M_imm <= E_imm;
    //     M_imm_csr <= E_imm_csr;
    //     M_valid_inst <= E_valid_inst;
    //     // M_rs1_uimm_data <= E_f3[2] ? {27'd0, E_rs1} : EX_out; // uimm / rs1_data

    //     W_op <= M_op;
    //     W_f3 <= M_f3;
    //     W_rd <= M_rd;
    //     W_rs1 <= M_rs1;
    //     W_imm <= M_imm;
    //     W_imm_csr <= M_imm_csr;
    //     W_valid_inst <= M_valid_inst;
    //     // W_rs1_uimm_data <= M_rs1_uimm_data;    
    end else if (IM_stall || DM_stall) begin // all stage stall
        E_op <= E_op;
        E_f3 <= E_f3;
        E_rd <= E_rd;
        E_rs1 <= E_rs1;
        E_rs2 <= E_rs2;
        E_f7 <= E_f7;
        E_imm <= E_imm;
        E_imm_csr <= E_imm_csr;
        E_valid_inst <= E_valid_inst;

        M_op <= M_op;
        M_f3 <= M_f3;
        M_rd <= M_rd;
        M_rs1 <= M_rs1;
        M_rs2 <= M_rs2;
        M_imm <= M_imm;
        M_imm_csr <= M_imm_csr;
        M_valid_inst <= M_valid_inst;
        // M_rs1_uimm_data <= M_rs1_uimm_data;

        W_op <= W_op;
        W_f3 <= W_f3;
        W_rd <= W_rd;
        W_rs1 <= W_rs1;
        W_imm <= W_imm;
        W_imm_csr <= W_imm_csr;
        W_valid_inst <= W_valid_inst;
        // W_rs1_uimm_data <= W_rs1_uimm_data;
    end else if (stall || jb) begin // set to addi x0, x0, 0 (NOP)
        E_op <= 5'b00100;
        E_f3 <= 3'b000;
        E_rd <= 5'b00000;
        E_rs1 <= 5'b00000;
        E_rs2 <= 5'b00000;
        E_f7 <= 2'b00;
        E_imm <= 2'b00;
        E_imm_csr <= 4'b0000;
        E_valid_inst <= 1'b0;

        M_op <= E_op;
        M_f3 <= E_f3;
        M_rd <= E_rd;
        M_rs1 <= E_rs1;
        M_rs2 <= E_rs2;
        M_imm <= E_imm;
        M_imm_csr <= E_imm_csr;
        M_valid_inst <= E_valid_inst;
        // M_rs1_uimm_data <= E_f3[2] ? {27'd0, E_rs1} : EX_out; // uimm / rs1_data

        W_op <= M_op;
        W_f3 <= M_f3;
        W_rd <= M_rd;
        W_rs1 <= M_rs1;
        W_imm <= M_imm;
        W_imm_csr <= M_imm_csr;
        W_valid_inst <= M_valid_inst;
        // W_rs1_uimm_data <= M_rs1_uimm_data;
    end else if (D_WFI || D_MRET) begin // EX(NOP), MEM, WB stages keep going, IF, ID stages stall
        E_op <= 5'b00100;
        E_f3 <= 3'b000;
        E_rd <= 5'b00000;
        E_rs1 <= 5'b00000;
        E_rs2 <= 5'b00000;
        E_f7 <= 2'b00;
        E_imm <= 2'b00;
        E_imm_csr <= 4'b0000;
        E_valid_inst <= 1'b0;

        M_op <= E_op;
        M_f3 <= E_f3;
        M_rd <= E_rd;
        M_rs1 <= E_rs1;
        M_rs2 <= E_rs2;
        M_imm <= E_imm;
        M_imm_csr <= E_imm_csr;
        M_valid_inst <= E_valid_inst;
        // M_rs1_uimm_data <= E_f3[2] ? {27'd0, E_rs1} : EX_out; // uimm / rs1_data

        W_op <= M_op;
        W_f3 <= M_f3;
        W_rd <= M_rd;
        W_rs1 <= M_rs1;
        W_imm <= M_imm;
        W_imm_csr <= M_imm_csr;
        W_valid_inst <= M_valid_inst;
        // W_rs1_uimm_data <= M_rs1_uimm_data;  
    end else begin
        E_op <= opcode;
        E_f3 <= funct3;
        E_rd <= rd_index;
        E_rs1 <= rs1_index;
        E_rs2 <= rs2_index;
        E_f7 <= func7;
        E_imm <= imm;
        E_imm_csr <= imm_csr;
        E_valid_inst <= valid_inst;
        
        M_op <= E_op;
        M_f3 <= E_f3;
        M_rd <= E_rd;
        M_imm <= E_imm;
        M_rs1 <= E_rs1;
        M_rs2 <= E_rs2;
        M_imm_csr <= E_imm_csr;
        M_valid_inst <= E_valid_inst;
        // M_rs1_uimm_data <= E_f3[2] ? {27'd0, E_rs1} : EX_out; 

        W_op <= M_op;
        W_f3 <= M_f3;
        W_rd <= M_rd;
        W_rs1 <= M_rs1;
        W_imm <= M_imm;
        W_imm_csr <= M_imm_csr;
        W_valid_inst <= M_valid_inst;
        // W_rs1_uimm_data <= M_rs1_uimm_data;
    end
end

endmodule
