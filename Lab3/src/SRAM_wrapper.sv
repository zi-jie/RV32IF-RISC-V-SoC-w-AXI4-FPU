`include "Slave_FSM.sv"
//`include "../sim/SRAM/SRAM_rtl.sv"
`include "../include/AXI_define.svh"

module SRAM_wrapper(
	input ACLK,
	input ARESETn,
	input [`AXI_IDS_BITS-1:0] AWID_S,
    input [`AXI_ADDR_BITS-1:0] AWADDR_S,    
    input [`AXI_LEN_BITS-1:0] AWLEN_S,       
    input [`AXI_SIZE_BITS-1:0] AWSIZE_S,       
    input [1:0] AWBURST_S,    
    input AWVALID_S,
    output logic AWREADY_S,    
    input [`AXI_DATA_BITS-1:0] WDATA_S,
    input [`AXI_STRB_BITS-1:0] WSTRB_S,       
    input WLAST_S,       
    input WVALID_S,      
    output logic WREADY_S,      
    output logic [`AXI_IDS_BITS-1:0] BID_S,
    output logic [1:0] BRESP_S,       
    output logic BVALID_S,       
    input BREADY_S,       
    input [`AXI_IDS_BITS-1:0] ARID_S,     
    input [`AXI_ADDR_BITS-1:0] ARADDR_S,       
    input [`AXI_LEN_BITS-1:0] ARLEN_S,       
    input [`AXI_SIZE_BITS-1:0] ARSIZE_S,       
    input [1:0] ARBURST_S,      
    input ARVALID_S,      
    output logic ARREADY_S,      
    output logic [`AXI_IDS_BITS-1:0] RID_S,
    output logic [`AXI_DATA_BITS-1:0] RDATA_S,       
    output logic [1:0] RRESP_S,       
    output logic RLAST_S,       
    output logic RVALID_S,       
    input RREADY_S   
);

logic Rvalid_wire;
logic previous_r;
logic R_doing;
logic W_doing;
logic FSM_WREADY;
logic [`AXI_ADDR_BITS-1:0] W_addr;
logic [`AXI_ADDR_BITS-1:0] R_addr;
logic [`AXI_ADDR_BITS-1:0] SRAM_addr;
logic SRAM_WEB;
logic [31:0] SRAM_BWEB;
logic [`AXI_DATA_BITS-1:0] SRAM_DO;
logic [`AXI_DATA_BITS-1:0] SRAM_DO_reg;
logic previous_ar;

//assign SRAM_addr = (W_doing)? W_addr:(ARVALID_S && )? ARADDR_S:R_addr;
assign WREADY_S = FSM_WREADY;
assign SRAM_WEB = ~(W_doing & WVALID_S & FSM_WREADY);
assign SRAM_BWEB = {{8{~WSTRB_S[3]}}, {8{~WSTRB_S[2]}}, {8{~WSTRB_S[1]}}, {8{~WSTRB_S[0]}}};
assign RDATA_S = (previous_ar || previous_r)? SRAM_DO:SRAM_DO_reg;
assign RVALID_S = Rvalid_wire;

always_comb begin
    if (W_doing)
        SRAM_addr = W_addr;
    else if ((ARVALID_S == 1'b1) && (R_doing == 1'b0))
        SRAM_addr = ARADDR_S;
    else if (((R_doing == 1'b1) && (RREADY_S == 1'b1) && (Rvalid_wire == 1'b1)))
        SRAM_addr = R_addr + 32'd4;
    else 
        SRAM_addr = R_addr;
end

always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn)
        previous_r <= 1'b0;
    else if (((R_doing == 1'b1) && (RREADY_S == 1'b1) && (Rvalid_wire == 1'b1)))
        previous_r <= 1'b1;
    else 
        previous_r <= 1'b0;
end

always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn)
        SRAM_DO_reg <= `AXI_DATA_BITS'b0;
    else if (previous_ar || (RREADY_S != 1'b1) || (Rvalid_wire != 1'b1))
        SRAM_DO_reg <= SRAM_DO;
    else
        SRAM_DO_reg <= SRAM_DO_reg;
end

Slave_FSM slave1(
    .ACLK(ACLK),
	.ARESETn(ARESETn),
	.AWID_S(AWID_S),
    .AWADDR_S(AWADDR_S),             
    .AWVALID_S(AWVALID_S),
    .AWREADY_S(AWREADY_S),         
    .WLAST_S(WLAST_S),
    .WVALID_S(WVALID_S),            
    .WREADY_S(FSM_WREADY),      
    .BID_S(BID_S),
    .BRESP_S(BRESP_S),       
    .BVALID_S(BVALID_S),       
    .BREADY_S(BREADY_S),       
    .ARID_S(ARID_S),     
    .ARADDR_S(ARADDR_S), 
    .ARLEN_S(ARLEN_S),           
    .ARVALID_S(ARVALID_S),      
    .ARREADY_S(ARREADY_S),      
    .RID_S(RID_S),      
    .RRESP_S(RRESP_S),       
    .RLAST_S(RLAST_S),       
    .RVALID_S(Rvalid_wire),       
    .RREADY_S(RREADY_S),
    .R_doing(R_doing),
    .W_doing(W_doing),
    .R_ADDR_S(R_addr),
    .W_ADDR_S(W_addr),
    .previous_ar(previous_ar)
);

TS1N16ADFPCLLLVTA512X45M4SWSHOD i_SRAM(
	.SLP(1'b0),
    .DSLP(1'b0),
    .SD(1'b0),
    .PUDELAY(),
    .CLK(ACLK), 
    .CEB(1'b0), 
    .WEB(SRAM_WEB),
    .A(SRAM_addr[15:2]), 
    .D(WDATA_S),
    .BWEB(SRAM_BWEB),
    .RTSEL(2'b01),
    .WTSEL(2'b01),
    .Q(SRAM_DO)
);

endmodule
