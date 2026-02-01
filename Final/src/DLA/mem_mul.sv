 
`include "../../include/peremeters.svh"
module mem_mul(
    input clk,
    input rst,
    input stall,

    input [`BYTE - 1:0] ifm_mem_in [8:0],

    output logic [`BYTE - 1:0] ifm_mem_result [8:0]
);
    integer x;
  always_ff @( posedge clk /*or negedge rst*/) begin
    //initialize
    if(!rst) begin
        for(x=0; x<9; x++) ifm_mem_result[x] <= 8'h0;
    end
    else if(stall) begin
        for(x=0; x<9; x++) ifm_mem_result[x] <= ifm_mem_result[x];
    end 
    else begin
        for(x=0; x<9; x++) ifm_mem_result[x] <= ifm_mem_in[x];
    end 
  end
endmodule