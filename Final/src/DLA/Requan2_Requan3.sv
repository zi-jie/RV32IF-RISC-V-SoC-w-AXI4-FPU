//! remove it from pipeline
 
`include "../../include/peremeters.svh"
module Requan2_Requan3(
    input clk,
    input rst,
    input stall,

    input [25:0] Requan2_result_in,

    output logic [25:0] Requan2_result
);
    integer x;
  always_ff @( posedge clk /*or negedge rst*/) begin
    //initialize
    if(!rst) begin
        Requan2_result <= 26'h0;
    end
    else if(stall) begin
        Requan2_result <= Requan2_result;
    end 
    else begin
        Requan2_result <= Requan2_result_in;
    end 
  end
endmodule