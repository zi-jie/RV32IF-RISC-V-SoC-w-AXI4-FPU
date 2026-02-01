 
`include "../../include/peremeters.svh"
module Requan2 (
  input signed[`HWORD - 1:0] RQ1_result,
  input [9:0] mantissa,
  input do_requan,
  output logic signed[25:0] RQ2_result
);
logic signed[25:0] mul_result;
logic signed[10:0] signed_mantissa;
assign signed_mantissa = {1'b0, mantissa};
assign mul_result = (RQ1_result * signed_mantissa);

assign RQ2_result = (do_requan)? mul_result : RQ1_result; 

endmodule
