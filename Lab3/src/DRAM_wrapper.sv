`include "../include/AXI_define.svh"
`include "DRAM_slave_FSM.sv"
`include "DRAM_FSM.sv"

module DRAM_wrapper(
    input ACLK,
    input ARESETn,

    // connect with AXI, write channel
    input [`AXI_IDS_BITS-1:0] AWID_S5,
    input [`AXI_ADDR_BITS-1:0] AWADDR_S5,    
    input [`AXI_LEN_BITS-1:0] AWLEN_S5,       
    input [`AXI_SIZE_BITS-1:0] AWSIZE_S5,       
    input [1:0] AWBURST_S5,    
    input AWVALID_S5,
    output logic AWREADY_S5,    
    input [`AXI_DATA_BITS-1:0] WDATA_S5,
    input [`AXI_STRB_BITS-1:0] WSTRB_S5,       
    input WLAST_S5,       
    input WVALID_S5,      
    output logic WREADY_S5,      
    output logic [`AXI_IDS_BITS-1:0] BID_S5,
    output logic [1:0] BRESP_S5,       
    output logic BVALID_S5,       
    input BREADY_S5,

    // connect with AXI, read channel
    input [`AXI_IDS_BITS-1:0] ARID_S5,     
    input [`AXI_ADDR_BITS-1:0] ARADDR_S5,       
    input [`AXI_LEN_BITS-1:0] ARLEN_S5,       
    input [`AXI_SIZE_BITS-1:0] ARSIZE_S5,       
    input [1:0] ARBURST_S5,      
    input ARVALID_S5,      
    output logic ARREADY_S5,      
    output logic [`AXI_IDS_BITS-1:0] RID_S5,
    output logic [`AXI_DATA_BITS-1:0] RDATA_S5,       
    output logic [1:0] RRESP_S5,       
    output logic RLAST_S5,       
    output logic RVALID_S5,       
    input RREADY_S5,

    // connect with DRAM, top's input/output
    input [`DRAM_DATA_BITS-1:0] DRAM_Q,
    input DRAM_valid,
    output logic DRAM_CSn,
    output logic [3:0] DRAM_WEn,
    output logic DRAM_RASn,
    output logic DRAM_CASn,
    output logic [`DRAM_ADDR_BITS-1:0] DRAM_A,
    output logic [`DRAM_DATA_BITS-1:0] DRAM_D
);

logic get_addr;
logic read_data_valid;
logic [`DRAM_DATA_BITS-1:0] read_data;
logic DRAM_write_done;
logic DRAM_idle;
logic chip_enable;
logic read_write_sel;
logic [`DRAM_SLAVE_ADDR_BITS-1:0] R_W_addr;
logic [`DRAM_DATA_BITS-1:0] write_data;
logic [3:0] WEn_to_DRAM_FSM;
logic R_W_finish;

DRAM_slave_FSM DRAM_slave_fsm(
    .ACLK(ACLK),
    .ARESETn(ARESETn),
    .AWID_S(AWID_S5),
    .AWADDR_S(AWADDR_S5),    
    .AWLEN_S(AWLEN_S5),       
    .AWSIZE_S(AWSIZE_S5),       
    .AWBURST_S(AWBURST_S5),    
    .AWVALID_S(AWVALID_S5),
    .AWREADY_S(AWREADY_S5),    
    .WDATA_S(WDATA_S5),
    .WSTRB_S(WSTRB_S5),       
    .WLAST_S(WLAST_S5),       
    .WVALID_S(WVALID_S5),      
    .WREADY_S(WREADY_S5),      
    .BID_S(BID_S5),
    .BRESP_S(BRESP_S5),       
    .BVALID_S(BVALID_S5),       
    .BREADY_S(BREADY_S5),
    .ARID_S(ARID_S5),     
    .ARADDR_S(ARADDR_S5),       
    .ARLEN_S(ARLEN_S5),       
    .ARSIZE_S(ARSIZE_S5),       
    .ARBURST_S(ARBURST_S5),      
    .ARVALID_S(ARVALID_S5),      
    .ARREADY_S(ARREADY_S5),      
    .RID_S(RID_S5),
    .RDATA_S(RDATA_S5),       
    .RRESP_S(RRESP_S5),       
    .RLAST_S(RLAST_S5),       
    .RVALID_S(RVALID_S5),       
    .RREADY_S(RREADY_S5),
    .get_addr(get_addr),
    .read_data_valid(read_data_valid),
    .read_data(read_data),
    .DRAM_write_done(DRAM_write_done),
    .DRAM_idle(DRAM_idle),
    .chip_enable(chip_enable),
    .read_write_sel(read_write_sel),
    .R_W_addr(R_W_addr),
    .write_data(write_data),
    .WEn_to_DRAM_FSM(WEn_to_DRAM_FSM),
    .R_W_finish(R_W_finish)
);

DRAM_FSM DRAM_fsm(
    .ACLK(ACLK),
    .ARESETn(ARESETn),
    .DRAM_rdata(DRAM_Q),
    .DRAM_rdata_valid(DRAM_valid),
    .DRAM_CSn(DRAM_CSn),
    .DRAM_WEn(DRAM_WEn),
    .DRAM_RASn(DRAM_RASn),
    .DRAM_CASn(DRAM_CASn),
    .DRAM_addr(DRAM_A),
    .DRAM_wdata(DRAM_D),
    .chip_enable(chip_enable),
    .read_write_sel(read_write_sel),
    .R_W_addr(R_W_addr),
    .write_data(write_data),
    .WEn_to_DRAM_FSM(WEn_to_DRAM_FSM),
    .R_W_finish(R_W_finish),
    .get_addr(get_addr),
    .read_data_valid(read_data_valid),
    .read_data(read_data),
    .DRAM_write_done(DRAM_write_done),
    .DRAM_idle(DRAM_idle)
);

endmodule