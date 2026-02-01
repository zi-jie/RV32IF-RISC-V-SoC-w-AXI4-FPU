module CSR_Reg (
    input logic clk,            // Clock signal
    input logic rst,          // Active-low reset
    input logic IM_stall,
    input logic DM_stall,
    // input logic [4:0] opcode,  // 5-bit opcode input
    // input logic [2:0] funct3,  // 3-bit funct3 input
    // input logic [4:0] rs1_index, // Index of the source register 1
    // input logic [4:0] rd_index, // Index of the destination register
    // input logic imm_1,       // Imm[1]: decide high or low 32 bits
    input logic [1:0] imm,       // W_imm
    input logic valid_inst, // valid instruction (W_valid_inst)
    output logic [31:0] csr_out // 64-bit instruction retire counter output
);

    // logic valid_inst;
    logic [63:0] instret;
    logic [63:0] cycle;

    // other than addi x0, x0, 0 (NOP)
    // assign valid_inst = ~((opcode == 5'b00100) && (funct3 == 3'b000) && (rs1_index == 5'b00000) && (rd_index == 5'b00000));
    // assign csr_out = (imm_1 ? instret[63:32] : instret[31:0]);
    always_comb begin
        case (imm) 
            2'b11: csr_out = instret[63:32];
            2'b01: csr_out = (instret[31:0]); //WB late 4 cycles TODO: maybe less than 4 because of NOP 
            2'b10: csr_out = cycle[63:32];
            2'b00: csr_out = (cycle[31:0] - 32'd4); //WB late 4 cycles
            default: csr_out = 32'd0;
        endcase
    end

    // Inst_Reg: Internal 64-bit counter
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            instret <= 64'd0;  // Reset counter to 0
        end else if (valid_inst && (IM_stall == 0 && DM_stall == 0)) begin
            instret <= instret + 1;  // Increment the instruction retire counter
        end
        else begin
            instret <= instret;  // Do not increment the counter
        end
    end

    // Cycle Reg
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            cycle <= 64'd0;  // Reset counter to 0
        end else begin
            cycle <= cycle + 1;  // Increment the cycle counter on each clock cycle
        end
    end

endmodule
