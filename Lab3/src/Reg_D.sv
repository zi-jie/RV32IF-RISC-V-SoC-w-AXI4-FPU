module Reg_D (
    input logic clk,
    input logic rst,
    input logic interrupt_taken,
    input logic interrupt_taken_reg,
    input logic D_MRET,
    input logic D_WFI,
    input logic stall,
    input logic IM_stall,
    input logic DM_stall,
    input logic jb,  
    input logic [31:0] pc_in,    
    input logic [31:0] inst_in,
    output logic [31:0] pc_out,
    output logic [31:0] inst_out
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out <= 32'd0;  // Reset to NOP
            inst_out <= 32'd0; // NOP
        // end else if (interrupt_taken || D_MRET) begin
        end else if (interrupt_taken || interrupt_taken_reg) begin
            pc_out <= 32'd0;  // Reset to NOP
            inst_out <= 32'h00000013; // NOP
        end else if (jb) begin
            pc_out <= 32'd0;  // Flush: jump/branch, sending NOP
            inst_out <= 32'h00000013;  // Flush: jump/branch, sending NOP
        end else if (stall || IM_stall || DM_stall) begin // keep
            pc_out <= pc_out;  // Keep current value on stall
            inst_out <= inst_out;  // Keep current value on stall
        // end else if (jb) begin
        //     pc_out <= 32'd0;  // Flush: jump/branch, sending NOP
        //     inst_out <= 32'h00000013;  // Flush: jump/branch, sending NOP
        end else if (D_MRET) begin
            pc_out <= 32'd0;  // Flush: jump/branch, sending NOP
            inst_out <= 32'h00000013;  // Flush: jump/branch, sending NOP
        end else if (D_WFI) begin
            pc_out <= pc_out;  // Keep current value on stall
            inst_out <= inst_out;  // Keep current value on stall            
        end else begin
            pc_out <= pc_in;  // Normal operation
            inst_out <= inst_in;  // Normal operation
        end
    end
endmodule