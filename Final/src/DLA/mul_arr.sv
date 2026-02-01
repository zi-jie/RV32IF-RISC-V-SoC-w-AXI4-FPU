//simply mul?
// 9 mac
 
`include "../../include/peremeters.svh"
module mul_arr (
  input signed [`BYTE - 1:0] ifm [`MAC_NUM - 1 : 0],
  input signed [`BYTE - 1:0] weight[`MAC_NUM - 1 : 0],
  output logic signed [`HWORD - 1:0] mul_result[`MAC_NUM - 1 : 0]
);
genvar idx;
generate
  for(idx = 0 ; idx < `MAC_NUM ; idx++)begin : mul_array
    assign mul_result[idx] = ifm[idx] * weight[idx];
  end
endgenerate

endmodule