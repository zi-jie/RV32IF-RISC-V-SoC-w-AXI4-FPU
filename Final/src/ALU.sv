module ALU (
    input  [4:0]  opcode,      // Opcode to define the type of instruction
    input  [2:0]  func3,       // Function 3 field for more specific operation decoding
    input  [3:0]  func7,       // Func7 [29, 27, 30, 25]
    input  [31:0] operand1,    // First operand
    input  [31:0] operand2,    // Second operand
    output logic [31:0] alu_out // ALU output result
);

logic [63:0] extended_operand1, extended_operand2; 
// logic [63:0] full_result;  
logic [63:0] full_result_uu, full_result_ss, full_result_su;

// logic [63:0] mul_ss;
// logic [63:0] mul_su;
// logic [63:0] mul_uu;
// logic [63:0] mul_result_uu;
// logic [32:0] mul1, mul2;

// assign mul1 = $signed({operand1[31],operand1});
// assign mul2 = $unsigned(operand2);

// assign mul_ss = $signed(operand1) * $signed(operand2);
// assign mul_su = $signed(mul1) * $signed(mul2);
// assign mul_uu = operand1 * operand2;

logic [32:0] mult1, mult2;

assign mult1 = $signed({operand1[31],operand1});
assign mult2 = $unsigned(operand2);
assign full_result_ss = $signed(operand1) * $signed(operand2);
assign full_result_su = $signed(mult1) * $signed(mult2);
assign full_result_uu = operand1 * operand2;

    always_comb begin
        extended_operand1 = { {32{operand1[31]}}, operand1 };
        extended_operand2 = { {32{operand2[31]}}, operand2 };
    end

    // always_comb begin 
    //     full_result_uu = operand1 * operand2;
    //     full_result_ss = extended_operand1 * extended_operand2;
    //     full_result_su = extended_operand1 * operand2;
    // end

    always_comb begin 
        case (opcode)
            5'b01100: begin // Register-Register Instructions (R-type)
                if (func7[0]) begin // MUL (func7[25] == 1)
                    case (func3) 
                        3'b000: alu_out = full_result_ss[31:0];
                        3'b001: alu_out = full_result_ss[63:32];
                        3'b010: alu_out = full_result_su[63:32];
                        3'b011: alu_out = full_result_uu[63:32];                        
                        // 3'b000: alu_out = mul_ss[31:0]; // MUL
                        // 3'b001: alu_out = mul_ss[63:32]; // MULH
                        // 3'b010: alu_out = mul_su[63:32]; // MULHSU
                        // 3'b011: alu_out = mul_uu[63:32]; // MULHU
                        // 3'b000: begin // MUL
                        //     // full_result = operand1 * operand2;
                        //     alu_out = full_result_uu[31:0];
                        // end
                        // 3'b001: begin // MULH
                        //     // full_result = extended_operand1 * extended_operand2;
                        //     alu_out = full_result_ss[63:32];
                        // end
                        // 3'b010: begin // MULHSU
                        //     // extended_operand2 = operand2;  
                        //     // full_result = extended_operand1 * operand2;
                        //     alu_out = full_result_su[63:32];
                        // end
                        // 3'b011: begin // MULHU
                        //     // extended_operand1 = operand1;
                        //     // extended_operand2 = operand2;
                        //     // full_result = operand1 * operand2;
                        //     alu_out = full_result_uu[63:32];
                        // end
                        default: alu_out = 32'b0;
                    endcase
                end
                else begin // func7[25] == 0
                    case (func3)
                        3'b000: alu_out = (func7[1]) ? (operand1 - operand2) : (operand1 + operand2); // ADD/SUB
                        3'b001: begin
                            case({func7[1], func7[3:2]})
                                3'b000: alu_out = operand1 << operand2[4:0]; // SLL
                                3'b110: alu_out = (operand1 << operand2[4:0]) | (operand1 >> (32 - operand2[4:0])); // ROL
                                3'b101: alu_out = operand1 & ~(1'b1 << operand2[4:0]); // BCLR
                                3'b011: alu_out = operand1 | (1'b1 << operand2[4:0]); // BSET
                                3'b111: alu_out = operand1 ^ (1'b1 << operand2[4:0]); // BINV
                                default: alu_out = 32'b0;
                            endcase
                        end                
                        3'b010: alu_out = (operand1[31] != operand2[31]) ? operand1[31] : (operand1 < operand2); // SLT (signed)
                        3'b011: alu_out = (operand1 < operand2) ? 32'b1 : 32'b0; // SLTU (unsigned)
                        3'b100: alu_out = (func7[1]) ? ~(operand1 ^ operand2) : (operand1 ^ operand2); // XNOR/XOR
                        3'b101: begin
                            if (func7[3]) // inst[29]
                                alu_out = (operand1 >> operand2[4:0]) | (operand1 << (32 - operand2[4:0]));
                            else begin
                                if (func7[1]) // inst[30]
                                    alu_out = (operand1 >>> operand2[4:0]); // SRA
                                else
                                    alu_out = (operand1 >> operand2[4:0]); // SRL
                            end
                        end
                        3'b110: alu_out = (func7[1]) ? (operand1 | ~operand2) : (operand1 | operand2); // OR
                        3'b111: alu_out = (func7[1]) ? (operand1 & ~operand2) : (operand1 & operand2); // AND
                        default: alu_out = 32'b0;
                    endcase
                end
            end
            5'b00100: begin // Register-Immediate Instructions (I-type)
                case (func3)
                    3'b000: alu_out = operand1 + operand2; // ADDI
                    3'b001: alu_out = func7[3] ? (operand1 | (1 << operand2[4:0])) : operand1 << operand2[4:0]; // BSETI/SLLI
                    3'b010: alu_out = (operand1[31] != operand2[31]) ? operand1[31] : (operand1 < operand2); // SLTI (signed)
                    3'b011: alu_out = (operand1 < operand2) ? 32'b1 : 32'b0; // SLTIU (unsigned)
                    3'b100: alu_out = operand1 ^ operand2; // XORI
                    3'b101: begin
                        if (func7[1] && operand1[31]) 
                            alu_out = (operand1 >> operand2[4:0]) | ({32{1'b1}} << (32 - operand2[4:0])); // SRAI
                        else 
                            alu_out = operand1 >> operand2[4:0]; // SRLI
                    end
                    // alu_out = (func7[1]) ? (operand1 >>> operand2[4:0]) : (operand1 >> operand2[4:0]); // SRLI/SRAI
                    3'b110: alu_out = operand1 | operand2; // ORI
                    3'b111: alu_out = operand1 & operand2; // ANDI
                    default: alu_out = 32'b0;
                endcase
            end
            5'b11000: begin // B-type
                case (func3)
                    3'b000: alu_out = (operand1 == operand2) ? 32'd1 : 32'd0; // BEQ
                    3'b001: alu_out = (operand1 != operand2) ? 32'd1 : 32'd0; // BNE
                    3'b100: alu_out = (operand1[31] != operand2[31]) ? operand1[31] : (operand1 < operand2) ? 32'd1 : 32'd0; // BLT
                    3'b101: alu_out = (operand1[31] != operand2[31]) ? !operand1[31] : (operand1 >= operand2) ? 32'd1 : 32'd0; // BGE
                    3'b110: alu_out = (operand1 < operand2) ? 32'd1 : 32'd0; // BLTU
                    3'b111: alu_out = (operand1 >= operand2) ? 32'd1 : 32'd0; // BGEU
                    default: alu_out = 32'b0;
                endcase
            end
            5'b00000, // Load (I-type), Store (S-type)
            5'b00001, // FLW (I-type), FSW (S-type)
            5'b01001, // FSW (S-type)
            5'b01000: alu_out = operand1 + operand2; // rs1 + imm
            5'b01101: alu_out = operand2; // LUI rd = imm
            5'b00101: alu_out = operand1 + operand2; // AUIPC rd = pc + imm
            
            5'b11011, // JAL (J-type), JALR (I-type)
            5'b11001: alu_out = operand1 + 32'd4; 
            default: alu_out = 32'b0; // Default case for unsupported instructions
        endcase
    end

endmodule