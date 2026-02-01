module Decoder (
    input [31:0] inst,
    output logic [4:0] dc_out_opcode,
    output logic [2:0] dc_out_func3,
    // output logic       dc_out_func5,
    output logic [3:0] dc_out_func7,
    output logic [4:0] dc_out_rs1_index,
    output logic [4:0] dc_out_rs2_index,
    output logic [4:0] dc_out_rd_index,
    output logic [1:0] dc_out_imm,
    output logic [3:0] dc_out_imm_csr, // imm 28, 26, 22, 20 
    output logic dc_out_valid_inst // valid instruction
);

    assign dc_out_opcode = inst[6:2];

    assign dc_out_func3 = inst[14:12];
    
    // assign dc_out_func7 = {inst[30], inst[25]};
    assign dc_out_func7 = {inst[29], inst[27], inst[30], inst[25]};

    assign dc_out_rs1_index = inst[19:15];
    assign dc_out_rs2_index = inst[24:20];

    assign dc_out_rd_index = inst[11:7];

    // CSR type
    assign dc_out_imm = {inst[27], inst[21]};
    assign dc_out_imm_csr = {inst[28], inst[26], inst[22], inst[20]};

    assign dc_out_valid_inst = ~(inst == 32'h00000013); // NOP addi x0, x0, 0

endmodule
