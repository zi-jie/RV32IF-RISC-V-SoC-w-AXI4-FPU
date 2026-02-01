`include "../include/def.svh"

module aFIFO ( 
    input logic wclk,
    input logic rclk,
    input logic wrst,
    input logic rrst,
    input logic [`DATASIZE-1:0] wdata,
    output logic [`DATASIZE-1:0] rdata,
    input logic wpush,
    input logic rpop, 
    output logic wfull,
    output logic rempty
);

    logic [`ADDRSIZE-1:0] waddr, raddr;
    logic [`ADDRSIZE:0] wptr, rptr; 
    logic [`ADDRSIZE:0] wptr_rclk, rptr_wclk;

    fifomem fifomem1(
        .rdata(rdata),
        .wdata(wdata),
        .waddr(waddr),
        .raddr(raddr),
        .wpush(wpush),
        .wfull(wfull),
        .wclk(wclk)
    );

    wptr_full wptr_full1(
        .wfull(wfull),
        .waddr(waddr),
        .wptr(wptr),
        .rptr_wclk(rptr_wclk),
        .wpush(wpush),
        .wclk(wclk),
        .wrst(wrst)
    );

    rptr_empty rptr_empty1(
        .empty(rempty),
        .raddr(raddr),
        .rptr(rptr),
        .wptr_rclk(wptr_rclk),
        .rpop(rpop),
        .rclk(rclk),
        .rrst(rrst)
    );

    sync_r2w sync_r2w_wclk(
        .rptr_wclk(rptr_wclk),
        .rptr(rptr),
        .wclk(wclk),
        .wrst(wrst)
    );

    sync_r2w sync_r2w_rclk(
        .rptr_wclk(wptr_rclk),
        .rptr(wptr),
        .wclk(rclk),
        .wrst(rrst)
    );


endmodule