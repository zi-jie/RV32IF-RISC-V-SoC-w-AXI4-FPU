`include "../include/def.svh"

module top(
  input  logic           cpu_clk,
  input  logic           axi_clk,
  input  logic           rom_clk,
  input  logic           dram_clk,
  input  logic           cpu_rst,
  input  logic           axi_rst,
  input  logic           rom_rst,
  input  logic           dram_rst,
  input  logic [   31:0] ROM_out,
  input  logic [   31:0] DRAM_Q,
  output logic           ROM_read,
  output logic           ROM_enable,
  output logic [   11:0] ROM_address,
  output logic           DRAM_CSn,
  output logic [    3:0] DRAM_WEn,
  output logic           DRAM_RASn,
  output logic           DRAM_CASn,
  output logic [   10:0] DRAM_A,
  output logic [   31:0] DRAM_D,
  input  logic           DRAM_valid
);

logic DMA_interrupt;
logic WDT_interrupt;
logic DLA_interrupt;

/* Master */
// Master 1: AW
logic [`AXI_ID_BITS-1:0]    AWID_M1;
logic [`AXI_ADDR_BITS-1:0]  AWADDR_M1;
logic [`AXI_LEN_BITS-1:0]   AWLEN_M1;
logic [`AXI_SIZE_BITS-1:0]  AWSIZE_M1;
logic [1:0]                 AWBURST_M1;
logic                       AWVALID_M1;
logic                       AWREADY_M1;
// Master 1: W
logic [`AXI_DATA_BITS-1:0]  WDATA_M1;
logic [`AXI_STRB_BITS-1:0]  WSTRB_M1;
logic                       WLAST_M1;
logic                       WVALID_M1;
logic                       WREADY_M1;
logic [`AXI_ID_BITS-1:0]    BID_M1;
logic [1:0]                 BRESP_M1;
logic                       BVALID_M1;
logic                       BREADY_M1;
// Master 0: AR
logic [`AXI_ID_BITS-1:0]    ARID_M0;
logic [`AXI_ADDR_BITS-1:0]  ARADDR_M0;
logic [`AXI_LEN_BITS-1:0]   ARLEN_M0;
logic [`AXI_SIZE_BITS-1:0]  ARSIZE_M0;
logic [1:0]                 ARBURST_M0;
logic                       ARVALID_M0;
logic                       ARREADY_M0;
// Master 0: R
logic [`AXI_ID_BITS-1:0]    RID_M0;
logic [`AXI_DATA_BITS-1:0]  RDATA_M0;
logic [1:0]                 RRESP_M0;
logic                       RLAST_M0;
logic                       RVALID_M0;
logic                       RREADY_M0;
// Master 1: AR
logic [`AXI_ID_BITS-1:0]    ARID_M1;
logic [`AXI_ADDR_BITS-1:0]  ARADDR_M1;
logic [`AXI_LEN_BITS-1:0]   ARLEN_M1;
logic [`AXI_SIZE_BITS-1:0]  ARSIZE_M1;
logic [1:0]                 ARBURST_M1;
logic                       ARVALID_M1;
logic                       ARREADY_M1;
// Master 1: R
logic [`AXI_ID_BITS-1:0]    RID_M1;
logic [`AXI_DATA_BITS-1:0]  RDATA_M1;
logic [1:0]                 RRESP_M1;
logic                       RLAST_M1;
logic                       RVALID_M1;
logic                       RREADY_M1;

/* Master 2 */
// Master 2 (DMA): AW
logic [`AXI_ID_BITS-1:0]    AWID_M2;
logic [`AXI_ADDR_BITS-1:0]  AWADDR_M2;
logic [`AXI_LEN_BITS-1:0]   AWLEN_M2;
logic [`AXI_SIZE_BITS-1:0]  AWSIZE_M2;
logic [1:0]                 AWBURST_M2;
logic                       AWVALID_M2;
logic                       AWREADY_M2;
// Master 2 (DMA): W
logic [`AXI_DATA_BITS-1:0]  WDATA_M2;
logic [`AXI_STRB_BITS-1:0]  WSTRB_M2;
logic                       WLAST_M2;
logic                       WVALID_M2;
logic                       WREADY_M2;
logic [`AXI_ID_BITS-1:0]    BID_M2;
logic [1:0]                 BRESP_M2;
logic                       BVALID_M2;
logic                       BREADY_M2;
// Master 2 (DMA): AR
logic [`AXI_ID_BITS-1:0]    ARID_M2;
logic [`AXI_ADDR_BITS-1:0]  ARADDR_M2;
logic [`AXI_LEN_BITS-1:0]   ARLEN_M2;
logic [`AXI_SIZE_BITS-1:0]  ARSIZE_M2;
logic [1:0]                 ARBURST_M2;
logic                       ARVALID_M2;
logic                       ARREADY_M2;
// Master 2 (DMA): R
logic [`AXI_ID_BITS-1:0]    RID_M2;
logic [`AXI_DATA_BITS-1:0]  RDATA_M2;
logic [1:0]                 RRESP_M2;
logic                       RLAST_M2;
logic                       RVALID_M2;
logic                       RREADY_M2;

/* Slave */
// Slave 1: AW
logic [`AXI_IDS_BITS-1:0]   AWID_S1;
logic [`AXI_ADDR_BITS-1:0]  AWADDR_S1;
logic [`AXI_LEN_BITS-1:0]   AWLEN_S1;
logic [`AXI_SIZE_BITS-1:0]  AWSIZE_S1;
logic [1:0]                 AWBURST_S1;
logic                       AWVALID_S1;
logic                       AWREADY_S1;
// Slave 1: W
logic [`AXI_DATA_BITS-1:0]  WDATA_S1;
logic [`AXI_STRB_BITS-1:0]  WSTRB_S1;
logic                       WLAST_S1;
logic                       WVALID_S1;
logic                       WREADY_S1;
// Slave 1: B
logic [`AXI_IDS_BITS-1:0]   BID_S1;
logic [1:0]                 BRESP_S1;
logic                       BVALID_S1;
logic                       BREADY_S1;
// Slave 2: AW
logic [`AXI_IDS_BITS-1:0]   AWID_S2;
logic [`AXI_ADDR_BITS-1:0]  AWADDR_S2;
logic [`AXI_LEN_BITS-1:0]   AWLEN_S2;
logic [`AXI_SIZE_BITS-1:0]  AWSIZE_S2;
logic [1:0]                 AWBURST_S2;
logic                       AWVALID_S2;
logic                       AWREADY_S2;
// Slave 2: W   
logic [`AXI_DATA_BITS-1:0]  WDATA_S2;
logic [`AXI_STRB_BITS-1:0]  WSTRB_S2;
logic                       WLAST_S2;
logic                       WVALID_S2;
logic                       WREADY_S2;
// Slave 2: B
logic [`AXI_IDS_BITS-1:0]   BID_S2;
logic [1:0]                 BRESP_S2;
logic                       BVALID_S2;
logic                       BREADY_S2;
// Slave 1: AR
logic [`AXI_IDS_BITS-1:0]   ARID_S1;
logic [`AXI_ADDR_BITS-1:0]  ARADDR_S1;
logic [`AXI_LEN_BITS-1:0]   ARLEN_S1;
logic [`AXI_SIZE_BITS-1:0]  ARSIZE_S1;
logic [1:0]                 ARBURST_S1;
logic                       ARVALID_S1;
logic                       ARREADY_S1;
// Slave 1: R
logic [`AXI_IDS_BITS-1:0]   RID_S1;
logic [`AXI_DATA_BITS-1:0]  RDATA_S1;
logic [1:0]                 RRESP_S1;
logic                       RLAST_S1;
logic                       RVALID_S1;
logic                       RREADY_S1;
// Slave 2: AR
logic [`AXI_IDS_BITS-1:0]   ARID_S2;
logic [`AXI_ADDR_BITS-1:0]  ARADDR_S2;
logic [`AXI_LEN_BITS-1:0]   ARLEN_S2;
logic [`AXI_SIZE_BITS-1:0]  ARSIZE_S2;
logic [1:0]                 ARBURST_S2;
logic                       ARVALID_S2;
logic                       ARREADY_S2;
// Slave 2: R
logic [`AXI_IDS_BITS-1:0]   RID_S2;
logic [`AXI_DATA_BITS-1:0]  RDATA_S2;
logic [1:0]                 RRESP_S2;
logic                       RLAST_S2;
logic                       RVALID_S2;
logic                       RREADY_S2;

/* Slave 0 */
// Slave 0 (ROM): AR
logic [`AXI_IDS_BITS-1:0]   ARID_S0;
logic [`AXI_ADDR_BITS-1:0]  ARADDR_S0;
logic [`AXI_LEN_BITS-1:0]   ARLEN_S0;
logic [`AXI_SIZE_BITS-1:0]  ARSIZE_S0;
logic [1:0]                 ARBURST_S0;
logic                       ARVALID_S0;
logic                       ARREADY_S0;
// Slave 0 (ROM): R
logic [`AXI_IDS_BITS-1:0]   RID_S0;
logic [`AXI_DATA_BITS-1:0]  RDATA_S0;
logic [1:0]                 RRESP_S0;
logic                       RLAST_S0;
logic                       RVALID_S0;
logic                       RREADY_S0;

/* Slave 3 */
// Slave 3 (DMA): AW
logic [`AXI_IDS_BITS-1:0]   AWID_S3;
logic [`AXI_ADDR_BITS-1:0]  AWADDR_S3;
logic [`AXI_LEN_BITS-1:0]   AWLEN_S3;
logic [`AXI_SIZE_BITS-1:0]  AWSIZE_S3;
logic [1:0]                 AWBURST_S3;
logic                       AWVALID_S3;
logic                       AWREADY_S3;
// Slave 3 (DMA): W   
logic [`AXI_DATA_BITS-1:0]  WDATA_S3;
logic [`AXI_STRB_BITS-1:0]  WSTRB_S3;
logic                       WLAST_S3;
logic                       WVALID_S3;
logic                       WREADY_S3;
// Slave 3 (DMA): B
logic [`AXI_IDS_BITS-1:0]   BID_S3;
logic [1:0]                 BRESP_S3;
logic                       BVALID_S3;
logic                       BREADY_S3;

/* Slave 4: WDT */ 
// AW
logic [`AXI_IDS_BITS-1:0]   AWID_S4;
logic [`AXI_ADDR_BITS-1:0]  AWADDR_S4;
logic [`AXI_LEN_BITS-1:0]   AWLEN_S4;
logic [`AXI_SIZE_BITS-1:0]  AWSIZE_S4;
logic [1:0]                 AWBURST_S4;
logic                       AWVALID_S4;
logic                       AWREADY_S4;
// W
logic [`AXI_DATA_BITS-1:0]  WDATA_S4;
logic [`AXI_STRB_BITS-1:0]  WSTRB_S4;
logic                       WLAST_S4;
logic                       WVALID_S4;
logic                       WREADY_S4;
// B
logic [`AXI_IDS_BITS-1:0]   BID_S4;
logic [1:0]                 BRESP_S4;
logic                       BVALID_S4;
logic                       BREADY_S4;
// AR
logic [`AXI_IDS_BITS-1:0]   ARID_S4;
logic [`AXI_ADDR_BITS-1:0]  ARADDR_S4;
logic [`AXI_LEN_BITS-1:0]   ARLEN_S4;
logic [`AXI_SIZE_BITS-1:0]  ARSIZE_S4;
logic [1:0]                 ARBURST_S4;
logic                       ARVALID_S4;
logic                       ARREADY_S4;
// R
logic [`AXI_IDS_BITS-1:0]   RID_S4;
logic [`AXI_DATA_BITS-1:0]  RDATA_S4;
logic [1:0]                 RRESP_S4;
logic                       RLAST_S4;
logic                       RVALID_S4;
logic                       RREADY_S4;

/* Slave 5: DRAM */
// Slave 5 (DRAM): AW
logic [`AXI_IDS_BITS-1:0]   AWID_S5;
logic [`AXI_ADDR_BITS-1:0]  AWADDR_S5;
logic [`AXI_LEN_BITS-1:0]   AWLEN_S5;
logic [`AXI_SIZE_BITS-1:0]  AWSIZE_S5;
logic [1:0]                 AWBURST_S5;
logic                       AWVALID_S5;
logic                       AWREADY_S5;
// Slave 5 (DRAM): W   
logic [`AXI_DATA_BITS-1:0]  WDATA_S5;
logic [`AXI_STRB_BITS-1:0]  WSTRB_S5;
logic                       WLAST_S5;
logic                       WVALID_S5;
logic                       WREADY_S5;
// Slave 5 (DRAM): B
logic [`AXI_IDS_BITS-1:0]   BID_S5;
logic [1:0]                 BRESP_S5;
logic                       BVALID_S5;
logic                       BREADY_S5;
// Slave 5 (DRAM): AR
logic [`AXI_IDS_BITS-1:0]   ARID_S5;
logic [`AXI_ADDR_BITS-1:0]  ARADDR_S5;
logic [`AXI_LEN_BITS-1:0]   ARLEN_S5;
logic [`AXI_SIZE_BITS-1:0]  ARSIZE_S5;
logic [1:0]                 ARBURST_S5;
logic                       ARVALID_S5;
logic                       ARREADY_S5;
// Slave 5 (DRAM): R
logic [`AXI_IDS_BITS-1:0]   RID_S5;
logic [`AXI_DATA_BITS-1:0]  RDATA_S5;
logic [1:0]                 RRESP_S5;
logic                       RLAST_S5;
logic                       RVALID_S5;
logic                       RREADY_S5;

