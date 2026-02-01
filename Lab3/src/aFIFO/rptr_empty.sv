`include "../include/AXI_define.svh"

module rptr_empty (
    output logic                     empty,
    output logic [`ADDRSIZE-1:0]      raddr,
    output logic [`ADDRSIZE  :0]      rptr,
    input  logic [`ADDRSIZE  :0]      wptr_rclk,
    input  logic                     rpop,
    input  logic                     rclk, 
    input  logic                     rrst
);

    logic not_empty;
    logic rempty_val;
    logic [`ADDRSIZE:0] rbin;
    logic [`ADDRSIZE:0] rgraynext, rbinnext;

    assign empty = !not_empty;

    // GRAYSTYLE2 pointer
    always @(posedge rclk or posedge rrst) begin
        if (rrst) {rbin, rptr} <= 0;
        else         {rbin, rptr} <= {rbinnext, rgraynext};
    end

    // Memory read-address pointer (okay to use binary to address memory)
    assign raddr     = rbin[`ADDRSIZE-1:0];
    assign rbinnext  = rbin + (rpop & ~empty);
    assign rgraynext = (rbinnext>>1) ^ rbinnext;

    // FIFO empty when the next rptr == synchronized wptr or on reset
    assign rempty_val = (rgraynext == wptr_rclk);

    always @(posedge rclk or posedge rrst) begin
        if (rrst) 
            not_empty <= 1'b0;
        else         
            not_empty <= ~rempty_val;
    end

endmodule
