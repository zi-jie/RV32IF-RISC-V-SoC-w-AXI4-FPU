`include "../../include/def.svh"

module wptr_full (
    output logic                     wfull,
    output logic [`ADDRSIZE-1:0]      waddr,
    output logic [`ADDRSIZE  :0]      wptr,
    input  logic [`ADDRSIZE  :0]      rptr_wclk,
    input  logic                     wpush, 
    input  logic                     wclk, 
    input  logic                     wrst
);

    logic [`ADDRSIZE:0] wbin;
    logic [`ADDRSIZE:0] wgraynext, wbinnext;

    // GRAYSTYLE2 pointer
    always_ff @(posedge wclk or posedge wrst) begin
      if (wrst) {wbin, wptr} <= 0;
      else      {wbin, wptr} <= {wbinnext, wgraynext};
    end

    // Memory write-address pointer (okay to use binary to address memory)
    assign waddr     = wbin[`ADDRSIZE-1:0];
    assign wbinnext  = wbin + (wpush & ~wfull);
    assign wgraynext = (wbinnext>>1) ^ wbinnext;

    // Simplified version of the three necessary full-tests:
    assign wfull_val = (wgraynext == {~rptr_wclk[`ADDRSIZE:`ADDRSIZE-1], rptr_wclk[`ADDRSIZE-2:0]});

    always_ff @(posedge wclk or posedge wrst) begin
      if (wrst) wfull <= 1'b0;
      else      wfull <= wfull_val;
    end

endmodule