/* Slave 6: DLA */
// Slave 6 (DLA): AW
logic [`AXI_IDS_BITS-1:0]   AWID_S6;
logic [`AXI_ADDR_BITS-1:0]  AWADDR_S6;
logic [`AXI_LEN_BITS-1:0]   AWLEN_S6;
logic [`AXI_SIZE_BITS-1:0]  AWSIZE_S6;
logic [1:0]                 AWBURST_S6;
logic                       AWVALID_S6;
logic                       AWREADY_S6;
// Slave 6 (DLA): W   
logic [`AXI_DATA_BITS-1:0]  WDATA_S6;
logic [`AXI_STRB_BITS-1:0]  WSTRB_S6;
logic                       WLAST_S6;
logic                       WVALID_S6;
logic                       WREADY_S6;
// Slave 6 (DLA): B
logic [`AXI_IDS_BITS-1:0]   BID_S6;
logic [1:0]                 BRESP_S6;
logic                       BVALID_S6;
logic                       BREADY_S6;
// Slave 6 (DLA): AR
logic [`AXI_IDS_BITS-1:0]   ARID_S6;
logic [`AXI_ADDR_BITS-1:0]  ARADDR_S6;
logic [`AXI_LEN_BITS-1:0]   ARLEN_S6;
logic [`AXI_SIZE_BITS-1:0]  ARSIZE_S6;
logic [1:0]                 ARBURST_S6;
logic                       ARVALID_S6;
logic                       ARREADY_S6;
// Slave 6 (DLA): R
logic [`AXI_IDS_BITS-1:0]   RID_S6;
logic [`AXI_DATA_BITS-1:0]  RDATA_S6;
logic [1:0]                 RRESP_S6;
logic                       RLAST_S6;
logic                       RVALID_S6;
logic                       RREADY_S6;

/* fifo signals */
logic wfull_m0_ar, rempty_m0_ar;
logic wfull_m0_r, rempty_m0_r;

logic wfull_m1_aw, rempty_m1_aw;
logic wfull_m1_w, rempty_m1_w;
logic wfull_m1_b, rempty_m1_b;
logic wfull_m1_ar, rempty_m1_ar;
logic wfull_m1_r, rempty_m1_r;

logic wfull_m2_aw, rempty_m2_aw;
logic wfull_m2_w, rempty_m2_w;
logic wfull_m2_b, rempty_m2_b;
logic wfull_m2_ar, rempty_m2_ar;
logic wfull_m2_r, rempty_m2_r;

logic wfull_s0_ar, rempty_s0_ar;
logic wfull_s0_r, rempty_s0_r;

logic wfull_s1_aw, rempty_s1_aw;
logic wfull_s1_w, rempty_s1_w;
logic wfull_s1_b, rempty_s1_b;
logic wfull_s1_ar, rempty_s1_ar;
logic wfull_s1_r, rempty_s1_r;

logic wfull_s2_aw, rempty_s2_aw;
logic wfull_s2_w, rempty_s2_w;
logic wfull_s2_b, rempty_s2_b;
logic wfull_s2_ar, rempty_s2_ar;
logic wfull_s2_r, rempty_s2_r;

logic wfull_s3_aw, rempty_s3_aw;
logic wfull_s3_w, rempty_s3_w;
logic wfull_s3_b, rempty_s3_b;

logic wfull_s4_aw, rempty_s4_aw;
logic wfull_s4_w, rempty_s4_w;
logic wfull_s4_b, rempty_s4_b;
logic wfull_s4_ar, rempty_s4_ar;
logic wfull_s4_r, rempty_s4_r;

logic wfull_s5_aw, rempty_s5_aw;
logic wfull_s5_w, rempty_s5_w;
logic wfull_s5_b, rempty_s5_b;
logic wfull_s5_ar, rempty_s5_ar;
logic wfull_s5_r, rempty_s5_r;

logic wfull_s6_aw, rempty_s6_aw;
logic wfull_s6_w, rempty_s6_w;
logic wfull_s6_b, rempty_s6_b;
logic wfull_s6_ar, rempty_s6_ar;
logic wfull_s6_r, rempty_s6_r;

// fifo AXI signals
logic [`AXI_ID_BITS-1:0]    ARID_M0_AXI;
logic [`AXI_ADDR_BITS-1:0]  ARADDR_M0_AXI;
logic [`AXI_LEN_BITS-1:0]   ARLEN_M0_AXI;
logic [`AXI_SIZE_BITS-1:0]  ARSIZE_M0_AXI;
logic [1:0]                 ARBURST_M0_AXI;
logic                       ARVALID_M0_AXI;
logic                       ARREADY_M0_AXI;
logic [`AXI_ID_BITS-1:0]    RID_M0_AXI;
logic [`AXI_DATA_BITS-1:0]  RDATA_M0_AXI;
logic [1:0]                 RRESP_M0_AXI;
logic                       RLAST_M0_AXI;
logic                       RVALID_M0_AXI;
logic                       RREADY_M0_AXI;

logic [`AXI_ID_BITS-1:0]    AWID_M1_AXI;
logic [`AXI_ADDR_BITS-1:0]  AWADDR_M1_AXI;
logic [`AXI_LEN_BITS-1:0]   AWLEN_M1_AXI;
logic [`AXI_SIZE_BITS-1:0]  AWSIZE_M1_AXI;
logic [1:0]                 AWBURST_M1_AXI;
logic                       AWVALID_M1_AXI;
logic                       AWREADY_M1_AXI;
logic [`AXI_DATA_BITS-1:0]  WDATA_M1_AXI;
logic [`AXI_STRB_BITS-1:0]  WSTRB_M1_AXI;
logic                       WLAST_M1_AXI;
logic                       WVALID_M1_AXI;
logic                       WREADY_M1_AXI;
logic [`AXI_ID_BITS-1:0]    BID_M1_AXI;
logic [1:0]                 BRESP_M1_AXI;
logic                       BVALID_M1_AXI;
logic                       BREADY_M1_AXI;
logic [`AXI_ID_BITS-1:0]    ARID_M1_AXI;
logic [`AXI_ADDR_BITS-1:0]  ARADDR_M1_AXI;
logic [`AXI_LEN_BITS-1:0]   ARLEN_M1_AXI;
logic [`AXI_SIZE_BITS-1:0]  ARSIZE_M1_AXI;
logic [1:0]                 ARBURST_M1_AXI;
logic                       ARVALID_M1_AXI;
logic                       ARREADY_M1_AXI;
logic [`AXI_ID_BITS-1:0]    RID_M1_AXI;
logic [`AXI_DATA_BITS-1:0]  RDATA_M1_AXI;
logic [1:0]                 RRESP_M1_AXI;
logic                       RLAST_M1_AXI;
logic                       RVALID_M1_AXI;
logic                       RREADY_M1_AXI;

logic [`AXI_ID_BITS-1:0]    AWID_M2_AXI;
logic [`AXI_ADDR_BITS-1:0]  AWADDR_M2_AXI;
logic [`AXI_LEN_BITS-1:0]   AWLEN_M2_AXI;
logic [`AXI_SIZE_BITS-1:0]  AWSIZE_M2_AXI;
logic [1:0]                 AWBURST_M2_AXI;
logic                       AWVALID_M2_AXI;
logic                       AWREADY_M2_AXI;
logic [`AXI_DATA_BITS-1:0]  WDATA_M2_AXI;
logic [`AXI_STRB_BITS-1:0]  WSTRB_M2_AXI;
logic                       WLAST_M2_AXI;
logic                       WVALID_M2_AXI;
logic                       WREADY_M2_AXI;
logic [`AXI_ID_BITS-1:0]    BID_M2_AXI;
logic [1:0]                 BRESP_M2_AXI;
logic                       BVALID_M2_AXI;
logic                       BREADY_M2_AXI;
logic [`AXI_ID_BITS-1:0]    ARID_M2_AXI;
logic [`AXI_ADDR_BITS-1:0]  ARADDR_M2_AXI;
logic [`AXI_LEN_BITS-1:0]   ARLEN_M2_AXI;
logic [`AXI_SIZE_BITS-1:0]  ARSIZE_M2_AXI;
logic [1:0]                 ARBURST_M2_AXI;
logic                       ARVALID_M2_AXI;
logic                       ARREADY_M2_AXI;
logic [`AXI_ID_BITS-1:0]    RID_M2_AXI;
logic [`AXI_DATA_BITS-1:0]  RDATA_M2_AXI;
logic [1:0]                 RRESP_M2_AXI;
logic                       RLAST_M2_AXI;
logic                       RVALID_M2_AXI;
logic                       RREADY_M2_AXI;

/* Slave 0 */
// Slave 0 (ROM): AR
logic [`AXI_IDS_BITS-1:0]   ARID_S0_AXI;
logic [`AXI_ADDR_BITS-1:0]  ARADDR_S0_AXI;
logic [`AXI_LEN_BITS-1:0]   ARLEN_S0_AXI;
logic [`AXI_SIZE_BITS-1:0]  ARSIZE_S0_AXI;
logic [1:0]                 ARBURST_S0_AXI;
logic                       ARVALID_S0_AXI;
logic                       ARREADY_S0_AXI;
// Slave 0 (ROM): R
logic [`AXI_IDS_BITS-1:0]   RID_S0_AXI;
logic [`AXI_DATA_BITS-1:0]  RDATA_S0_AXI;
logic [1:0]                 RRESP_S0_AXI;
logic                       RLAST_S0_AXI;
logic                       RVALID_S0_AXI;
logic                       RREADY_S0_AXI;

/* Slave 1 */
// AW
logic [`AXI_IDS_BITS-1:0]   AWID_S1_AXI;
logic [`AXI_ADDR_BITS-1:0]  AWADDR_S1_AXI;
logic [`AXI_LEN_BITS-1:0]   AWLEN_S1_AXI;
logic [`AXI_SIZE_BITS-1:0]  AWSIZE_S1_AXI;
logic [1:0]                 AWBURST_S1_AXI;
logic                       AWVALID_S1_AXI;
logic                       AWREADY_S1_AXI;
// W
logic [`AXI_DATA_BITS-1:0]  WDATA_S1_AXI;
logic [`AXI_STRB_BITS-1:0]  WSTRB_S1_AXI;
logic                       WLAST_S1_AXI;
logic                       WVALID_S1_AXI;
logic                       WREADY_S1_AXI;
// B
logic [`AXI_IDS_BITS-1:0]   BID_S1_AXI;
logic [1:0]                 BRESP_S1_AXI;
logic                       BVALID_S1_AXI;
logic                       BREADY_S1_AXI;
// AR
logic [`AXI_IDS_BITS-1:0]   ARID_S1_AXI;
logic [`AXI_ADDR_BITS-1:0]  ARADDR_S1_AXI;
logic [`AXI_LEN_BITS-1:0]   ARLEN_S1_AXI;
logic [`AXI_SIZE_BITS-1:0]  ARSIZE_S1_AXI;
logic [1:0]                 ARBURST_S1_AXI;
logic                       ARVALID_S1_AXI;
logic                       ARREADY_S1_AXI;
// R
logic [`AXI_IDS_BITS-1:0]   RID_S1_AXI;
logic [`AXI_DATA_BITS-1:0]  RDATA_S1_AXI;
logic [1:0]                 RRESP_S1_AXI;
logic                       RLAST_S1_AXI;
logic                       RVALID_S1_AXI;
logic                       RREADY_S1_AXI;

