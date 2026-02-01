`include "../../include/def.svh"

module sync_r2w (
    output logic [`ADDRSIZE:0] rptr_wclk,
    input  logic [`ADDRSIZE:0] rptr,
    input  logic wclk, 
    input  logic wrst
);

    logic [`ADDRSIZE:0] wq1_rptr; // middle flip-flop

    // 2-stage synchronizer fifo 
    always_ff @(posedge wclk or posedge wrst) begin
        if (wrst)    {rptr_wclk,wq1_rptr} <= 0;
        else         {rptr_wclk,wq1_rptr} <= {wq1_rptr,rptr};
    end

endmodule
