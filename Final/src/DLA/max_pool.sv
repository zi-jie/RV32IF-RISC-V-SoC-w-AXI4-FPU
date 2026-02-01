// 8bit?
 
`include "../../include/peremeters.svh"
//maybe read number in last cycle to early compare
module max_pool (
  input rst,
  input clk,
  input signed [`HWORD - 1:0] Requan_result,
  input [`OUT_BUF_BITS - 2:0]index, //! don't pass lsb
  input wen,
  output logic [`HWORD - 1:0] pool_result
);

logic signed [`HWORD - 1:0] pool_buffer [(`OUT_BUF_SIZE/2) - 1:0];
integer  x;
  always_ff @( posedge clk /*or negedge rst*/) begin
    //initialize
    if(!rst) begin
        for(x=0; x<(`OUT_BUF_SIZE/2); x++) pool_buffer[x] <= 16'h8000; //min
    end
    else if(wen) begin
      if(Requan_result > pool_buffer[index])pool_buffer[index] <= Requan_result; //crtical?
    end
  end

assign pool_result = (Requan_result > pool_buffer[index])? Requan_result : pool_buffer[index];

endmodule



/*
in puffer : 4*4 byte

o : in buffer /x : not in buffer /v: have done pooling

1.
ooooxxxxxxxx
xxxxxxxxxxxx    
xxxxxxxxxxxx
xxxxxxxxxxxx
2.
ooooooooxxxx
xxxxxxxxxxxx
xxxxxxxxxxxx
xxxxxxxxxxxx
3.
oooooooooooo
xxxxxxxxxxxx
xxxxxxxxxxxx
xxxxxxxxxxxx
4-1.
oooooooooooo
oxxxxxxxxxxx
xxxxxxxxxxxx
xxxxxxxxxxxx
4-2.
oooooooooooo     vvoooooooooo
ooxxxxxxxxxx  ==>vvxxxxxxxxxx
xxxxxxxxxxxx     xxxxxxxxxxxx
xxxxxxxxxxxx     xxxxxxxxxxxx
4-3.
vvoooooooooo
vvoxxxxxxxxx
xxxxxxxxxxxx
xxxxxxxxxxxx
4-4.
vvoooooooooo     vvvvoooooooo
vvooxxxxxxxx  ==>vvvvxxxxxxxx
xxxxxxxxxxxx     xxxxxxxxxxxx
xxxxxxxxxxxx     xxxxxxxxxxxx
5.
vvvvooooxxxx
vvvvooooxxxx
xxxxxxxxxxxx
xxxxxxxxxxxx
6.
vvvvvvooooox
vvvvvvooxxxx
xxxxxxxxxxxx
xxxxxxxxxxxx

*/