//! remove it from pipeline
 
`include "../../include/peremeters.svh"
module Requan3_wb(
    input clk,
    input rst,
    input stall,

    input [`HWORD - 1:0] Requan3_result_in,

    output logic [`HWORD - 1:0] Requan3_result
);
    integer x;
  always_ff @( posedge clk /*or negedge rst*/) begin
    //initialize
    if(!rst) begin
        Requan3_result <= 16'h0;
    end
    else if(stall) begin
        Requan3_result <= Requan3_result;
    end 
    else begin
        Requan3_result <= Requan3_result_in;
    end 
  end
endmodule