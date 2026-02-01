 
`include "../../include/peremeters.svh"
module LReLU_Requan1(
    input clk,
    input rst,
    input stall,

    input [`HWORD - 1:0] LReLU_result_in,

    output logic [`HWORD - 1:0] LReLU_result
);
    integer x;
  always_ff @( posedge clk /*or negedge rst*/) begin
    //initialize
    if(!rst) begin
        LReLU_result <= 16'h0;
    end
    else if(stall) begin
        LReLU_result <= LReLU_result;
    end 
    else begin
        LReLU_result <= LReLU_result_in;
    end 
  end
endmodule