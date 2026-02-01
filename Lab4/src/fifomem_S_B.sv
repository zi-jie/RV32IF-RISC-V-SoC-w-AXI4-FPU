`include "../include/def.svh"

module fifomem_S_B (
    output [`S_B_DATASIZE-1:0] rdata,
    input [`S_B_DATASIZE-1:0] wdata,
    input [`ADDRSIZE-1:0] waddr, raddr,
    input wpush,
    input wfull, 
    input wclk
);

    // RTL Verilog memory model
    localparam DEPTH = 1<<`ADDRSIZE;
    
    logic [`S_B_DATASIZE-1:0] mem [0:DEPTH-1];
    
    assign rdata = mem[raddr];
    
    always_ff @(posedge wclk) begin
        if (wpush && !wfull) 
            mem[waddr] <= wdata;
    end

endmodule
