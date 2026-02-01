// `include "CPU.sv"
// `include "L1C_inst_wrapper.sv"
// `include "L1C_data_wrapper.sv"
// `include "../include/AXI_define.svh"
`include "../include/def.svh"

module CPU_wrapper (
    input  logic                        ACLK,
    input  logic                        ARESETn,
    // HW3 new
    input  logic                        DMA_interrupt,
    input  logic                        WDT_interrupt,
    input  logic                        DLA_interrupt,
    // Master interface 1 (AW channel)
    output logic [`AXI_ID_BITS-1:0]     AWID_M1,
    output logic [`AXI_ADDR_BITS-1:0]   AWADDR_M1,
    output logic [`AXI_LEN_BITS-1:0]    AWLEN_M1,
    output logic [`AXI_SIZE_BITS-1:0]   AWSIZE_M1,
    output logic [1:0]                  AWBURST_M1,
    output logic                        AWVALID_M1,
    input  logic                        AWREADY_M1,
    // Master interface 1 (W channel)
    output logic [`AXI_DATA_BITS-1:0]   WDATA_M1,
    output logic [`AXI_STRB_BITS-1:0]   WSTRB_M1,
    output logic                        WLAST_M1,
    output logic                        WVALID_M1,
    input  logic                        WREADY_M1,
    // Master interface 1 (B channel)
    input  logic [`AXI_ID_BITS-1:0]     BID_M1,
    input  logic [1:0]                  BRESP_M1,
    input  logic                        BVALID_M1,
    output logic                        BREADY_M1,
    // Master interface 0 (AR channel)
    output logic [`AXI_ID_BITS-1:0]     ARID_M0,
    output logic [`AXI_ADDR_BITS-1:0]   ARADDR_M0,
    output logic [`AXI_LEN_BITS-1:0]    ARLEN_M0,
    output logic [`AXI_SIZE_BITS-1:0]   ARSIZE_M0,
    output logic [1:0]                  ARBURST_M0,
    output logic                        ARVALID_M0,
    input  logic                        ARREADY_M0,
    // Master interface 0 (R channel)
    input  logic [`AXI_ID_BITS-1:0]     RID_M0,
    input  logic [`AXI_DATA_BITS-1:0]   RDATA_M0,
    input  logic [1:0]                  RRESP_M0,
    input  logic                        RLAST_M0,
    input  logic                        RVALID_M0,
    output logic                        RREADY_M0,
    // Master interface 1 (AR channel)
    output logic [`AXI_ID_BITS-1:0]     ARID_M1,
    output logic [`AXI_ADDR_BITS-1:0]   ARADDR_M1,
    output logic [`AXI_LEN_BITS-1:0]    ARLEN_M1,
    output logic [`AXI_SIZE_BITS-1:0]   ARSIZE_M1,
    output logic [1:0]                  ARBURST_M1,
    output logic                        ARVALID_M1,
    input  logic                        ARREADY_M1,
    // Master interface 1 (R channel)
    input  logic [`AXI_ID_BITS-1:0]     RID_M1,
    input  logic [`AXI_DATA_BITS-1:0]   RDATA_M1,
    input  logic [1:0]                  RRESP_M1,
    input  logic                        RLAST_M1,
    input  logic                        RVALID_M1,
    output logic                        RREADY_M1
);

logic cpu_IM_handshake;
logic cpu_IM_stall, cpu_DM_stall;
logic [31:0] cpu_INST;
logic [31:0] cpu_DM_DI, cpu_DM_DO;
logic [31:0] cpu_DM_A;
logic [31:0] cpu_PC;
logic [3:0] cpu_DM_BWEB;
logic [1:0] cpu_DM_next_RW;

CPU CPU1(
    .clk(ACLK),
    .rst(~ARESETn),
    .DMA_interrupt(DMA_interrupt),
    .WDT_interrupt(WDT_interrupt),
    .DLA_interrupt(DLA_interrupt),
    .IM_stall(cpu_IM_stall),
    .DM_stall(cpu_DM_stall),
    .IM_handshake(cpu_IM_handshake),
    .INST(cpu_INST), 
    .DM_DI(cpu_DM_DI),
    .DM_A(cpu_DM_A),
    .PC(cpu_PC), // IM Address 
    .DM_DO(cpu_DM_DO),
    .DM_BWEB(cpu_DM_BWEB),
    .DM_next_RW(cpu_DM_next_RW)
);

L1C_inst_wrapper L1C_inst_wrapper1(
    .clk(ACLK),
    .rst(ARESETn),
    .PC(cpu_PC),
    .cpu_INST(cpu_INST),
    .INST_valid(cpu_IM_handshake), // HW3's IM_handshake
    .cpu_IM_stall(cpu_IM_stall),
    .ARID_M(ARID_M0),
    .ARADDR_M(ARADDR_M0),
    .ARLEN_M(ARLEN_M0),
    .ARSIZE_M(ARSIZE_M0),
    .ARBURST_M(ARBURST_M0),
    .ARVALID_M(ARVALID_M0),
    .ARREADY_M(ARREADY_M0),
    .RID_M(RID_M0),		
    .RDATA_M(RDATA_M0),
    .RRESP_M(RRESP_M0),
    .RLAST_M(RLAST_M0),
    .RVALID_M(RVALID_M0),
    .RREADY_M(RREADY_M0),
    .DM_stall(cpu_DM_stall)
);

L1C_data_wrapper L1C_data_wrapper1(
    .clk(ACLK),
    .rst(ARESETn),
    .DM_A(cpu_DM_A),
    .DM_DI(cpu_DM_DI),
    .DM_BWEB(cpu_DM_BWEB),
    .DM_DO(cpu_DM_DO),
    .cpu_DM_stall(cpu_DM_stall),
    .cpu_DM_next_RW(cpu_DM_next_RW),
    .AWID_M(AWID_M1),
    .AWADDR_M(AWADDR_M1),
    .AWLEN_M(AWLEN_M1),
    .AWSIZE_M(AWSIZE_M1),
    .AWBURST_M(AWBURST_M1),
    .AWVALID_M(AWVALID_M1),
    .AWREADY_M(AWREADY_M1),		
    .WDATA_M(WDATA_M1),     
    .WSTRB_M(WSTRB_M1), 
    .WLAST_M(WLAST_M1),
    .WVALID_M(WVALID_M1),
    .WREADY_M(WREADY_M1),
    .BID_M(BID_M1),
    .BRESP_M(BRESP_M1),
    .BVALID_M(BVALID_M1),
    .BREADY_M(BREADY_M1),
    .ARID_M(ARID_M1),
    .ARADDR_M(ARADDR_M1),
    .ARLEN_M(ARLEN_M1),
    .ARSIZE_M(ARSIZE_M1),
    .ARBURST_M(ARBURST_M1),
    .ARVALID_M(ARVALID_M1),
    .ARREADY_M(ARREADY_M1),
    .RID_M(RID_M1),		
    .RDATA_M(RDATA_M1),
    .RRESP_M(RRESP_M1),
    .RLAST_M(RLAST_M1),
    .RVALID_M(RVALID_M1),
    .RREADY_M(RREADY_M1),
    .IM_stall(cpu_IM_stall)
);

endmodule