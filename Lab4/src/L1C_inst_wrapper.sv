// `include "cache_IM_controlFSM.sv"
// `include "L1C_inst.sv"
// `include "CPU_IMmaster_FSM.sv"
// `include "../include/AXI_define.svh"
`include "../include/def.svh"

module L1C_inst_wrapper(
    input clk,
    input rst,

    // connect with CPU
    input [31:0] PC,
    output logic [31:0] cpu_INST,
    output logic INST_valid, // HW3's IM_handshake
    output logic cpu_IM_stall,

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

    // connect with cache DM control FSM
    input DM_stall
);

logic ARvalid;
logic [`AXI_ADDR_BITS-1:0] read_addr;
logic read_data_valid;
logic [`AXI_DATA_BITS-1:0] read_data;
logic Rlast;

logic hit;
logic [`AXI_DATA_BITS-1:0] read_data_C;  
logic [`AXI_ADDR_BITS-1:0] RW_addr_C;
logic [`AXI_DATA_BITS-1:0] write_data_C;
logic WEB_C; // LOW: write, HIGH: read
logic read_req_hit;
logic read_req_miss_last;

cache_IM_controlFSM cache_IM_controlFSM1(
    .clk(clk),
    .rst(~rst),
    .PC(PC),
    .cpu_INST(cpu_INST),
    .INST_valid(INST_valid), // HW3's IM_handshake
    .cpu_IM_stall(cpu_IM_stall),
    .ARvalid(ARvalid),
    .read_addr_M(read_addr), // also to cache L1C_inst
    .read_data_valid_M(read_data_valid),
    .read_data_M(read_data),
    .Rlast(Rlast),
    .hit(hit),
    .read_data_C(read_data_C),  
    .RW_addr_C(RW_addr_C),
    .write_data_C(write_data_C),
    .WEB_C(WEB_C), // LOW: write, HIGH: read
    .read_req_hit(read_req_hit),
    .read_req_miss_last(read_req_miss_last),
    .DM_stall(DM_stall)
);

L1C_inst L1C_inst1(
  .clk(clk),
  .rst(~rst),
  .RW_addr_C(RW_addr_C),
  .write_data_C(write_data_C),
  .WEB_C(WEB_C),
  .read_req_hit(read_req_hit),
  .read_req_miss_last(read_req_miss_last),
  .hit(hit),
  .read_data_C(read_data_C)
);

CPU_IMmaster_FSM CPU_IMmaster_FSM1(
    .ACLK(clk),
    .ARESETn(rst),
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
    .read_data_valid(read_data_valid),
    .read_data(read_data),
    .Rlast(Rlast)
);

endmodule