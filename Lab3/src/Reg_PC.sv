module Reg_PC (
    input logic clk,        // Clock signal
    input logic rst,        // Reset signal, active high
    input logic D_WFI,      // Wait for interrupt signal
    input logic stall,      // Stall signal
    input logic IM_stall,
    input logic DM_stall,
    input logic [31:0] next_pc, // Next PC value
    output reg [31:0] current_pc // Current PC value
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            current_pc <= 32'd0; // Reset PC to 0 when reset is active
        end else if (stall || IM_stall || DM_stall) begin
            current_pc <= current_pc; // Do not update PC if stall signal is active
        end else if (D_WFI) begin
            current_pc <= current_pc; // Do not update PC if stall signal is active
        end else begin
            current_pc <= next_pc; // Update PC with the next PC value
        end
    end

endmodule
