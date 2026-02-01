`include "../include/AXI_define.svh"
`include "DMA_slave_FSM.sv"
`include "DMA_master_FSM.sv"
`include "DMA.sv"

module DMA_wrapper(
    input ACLK,
    input ARESETn,

    // DMA slave, write channel
    input [`AXI_IDS_BITS-1:0] AWID_S3,
    input [`AXI_ADDR_BITS-1:0] AWADDR_S3,    
    input [`AXI_LEN_BITS-1:0] AWLEN_S3,       
    input [`AXI_SIZE_BITS-1:0] AWSIZE_S3,       
    input [1:0] AWBURST_S3,    
    input AWVALID_S3,
    output logic AWREADY_S3,    
    input [`AXI_DATA_BITS-1:0] WDATA_S3,
    input [`AXI_STRB_BITS-1:0] WSTRB_S3,       
    input WLAST_S3,       
    input WVALID_S3,      
    output logic WREADY_S3,      
    output logic [`AXI_IDS_BITS-1:0] BID_S3,
    output logic [1:0] BRESP_S3,       
    output logic BVALID_S3,       
    input BREADY_S3,

    // DMA master, write channel
    output logic [`AXI_ID_BITS-1:0] AWID_M2,
    output logic [`AXI_ADDR_BITS-1:0] AWADDR_M2,
    output logic [`AXI_LEN_BITS-1:0] AWLEN_M2,
    output logic [`AXI_SIZE_BITS-1:0] AWSIZE_M2,
    output logic [1:0] AWBURST_M2,
    output logic AWVALID_M2,
    input AWREADY_M2,		
    output logic [`AXI_DATA_BITS-1:0] WDATA_M2,     
    output logic [`AXI_STRB_BITS-1:0] WSTRB_M2, 
    output logic WLAST_M2,
    output logic WVALID_M2,
    input WREADY_M2,
    input [`AXI_ID_BITS-1:0] BID_M2,
    input [1:0] BRESP_M2,
    input BVALID_M2,
    output logic BREADY_M2, 

    // DMA master, read channel
    output logic [`AXI_ID_BITS-1:0] ARID_M2,
    output logic [`AXI_ADDR_BITS-1:0] ARADDR_M2,
    output logic [`AXI_LEN_BITS-1:0] ARLEN_M2,
    output logic [`AXI_SIZE_BITS-1:0] ARSIZE_M2,
    output logic [1:0] ARBURST_M2,
    output logic ARVALID_M2,
    input ARREADY_M2,
    input [`AXI_ID_BITS-1:0] RID_M2,		
    input [`AXI_DATA_BITS-1:0] RDATA_M2,
    input [1:0] RRESP_M2,
    input RLAST_M2,
    input RVALID_M2,
    output logic RREADY_M2,

    // output to CPU
    output logic DMA_interrupt
);

logic [`AXI_ADDR_BITS-1:0] config_addr;
logic DMASRC_valid;
logic DMADST_valid;
logic DMALEN_valid;
logic DMA_enable;

logic [`AXI_LEN_BITS-1:0] burst_len;
logic read_data_valid;
logic [`AXI_DATA_BITS-1:0] read_data;
logic AR_valid;
logic [`AXI_ADDR_BITS-1:0] read_addr;
logic AW_valid;
logic [`AXI_ADDR_BITS-1:0] write_addr;
logic W_valid;
logic [`AXI_DATA_BITS-1:0] write_data;
logic W_last;
logic master_W_done;
logic master_B_done;

DMA_slave_FSM DMA_slave_FSM1(
    .ACLK(ACLK),
    .ARESETn(ARESETn),
    .AWID_S(AWID_S3),
    .AWADDR_S(AWADDR_S3),    
    .AWLEN_S(AWLEN_S3),       
    .AWSIZE_S(AWSIZE_S3),       
    .AWBURST_S(AWBURST_S3),    
    .AWVALID_S(AWVALID_S3),
    .AWREADY_S(AWREADY_S3),    
    .WDATA_S(WDATA_S3),
    .WSTRB_S(WSTRB_S3),       
    .WLAST_S(WLAST_S3),       
    .WVALID_S(WVALID_S3),      
    .WREADY_S(WREADY_S3),      
    .BID_S(BID_S3),
    .BRESP_S(BRESP_S3),       
    .BVALID_S(BVALID_S3),       
    .BREADY_S(BREADY_S3),
    .config_addr(config_addr),
    .DMASRC_valid(DMASRC_valid),
    .DMADST_valid(DMADST_valid),
    .DMALEN_valid(DMALEN_valid),
    .DMA_enable(DMA_enable)
);

DMA DMA1(
    .ACLK(ACLK),
    .ARESETn(ARESETn),
    .config_addr(config_addr),
    .DMASRC_valid(DMASRC_valid),
    .DMADST_valid(DMADST_valid),
    .DMALEN_valid(DMALEN_valid),
    .DMA_enable(DMA_enable),
    .burst_len(burst_len),
    .read_data_valid(read_data_valid),
    .read_data(read_data),
    .AR_valid(AR_valid),
    .read_addr(read_addr),
    .AW_valid(AW_valid),
    .write_addr(write_addr),
    .W_valid(W_valid),
    .write_data(write_data),
    .W_last(W_last),
    .master_W_done(master_W_done),
    .master_B_done(master_B_done),
    .DMA_interrupt(DMA_interrupt)
);

DMA_master_FSM DMA_master_FSM1(
    .ACLK(ACLK),
    .ARESETn(ARESETn),
    .AWID_M(AWID_M2),
    .AWADDR_M(AWADDR_M2),
    .AWLEN_M(AWLEN_M2),
    .AWSIZE_M(AWSIZE_M2),
    .AWBURST_M(AWBURST_M2),
    .AWVALID_M(AWVALID_M2),
    .AWREADY_M(AWREADY_M2),		
    .WDATA_M(WDATA_M2),     
    .WSTRB_M(WSTRB_M2), 
    .WLAST_M(WLAST_M2),
    .WVALID_M(WVALID_M2),
    .WREADY_M(WREADY_M2),
    .BID_M(BID_M2),
    .BRESP_M(BRESP_M2),
    .BVALID_M(BVALID_M2),
    .BREADY_M(BREADY_M2),
    .ARID_M(ARID_M2),
    .ARADDR_M(ARADDR_M2),
    .ARLEN_M(ARLEN_M2),
    .ARSIZE_M(ARSIZE_M2),
    .ARBURST_M(ARBURST_M2),
    .ARVALID_M(ARVALID_M2),
    .ARREADY_M(ARREADY_M2),
    .RID_M(RID_M2),		
    .RDATA_M(RDATA_M2),
    .RRESP_M(RRESP_M2),
    .RLAST_M(RLAST_M2),
    .RVALID_M(RVALID_M2),
    .RREADY_M(RREADY_M2),
    .burst_len(burst_len),
    .read_data_valid(read_data_valid),
    .read_data(read_data),
    .AR_valid(AR_valid),
    .read_addr(read_addr),
    .AW_valid(AW_valid),
    .write_addr(write_addr),
    .W_valid(W_valid),
    .write_data(write_data),
    .W_last(W_last),
    .master_W_done(master_W_done),
    .master_B_done(master_B_done)
);


endmodule