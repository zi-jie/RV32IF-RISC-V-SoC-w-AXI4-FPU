 
`include "../../include/peremeters.svh"
module Requan3 (
  input signed [25:0] RQ2_result,
  input [3:0] shift_bits,
  input do_requan,
  output logic [`HWORD - 1:0] RQ3_result
);

logic signed [25:0] shift_result;
logic signed [15:0] shift_result_sign_extend;
assign shift_result = RQ2_result >> (shift_bits+1);
assign shift_result_sign_extend = {{8{shift_result[7]}},shift_result[7:0]};
assign RQ3_result = (do_requan)? shift_result_sign_extend : RQ2_result[15:0]; 

endmodule
