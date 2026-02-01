//adder2 : adder2 res
 
`include "../../include/peremeters.svh"
module adder2_LReLU(
    input clk,
    input rst,
    input stall,

    input [`HWORD - 1:0] adder2_result_in,

    output logic [`HWORD - 1:0] adder2_result
);
    integer x;
  always_ff @( posedge clk /*or negedge rst*/) begin
    //initialize
    if(!rst) begin
        adder2_result <= 16'h0;
    end
    else if(stall) begin
        adder2_result <= adder2_result;
    end 
    else begin
        adder2_result <= adder2_result_in;
    end 
  end
endmodule