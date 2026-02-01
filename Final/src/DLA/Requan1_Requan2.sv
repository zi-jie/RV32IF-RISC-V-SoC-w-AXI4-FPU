//! remove it from pipeline
 
`include "../../include/peremeters.svh"
module Requan1_Requan2(
    input clk,
    input rst,
    input stall,

    input [`HWORD - 1:0] Requan1_result_in,

    output logic [`HWORD - 1:0] Requan1_result
);
    integer x;
  always_ff @( posedge clk /*or negedge rst*/) begin
    //initialize
    if(!rst) begin
        Requan1_result <= 16'h0;
    end
    else if(stall) begin
        Requan1_result <= Requan1_result;
    end 
    else begin
        Requan1_result <= Requan1_result_in;
    end 
  end
endmodule