/* Slave 2 */
// AW
logic [`AXI_IDS_BITS-1:0]   AWID_S2_AXI;
logic [`AXI_ADDR_BITS-1:0]  AWADDR_S2_AXI;
logic [`AXI_LEN_BITS-1:0]   AWLEN_S2_AXI;
logic [`AXI_SIZE_BITS-1:0]  AWSIZE_S2_AXI;
logic [1:0]                 AWBURST_S2_AXI;
logic                       AWVALID_S2_AXI;
logic                       AWREADY_S2_AXI;
// W
logic [`AXI_DATA_BITS-1:0]  WDATA_S2_AXI;
logic [`AXI_STRB_BITS-1:0]  WSTRB_S2_AXI;
logic                       WLAST_S2_AXI;
logic                       WVALID_S2_AXI;
logic                       WREADY_S2_AXI;
// B
logic [`AXI_IDS_BITS-1:0]   BID_S2_AXI;
logic [1:0]                 BRESP_S2_AXI;
logic                       BVALID_S2_AXI;
logic                       BREADY_S2_AXI;
// AR
logic [`AXI_IDS_BITS-1:0]   ARID_S2_AXI;
logic [`AXI_ADDR_BITS-1:0]  ARADDR_S2_AXI;
logic [`AXI_LEN_BITS-1:0]   ARLEN_S2_AXI;
logic [`AXI_SIZE_BITS-1:0]  ARSIZE_S2_AXI;
logic [1:0]                 ARBURST_S2_AXI;
logic                       ARVALID_S2_AXI;
logic                       ARREADY_S2_AXI;
// R
logic [`AXI_IDS_BITS-1:0]   RID_S2_AXI;
logic [`AXI_DATA_BITS-1:0]  RDATA_S2_AXI;
logic [1:0]                 RRESP_S2_AXI;
logic                       RLAST_S2_AXI;
logic                       RVALID_S2_AXI;
logic                       RREADY_S2_AXI;

/* Slave 3:DMA */
// AW
logic [`AXI_IDS_BITS-1:0]   AWID_S3_AXI;
logic [`AXI_ADDR_BITS-1:0]  AWADDR_S3_AXI;
logic [`AXI_LEN_BITS-1:0]   AWLEN_S3_AXI;
logic [`AXI_SIZE_BITS-1:0]  AWSIZE_S3_AXI;
logic [1:0]                 AWBURST_S3_AXI;
logic                       AWVALID_S3_AXI;
logic                       AWREADY_S3_AXI;
// W
logic [`AXI_DATA_BITS-1:0]  WDATA_S3_AXI;
logic [`AXI_STRB_BITS-1:0]  WSTRB_S3_AXI;
logic                       WLAST_S3_AXI;
logic                       WVALID_S3_AXI;
logic                       WREADY_S3_AXI;
// B
logic [`AXI_IDS_BITS-1:0]   BID_S3_AXI;
logic [1:0]                 BRESP_S3_AXI;
logic                       BVALID_S3_AXI;
logic                       BREADY_S3_AXI;

/* aFIFO WDT */
// AW
logic [`AXI_IDS_BITS-1:0]   AWID_S4_AXI;
logic [`AXI_ADDR_BITS-1:0]  AWADDR_S4_AXI;
logic [`AXI_LEN_BITS-1:0]   AWLEN_S4_AXI;
logic [`AXI_SIZE_BITS-1:0]  AWSIZE_S4_AXI;
logic [1:0]                 AWBURST_S4_AXI;
logic                       AWVALID_S4_AXI;
logic                       AWREADY_S4_AXI;
// W
logic [`AXI_DATA_BITS-1:0]  WDATA_S4_AXI;
logic [`AXI_STRB_BITS-1:0]  WSTRB_S4_AXI;
logic                       WLAST_S4_AXI;
logic                       WVALID_S4_AXI;
logic                       WREADY_S4_AXI;
// B
logic [`AXI_IDS_BITS-1:0]   BID_S4_AXI;
logic [1:0]                 BRESP_S4_AXI;
logic                       BVALID_S4_AXI;
logic                       BREADY_S4_AXI;
// AR
logic [`AXI_IDS_BITS-1:0]   ARID_S4_AXI;
logic [`AXI_ADDR_BITS-1:0]  ARADDR_S4_AXI;
logic [`AXI_LEN_BITS-1:0]   ARLEN_S4_AXI;
logic [`AXI_SIZE_BITS-1:0]  ARSIZE_S4_AXI;
logic [1:0]                 ARBURST_S4_AXI;
logic                       ARVALID_S4_AXI;
logic                       ARREADY_S4_AXI;
// R
logic [`AXI_IDS_BITS-1:0]   RID_S4_AXI;
logic [`AXI_DATA_BITS-1:0]  RDATA_S4_AXI;
logic [1:0]                 RRESP_S4_AXI;
logic                       RLAST_S4_AXI;
logic                       RVALID_S4_AXI;
logic                       RREADY_S4_AXI;

/* Slave 5: DRAM */
// AW
logic [`AXI_IDS_BITS-1:0]   AWID_S5_AXI;
logic [`AXI_ADDR_BITS-1:0]  AWADDR_S5_AXI;
logic [`AXI_LEN_BITS-1:0]   AWLEN_S5_AXI;
logic [`AXI_SIZE_BITS-1:0]  AWSIZE_S5_AXI;
logic [1:0]                 AWBURST_S5_AXI;
logic                       AWVALID_S5_AXI;
logic                       AWREADY_S5_AXI;
// W
logic [`AXI_DATA_BITS-1:0]  WDATA_S5_AXI;
logic [`AXI_STRB_BITS-1:0]  WSTRB_S5_AXI;
logic                       WLAST_S5_AXI;
logic                       WVALID_S5_AXI;
logic                       WREADY_S5_AXI;
// B
logic [`AXI_IDS_BITS-1:0]   BID_S5_AXI;
logic [1:0]                 BRESP_S5_AXI;
logic                       BVALID_S5_AXI;
logic                       BREADY_S5_AXI;
// AR
logic [`AXI_IDS_BITS-1:0]   ARID_S5_AXI;
logic [`AXI_ADDR_BITS-1:0]  ARADDR_S5_AXI;
logic [`AXI_LEN_BITS-1:0]   ARLEN_S5_AXI;
logic [`AXI_SIZE_BITS-1:0]  ARSIZE_S5_AXI;
logic [1:0]                 ARBURST_S5_AXI;
logic                       ARVALID_S5_AXI;
logic                       ARREADY_S5_AXI;
// R
logic [`AXI_IDS_BITS-1:0]   RID_S5_AXI;
logic [`AXI_DATA_BITS-1:0]  RDATA_S5_AXI;
logic [1:0]                 RRESP_S5_AXI;
logic                       RLAST_S5_AXI;
logic                       RVALID_S5_AXI;
logic                       RREADY_S5_AXI;

