// how to do *0.1
//(0.1)base10 ~= (0.00011001101)base2
//(0.0001101) ~= (0.1015)base10
`include "../../include/peremeters.svh"
 
module LReLU (
  input signed[`HWORD - 1:0] add2_result,
  input do_LReLU,
  output logic [`HWORD - 1:0] LR_result
);
logic signed [24:0] neg_LReLU_output ;
logic signed [6:0] mantissa;
assign mantissa = 7'b0110011;
assign neg_LReLU_output = (add2_result * mantissa);
logic  [`HWORD - 1:0] LReLU_output ;
assign LReLU_output = (add2_result[15])? {9'h11f,neg_LReLU_output[24:9]} : add2_result;
assign LR_result = (do_LReLU)? LReLU_output : add2_result; 

endmodule