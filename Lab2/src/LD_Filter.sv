module LD_Filter (
    input [2:0] func3,      // Operation type
    input [31:0] ld_data,   // Data loaded from memory
    output reg [31:0] ld_data_f  // Filtered data output
);

    // Process loaded data based on func3 value
    always_comb begin
        case (func3)
            3'b000: // LB: Load Byte
                ld_data_f = {{24{ld_data[7]}}, ld_data[7:0]}; // Sign-extend from byte
            3'b001: // LH: Load Halfword
                ld_data_f = {{16{ld_data[15]}}, ld_data[15:0]}; // Sign-extend from halfword
            3'b010: // LW: Load Word
                ld_data_f = ld_data; // Direct assignment (word is already 32-bit)
            3'b100: // LBU: Load Byte Unsigned
                ld_data_f = {24'b0, ld_data[7:0]}; // Zero-extend from byte
            3'b101: // LHU: Load Halfword Unsigned
                ld_data_f = {16'b0, ld_data[15:0]}; // Zero-extend from halfword
            default:
                ld_data_f = 32'b0; // Fallback for undefined func3 codes
        endcase
    end

endmodule