/* Slave 6: DLA */
// AW
logic [`AXI_IDS_BITS-1:0]   AWID_S6_AXI;
logic [`AXI_ADDR_BITS-1:0]  AWADDR_S6_AXI;
logic [`AXI_LEN_BITS-1:0]   AWLEN_S6_AXI;
logic [`AXI_SIZE_BITS-1:0]  AWSIZE_S6_AXI;
logic [1:0]                 AWBURST_S6_AXI;
logic                       AWVALID_S6_AXI;
logic                       AWREADY_S6_AXI;
// W
logic [`AXI_DATA_BITS-1:0]  WDATA_S6_AXI;
logic [`AXI_STRB_BITS-1:0]  WSTRB_S6_AXI;
logic                       WLAST_S6_AXI;
logic                       WVALID_S6_AXI;
logic                       WREADY_S6_AXI;
// B
logic [`AXI_IDS_BITS-1:0]   BID_S6_AXI;
logic [1:0]                 BRESP_S6_AXI;
logic                       BVALID_S6_AXI;
logic                       BREADY_S6_AXI;
// AR
logic [`AXI_IDS_BITS-1:0]   ARID_S6_AXI;
logic [`AXI_ADDR_BITS-1:0]  ARADDR_S6_AXI;
logic [`AXI_LEN_BITS-1:0]   ARLEN_S6_AXI;
logic [`AXI_SIZE_BITS-1:0]  ARSIZE_S6_AXI;
logic [1:0]                 ARBURST_S6_AXI;
logic                       ARVALID_S6_AXI;
logic                       ARREADY_S6_AXI;
// R
logic [`AXI_IDS_BITS-1:0]   RID_S6_AXI;
logic [`AXI_DATA_BITS-1:0]  RDATA_S6_AXI;
logic [1:0]                 RRESP_S6_AXI;
logic                       RLAST_S6_AXI;
logic                       RVALID_S6_AXI;
logic                       RREADY_S6_AXI;

CPU_wrapper CPU_wrapper1(
	.ACLK(cpu_clk),
	.ARESETn(~cpu_rst),
	.DMA_interrupt(DMA_interrupt),
	.WDT_interrupt(WDT_interrupt),
	.DLA_interrupt(DLA_interrupt),
	.AWID_M1(AWID_M1),
	.AWADDR_M1(AWADDR_M1),
	.AWLEN_M1(AWLEN_M1),
	.AWSIZE_M1(AWSIZE_M1),
	.AWBURST_M1(AWBURST_M1),
	.AWVALID_M1(AWVALID_M1),
	.AWREADY_M1(AWREADY_M1),		
	.WDATA_M1(WDATA_M1),     
	.WSTRB_M1(WSTRB_M1), 
	.WLAST_M1(WLAST_M1),
	.WVALID_M1(WVALID_M1),
	.WREADY_M1(WREADY_M1),
	.BID_M1(BID_M1),
	.BRESP_M1(BRESP_M1),
	.BVALID_M1(BVALID_M1),
	.BREADY_M1(BREADY_M1), 
	.ARID_M0(ARID_M0),
	.ARADDR_M0(ARADDR_M0),
	.ARLEN_M0(ARLEN_M0),
	.ARSIZE_M0(ARSIZE_M0),
	.ARBURST_M0(ARBURST_M0),
	.ARVALID_M0(ARVALID_M0),
	.ARREADY_M0(ARREADY_M0),
	.RID_M0(RID_M0),		
	.RDATA_M0(RDATA_M0),
	.RRESP_M0(RRESP_M0),
	.RLAST_M0(RLAST_M0),
	.RVALID_M0(RVALID_M0),
	.RREADY_M0(RREADY_M0),
	.ARID_M1(ARID_M1),
	.ARADDR_M1(ARADDR_M1),
	.ARLEN_M1(ARLEN_M1),
	.ARSIZE_M1(ARSIZE_M1),
	.ARBURST_M1(ARBURST_M1),
	.ARVALID_M1(ARVALID_M1),
	.ARREADY_M1(ARREADY_M1),
	.RID_M1(RID_M1),
	.RDATA_M1(RDATA_M1),
	.RRESP_M1(RRESP_M1),
	.RLAST_M1(RLAST_M1),
	.RVALID_M1(RVALID_M1),
	.RREADY_M1(RREADY_M1)    
);

AXI AXI1(
	.ACLK(axi_clk),
	.ARESETn(~axi_rst),
	.AWID_M1(AWID_M1_AXI),
	.AWADDR_M1(AWADDR_M1_AXI),
	.AWLEN_M1(AWLEN_M1_AXI),
	.AWSIZE_M1(AWSIZE_M1_AXI),
	.AWBURST_M1(AWBURST_M1_AXI),
	.AWVALID_M1(AWVALID_M1_AXI),
	.AWREADY_M1(AWREADY_M1_AXI),
	.WDATA_M1(WDATA_M1_AXI),
	.WSTRB_M1(WSTRB_M1_AXI),
	.WLAST_M1(WLAST_M1_AXI),
	.WVALID_M1(WVALID_M1_AXI),
	.WREADY_M1(WREADY_M1_AXI),
	.BID_M1(BID_M1_AXI),
	.BRESP_M1(BRESP_M1_AXI),
	.BVALID_M1(BVALID_M1_AXI),
	.BREADY_M1(BREADY_M1_AXI),
	.AWID_M2(AWID_M2_AXI),
	.AWADDR_M2(AWADDR_M2_AXI),
	.AWLEN_M2(AWLEN_M2_AXI),
	.AWSIZE_M2(AWSIZE_M2_AXI),
	.AWBURST_M2(AWBURST_M2_AXI),
	.AWVALID_M2(AWVALID_M2_AXI),
	.AWREADY_M2(AWREADY_M2_AXI),
	.WDATA_M2(WDATA_M2_AXI),
	.WSTRB_M2(WSTRB_M2_AXI),
	.WLAST_M2(WLAST_M2_AXI),
	.WVALID_M2(WVALID_M2_AXI),
	.WREADY_M2(WREADY_M2_AXI),
	.BID_M2(BID_M2_AXI),
	.BRESP_M2(BRESP_M2_AXI),
	.BVALID_M2(BVALID_M2_AXI),
	.BREADY_M2(BREADY_M2_AXI),
	.ARID_M0(ARID_M0_AXI),
	.ARADDR_M0(ARADDR_M0_AXI),
	.ARLEN_M0(ARLEN_M0_AXI),
	.ARSIZE_M0(ARSIZE_M0_AXI),
	.ARBURST_M0(ARBURST_M0_AXI),
	.ARVALID_M0(ARVALID_M0_AXI),
	.ARREADY_M0(ARREADY_M0_AXI),
	.RID_M0(RID_M0_AXI),
	.RDATA_M0(RDATA_M0_AXI),
	.RRESP_M0(RRESP_M0_AXI),
	.RLAST_M0(RLAST_M0_AXI),
	.RVALID_M0(RVALID_M0_AXI),
	.RREADY_M0(RREADY_M0_AXI),
	.ARID_M1(ARID_M1_AXI),
	.ARADDR_M1(ARADDR_M1_AXI),
	.ARLEN_M1(ARLEN_M1_AXI),
	.ARSIZE_M1(ARSIZE_M1_AXI),
	.ARBURST_M1(ARBURST_M1_AXI),
	.ARVALID_M1(ARVALID_M1_AXI),
	.ARREADY_M1(ARREADY_M1_AXI),
	.RID_M1(RID_M1_AXI),
	.RDATA_M1(RDATA_M1_AXI),
	.RRESP_M1(RRESP_M1_AXI),
	.RLAST_M1(RLAST_M1_AXI),
	.RVALID_M1(RVALID_M1_AXI),
	.RREADY_M1(RREADY_M1_AXI),
	.ARID_M2(ARID_M2_AXI),
	.ARADDR_M2(ARADDR_M2_AXI),
	.ARLEN_M2(ARLEN_M2_AXI),
	.ARSIZE_M2(ARSIZE_M2_AXI),
	.ARBURST_M2(ARBURST_M2_AXI),
	.ARVALID_M2(ARVALID_M2_AXI),
	.ARREADY_M2(ARREADY_M2_AXI),
	.RID_M2(RID_M2_AXI),
	.RDATA_M2(RDATA_M2_AXI),
	.RRESP_M2(RRESP_M2_AXI),
	.RLAST_M2(RLAST_M2_AXI),
	.RVALID_M2(RVALID_M2_AXI),
	.RREADY_M2(RREADY_M2_AXI),
	.AWID_S1(AWID_S1_AXI),
	.AWADDR_S1(AWADDR_S1_AXI),
	.AWLEN_S1(AWLEN_S1_AXI),
	.AWSIZE_S1(AWSIZE_S1_AXI),
	.AWBURST_S1(AWBURST_S1_AXI),
	.AWVALID_S1(AWVALID_S1_AXI),
	.AWREADY_S1(AWREADY_S1_AXI),
	.WDATA_S1(WDATA_S1_AXI),
	.WSTRB_S1(WSTRB_S1_AXI),
	.WLAST_S1(WLAST_S1_AXI),
	.WVALID_S1(WVALID_S1_AXI),
	.WREADY_S1(WREADY_S1_AXI),
	.BID_S1(BID_S1_AXI),
	.BRESP_S1(BRESP_S1_AXI),
	.BVALID_S1(BVALID_S1_AXI),
	.BREADY_S1(BREADY_S1_AXI),
	.AWID_S2(AWID_S2_AXI),
	.AWADDR_S2(AWADDR_S2_AXI),
	.AWLEN_S2(AWLEN_S2_AXI),
	.AWSIZE_S2(AWSIZE_S2_AXI),
	.AWBURST_S2(AWBURST_S2_AXI),
	.AWVALID_S2(AWVALID_S2_AXI),
	.AWREADY_S2(AWREADY_S2_AXI),
	.WDATA_S2(WDATA_S2_AXI),
	.WSTRB_S2(WSTRB_S2_AXI),
	.WLAST_S2(WLAST_S2_AXI),
	.WVALID_S2(WVALID_S2_AXI),
	.WREADY_S2(WREADY_S2_AXI),
	.BID_S2(BID_S2_AXI),
	.BRESP_S2(BRESP_S2_AXI),
	.BVALID_S2(BVALID_S2_AXI),
	.BREADY_S2(BREADY_S2_AXI),
	.AWID_S3(AWID_S3_AXI),
	.AWADDR_S3(AWADDR_S3_AXI),
	.AWLEN_S3(AWLEN_S3_AXI),
	.AWSIZE_S3(AWSIZE_S3_AXI),
	.AWBURST_S3(AWBURST_S3_AXI),
	.AWVALID_S3(AWVALID_S3_AXI),
	.AWREADY_S3(AWREADY_S3_AXI),
	.WDATA_S3(WDATA_S3_AXI),
	.WSTRB_S3(WSTRB_S3_AXI),
	.WLAST_S3(WLAST_S3_AXI),
	.WVALID_S3(WVALID_S3_AXI),
	.WREADY_S3(WREADY_S3_AXI),
	.BID_S3(BID_S3_AXI),
	.BRESP_S3(BRESP_S3_AXI),
	.BVALID_S3(BVALID_S3_AXI),
	.BREADY_S3(BREADY_S3_AXI),
	.AWID_S4(AWID_S4_AXI),
	.AWADDR_S4(AWADDR_S4_AXI),
	.AWLEN_S4(AWLEN_S4_AXI),
	.AWSIZE_S4(AWSIZE_S4_AXI),
	.AWBURST_S4(AWBURST_S4_AXI),
	.AWVALID_S4(AWVALID_S4_AXI),
	.AWREADY_S4(AWREADY_S4_AXI),
	.WDATA_S4(WDATA_S4_AXI),
	.WSTRB_S4(WSTRB_S4_AXI),
	.WLAST_S4(WLAST_S4_AXI),
	.WVALID_S4(WVALID_S4_AXI),
	.WREADY_S4(WREADY_S4_AXI),
	.BID_S4(BID_S4_AXI),
	.BRESP_S4(BRESP_S4_AXI),
	.BVALID_S4(BVALID_S4_AXI),
	.BREADY_S4(BREADY_S4_AXI),
	.AWID_S5(AWID_S5_AXI),
	.AWADDR_S5(AWADDR_S5_AXI),
	.AWLEN_S5(AWLEN_S5_AXI),
	.AWSIZE_S5(AWSIZE_S5_AXI),
	.AWBURST_S5(AWBURST_S5_AXI),
	.AWVALID_S5(AWVALID_S5_AXI),
	.AWREADY_S5(AWREADY_S5_AXI),
	.WDATA_S5(WDATA_S5_AXI),
	.WSTRB_S5(WSTRB_S5_AXI),
	.WLAST_S5(WLAST_S5_AXI),
	.WVALID_S5(WVALID_S5_AXI),
	.WREADY_S5(WREADY_S5_AXI),
	.BID_S5(BID_S5_AXI),
	.BRESP_S5(BRESP_S5_AXI),
	.BVALID_S5(BVALID_S5_AXI),
	.BREADY_S5(BREADY_S5_AXI),
	.AWID_S6(AWID_S6_AXI),
	.AWADDR_S6(AWADDR_S6_AXI),
	.AWLEN_S6(AWLEN_S6_AXI),
	.AWSIZE_S6(AWSIZE_S6_AXI),
	.AWBURST_S6(AWBURST_S6_AXI),
	.AWVALID_S6(AWVALID_S6_AXI),
	.AWREADY_S6(AWREADY_S6_AXI),
	.WDATA_S6(WDATA_S6_AXI),
	.WSTRB_S6(WSTRB_S6_AXI),
	.WLAST_S6(WLAST_S6_AXI),
	.WVALID_S6(WVALID_S6_AXI),
	.WREADY_S6(WREADY_S6_AXI),
	.BID_S6(BID_S6_AXI),
	.BRESP_S6(BRESP_S6_AXI),
	.BVALID_S6(BVALID_S6_AXI),
	.BREADY_S6(BREADY_S6_AXI),
	.ARID_S0(ARID_S0_AXI),
	.ARADDR_S0(ARADDR_S0_AXI),
	.ARLEN_S0(ARLEN_S0_AXI),
	.ARSIZE_S0(ARSIZE_S0_AXI),
	.ARBURST_S0(ARBURST_S0_AXI),
	.ARVALID_S0(ARVALID_S0_AXI),
	.ARREADY_S0(ARREADY_S0_AXI),
	.RID_S0(RID_S0_AXI),
	.RDATA_S0(RDATA_S0_AXI),
	.RRESP_S0(RRESP_S0_AXI),
	.RLAST_S0(RLAST_S0_AXI),
	.RVALID_S0(RVALID_S0_AXI),
	.RREADY_S0(RREADY_S0_AXI),
	.ARID_S1(ARID_S1_AXI),
	.ARADDR_S1(ARADDR_S1_AXI),
	.ARLEN_S1(ARLEN_S1_AXI),
	.ARSIZE_S1(ARSIZE_S1_AXI),
	.ARBURST_S1(ARBURST_S1_AXI),
	.ARVALID_S1(ARVALID_S1_AXI),
	.ARREADY_S1(ARREADY_S1_AXI),
	.RID_S1(RID_S1_AXI),
	.RDATA_S1(RDATA_S1_AXI),
	.RRESP_S1(RRESP_S1_AXI),
	.RLAST_S1(RLAST_S1_AXI),
	.RVALID_S1(RVALID_S1_AXI),
	.RREADY_S1(RREADY_S1_AXI),
	.ARID_S2(ARID_S2_AXI),
	.ARADDR_S2(ARADDR_S2_AXI),
	.ARLEN_S2(ARLEN_S2_AXI),
	.ARSIZE_S2(ARSIZE_S2_AXI),
	.ARBURST_S2(ARBURST_S2_AXI),
	.ARVALID_S2(ARVALID_S2_AXI),
	.ARREADY_S2(ARREADY_S2_AXI),
	.RID_S2(RID_S2_AXI),
	.RDATA_S2(RDATA_S2_AXI),
	.RRESP_S2(RRESP_S2_AXI),
	.RLAST_S2(RLAST_S2_AXI),
	.RVALID_S2(RVALID_S2_AXI),
	.RREADY_S2(RREADY_S2_AXI),
	.ARID_S4(ARID_S4_AXI),
	.ARADDR_S4(ARADDR_S4_AXI),
	.ARLEN_S4(ARLEN_S4_AXI),
	.ARSIZE_S4(ARSIZE_S4_AXI),
	.ARBURST_S4(ARBURST_S4_AXI),
	.ARVALID_S4(ARVALID_S4_AXI),
	.ARREADY_S4(ARREADY_S4_AXI),
	.RID_S4(RID_S4_AXI),
	.RDATA_S4(RDATA_S4_AXI),
	.RRESP_S4(RRESP_S4_AXI),
	.RLAST_S4(RLAST_S4_AXI),
	.RVALID_S4(RVALID_S4_AXI),
	.RREADY_S4(RREADY_S4_AXI),
	.ARID_S5(ARID_S5_AXI),
	.ARADDR_S5(ARADDR_S5_AXI),
	.ARLEN_S5(ARLEN_S5_AXI),
	.ARSIZE_S5(ARSIZE_S5_AXI),
	.ARBURST_S5(ARBURST_S5_AXI),
	.ARVALID_S5(ARVALID_S5_AXI),
	.ARREADY_S5(ARREADY_S5_AXI),
	.RID_S5(RID_S5_AXI),
	.RDATA_S5(RDATA_S5_AXI),
	.RRESP_S5(RRESP_S5_AXI),
	.RLAST_S5(RLAST_S5_AXI),
	.RVALID_S5(RVALID_S5_AXI),
	.RREADY_S5(RREADY_S5_AXI),
	.ARID_S6(ARID_S6_AXI),
	.ARADDR_S6(ARADDR_S6_AXI),
	.ARLEN_S6(ARLEN_S6_AXI),
	.ARSIZE_S6(ARSIZE_S6_AXI),
	.ARBURST_S6(ARBURST_S6_AXI),
	.ARVALID_S6(ARVALID_S6_AXI),
	.ARREADY_S6(ARREADY_S6_AXI),
	.RID_S6(RID_S6_AXI),
	.RDATA_S6(RDATA_S6_AXI),
	.RRESP_S6(RRESP_S6_AXI),
	.RLAST_S6(RLAST_S6_AXI),
	.RVALID_S6(RVALID_S6_AXI),
	.RREADY_S6(RREADY_S6_AXI)
);

// Slave 0: ROM (only read)
ROM_wrapper ROM1(
    .ACLK(rom_clk),
    .ARESETn(~rom_rst),
    .ARID_S0(ARID_S0),     
    .ARADDR_S0(ARADDR_S0),       
    .ARLEN_S0(ARLEN_S0),       
    .ARSIZE_S0(ARSIZE_S0),       
    .ARBURST_S0(ARBURST_S0),      
    .ARVALID_S0(ARVALID_S0),      
    .ARREADY_S0(ARREADY_S0),      
    .RID_S0(RID_S0),
    .RDATA_S0(RDATA_S0),       
    .RRESP_S0(RRESP_S0),       
    .RLAST_S0(RLAST_S0),       
    .RVALID_S0(RVALID_S0),       
    .RREADY_S0(RREADY_S0),
    .ROM_out(ROM_out),
    .ROM_read(ROM_read),
    .ROM_enable(ROM_enable),
    .ROM_address(ROM_address)
);

// Slave 1
SRAM_wrapper IM1(
	.ACLK(cpu_clk),
	.ARESETn(~cpu_rst),
	.AWID_S(AWID_S1),
	.AWADDR_S(AWADDR_S1),    
	.AWLEN_S(AWLEN_S1),       
	.AWSIZE_S(AWSIZE_S1),       
	.AWBURST_S(AWBURST_S1),    
	.AWVALID_S(AWVALID_S1),
	.AWREADY_S(AWREADY_S1),    
	.WDATA_S(WDATA_S1),
	.WSTRB_S(WSTRB_S1),       
	.WLAST_S(WLAST_S1),       
	.WVALID_S(WVALID_S1),      
	.WREADY_S(WREADY_S1),      
	.BID_S(BID_S1),
	.BRESP_S(BRESP_S1),       
	.BVALID_S(BVALID_S1),       
	.BREADY_S(BREADY_S1),       
	.ARID_S(ARID_S1),     
	.ARADDR_S(ARADDR_S1),       
	.ARLEN_S(ARLEN_S1),       
	.ARSIZE_S(ARSIZE_S1),       
	.ARBURST_S(ARBURST_S1),      
	.ARVALID_S(ARVALID_S1),      
	.ARREADY_S(ARREADY_S1),      
	.RID_S(RID_S1),
	.RDATA_S(RDATA_S1),       
	.RRESP_S(RRESP_S1),       
	.RLAST_S(RLAST_S1),       
	.RVALID_S(RVALID_S1),       
	.RREADY_S(RREADY_S1)     
);

// Slave 2
SRAM_wrapper DM1(
	.ACLK(cpu_clk),
	.ARESETn(~cpu_rst),
	.AWID_S(AWID_S2),
	.AWADDR_S(AWADDR_S2),    
	.AWLEN_S(AWLEN_S2),       
	.AWSIZE_S(AWSIZE_S2),       
	.AWBURST_S(AWBURST_S2),    
	.AWVALID_S(AWVALID_S2),
	.AWREADY_S(AWREADY_S2),    
	.WDATA_S(WDATA_S2),
	.WSTRB_S(WSTRB_S2),       
	.WLAST_S(WLAST_S2),       
	.WVALID_S(WVALID_S2),      
	.WREADY_S(WREADY_S2),      
	.BID_S(BID_S2),
	.BRESP_S(BRESP_S2),       
	.BVALID_S(BVALID_S2),       
	.BREADY_S(BREADY_S2),       
	.ARID_S(ARID_S2),     
	.ARADDR_S(ARADDR_S2),       
	.ARLEN_S(ARLEN_S2),       
	.ARSIZE_S(ARSIZE_S2),       
	.ARBURST_S(ARBURST_S2),      
	.ARVALID_S(ARVALID_S2),      
	.ARREADY_S(ARREADY_S2),      
	.RID_S(RID_S2),
	.RDATA_S(RDATA_S2),       
	.RRESP_S(RRESP_S2),       
	.RLAST_S(RLAST_S2),       
	.RVALID_S(RVALID_S2),       
	.RREADY_S(RREADY_S2)   
);

// Slave 3: DMA (only write); Master 2
DMA_wrapper DMA1(
    .ACLK(cpu_clk),
    .ARESETn(~cpu_rst),
    .AWID_S3(AWID_S3), // Slave 3: only write channel
    .AWADDR_S3(AWADDR_S3),    
    .AWLEN_S3(AWLEN_S3),       
    .AWSIZE_S3(AWSIZE_S3),       
    .AWBURST_S3(AWBURST_S3),    
    .AWVALID_S3(AWVALID_S3),
    .AWREADY_S3(AWREADY_S3),    
    .WDATA_S3(WDATA_S3),
    .WSTRB_S3(WSTRB_S3),       
    .WLAST_S3(WLAST_S3),       
    .WVALID_S3(WVALID_S3),      
    .WREADY_S3(WREADY_S3),      
    .BID_S3(BID_S3),
    .BRESP_S3(BRESP_S3),       
    .BVALID_S3(BVALID_S3),       
    .BREADY_S3(BREADY_S3),
    .AWID_M2(AWID_M2),
    .AWADDR_M2(AWADDR_M2),
    .AWLEN_M2(AWLEN_M2),
    .AWSIZE_M2(AWSIZE_M2),
    .AWBURST_M2(AWBURST_M2),
    .AWVALID_M2(AWVALID_M2),
    .AWREADY_M2(AWREADY_M2),		
    .WDATA_M2(WDATA_M2),     
    .WSTRB_M2(WSTRB_M2), 
    .WLAST_M2(WLAST_M2),
    .WVALID_M2(WVALID_M2),
    .WREADY_M2(WREADY_M2),
    .BID_M2(BID_M2),
    .BRESP_M2(BRESP_M2),
    .BVALID_M2(BVALID_M2),
    .BREADY_M2(BREADY_M2), 
    .ARID_M2(ARID_M2),
    .ARADDR_M2(ARADDR_M2),
    .ARLEN_M2(ARLEN_M2),
    .ARSIZE_M2(ARSIZE_M2),
    .ARBURST_M2(ARBURST_M2),
    .ARVALID_M2(ARVALID_M2),
    .ARREADY_M2(ARREADY_M2),
    .RID_M2(RID_M2),		
    .RDATA_M2(RDATA_M2),
    .RRESP_M2(RRESP_M2),
    .RLAST_M2(RLAST_M2),
    .RVALID_M2(RVALID_M2),
    .RREADY_M2(RREADY_M2),
    .DMA_interrupt(DMA_interrupt) 
);

// Slave 4: WDT
WDT_wrapper WDT_wrapper1(
	.ACLK(cpu_clk),
	.ARESETn(~cpu_rst),
	.AWID_S(AWID_S4),
	.AWADDR_S(AWADDR_S4),    
	.AWLEN_S(AWLEN_S4),       
	.AWSIZE_S(AWSIZE_S4),       
	.AWBURST_S(AWBURST_S4),    
	.AWVALID_S(AWVALID_S4),
	.AWREADY_S(AWREADY_S4),    
	.WDATA_S(WDATA_S4),
	.WSTRB_S(WSTRB_S4),       
	.WLAST_S(WLAST_S4),       
	.WVALID_S(WVALID_S4),      
	.WREADY_S(WREADY_S4),      
	.BID_S(BID_S4),
	.BRESP_S(BRESP_S4),       
	.BVALID_S(BVALID_S4),       
	.BREADY_S(BREADY_S4),       
	.ARID_S(ARID_S4),     
	.ARADDR_S(ARADDR_S4),       
	.ARLEN_S(ARLEN_S4),       
	.ARSIZE_S(ARSIZE_S4),       
	.ARBURST_S(ARBURST_S4),      
	.ARVALID_S(ARVALID_S4),      
	.ARREADY_S(ARREADY_S4),      
	.RID_S(RID_S4),
	.RDATA_S(RDATA_S4),       
	.RRESP_S(RRESP_S4),       
	.RLAST_S(RLAST_S4),       
	.RVALID_S(RVALID_S4),       
	.RREADY_S(RREADY_S4),
	.clk2(rom_clk),
	.rst2(rom_rst),
	.WDT_interrupt(WDT_interrupt)    
);

// Slave 5: DRAM
DRAM_wrapper DRAM1(
    .ACLK(dram_clk),
    .ARESETn(~dram_rst),
    .AWID_S5(AWID_S5),
    .AWADDR_S5(AWADDR_S5),    
    .AWLEN_S5(AWLEN_S5),       
    .AWSIZE_S5(AWSIZE_S5),       
    .AWBURST_S5(AWBURST_S5),    
    .AWVALID_S5(AWVALID_S5),
    .AWREADY_S5(AWREADY_S5),    
    .WDATA_S5(WDATA_S5),
    .WSTRB_S5(WSTRB_S5),       
    .WLAST_S5(WLAST_S5),       
    .WVALID_S5(WVALID_S5),      
    .WREADY_S5(WREADY_S5),      
    .BID_S5(BID_S5),
    .BRESP_S5(BRESP_S5),       
    .BVALID_S5(BVALID_S5),       
    .BREADY_S5(BREADY_S5),
    .ARID_S5(ARID_S5),     
    .ARADDR_S5(ARADDR_S5),       
    .ARLEN_S5(ARLEN_S5),       
    .ARSIZE_S5(ARSIZE_S5),       
    .ARBURST_S5(ARBURST_S5),      
    .ARVALID_S5(ARVALID_S5),      
    .ARREADY_S5(ARREADY_S5),      
    .RID_S5(RID_S5),
    .RDATA_S5(RDATA_S5),       
    .RRESP_S5(RRESP_S5),       
    .RLAST_S5(RLAST_S5),       
    .RVALID_S5(RVALID_S5),       
    .RREADY_S5(RREADY_S5),
    .DRAM_Q(DRAM_Q),
    .DRAM_valid(DRAM_valid),
    .DRAM_CSn(DRAM_CSn),
    .DRAM_WEn(DRAM_WEn),
    .DRAM_RASn(DRAM_RASn),
    .DRAM_CASn(DRAM_CASn),
    .DRAM_A(DRAM_A),
    .DRAM_D(DRAM_D)
);

// Slave 6: DLA
DLA_top DLA_top1(
    .CPU_clk(cpu_clk),
    .CPU_rst(cpu_rst), 
    .DLA_clk(cpu_clk),
    .DLA_rst(cpu_rst),    
    .ARID(ARID_S6),
    .ARADDR(ARADDR_S6),
    .ARLEN(ARLEN_S6[3:0]),
    .ARSIZE(ARSIZE_S6),
    .ARBURST(ARBURST_S6),
    .ARVALID(ARVALID_S6),
    .RREADY(RREADY_S6),
    .AWID(AWID_S6),
    .AWADDR(AWADDR_S6),
    .AWLEN(AWLEN_S6[3:0]),
    .AWSIZE(AWSIZE_S6),
    .AWBURST(AWBURST_S6),
    .AWVALID(AWVALID_S6),
    .WDATA(WDATA_S6),
    .WSTRB(WSTRB_S6),
    .WLAST(WLAST_S6),
    .WVALID(WVALID_S6),
    .BREADY(BREADY_S6),
    .ARREADY(ARREADY_S6),
    .RID(RID_S6),
    .RDATA(RDATA_S6),
    .RRESP(RRESP_S6),
    .RLAST(RLAST_S6),
    .RVALID(RVALID_S6),
    .AWREADY(AWREADY_S6),
    .WREADY(WREADY_S6),
    .BID(BID_S6),
    .BRESP(BRESP_S6),
    .BVALID(BVALID_S6),
    .DLA_inpt(DLA_interrupt)
);

/* aFIFO */

/* aFIFO: CPU(m0) <-> AXI */
aFIFO_M_ARAW afifo_m0_ar (
	// cpu domain
	.wclk    (cpu_clk),           
	.wrst    (cpu_rst),           
	.wdata   ({ARID_M0, ARADDR_M0, ARLEN_M0, ARSIZE_M0, ARBURST_M0}),          
	.wpush   (ARVALID_M0 && !wfull_m0_ar), 
	.wfull   (wfull_m0_ar),             

	// axi domain
	.rclk    (axi_clk),           
	.rrst    (axi_rst),           
	.rdata   ({ARID_M0_AXI, ARADDR_M0_AXI, ARLEN_M0_AXI, ARSIZE_M0_AXI, ARBURST_M0_AXI}),        
	.rpop    (!rempty_m0_ar && ARREADY_M0_AXI), 
	.rempty  (rempty_m0_ar)             
);

assign ARREADY_M0     = !wfull_m0_ar;   // for CPU(M0)
assign ARVALID_M0_AXI = !rempty_m0_ar;  // for AXI

aFIFO_M_R afifo_m0_r (
	// axi domain
	.wclk    (axi_clk),           
	.wrst    (axi_rst),           
	.wdata   ({RID_M0_AXI, RDATA_M0_AXI, RRESP_M0_AXI, RLAST_M0_AXI}),          
	.wpush   (RVALID_M0_AXI && !wfull_m0_r), 
	.wfull   (wfull_m0_r),             

	// cpu domain
	.rclk    (cpu_clk),           
	.rrst    (cpu_rst),           
	.rdata   ({RID_M0, RDATA_M0, RRESP_M0, RLAST_M0}),        
	.rpop    (!rempty_m0_r && RREADY_M0), 
	.rempty  (rempty_m0_r)             
);

assign RREADY_M0_AXI = !wfull_m0_r;   // for CPU(M0)
assign RVALID_M0	 = !rempty_m0_r;    // for AXI


/* aFIFO: CPU(m1) <-> AXI */
aFIFO_M_ARAW afifo_m1_aw (
    // cpu domain
    .wclk    (cpu_clk),           
    .wrst    (cpu_rst),           
    .wdata   ({AWID_M1, AWADDR_M1, AWLEN_M1, AWSIZE_M1, AWBURST_M1}),          
    .wpush   (AWVALID_M1 && !wfull_m1_aw), 
    .wfull   (wfull_m1_aw),             

    // axi domain
    .rclk    (axi_clk),           
    .rrst    (axi_rst),           
    .rdata   ({AWID_M1_AXI, AWADDR_M1_AXI, AWLEN_M1_AXI, AWSIZE_M1_AXI, AWBURST_M1_AXI}),        
    .rpop    (!rempty_m1_aw && AWREADY_M1_AXI), 
    .rempty  (rempty_m1_aw)             
);

// have space / have data
assign AWREADY_M1     = !wfull_m1_aw;   // for CPU(M1)
assign AWVALID_M1_AXI = !rempty_m1_aw;  // for AXI

aFIFO_M_W afifo_m1_w (
    // cpu domain
    .wclk    (cpu_clk),           
    .wrst    (cpu_rst),           
    .wdata   ({WDATA_M1, WSTRB_M1, WLAST_M1}),          
    .wpush   (WVALID_M1 && !wfull_m1_w), 
    .wfull   (wfull_m1_w),             

    // axi domain
    .rclk    (axi_clk),           
    .rrst    (axi_rst),           
    .rdata   ({WDATA_M1_AXI, WSTRB_M1_AXI, WLAST_M1_AXI}),        
    .rpop    (!rempty_m1_w && WREADY_M1_AXI), 
    .rempty  (rempty_m1_w)             
);

assign WREADY_M1     = !wfull_m1_w;   // for CPU(M1)
assign WVALID_M1_AXI = !rempty_m1_w;  // for AXI

aFIFO_M_B afifo_m1_b (
	// axi domain
	.wclk    (axi_clk),           
	.wrst    (axi_rst),           
	.wdata   ({BID_M1_AXI, BRESP_M1_AXI}),          
	.wpush   (BVALID_M1_AXI && !wfull_m1_b), 
	.wfull   (wfull_m1_b),             

	// cpu domain
	.rclk    (cpu_clk),           
	.rrst    (cpu_rst),           
	.rdata   ({BID_M1, BRESP_M1}),        
	.rpop    (!rempty_m1_b && BREADY_M1), 
	.rempty  (rempty_m1_b)             
);

assign BREADY_M1_AXI     = !wfull_m1_b;    // for AXI
assign BVALID_M1		 = !rempty_m1_b;   // for CPU(M1)

aFIFO_M_ARAW afifo_m1_ar (
	// cpu domain
	.wclk    (cpu_clk),           
	.wrst    (cpu_rst),           
	.wdata   ({ARID_M1, ARADDR_M1, ARLEN_M1, ARSIZE_M1, ARBURST_M1}),          
	.wpush   (ARVALID_M1 && !wfull_m1_ar), 
	.wfull   (wfull_m1_ar),             

	// axi domain
	.rclk    (axi_clk),           
	.rrst    (axi_rst),           
	.rdata   ({ARID_M1_AXI, ARADDR_M1_AXI, ARLEN_M1_AXI, ARSIZE_M1_AXI, ARBURST_M1_AXI}),        
	.rpop    (!rempty_m1_ar && ARREADY_M1_AXI), 
	.rempty  (rempty_m1_ar)             
);

assign ARREADY_M1     = !wfull_m1_ar;   // for CPU(M1)
assign ARVALID_M1_AXI = !rempty_m1_ar;  // for AXI

aFIFO_M_R afifo_m1_r (
	// axi domain
	.wclk    (axi_clk),           
	.wrst    (axi_rst),           
	.wdata   ({RID_M1_AXI, RDATA_M1_AXI, RRESP_M1_AXI, RLAST_M1_AXI}),          
	.wpush   (RVALID_M1_AXI && !wfull_m1_r), 
	.wfull   (wfull_m1_r),             

	// cpu domain
	.rclk    (cpu_clk),           
	.rrst    (cpu_rst),           
	.rdata   ({RID_M1, RDATA_M1, RRESP_M1, RLAST_M1}),        
	.rpop    (!rempty_m1_r && RREADY_M1), 
	.rempty  (rempty_m1_r)             
);

assign RREADY_M1_AXI = !wfull_m1_r;   // for AXI
assign RVALID_M1     = !rempty_m1_r;  // for CPU(M1)

/* aFIFO: DMA(m2) <-> AXI */
aFIFO_M_ARAW afifo_m2_aw (
	// dma domain
	.wclk    (cpu_clk),           
	.wrst    (cpu_rst),           
	.wdata   ({AWID_M2, AWADDR_M2, AWLEN_M2, AWSIZE_M2, AWBURST_M2}),          
	.wpush   (AWVALID_M2 && !wfull_m2_aw), 
	.wfull   (wfull_m2_aw),             

	// axi domain
	.rclk    (axi_clk),           
	.rrst    (axi_rst),           
	.rdata   ({AWID_M2_AXI, AWADDR_M2_AXI, AWLEN_M2_AXI, AWSIZE_M2_AXI, AWBURST_M2_AXI}),        
	.rpop    (!rempty_m2_aw && AWREADY_M2_AXI), 
	.rempty  (rempty_m2_aw)             
);

assign AWREADY_M2     = !wfull_m2_aw;   // for DMA(M2)
assign AWVALID_M2_AXI = !rempty_m2_aw;  // for AXI

aFIFO_M_W afifo_m2_w (
	// dma domain
	.wclk    (cpu_clk),           
	.wrst    (cpu_rst),           
	.wdata   ({WDATA_M2, WSTRB_M2, WLAST_M2}),          
	.wpush   (WVALID_M2 && !wfull_m2_w), 
	.wfull   (wfull_m2_w),             

	// axi domain
	.rclk    (axi_clk),           
	.rrst    (axi_rst),           
	.rdata   ({WDATA_M2_AXI, WSTRB_M2_AXI, WLAST_M2_AXI}),        
	.rpop    (!rempty_m2_w && WREADY_M2_AXI), 
	.rempty  (rempty_m2_w)             
);

assign WREADY_M2     = !wfull_m2_w;   // for DMA(M2)
assign WVALID_M2_AXI = !rempty_m2_w;  // for AXI

aFIFO_M_B afifo_m2_b (
	// axi domain
	.wclk    (axi_clk),           
	.wrst    (axi_rst),           
	.wdata   ({BID_M2_AXI, BRESP_M2_AXI}),          
	.wpush   (BVALID_M2_AXI && !wfull_m2_b), 
	.wfull   (wfull_m2_b),             

	// dma domain
	.rclk    (cpu_clk),           
	.rrst    (cpu_rst),           
	.rdata   ({BID_M2, BRESP_M2}),        
	.rpop    (!rempty_m2_b && BREADY_M2), 
	.rempty  (rempty_m2_b)             
);

assign BREADY_M2_AXI = !wfull_m2_b;   // for DMA(M2)
assign BVALID_M2	 = !rempty_m2_b;    // for AXI

aFIFO_M_ARAW afifo_m2_ar (
	// dma domain
	.wclk    (cpu_clk),           
	.wrst    (cpu_rst),           
	.wdata   ({ARID_M2, ARADDR_M2, ARLEN_M2, ARSIZE_M2, ARBURST_M2}),          
	.wpush   (ARVALID_M2 && !wfull_m2_ar), 
	.wfull   (wfull_m2_ar),             

	// axi domain
	.rclk    (axi_clk),           
	.rrst    (axi_rst),           
	.rdata   ({ARID_M2_AXI, ARADDR_M2_AXI, ARLEN_M2_AXI, ARSIZE_M2_AXI, ARBURST_M2_AXI}),        
	.rpop    (!rempty_m2_ar && ARREADY_M2_AXI), 
	.rempty  (rempty_m2_ar)             
);

assign ARREADY_M2     = !wfull_m2_ar;   // for DMA(M2)
assign ARVALID_M2_AXI = !rempty_m2_ar;  // for AXI

aFIFO_M_R afifo_m2_r (
	// axi domain
	.wclk    (axi_clk),           
	.wrst    (axi_rst),           
	.wdata   ({RID_M2_AXI, RDATA_M2_AXI, RRESP_M2_AXI, RLAST_M2_AXI}),          
	.wpush   (RVALID_M2_AXI && !wfull_m2_r), 
	.wfull   (wfull_m2_r),             

	// dma domain
	.rclk    (cpu_clk),           
	.rrst    (cpu_rst),           
	.rdata   ({RID_M2, RDATA_M2, RRESP_M2, RLAST_M2}),        
	.rpop    (!rempty_m2_r && RREADY_M2), 
	.rempty  (rempty_m2_r)             
);

assign RREADY_M2_AXI = !wfull_m2_r;   // for AXI
assign RVALID_M2     = !rempty_m2_r;  // for DMA(M2)

/* Slave */

/* aFIFO: ROM(s0) <-> AXI */
// AR: AXI -> ROM
aFIFO_S_ARAW afifo_s0_ar (
	// axi domain
	.wclk    (axi_clk),           
	.wrst    (axi_rst),           
	.wdata   ({ARID_S0_AXI, ARADDR_S0_AXI, ARLEN_S0_AXI, ARSIZE_S0_AXI, ARBURST_S0_AXI}),          
	.wpush   (ARVALID_S0_AXI && !wfull_s0_ar), 
	.wfull   (wfull_s0_ar),             

	// rom domain
	.rclk    (rom_clk),           
	.rrst    (rom_rst),           
	.rdata   ({ARID_S0, ARADDR_S0, ARLEN_S0, ARSIZE_S0, ARBURST_S0}),        
	.rpop    (!rempty_s0_ar && ARREADY_S0), 
	.rempty  (rempty_s0_ar)             
);

assign ARREADY_S0_AXI = !wfull_s0_ar;   // for AXI  
assign ARVALID_S0     = !rempty_s0_ar;  // for ROM(S0)

// R: ROM -> AXI
aFIFO_S_R afifo_s0_r (
	// rom domain 
	.wclk    (rom_clk),           
	.wrst    (rom_rst),           
	.wdata   ({RID_S0, RDATA_S0, RRESP_S0, RLAST_S0}),          
	.wpush   (RVALID_S0 && !wfull_s0_r), 
	.wfull   (wfull_s0_r),             

	// axi domain
	.rclk    (axi_clk),           
	.rrst    (axi_rst),           
	.rdata   ({RID_S0_AXI, RDATA_S0_AXI, RRESP_S0_AXI, RLAST_S0_AXI}),        
	.rpop    (!rempty_s0_r && RREADY_S0_AXI), 
	.rempty  (rempty_s0_r)             
);

assign RREADY_S0     = !wfull_s0_r;    // for ROM(S0)
assign RVALID_S0_AXI = !rempty_s0_r;   // for AXI

/* aFIFO: IM(s1) <-> AXI */
// AW: AXI -> IM
aFIFO_S_ARAW afifo_s1_aw (
	// axi domain
	.wclk    (axi_clk),           
	.wrst    (axi_rst),           
	.wdata   ({AWID_S1_AXI, AWADDR_S1_AXI, AWLEN_S1_AXI, AWSIZE_S1_AXI, AWBURST_S1_AXI}),          
	.wpush   (AWVALID_S1_AXI && !wfull_s1_aw), 
	.wfull   (wfull_s1_aw),             

	// im domain
	.rclk    (cpu_clk),           
	.rrst    (cpu_rst),           
	.rdata   ({AWID_S1, AWADDR_S1, AWLEN_S1, AWSIZE_S1, AWBURST_S1}),        
	.rpop    (!rempty_s1_aw && AWREADY_S1), 
	.rempty  (rempty_s1_aw)             
);

assign AWREADY_S1_AXI = !wfull_s1_aw;   // for AXI
assign AWVALID_S1     = !rempty_s1_aw;  // for IM(S1)

// W: AXI -> IM  
aFIFO_S_W afifo_s1_w (
	// axi domain
	.wclk    (axi_clk),           
	.wrst    (axi_rst),           
	.wdata   ({WDATA_S1_AXI, WSTRB_S1_AXI, WLAST_S1_AXI}),          
	.wpush   (WVALID_S1_AXI && !wfull_s1_w), 
	.wfull   (wfull_s1_w),             

	// im domain
	.rclk    (cpu_clk),           
	.rrst    (cpu_rst),           
	.rdata   ({WDATA_S1, WSTRB_S1, WLAST_S1}),        
	.rpop    (!rempty_s1_w && WREADY_S1), 
	.rempty  (rempty_s1_w)             
);

assign WREADY_S1_AXI = !wfull_s1_w;   // for AXI
assign WVALID_S1     = !rempty_s1_w;  // for IM(S1)

// B: IM -> AXI
aFIFO_S_B afifo_s1_b (
	// im domain
	.wclk    (cpu_clk),           
	.wrst    (cpu_rst),           
	.wdata   ({BID_S1, BRESP_S1}),          
	.wpush   (BVALID_S1 && !wfull_s1_b), 
	.wfull   (wfull_s1_b),             

	// axi domain
	.rclk    (axi_clk),           
	.rrst    (axi_rst),           
	.rdata   ({BID_S1_AXI, BRESP_S1_AXI}),        
	.rpop    (!rempty_s1_b && BREADY_S1_AXI), 
	.rempty  (rempty_s1_b)             
);

assign BREADY_S1     = !wfull_s1_b;    // for IM(S1)
assign BVALID_S1_AXI = !rempty_s1_b;   // for AXI

// AR: AXI -> IM
aFIFO_S_ARAW afifo_s1_ar (
	// axi domain
	.wclk    (axi_clk),           
	.wrst    (axi_rst),           
	.wdata   ({ARID_S1_AXI, ARADDR_S1_AXI, ARLEN_S1_AXI, ARSIZE_S1_AXI, ARBURST_S1_AXI}),          
	.wpush   (ARVALID_S1_AXI && !wfull_s1_ar), 
	.wfull   (wfull_s1_ar),             

	// im domain
	.rclk    (cpu_clk),           
	.rrst    (cpu_rst),           
	.rdata   ({ARID_S1, ARADDR_S1, ARLEN_S1, ARSIZE_S1, ARBURST_S1}),        
	.rpop    (!rempty_s1_ar && ARREADY_S1), 
	.rempty  (rempty_s1_ar)             
);

assign ARREADY_S1_AXI = !wfull_s1_ar;   // for AXI
assign ARVALID_S1     = !rempty_s1_ar;  // for IM(S1)

// R: IM -> AXI
aFIFO_S_R afifo_s1_r (
	// im domain
	.wclk    (cpu_clk),           
	.wrst    (cpu_rst),           
	.wdata   ({RID_S1, RDATA_S1, RRESP_S1, RLAST_S1}),          
	.wpush   (RVALID_S1 && !wfull_s1_r), 
	.wfull   (wfull_s1_r),             

	// axi domain
	.rclk    (axi_clk),           
	.rrst    (axi_rst),           
	.rdata   ({RID_S1_AXI, RDATA_S1_AXI, RRESP_S1_AXI, RLAST_S1_AXI}),        
	.rpop    (!rempty_s1_r && RREADY_S1_AXI), 
	.rempty  (rempty_s1_r)             
);

assign RREADY_S1     = !wfull_s1_r;    // for IM(S1)  
assign RVALID_S1_AXI = !rempty_s1_r;   // for AXI

/* aFIFO: DM(s2) <-> AXI */
// AW: AXI -> DM
aFIFO_S_ARAW afifo_s2_aw (
	// axi domain
	.wclk    (axi_clk),           
	.wrst    (axi_rst),           
	.wdata   ({AWID_S2_AXI, AWADDR_S2_AXI, AWLEN_S2_AXI, AWSIZE_S2_AXI, AWBURST_S2_AXI}),          
	.wpush   (AWVALID_S2_AXI && !wfull_s2_aw), 
	.wfull   (wfull_s2_aw),             

	// dm domain
	.rclk    (cpu_clk),           
	.rrst    (cpu_rst),           
	.rdata   ({AWID_S2, AWADDR_S2, AWLEN_S2, AWSIZE_S2, AWBURST_S2}),        
	.rpop    (!rempty_s2_aw && AWREADY_S2), 
	.rempty  (rempty_s2_aw)             
);

assign AWREADY_S2_AXI = !wfull_s2_aw;   // for AXI
assign AWVALID_S2     = !rempty_s2_aw;  // for DM(S2)

// W: AXI -> DM  
aFIFO_S_W afifo_s2_w (
	// axi domain
	.wclk    (axi_clk),           
	.wrst    (axi_rst),           
	.wdata   ({WDATA_S2_AXI, WSTRB_S2_AXI, WLAST_S2_AXI}),          
	.wpush   (WVALID_S2_AXI && !wfull_s2_w), 
	.wfull   (wfull_s2_w),             

	// dm domain
	.rclk    (cpu_clk),           
	.rrst    (cpu_rst),           
	.rdata   ({WDATA_S2, WSTRB_S2, WLAST_S2}),        
	.rpop    (!rempty_s2_w && WREADY_S2), 
	.rempty  (rempty_s2_w)             
);

assign WREADY_S2_AXI = !wfull_s2_w;   // for AXI
assign WVALID_S2     = !rempty_s2_w;  // for DM(S2)

// B: DM -> AXI
aFIFO_S_B afifo_s2_b (
	// dm domain
	.wclk    (cpu_clk),           
	.wrst    (cpu_rst),           
	.wdata   ({BID_S2, BRESP_S2}),          
	.wpush   (BVALID_S2 && !wfull_s2_b), 
	.wfull   (wfull_s2_b),             

	// axi domain
	.rclk    (axi_clk),           
	.rrst    (axi_rst),           
	.rdata   ({BID_S2_AXI, BRESP_S2_AXI}),        
	.rpop    (!rempty_s2_b && BREADY_S2_AXI), 
	.rempty  (rempty_s2_b)             
);

assign BREADY_S2     = !wfull_s2_b;    // for DM(S2)
assign BVALID_S2_AXI = !rempty_s2_b;   // for AXI

// AR: AXI -> DM
aFIFO_S_ARAW afifo_s2_ar (
	// axi domain
	.wclk    (axi_clk),           
	.wrst    (axi_rst),           
	.wdata   ({ARID_S2_AXI, ARADDR_S2_AXI, ARLEN_S2_AXI, ARSIZE_S2_AXI, ARBURST_S2_AXI}),          
	.wpush   (ARVALID_S2_AXI && !wfull_s2_ar), 
	.wfull   (wfull_s2_ar),             

	// dm domain
	.rclk    (cpu_clk),           
	.rrst    (cpu_rst),           
	.rdata   ({ARID_S2, ARADDR_S2, ARLEN_S2, ARSIZE_S2, ARBURST_S2}),        
	.rpop    (!rempty_s2_ar && ARREADY_S2), 
	.rempty  (rempty_s2_ar)             
);

assign ARREADY_S2_AXI = !wfull_s2_ar;   // for AXI
assign ARVALID_S2     = !rempty_s2_ar;  // for DM(S2)

// R: DM -> AXI
aFIFO_S_R afifo_s2_r (
	// dm domain
	.wclk    (cpu_clk),           
	.wrst    (cpu_rst),           
	.wdata   ({RID_S2, RDATA_S2, RRESP_S2, RLAST_S2}),          
	.wpush   (RVALID_S2 && !wfull_s2_r), 
	.wfull   (wfull_s2_r),             

	// axi domain
	.rclk    (axi_clk),           
	.rrst    (axi_rst),           
	.rdata   ({RID_S2_AXI, RDATA_S2_AXI, RRESP_S2_AXI, RLAST_S2_AXI}),        
	.rpop    (!rempty_s2_r && RREADY_S2_AXI), 
	.rempty  (rempty_s2_r)             
);

assign RREADY_S2     = !wfull_s2_r;    // for DM(S2)
assign RVALID_S2_AXI = !rempty_s2_r;   // for AXI

/* aFIFO: DMA(s3) <-> AXI */
// AW: AXI -> DMA
aFIFO_S_ARAW afifo_s3_aw (
	// axi domain
	.wclk    (axi_clk),           
	.wrst    (axi_rst),           
	.wdata   ({AWID_S3_AXI, AWADDR_S3_AXI, AWLEN_S3_AXI, AWSIZE_S3_AXI, AWBURST_S3_AXI}),          
	.wpush   (AWVALID_S3_AXI && !wfull_s3_aw), 
	.wfull   (wfull_s3_aw),             

	// dma domain
	.rclk    (cpu_clk),           
	.rrst    (cpu_rst),           
	.rdata   ({AWID_S3, AWADDR_S3, AWLEN_S3, AWSIZE_S3, AWBURST_S3}),        
	.rpop    (!rempty_s3_aw && AWREADY_S3), 
	.rempty  (rempty_s3_aw)             
);

assign AWREADY_S3_AXI = !wfull_s3_aw;   // for AXI
assign AWVALID_S3     = !rempty_s3_aw;  // for DMA(S3)

// W: AXI -> DMA  
aFIFO_S_W afifo_s3_w (
	// axi domain 
	.wclk    (axi_clk),           
	.wrst    (axi_rst),           
	.wdata   ({WDATA_S3_AXI, WSTRB_S3_AXI, WLAST_S3_AXI}),          
	.wpush   (WVALID_S3_AXI && !wfull_s3_w), 
	.wfull   (wfull_s3_w),             

	// dma domain
	.rclk    (cpu_clk),           
	.rrst    (cpu_rst),           
	.rdata   ({WDATA_S3, WSTRB_S3, WLAST_S3}),        
	.rpop    (!rempty_s3_w && WREADY_S3), 
	.rempty  (rempty_s3_w)             
);

assign WREADY_S3_AXI = !wfull_s3_w;   // for AXI
assign WVALID_S3     = !rempty_s3_w;  // for DMA(S3)

// B: DMA -> AXI
aFIFO_S_B afifo_s3_b (
	// dma domain
	.wclk    (cpu_clk),           
	.wrst    (cpu_rst),           
	.wdata   ({BID_S3, BRESP_S3}),          
	.wpush   (BVALID_S3 && !wfull_s3_b), 
	.wfull   (wfull_s3_b),             

	// axi domain
	.rclk    (axi_clk),           
	.rrst    (axi_rst),           
	.rdata   ({BID_S3_AXI, BRESP_S3_AXI}),        
	.rpop    (!rempty_s3_b && BREADY_S3_AXI), 
	.rempty  (rempty_s3_b)             
);

assign BREADY_S3     = !wfull_s3_b;    // for DMA(S3)
assign BVALID_S3_AXI = !rempty_s3_b;   // for AXI

/* aFIFO: WDT(s4) <-> AXI */
// AW: AXI -> WDT
aFIFO_S_ARAW afifo_s4_aw (
	// axi domain
	.wclk    (axi_clk),           
	.wrst    (axi_rst),           
	.wdata   ({AWID_S4_AXI, AWADDR_S4_AXI, AWLEN_S4_AXI, AWSIZE_S4_AXI, AWBURST_S4_AXI}),          
	.wpush   (AWVALID_S4_AXI && !wfull_s4_aw), 
	.wfull   (wfull_s4_aw),             

	// im domain
	.rclk    (rom_clk),           
	.rrst    (rom_rst),           
	.rdata   ({AWID_S4, AWADDR_S4, AWLEN_S4, AWSIZE_S4, AWBURST_S4}),        
	.rpop    (!rempty_s4_aw && AWREADY_S4), 
	.rempty  (rempty_s4_aw)             
);

assign AWREADY_S4_AXI = !wfull_s4_aw;   // for AXI
assign AWVALID_S4     = !rempty_s4_aw;  // for WDT(S4)

// W: AXI -> WDT  
aFIFO_S_W afifo_s4_w (
	// axi domain
	.wclk    (axi_clk),           
	.wrst    (axi_rst),           
	.wdata   ({WDATA_S4_AXI, WSTRB_S4_AXI, WLAST_S4_AXI}),          
	.wpush   (WVALID_S4_AXI && !wfull_s4_w), 
	.wfull   (wfull_s4_w),             

	// wdt domain
	.rclk    (rom_clk),           
	.rrst    (rom_rst),           
	.rdata   ({WDATA_S4, WSTRB_S4, WLAST_S4}),        
	.rpop    (!rempty_s4_w && WREADY_S4), 
	.rempty  (rempty_s4_w)             
);

assign WREADY_S4_AXI = !wfull_s4_w;   // for AXI
assign WVALID_S4     = !rempty_s4_w;  // for WDT(S4)

// B: WDT -> AXI
aFIFO_S_B afifo_s4_b (
	// wdt domain
	.wclk    (rom_clk),           
	.wrst    (rom_rst),           
	.wdata   ({BID_S4, BRESP_S4}),          
	.wpush   (BVALID_S4 && !wfull_s4_b), 
	.wfull   (wfull_s4_b),             

	// axi domain
	.rclk    (axi_clk),           
	.rrst    (axi_rst),           
	.rdata   ({BID_S4_AXI, BRESP_S4_AXI}),        
	.rpop    (!rempty_s4_b && BREADY_S4_AXI), 
	.rempty  (rempty_s4_b)             
);

assign BREADY_S4     = !wfull_s4_b;    // for WDT(S4)
assign BVALID_S4_AXI = !rempty_s4_b;   // for AXI

// AR: AXI -> WDT
aFIFO_S_ARAW afifo_s4_ar (
	// axi domain
	.wclk    (axi_clk),           
	.wrst    (axi_rst),           
	.wdata   ({ARID_S4_AXI, ARADDR_S4_AXI, ARLEN_S4_AXI, ARSIZE_S4_AXI, ARBURST_S4_AXI}),          
	.wpush   (ARVALID_S4_AXI && !wfull_s4_ar), 
	.wfull   (wfull_s4_ar),             

	// wdt domain
	.rclk    (rom_clk),           
	.rrst    (rom_rst),           
	.rdata   ({ARID_S4, ARADDR_S4, ARLEN_S4, ARSIZE_S4, ARBURST_S4}),        
	.rpop    (!rempty_s4_ar && ARREADY_S4), 
	.rempty  (rempty_s4_ar)             
);

assign ARREADY_S4_AXI = !wfull_s4_ar;   // for AXI
assign ARVALID_S4     = !rempty_s4_ar;  // for WDT(S4)

// R: WDT -> AXI
aFIFO_S_R afifo_s4_r (
	// WDT domain
	.wclk    (rom_clk),           
	.wrst    (rom_rst),           
	.wdata   ({RID_S4, RDATA_S4, RRESP_S4, RLAST_S4}),          
	.wpush   (RVALID_S4 && !wfull_s4_r), 
	.wfull   (wfull_s4_r),             

	// axi domain
	.rclk    (axi_clk),           
	.rrst    (axi_rst),           
	.rdata   ({RID_S4_AXI, RDATA_S4_AXI, RRESP_S4_AXI, RLAST_S4_AXI}),        
	.rpop    (!rempty_s4_r && RREADY_S4_AXI), 
	.rempty  (rempty_s4_r)             
);

assign RREADY_S4     = !wfull_s4_r;    // for WDT(S4)  
assign RVALID_S4_AXI = !rempty_s4_r;   // for AXI

/* aFIFO: DRAM(s5) <-> AXI */
// AW: AXI -> DRAM
aFIFO_S_ARAW afifo_s5_aw (
	// axi domain
	.wclk    (axi_clk),           
	.wrst    (axi_rst),           
	.wdata   ({AWID_S5_AXI, AWADDR_S5_AXI, AWLEN_S5_AXI, AWSIZE_S5_AXI, AWBURST_S5_AXI}),          
	.wpush   (AWVALID_S5_AXI && !wfull_s5_aw), 
	.wfull   (wfull_s5_aw),             

	// dram domain
	.rclk    (dram_clk),           
	.rrst    (dram_rst),           
	.rdata   ({AWID_S5, AWADDR_S5, AWLEN_S5, AWSIZE_S5, AWBURST_S5}),        
	.rpop    (!rempty_s5_aw && AWREADY_S5), 
	.rempty  (rempty_s5_aw)             
);

assign AWREADY_S5_AXI = !wfull_s5_aw;   // for AXI
assign AWVALID_S5     = !rempty_s5_aw;  // for DRAM(S5)

// W: AXI -> DRAM  
aFIFO_S_W afifo_s5_w (
	// axi domain
	.wclk    (axi_clk),           
	.wrst    (axi_rst),           
	.wdata   ({WDATA_S5_AXI, WSTRB_S5_AXI, WLAST_S5_AXI}),          
	.wpush   (WVALID_S5_AXI && !wfull_s5_w), 
	.wfull   (wfull_s5_w),             

	// dram domain
	.rclk    (dram_clk),           
	.rrst    (dram_rst),           
	.rdata   ({WDATA_S5, WSTRB_S5, WLAST_S5}),        
	.rpop    (!rempty_s5_w && WREADY_S5), 
	.rempty  (rempty_s5_w)             
);

assign WREADY_S5_AXI = !wfull_s5_w;   // for AXI
assign WVALID_S5     = !rempty_s5_w;  // for DRAM(S5)

// B: DRAM -> AXI
aFIFO_S_B afifo_s5_b (
	// dram domain
	.wclk    (dram_clk),           
	.wrst    (dram_rst),           
	.wdata   ({BID_S5, BRESP_S5}),          
	.wpush   (BVALID_S5 && !wfull_s5_b), 
	.wfull   (wfull_s5_b),             

	// axi domain
	.rclk    (axi_clk),           
	.rrst    (axi_rst),           
	.rdata   ({BID_S5_AXI, BRESP_S5_AXI}),        
	.rpop    (!rempty_s5_b && BREADY_S5_AXI), 
	.rempty  (rempty_s5_b)             
);

assign BREADY_S5     = !wfull_s5_b;    // for DRAM(S5)
assign BVALID_S5_AXI = !rempty_s5_b;   // for AXI

// AR: AXI -> DRAM
aFIFO_S_ARAW afifo_s5_ar (
	// axi domain
	.wclk    (axi_clk),           
	.wrst    (axi_rst),           
	.wdata   ({ARID_S5_AXI, ARADDR_S5_AXI, ARLEN_S5_AXI, ARSIZE_S5_AXI, ARBURST_S5_AXI}),          
	.wpush   (ARVALID_S5_AXI && !wfull_s5_ar), 
	.wfull   (wfull_s5_ar),             

	// dram domain
	.rclk    (dram_clk),           
	.rrst    (dram_rst),           
	.rdata   ({ARID_S5, ARADDR_S5, ARLEN_S5, ARSIZE_S5, ARBURST_S5}),        
	.rpop    (!rempty_s5_ar && ARREADY_S5), 
	.rempty  (rempty_s5_ar)             
);

assign ARREADY_S5_AXI = !wfull_s5_ar;   // for AXI
assign ARVALID_S5     = !rempty_s5_ar;  // for DRAM(S5)

// R: DRAM -> AXI
aFIFO_S_R afifo_s5_r (
	// dram domain
	.wclk    (dram_clk),           
	.wrst    (dram_rst),           
	.wdata   ({RID_S5, RDATA_S5, RRESP_S5, RLAST_S5}),          
	.wpush   (RVALID_S5 && !wfull_s5_r), 
	.wfull   (wfull_s5_r),             

	// axi domain
	.rclk    (axi_clk),           
	.rrst    (axi_rst),           
	.rdata   ({RID_S5_AXI, RDATA_S5_AXI, RRESP_S5_AXI, RLAST_S5_AXI}),        
	.rpop    (!rempty_s5_r && RREADY_S5_AXI), 
	.rempty  (rempty_s5_r)             
);

assign RREADY_S5     = !wfull_s5_r;    // for DRAM(S5)
assign RVALID_S5_AXI = !rempty_s5_r;   // for AXI

/* aFIFO: DLA(s6) <-> AXI */
// AW: AXI -> DLA
aFIFO_S_ARAW afifo_s6_aw (
	// axi domain
	.wclk    (axi_clk),           
	.wrst    (axi_rst),           
	.wdata   ({AWID_S6_AXI, AWADDR_S6_AXI, AWLEN_S6_AXI, AWSIZE_S6_AXI, AWBURST_S6_AXI}),          
	.wpush   (AWVALID_S6_AXI && !wfull_s6_aw), 
	.wfull   (wfull_s6_aw),             

	// dla domain
	.rclk    (cpu_clk),           
	.rrst    (cpu_rst),           
	.rdata   ({AWID_S6, AWADDR_S6, AWLEN_S6, AWSIZE_S6, AWBURST_S6}),        
	.rpop    (!rempty_s6_aw && AWREADY_S6), 
	.rempty  (rempty_s6_aw)             
);

assign AWREADY_S6_AXI = !wfull_s6_aw;   // for AXI
assign AWVALID_S6     = !rempty_s6_aw;  // for DLA(S6)

// W: AXI -> DLA  
aFIFO_S_W afifo_s6_w (
	// axi domain
	.wclk    (axi_clk),           
	.wrst    (axi_rst),           
	.wdata   ({WDATA_S6_AXI, WSTRB_S6_AXI, WLAST_S6_AXI}),          
	.wpush   (WVALID_S6_AXI && !wfull_s6_w), 
	.wfull   (wfull_s6_w),             

	// dla domain
	.rclk    (cpu_clk),           
	.rrst    (cpu_rst),           
	.rdata   ({WDATA_S6, WSTRB_S6, WLAST_S6}),        
	.rpop    (!rempty_s6_w && WREADY_S6), 
	.rempty  (rempty_s6_w)             
);

assign WREADY_S6_AXI = !wfull_s6_w;   // for AXI
assign WVALID_S6     = !rempty_s6_w;  // for DLA(S6)

// B: DLA -> AXI
aFIFO_S_B afifo_s6_b (
	// dla domain
	.wclk    (cpu_clk),           
	.wrst    (cpu_rst),           
	.wdata   ({BID_S6, BRESP_S6}),          
	.wpush   (BVALID_S6 && !wfull_s6_b), 
	.wfull   (wfull_s6_b),             

	// axi domain
	.rclk    (axi_clk),           
	.rrst    (axi_rst),           
	.rdata   ({BID_S6_AXI, BRESP_S6_AXI}),        
	.rpop    (!rempty_s6_b && BREADY_S6_AXI), 
	.rempty  (rempty_s6_b)             
);

assign BREADY_S6     = !wfull_s6_b;    // for DLA(S6)
assign BVALID_S6_AXI = !rempty_s6_b;   // for AXI

// AR: AXI -> DLA
aFIFO_S_ARAW afifo_s6_ar (
	// axi domain
	.wclk    (axi_clk),           
	.wrst    (axi_rst),           
	.wdata   ({ARID_S6_AXI, ARADDR_S6_AXI, ARLEN_S6_AXI, ARSIZE_S6_AXI, ARBURST_S6_AXI}),          
	.wpush   (ARVALID_S6_AXI && !wfull_s6_ar), 
	.wfull   (wfull_s6_ar),             

	// dla domain
	.rclk    (cpu_clk),           
	.rrst    (cpu_rst),           
	.rdata   ({ARID_S6, ARADDR_S6, ARLEN_S6, ARSIZE_S6, ARBURST_S6}),        
	.rpop    (!rempty_s6_ar && ARREADY_S6), 
	.rempty  (rempty_s6_ar)             
);

assign ARREADY_S6_AXI = !wfull_s6_ar;   // for AXI
assign ARVALID_S6     = !rempty_s6_ar;  // for DLA(S6)

// R: DLA -> AXI
aFIFO_S_R afifo_s6_r (
	// dla domain
	.wclk    (cpu_clk),           
	.wrst    (cpu_rst),           
	.wdata   ({RID_S6, RDATA_S6, RRESP_S6, RLAST_S6}),          
	.wpush   (RVALID_S6 && !wfull_s6_r), 
	.wfull   (wfull_s6_r),             

	// axi domain
	.rclk    (axi_clk),           
	.rrst    (axi_rst),           
	.rdata   ({RID_S6_AXI, RDATA_S6_AXI, RRESP_S6_AXI, RLAST_S6_AXI}),        
	.rpop    (!rempty_s6_r && RREADY_S6_AXI), 
	.rempty  (rempty_s6_r)             
);

assign RREADY_S6     = !wfull_s6_r;    // for DLA(S6)
assign RVALID_S6_AXI = !rempty_s6_r;   // for AXI

endmodule
