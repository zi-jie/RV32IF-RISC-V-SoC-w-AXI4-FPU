//adder1 => 3 to 1
`include "../../include/peremeters.svh"
 
module adder2 (
  input signed [19:0] add1_result [2 : 0],
  output logic signed [`HWORD - 1:0] add2_result
);

// logic signed [19:0] add2_result_before_sat;
// assign add2_result_before_sat = add1_result[0] + add1_result[1] + add1_result[2];

// //saturate
// assign add2_result = (add2_result_before_sat > $signed({3'h0, 16'h7fff}))? 16'h7fff : 
//                     (add2_result_before_sat < $signed({3'h7, 16'h8000}))? 16'h8000 : add2_result_before_sat[15:0];

logic signed [22:0] temp_result;
assign temp_result = add1_result[0] + add1_result[1] + add1_result[2];

always_comb begin
  if(temp_result <= $signed(-32768))
    add2_result = -32768;
  else if(temp_result >= $signed(32767))
    add2_result = 32767;
  else
    add2_result = temp_result[`HWORD-1:0];
end

endmodule