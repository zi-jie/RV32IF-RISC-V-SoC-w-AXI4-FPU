 
`include "../../include/peremeters.svh"
module Requan1 (
  input signed [`HWORD - 1:0] LR_result,
  input signed [`HWORD - 1:0] bias,
  input do_requan,
  output logic signed [`HWORD - 1:0] RQ1_result
);
logic signed [16:0] sub_result;
assign sub_result = (LR_result - bias);

logic signed [`HWORD - 1:0] sub_result_saturate;
always_comb begin
  if(sub_result <= $signed(-32768))
    sub_result_saturate = -32768;
  else if(sub_result >= $signed(32767))
    sub_result_saturate = 32767;
  else
    sub_result_saturate = sub_result[`HWORD-1:0];
end

assign RQ1_result = (do_requan)? sub_result_saturate : LR_result; 

endmodule
