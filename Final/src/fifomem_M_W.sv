`include "../include/def.svh"

module fifomem_M_W (
    output [`M_W_DATASIZE-1:0] rdata,
    input [`M_W_DATASIZE-1:0] wdata,
    input [`ADDRSIZE-1:0] waddr, raddr,
    input wpush,
    input wfull, 
    input wclk
);

    // RTL Verilog memory model
    localparam DEPTH = 1<<`ADDRSIZE;
    
    logic [`M_W_DATASIZE-1:0] mem [0:DEPTH-1];
    
    assign rdata = mem[raddr];
    
    always_ff @(posedge wclk) begin
        if (wpush && !wfull) 
            mem[waddr] <= wdata;
    end

endmodule
