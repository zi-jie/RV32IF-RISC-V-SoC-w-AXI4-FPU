// `include "cache_DM_controlFSM.sv"
// `include "L1C_data.sv"
// `include "CPU_DMmaster_FSM.sv"
// `include "../include/AXI_define.svh"
`include "../include/def.svh"

module L1C_data_wrapper(
    input clk,
    input rst,

    // connect with CPU
    input [31:0] DM_A,
    input [31:0] DM_DI,
    input [3:0] DM_BWEB,
    output logic [31:0] DM_DO,
    output logic cpu_DM_stall,
    input [1:0] cpu_DM_next_RW,

    // AXI write channel
    output logic [`AXI_ID_BITS-1:0] AWID_M,
    output logic [`AXI_ADDR_BITS-1:0] AWADDR_M,
    output logic [`AXI_LEN_BITS-1:0] AWLEN_M,
    output logic [`AXI_SIZE_BITS-1:0] AWSIZE_M,
    output logic [1:0] AWBURST_M,
    output logic AWVALID_M,
    input AWREADY_M,		
    output logic [`AXI_DATA_BITS-1:0] WDATA_M,     
    output logic [`AXI_STRB_BITS-1:0] WSTRB_M, 
    output logic WLAST_M,
    output logic WVALID_M,
    input WREADY_M,
    input [`AXI_ID_BITS-1:0] BID_M,
    input [1:0] BRESP_M,
    input BVALID_M,
    output logic BREADY_M,

    // AXI read channel
    output logic [`AXI_ID_BITS-1:0] ARID_M,
    output logic [`AXI_ADDR_BITS-1:0] ARADDR_M,
    output logic [`AXI_LEN_BITS-1:0] ARLEN_M,
    output logic [`AXI_SIZE_BITS-1:0] ARSIZE_M,
    output logic [1:0] ARBURST_M,
    output logic ARVALID_M,
    input ARREADY_M,
    input [`AXI_ID_BITS-1:0] RID_M,		
    input [`AXI_DATA_BITS-1:0] RDATA_M,
    input [1:0] RRESP_M,
    input RLAST_M,
    input RVALID_M,
    output logic RREADY_M,

    // connect with cache IM control FSM
    input IM_stall
);

logic ARvalid;
logic [`AXI_ADDR_BITS-1:0] read_addr;
logic AWvalid;
logic [`AXI_ADDR_BITS-1:0] write_addr;
logic [`AXI_DATA_BITS-1:0] write_data;
logic [`AXI_STRB_BITS-1:0] write_bweb;
logic read_data_valid;
logic [`AXI_DATA_BITS-1:0] read_data;
logic Rlast;
logic write_done;

logic [`AXI_ADDR_BITS-1:0] RW_addr_C;
logic [`AXI_DATA_BITS-1:0] write_data_C;
logic [3:0] WEB_C;
logic read_req_hit;
logic read_req_miss_last;
logic write_req_hit;
logic hit;
logic [`AXI_DATA_BITS-1:0] read_data_C;

cache_DM_controlFSM cache_DM_controlFSM1(
    .clk(clk),
    .rst(~rst),
    .DM_A(DM_A),
    .DM_DI(DM_DI),
    .DM_BWEB(DM_BWEB),
    .DM_DO(DM_DO),
    .cpu_DM_stall(cpu_DM_stall),
    .cpu_DM_next_RW(cpu_DM_next_RW),
    .ARvalid(ARvalid),
    .read_addr_M(read_addr), // also to cache L1C_inst
    .AWvalid(AWvalid),
    .write_addr_M(write_addr),
    .write_data_M(write_data),
    .bweb_M(write_bweb),
    .read_data_valid_M(read_data_valid),
    .read_data_M(read_data),
    .Rlast(Rlast),
    .AXI_write_done(write_done),
    .hit(hit),
    .read_data_C(read_data_C),  
    .RW_addr_C(RW_addr_C),
    .write_data_C(write_data_C),
    .WEB_C(WEB_C), // LOW: write, HIGH: read
    .read_req_hit(read_req_hit),
    .read_req_miss_last(read_req_miss_last),
    .write_req_hit(write_req_hit),
    .IM_stall(IM_stall)
);

L1C_data L1C_data1(
  .clk(clk),
  .rst(~rst),
  .RW_addr_C(RW_addr_C),
  .write_data_C(write_data_C),
  .WEB_C(WEB_C),
  .read_req_hit(read_req_hit),
  .read_req_miss_last(read_req_miss_last),
  .write_req_hit(write_req_hit),
  .hit(hit),
  .read_data_C(read_data_C)
);

CPU_DMmaster_FSM CPU_DMmaster_FSM1(
    .ACLK(clk),
    .ARESETn(rst),
    .AWID_M(AWID_M),
    .AWADDR_M(AWADDR_M),
    .AWLEN_M(AWLEN_M),
    .AWSIZE_M(AWSIZE_M),
    .AWBURST_M(AWBURST_M),
    .AWVALID_M(AWVALID_M),
    .AWREADY_M(AWREADY_M),		
    .WDATA_M(WDATA_M),     
    .WSTRB_M(WSTRB_M), 
    .WLAST_M(WLAST_M),
    .WVALID_M(WVALID_M),
    .WREADY_M(WREADY_M),
    .BID_M(BID_M),
    .BRESP_M(BRESP_M),
    .BVALID_M(BVALID_M),
    .BREADY_M(BREADY_M),
    .ARID_M(ARID_M),
    .ARADDR_M(ARADDR_M),
    .ARLEN_M(ARLEN_M),
    .ARSIZE_M(ARSIZE_M),
    .ARBURST_M(ARBURST_M),
    .ARVALID_M(ARVALID_M),
    .ARREADY_M(ARREADY_M),
    .RID_M(RID_M),		
    .RDATA_M(RDATA_M),
    .RRESP_M(RRESP_M),
    .RLAST_M(RLAST_M),
    .RVALID_M(RVALID_M),
    .RREADY_M(RREADY_M),
    .ARvalid(ARvalid),
    .read_addr(read_addr),
    .AWvalid(AWvalid),
    .write_addr(write_addr),
    .write_data(write_data),
    .write_bweb(write_bweb),
    .read_data_valid(read_data_valid),
    .read_data(read_data),
    .Rlast(Rlast),
    .write_done(write_done)
);

endmodule