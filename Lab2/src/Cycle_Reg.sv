module Cycle_Reg (
    input logic clk,           // Clock signal
    input logic rst,         // Active-low reset
    input logic imm_1,       // Imm[1]: decide high or low 32 bits
    output logic [31:0] cycle_out  // 64-bit cycle counter output
);

    logic [63:0] cycle;
    // Internal 64-bit counter
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            cycle <= 64'd0;  // Reset counter to 0
        end else begin
            cycle <= cycle + 1;  // Increment the cycle counter on each clock cycle
        end
    end

    assign cycle_out = imm_1 ? cycle[63:32] : cycle[31:0];  // Output the lower 32 bits of the cycle counter

endmodule

