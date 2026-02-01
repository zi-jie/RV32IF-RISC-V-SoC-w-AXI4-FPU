module JB_Unit (
    input logic [31:0] operand1, 
    input logic [31:0] operand2, 
    output logic [31:0] jb_out   
);

    always_comb begin
        jb_out = (operand1 + operand2) & (~32'd1);
    end

endmodule
