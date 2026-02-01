//adder1_1 : adder_res1 / adder1_2 : adder_res2
 
`include "../../include/peremeters.svh"
module adder1_adder2(
    input clk,
    input rst,
    input stall,

    input [19:0] adder1_result_in [2:0],

    output logic [19:0] adder1_result [2:0]
);
    integer x;
  always_ff @( posedge clk /*or negedge rst*/) begin
    //initialize
    if(!rst) begin
        for(x=0; x<3; x++) adder1_result[x] <= 19'h0;
    end
    else if(stall) begin
        for(x=0; x<3; x++) adder1_result[x] <= adder1_result[x];
    end 
    else begin
        for(x=0; x<3; x++) adder1_result[x] <= adder1_result_in[x];
    end 
  end
endmodule