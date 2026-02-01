 
`include "../../include/peremeters.svh"
module mul_adder1(
    input clk,
    input rst,
    input stall,

    input [`HWORD - 1:0] mul_result_in [8:0],

    output logic [`HWORD - 1:0] mul_result [8:0]
);
    integer x;
  always_ff @( posedge clk /*or negedge rst*/) begin
    //initialize
    if(!rst) begin
        for(x=0; x<9; x++) mul_result[x] <= 16'h0;
    end
    else if(stall) begin
        for(x=0; x<9; x++) mul_result[x] <= mul_result[x];
    end 
    else begin
        for(x=0; x<9; x++) mul_result[x] <= mul_result_in[x];
    end 
  end
endmodule