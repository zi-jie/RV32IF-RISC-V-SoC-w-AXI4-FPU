//adder1 => 4 to 1
`include "../../include/peremeters.svh"
 
module adder1 (
  input signed [`HWORD - 1:0] mul_result [3 : 0],
  output logic signed [19:0] add1_result
);

assign add1_result = (mul_result[0] + mul_result[1]) + (mul_result[2] + mul_result[3]); 

endmodule