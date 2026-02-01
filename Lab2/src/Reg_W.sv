module Reg_W (
    input logic clk,
    input logic rst,
    input logic IM_stall,
    input logic DM_stall,
    input logic [31:0] alu_out_in,
    input logic [31:0] ld_data_in,
    output logic [31:0] alu_out_out,
    output logic [31:0] ld_data_out
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            alu_out_out <= 32'd0;  // Reset to NOP
            ld_data_out <= 32'd0;  // Reset to NOP
        end else if (IM_stall || DM_stall) begin
            alu_out_out <= alu_out_out;  // Keep current value on stall
            ld_data_out <= ld_data_out;  // Keep current value on stall
        end else begin
            alu_out_out <= alu_out_in;  // Normal operation
            ld_data_out <= ld_data_in;  // Normal operation
        end
    end
endmodule