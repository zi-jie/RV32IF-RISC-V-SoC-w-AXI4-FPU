module Imm_Ext (
    input [31:0] inst,
    output logic [31:0] imm_ext_out
);

    always_comb begin
        case(inst[6:2])
            // 5'b00100: begin// SLLI, 
            //     if (inst[14:12] == 3'b101 && inst[30] == 1'b1)
            //         imm_ext_out = {{27{inst[24]}}, inst[24:20]}; // SRAI
            //     else
            //         imm_ext_out = {{20{inst[31]}}, inst[31:20]}; // 
            // end
            5'b00100,
            5'b00000, // Load (I-type)
            5'b11001: // Immediate (I-type)
                imm_ext_out = {{20{inst[31]}}, inst[31:20]}; // Sign-extend from 12 to 32 bits

            5'b01000: // begin// Store (S-type) 
            //     if (inst[8:7] != 2'b00)
            //         imm_ext_out = {{19{inst[31]}}, inst[31:25], inst[11:7], 1'b0}; // Sign-extend from 12 to 32 bits
            //     else
            //         imm_ext_out = {{20{inst[31]}}, inst[31:25], inst[11:7]}; // Sign-extend from 12 to 32 bits
            // end
                imm_ext_out = {{20{inst[31]}}, inst[31:25], inst[11:7]}; // Sign-extend from 12 to 32 bits


            5'b11000: // Branch (B-type)
                imm_ext_out = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0}; // Sign-extend from 13 to 32 bits

            5'b01101, // LUI (U-type)
            5'b00101: // AUIPC (U-type)
                imm_ext_out = {inst[31:12], 12'b0}; // Upper immediate

            5'b11011: // JAL (J-type)
                imm_ext_out = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0}; // Sign-extend from 21 to 32 bits

            5'b00001:  // FLW type
                imm_ext_out = {{20{inst[31]}}, inst[31:20]}; 
            5'b01001:  // FSW type
                imm_ext_out = {{20{inst[31]}}, inst[31:25], inst[11:7]};
            //5'b10100:
            //5'b11100: CSR
            default: imm_ext_out = 32'b0; // Default case
        endcase
    end

endmodule
