module Reg_E (
    input logic clk,
    input logic rst,
    input logic D_WFI,
    input logic D_MRET,
    input logic interrupt_taken_reg,
    input logic stall,
    input logic IM_stall,
    input logic DM_stall,
    input logic jb,  // Jump or branch control
    input logic [31:0] pc_in,
    input logic [31:0] rs1_data_in,
    input logic [31:0] rs2_data_in,
    input logic [31:0] frs1_data_in,
    input logic [31:0] frs2_data_in,
    input logic [31:0] sext_imm_in,
    output logic [31:0] pc_out,
    output logic [31:0] rs1_data_out,
    output logic [31:0] rs2_data_out,
    output logic [31:0] frs1_data_out,
    output logic [31:0] frs2_data_out,
    output logic [31:0] sext_imm_out
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out <= 32'd0;  // Reset to NOP
            rs1_data_out <= 32'd0;  // Reset to NOP
            rs2_data_out <= 32'd0;  // Reset to NOP
            frs1_data_out <= 32'd0;  // Reset to NOP
            frs2_data_out <= 32'd0;  // Reset to NOP
            sext_imm_out <= 32'd0;  // Reset to NOP
        end else if (DM_stall || IM_stall) begin
            pc_out <= pc_out;  // Keep current value on stall
            rs1_data_out <= rs1_data_out;  // Keep current value on stall
            rs2_data_out <= rs2_data_out;  // Keep current value on stall
            frs1_data_out <= frs1_data_out;  // Keep current value on stall
            frs2_data_out <= frs2_data_out;  // Keep current value on stall
            sext_imm_out <= sext_imm_out;  // Keep current value on stall
        end else if (jb || stall || interrupt_taken_reg) begin // IM/DM stall = 0, then flush
            pc_out <= 32'd0;  // Flush: jump/branch, sending NOP
            rs1_data_out <= 32'd0;  // Flush: jump/branch, sending NOP
            rs2_data_out <= 32'd0;  // Flush: jump/branch, sending NOP
            frs1_data_out <= 32'd0;  // Flush: jump/branch, sending NOP
            frs2_data_out <= 32'd0;  // Flush: jump/branch, sending NOP
            sext_imm_out <= 32'd0;  // Flush: jump/branch, sending NOP
        end else if (D_MRET) begin // IM/DM stall = 0, then flush
            pc_out <= 32'd0;  // Flush: jump/branch, sending NOP
            rs1_data_out <= 32'd0;  // Flush: jump/branch, sending NOP
            rs2_data_out <= 32'd0;  // Flush: jump/branch, sending NOP
            frs1_data_out <= 32'd0;  // Flush: jump/branch, sending NOP
            frs2_data_out <= 32'd0;  // Flush: jump/branch, sending NOP
            sext_imm_out <= 32'd0;  // Flush: jump/branch, sending NOP
        end else if (D_WFI) begin // EXE stage set to NOP
            pc_out <= 32'd0;  // Reset to NOP
            rs1_data_out <= 32'd0;  // Reset to NOP
            rs2_data_out <= 32'd0;  // Reset to NOP
            frs1_data_out <= 32'd0;  // Reset to NOP
            frs2_data_out <= 32'd0;  // Reset to NOP
            sext_imm_out <= 32'd0;  // Reset to NOP
        end else begin
            pc_out <= pc_in;  // Normal operation
            rs1_data_out <= rs1_data_in;  // Normal operation
            rs2_data_out <= rs2_data_in;  // Normal operation
            frs1_data_out <= frs1_data_in;  // Normal operation
            frs2_data_out <= frs2_data_in;  // Normal operation
            sext_imm_out <= sext_imm_in;  // Normal operation
        end
    end
endmodule