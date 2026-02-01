//////////////////////////////////////////////////////////////////////
//          ██╗       ██████╗   ██╗  ██╗    ██████╗            		//
//          ██║       ██╔══█║   ██║  ██║    ██╔══█║            		//
//          ██║       ██████║   ███████║    ██████║            		//
//          ██║       ██╔═══╝   ██╔══██║    ██╔═══╝            		//
//          ███████╗  ██║  	    ██║  ██║    ██║  	           		//
//          ╚══════╝  ╚═╝  	    ╚═╝  ╚═╝    ╚═╝  	           		//
//                                                             		//
// 	2024 Advanced VLSI System Design, advisor: Lih-Yih, Chiou		//
//                                                             		//
//////////////////////////////////////////////////////////////////////
//                                                             		//
// 	Autor: 			TZUNG-JIN, TSAI (Leo)				  	   		//
//	Filename:		 AXI.sv			                            	//
//	Description:	Top module of AXI	 							//
// 	Version:		1.0	    								   		//
//////////////////////////////////////////////////////////////////////
`include "../include/AXI_define.svh"
`include "../src/AXI/AXI_Arbiter.sv"
`include "../src/AXI/AXI_Decoder.sv"

module AXI(

	input ACLK,
	input ARESETn,

	/* SLAVE INTERFACE FOR MASTERS */
	
	//WRITE ADDRESS 1
	input  [`AXI_ID_BITS-1:0]   AWID_M1,
	input  [`AXI_ADDR_BITS-1:0] AWADDR_M1,
	input  [`AXI_LEN_BITS-1:0]  AWLEN_M1,
	input  [`AXI_SIZE_BITS-1:0] AWSIZE_M1,
	input  [1:0]                AWBURST_M1,
	input                       AWVALID_M1,
	output logic                AWREADY_M1,
	
	//WRITE DATA 1
	input  [`AXI_DATA_BITS-1:0] WDATA_M1,
	input  [`AXI_STRB_BITS-1:0] WSTRB_M1,
	input                       WLAST_M1,
	input                       WVALID_M1,
	output logic                WREADY_M1,
	
	//WRITE RESPONSE 1
	output logic [`AXI_ID_BITS-1:0] BID_M1,
	output logic [1:0]              BRESP_M1,
	output logic                    BVALID_M1,
	input                           BREADY_M1,

	//WRITE ADDRESS 2
	input  [`AXI_ID_BITS-1:0]   AWID_M2,
	input  [`AXI_ADDR_BITS-1:0] AWADDR_M2,
	input  [`AXI_LEN_BITS-1:0]  AWLEN_M2,
	input  [`AXI_SIZE_BITS-1:0] AWSIZE_M2,
	input  [1:0]                AWBURST_M2,
	input                       AWVALID_M2,
	output logic                AWREADY_M2,

	//WRITE DATA 2
	input  [`AXI_DATA_BITS-1:0] WDATA_M2,
	input  [`AXI_STRB_BITS-1:0] WSTRB_M2,
	input                       WLAST_M2,
	input                       WVALID_M2,
	output logic                WREADY_M2,

	//WRITE RESPONSE 2
	output logic [`AXI_ID_BITS-1:0] BID_M2,
	output logic [1:0]              BRESP_M2,
	output logic                    BVALID_M2,
	input                           BREADY_M2,

	//READ ADDRESS0
	input  [`AXI_ID_BITS-1:0]   ARID_M0,
	input  [`AXI_ADDR_BITS-1:0] ARADDR_M0,
	input  [`AXI_LEN_BITS-1:0]  ARLEN_M0,
	input  [`AXI_SIZE_BITS-1:0] ARSIZE_M0,
	input  [1:0]                ARBURST_M0,
	input                       ARVALID_M0,
	output logic                ARREADY_M0,
	
	//READ DATA0
	output logic [`AXI_ID_BITS-1:0]   RID_M0,
	output logic [`AXI_DATA_BITS-1:0] RDATA_M0,
	output logic [1:0]                RRESP_M0,
	output logic                      RLAST_M0,
	output logic                      RVALID_M0,
	input                             RREADY_M0,
	
	//READ ADDRESS1
	input  [`AXI_ID_BITS-1:0]   ARID_M1,
	input  [`AXI_ADDR_BITS-1:0] ARADDR_M1,
	input  [`AXI_LEN_BITS-1:0]  ARLEN_M1,
	input  [`AXI_SIZE_BITS-1:0] ARSIZE_M1,
	input  [1:0]                ARBURST_M1,
	input                       ARVALID_M1,
	output logic                ARREADY_M1,
	
	//READ DATA1
	output logic [`AXI_ID_BITS-1:0]   RID_M1,
	output logic [`AXI_DATA_BITS-1:0] RDATA_M1,
	output logic [1:0]                RRESP_M1,
	output logic                      RLAST_M1,
	output logic                      RVALID_M1,
	input                             RREADY_M1,

	//READ ADDRESS2
	input  [`AXI_ID_BITS-1:0]   ARID_M2,
	input  [`AXI_ADDR_BITS-1:0] ARADDR_M2,
	input  [`AXI_LEN_BITS-1:0]  ARLEN_M2,
	input  [`AXI_SIZE_BITS-1:0] ARSIZE_M2,
	input  [1:0]                ARBURST_M2,
	input                       ARVALID_M2,
	output logic                ARREADY_M2,

	//READ DATA2
	output logic [`AXI_ID_BITS-1:0]   RID_M2,
	output logic [`AXI_DATA_BITS-1:0] RDATA_M2,
	output logic [1:0]                RRESP_M2,
	output logic                      RLAST_M2,
	output logic                      RVALID_M2,
	input                             RREADY_M2,

	/* MASTER INTERFACE FOR SLAVES */
	// //WRITE ADDRESS0
	// output logic [`AXI_IDS_BITS-1:0]  AWID_S0,
	// output logic [`AXI_ADDR_BITS-1:0] AWADDR_S0,
	// output logic [`AXI_LEN_BITS-1:0]  AWLEN_S0,
	// output logic [`AXI_SIZE_BITS-1:0] AWSIZE_S0,
	// output logic [1:0]                AWBURST_S0,
	// output logic                      AWVALID_S0,
	// input                             AWREADY_S0,
	
	// //WRITE DATA0
	// output logic [`AXI_DATA_BITS-1:0] WDATA_S0,
	// output logic [`AXI_STRB_BITS-1:0] WSTRB_S0,
	// output logic                      WLAST_S0,
	// output logic                      WVALID_S0,
	// input                             WREADY_S0,
	
	// //WRITE RESPONSE0
	// input  [`AXI_IDS_BITS-1:0] BID_S0,
	// input  [1:0]               BRESP_S0,
	// input                      BVALID_S0,
	// output logic               BREADY_S0,
	
	//WRITE ADDRESS1
	output logic [`AXI_IDS_BITS-1:0]  AWID_S1,
	output logic [`AXI_ADDR_BITS-1:0] AWADDR_S1,
	output logic [`AXI_LEN_BITS-1:0]  AWLEN_S1,
	output logic [`AXI_SIZE_BITS-1:0] AWSIZE_S1,
	output logic [1:0]                AWBURST_S1,
	output logic                      AWVALID_S1,
	input                             AWREADY_S1,
	
	//WRITE DATA1
	output logic [`AXI_DATA_BITS-1:0] WDATA_S1,
	output logic [`AXI_STRB_BITS-1:0] WSTRB_S1,
	output logic                      WLAST_S1,
	output logic                      WVALID_S1,
	input                             WREADY_S1,
	
	//WRITE RESPONSE1
	input  [`AXI_IDS_BITS-1:0] BID_S1,
	input  [1:0]               BRESP_S1,
	input                      BVALID_S1,
	output logic               BREADY_S1,

	//WRITE ADDRESS 2
	output logic [`AXI_IDS_BITS-1:0]  AWID_S2,
	output logic [`AXI_ADDR_BITS-1:0] AWADDR_S2,
	output logic [`AXI_LEN_BITS-1:0]  AWLEN_S2,
	output logic [`AXI_SIZE_BITS-1:0] AWSIZE_S2,
	output logic [1:0]                AWBURST_S2,
	output logic                      AWVALID_S2,
	input                             AWREADY_S2,

	//WRITE DATA 2
	output logic [`AXI_DATA_BITS-1:0] WDATA_S2,
	output logic [`AXI_STRB_BITS-1:0] WSTRB_S2,
	output logic                      WLAST_S2,
	output logic                      WVALID_S2,
	input                             WREADY_S2,

	//WRITE RESPONSE 2
	input  [`AXI_IDS_BITS-1:0] BID_S2,
	input  [1:0]               BRESP_S2,
	input                      BVALID_S2,
	output logic               BREADY_S2,

	//WRITE ADDRESS 3
	output logic [`AXI_IDS_BITS-1:0]  AWID_S3,
	output logic [`AXI_ADDR_BITS-1:0] AWADDR_S3,
	output logic [`AXI_LEN_BITS-1:0]  AWLEN_S3,
	output logic [`AXI_SIZE_BITS-1:0] AWSIZE_S3,
	output logic [1:0]                AWBURST_S3,
	output logic                      AWVALID_S3,
	input                             AWREADY_S3,

	//WRITE DATA 3
	output logic [`AXI_DATA_BITS-1:0] WDATA_S3,
	output logic [`AXI_STRB_BITS-1:0] WSTRB_S3,
	output logic                      WLAST_S3,
	output logic                      WVALID_S3,
	input                             WREADY_S3,

	//WRITE RESPONSE 3
	input  [`AXI_IDS_BITS-1:0] BID_S3,
	input  [1:0]               BRESP_S3,
	input                      BVALID_S3,
	output logic               BREADY_S3,

	//WRITE ADDRESS 4
	output logic [`AXI_IDS_BITS-1:0]  AWID_S4,
	output logic [`AXI_ADDR_BITS-1:0] AWADDR_S4,
	output logic [`AXI_LEN_BITS-1:0]  AWLEN_S4,
	output logic [`AXI_SIZE_BITS-1:0] AWSIZE_S4,
	output logic [1:0]                AWBURST_S4,
	output logic                      AWVALID_S4,
	input                             AWREADY_S4,

	//WRITE DATA 4
	output logic [`AXI_DATA_BITS-1:0] WDATA_S4,
	output logic [`AXI_STRB_BITS-1:0] WSTRB_S4,
	output logic                      WLAST_S4,
	output logic                      WVALID_S4,
	input                             WREADY_S4,

	//WRITE RESPONSE 4
	input  [`AXI_IDS_BITS-1:0] BID_S4,
	input  [1:0]               BRESP_S4,
	input                      BVALID_S4,
	output logic               BREADY_S4,

	//WRITE ADDRESS 5
	output logic [`AXI_IDS_BITS-1:0]  AWID_S5,
	output logic [`AXI_ADDR_BITS-1:0] AWADDR_S5,
	output logic [`AXI_LEN_BITS-1:0]  AWLEN_S5,
	output logic [`AXI_SIZE_BITS-1:0] AWSIZE_S5,
	output logic [1:0]                AWBURST_S5,
	output logic                      AWVALID_S5,
	input                             AWREADY_S5,

	//WRITE DATA 5
	output logic [`AXI_DATA_BITS-1:0] WDATA_S5,
	output logic [`AXI_STRB_BITS-1:0] WSTRB_S5,
	output logic                      WLAST_S5,
	output logic                      WVALID_S5,
	input                             WREADY_S5,

	//WRITE RESPONSE 5
	input  [`AXI_IDS_BITS-1:0] BID_S5,
	input  [1:0]               BRESP_S5,
	input                      BVALID_S5,
	output logic               BREADY_S5,
	
	//READ ADDRESS0
	output logic [`AXI_IDS_BITS-1:0]  ARID_S0,
	output logic [`AXI_ADDR_BITS-1:0] ARADDR_S0,
	output logic [`AXI_LEN_BITS-1:0]  ARLEN_S0,
	output logic [`AXI_SIZE_BITS-1:0] ARSIZE_S0,
	output logic [1:0]                ARBURST_S0,
	output logic                      ARVALID_S0,
	input                             ARREADY_S0,
	
	//READ DATA0
	input  [`AXI_IDS_BITS-1:0]   RID_S0,
	input  [`AXI_DATA_BITS-1:0]  RDATA_S0,
	input  [1:0]                 RRESP_S0,
	input                        RLAST_S0,
	input                        RVALID_S0,
	output logic                 RREADY_S0,
	
	//READ ADDRESS1
	output logic [`AXI_IDS_BITS-1:0]  ARID_S1,
	output logic [`AXI_ADDR_BITS-1:0] ARADDR_S1,
	output logic [`AXI_LEN_BITS-1:0]  ARLEN_S1,
	output logic [`AXI_SIZE_BITS-1:0] ARSIZE_S1,
	output logic [1:0]                ARBURST_S1,
	output logic                      ARVALID_S1,
	input                             ARREADY_S1,
	
	//READ DATA1
	input  [`AXI_IDS_BITS-1:0]   RID_S1,
	input  [`AXI_DATA_BITS-1:0]  RDATA_S1,
	input  [1:0]                 RRESP_S1,
	input                        RLAST_S1,
	input                        RVALID_S1,
	output logic                 RREADY_S1,
	
	//READ ADDRESS2
	output logic [`AXI_IDS_BITS-1:0]  ARID_S2,
	output logic [`AXI_ADDR_BITS-1:0] ARADDR_S2,
	output logic [`AXI_LEN_BITS-1:0]  ARLEN_S2,
	output logic [`AXI_SIZE_BITS-1:0] ARSIZE_S2,
	output logic [1:0]                ARBURST_S2,
	output logic                      ARVALID_S2,
	input                             ARREADY_S2,

	//READ DATA2
	input  [`AXI_IDS_BITS-1:0]   RID_S2,
	input  [`AXI_DATA_BITS-1:0]  RDATA_S2,
	input  [1:0]                 RRESP_S2,
	input                        RLAST_S2,
	input                        RVALID_S2,
	output logic                 RREADY_S2,

	// //READ ADDRESS3
	// output logic [`AXI_IDS_BITS-1:0]  ARID_S3,
	// output logic [`AXI_ADDR_BITS-1:0] ARADDR_S3,
	// output logic [`AXI_LEN_BITS-1:0]  ARLEN_S3,
	// output logic [`AXI_SIZE_BITS-1:0] ARSIZE_S3,
	// output logic [1:0]                ARBURST_S3,
	// output logic                      ARVALID_S3,
	// input                             ARREADY_S3,

	// //READ DATA3
	// input  [`AXI_IDS_BITS-1:0]   RID_S3,
	// input  [`AXI_DATA_BITS-1:0]  RDATA_S3,
	// input  [1:0]                 RRESP_S3,
	// input                        RLAST_S3,
	// input                        RVALID_S3,
	// output logic                 RREADY_S3,

	//READ ADDRESS4
	output logic [`AXI_IDS_BITS-1:0]  ARID_S4,
	output logic [`AXI_ADDR_BITS-1:0] ARADDR_S4,
	output logic [`AXI_LEN_BITS-1:0]  ARLEN_S4,
	output logic [`AXI_SIZE_BITS-1:0] ARSIZE_S4,
	output logic [1:0]                ARBURST_S4,
	output logic                      ARVALID_S4,
	input                             ARREADY_S4,

	//READ DATA4
	input  [`AXI_IDS_BITS-1:0]   RID_S4,
	input  [`AXI_DATA_BITS-1:0]  RDATA_S4,
	input  [1:0]                 RRESP_S4,
	input                        RLAST_S4,
	input                        RVALID_S4,
	output logic                 RREADY_S4,

	//READ ADDRESS5
	output logic [`AXI_IDS_BITS-1:0]  ARID_S5,
	output logic [`AXI_ADDR_BITS-1:0] ARADDR_S5,
	output logic [`AXI_LEN_BITS-1:0]  ARLEN_S5,
	output logic [`AXI_SIZE_BITS-1:0] ARSIZE_S5,
	output logic [1:0]                ARBURST_S5,
	output logic                      ARVALID_S5,
	input                             ARREADY_S5,

	//READ DATA5
	input  [`AXI_IDS_BITS-1:0]   RID_S5,
	input  [`AXI_DATA_BITS-1:0]  RDATA_S5,
	input  [1:0]                 RRESP_S5,
	input                        RLAST_S5,
	input                        RVALID_S5,
	output logic                 RREADY_S5
);
    //---------- you should put your design here ----------//

// decoder Master select slave 0/1 
logic [2:0] slave_select_m0, slave_select_m1, slave_select_m2;

// address high 16 bits to decoder
// logic [`AXI_ADDR_BITS/2-1:0] address_high_m0, address_high_m1;

// address 32 bits to decoder
logic [31:0] address_m0, address_m1, address_m2;

// arbiter
logic grant_s0_m0, grant_s0_m1, grant_s0_m2; // for arbiter slave 0
logic grant_s1_m0, grant_s1_m1, grant_s1_m2; // for arbiter slave 1
logic grant_s2_m0, grant_s2_m1, grant_s2_m2; // for arbiter slave 2
logic grant_s3_m0, grant_s3_m1, grant_s3_m2; // for arbiter slave 3
logic grant_s4_m0, grant_s4_m1, grant_s4_m2; // for arbiter slave 4
logic grant_s5_m0, grant_s5_m1, grant_s5_m2; // for arbiter slave 5

logic req_s0_m0, req_s0_m1, req_s0_m2; // for arbiter slave 0
logic req_s1_m0, req_s1_m1, req_s1_m2; // for arbiter slave 1
logic req_s2_m0, req_s2_m1, req_s2_m2; // for arbiter slave 2
logic req_s3_m0, req_s3_m1, req_s3_m2; // for arbiter slave 3
logic req_s4_m0, req_s4_m1, req_s4_m2; // for arbiter slave 4
logic req_s5_m0, req_s5_m1, req_s5_m2; // for arbiter slave 5
logic req_s6_m0, req_s6_m1, req_s6_m2; // for arbiter slave 6

logic end_m0, end_m1_R, end_m1_W; // for end of transfer
logic end_m2_R, end_m2_W; // for end of transfer

logic req_RW_m1; // master 1 read or write
logic req_RW_m2; // master 2 read or write

logic grant_RW_s0_m1, grant_RW_s1_m1, grant_RW_s2_m1, grant_RW_s3_m1, grant_RW_s4_m1, grant_RW_s5_m1;
logic grant_RW_s0_m2, grant_RW_s1_m2, grant_RW_s2_m2, grant_RW_s3_m2, grant_RW_s4_m2, grant_RW_s5_m2;
// indicate slave is assigning by Master1, Master1 can assign another slave
logic s0_m1_doing, s1_m1_doing, s2_m1_doing, s3_m1_doing, s4_m1_doing, s5_m1_doing;
logic s0_cpu_doing, s1_cpu_doing, s2_cpu_doing, s3_cpu_doing, s4_cpu_doing, s5_cpu_doing;
logic s0_dma_doing, s1_dma_doing, s2_dma_doing, s3_dma_doing, s4_dma_doing, s5_dma_doing;

// assign address_high_m0 = ARVALID_M0 ? ARADDR_M0[`AXI_ADDR_BITS-1:`AXI_ADDR_BITS/2] : 16'b0;

// assign address_high_m1 = ARVALID_M1 ? ARADDR_M1[`AXI_ADDR_BITS-1:`AXI_ADDR_BITS/2] :
//                   		 AWVALID_M1 ? AWADDR_M1[`AXI_ADDR_BITS-1:`AXI_ADDR_BITS/2] : 16'b0;
assign address_m0 = ARVALID_M0 ? ARADDR_M0 : 32'b0;

assign address_m1 = ARVALID_M1 ? ARADDR_M1 :
					AWVALID_M1 ? AWADDR_M1 : 32'b0;

assign address_m2 = ARVALID_M2 ? ARADDR_M2 :
					AWVALID_M2 ? AWADDR_M2 : 32'b0;

// Decoder Master1 to Slave 0-6
AXI_Decoder decoder_m0(
    .address(address_m0),
    .slave_select(slave_select_m0),
    .default_slave()
);

// Decoder Master1 to Slave 0-6
AXI_Decoder decoder_m1(
	.address(address_m1),
	.slave_select(slave_select_m1),
	.default_slave()
);

// Decoder Master2 to Slave 0-6
AXI_Decoder decoder_m2(
	.address(address_m2),
	.slave_select(slave_select_m2),
	.default_slave()
);

// Request signal for arbiter
// assign req_s0_m0 = (ARVALID_M0 || RVALID_M0) && (slave_select_m0 == 2'b01);
// assign req_s0_m1 = (ARVALID_M1 || AWVALID_M1 || RVALID_M1 || WVALID_M1) && (slave_select_m1 == 2'b01);
// assign req_s1_m0 = (ARVALID_M0 || RVALID_M0) && (slave_select_m0 == 2'b10);
// assign req_s1_m1 = (ARVALID_M1 || AWVALID_M1 || RVALID_M1 || WVALID_M1) && (slave_select_m1 == 2'b10);
// ROM
assign req_s0_m0 = (ARVALID_M0) && (slave_select_m0 == 3'b000);
assign req_s0_m1 = (ARVALID_M1 || AWVALID_M1) && (slave_select_m1 == 3'b000);
assign req_s0_m2 = (ARVALID_M2 || AWVALID_M2) && (slave_select_m2 == 3'b000);
// IM
assign req_s1_m0 = (ARVALID_M0) && (slave_select_m0 == 3'b001);
assign req_s1_m1 = (ARVALID_M1 || AWVALID_M1) && (slave_select_m1 == 3'b001);
assign req_s1_m2 = (ARVALID_M2 || AWVALID_M2) && (slave_select_m2 == 3'b001);
// DM
assign req_s2_m0 = (ARVALID_M0) && (slave_select_m0 == 3'b010);
assign req_s2_m1 = (ARVALID_M1 || AWVALID_M1) && (slave_select_m1 == 3'b010);
assign req_s2_m2 = (ARVALID_M2 || AWVALID_M2) && (slave_select_m2 == 3'b010);
// DMA
assign req_s3_m0 = (ARVALID_M0) && (slave_select_m0 == 3'b011);
assign req_s3_m1 = (ARVALID_M1 || AWVALID_M1) && (slave_select_m1 == 3'b011);
assign req_s3_m2 = (ARVALID_M2 || AWVALID_M2) && (slave_select_m2 == 3'b011);
// WDT
assign req_s4_m0 = (ARVALID_M0) && (slave_select_m0 == 3'b100);
assign req_s4_m1 = (ARVALID_M1 || AWVALID_M1) && (slave_select_m1 == 3'b100);
assign req_s4_m2 = (ARVALID_M2 || AWVALID_M2) && (slave_select_m2 == 3'b100);
// DRAM
assign req_s5_m0 = (ARVALID_M0) && (slave_select_m0 == 3'b101);
assign req_s5_m1 = (ARVALID_M1 || AWVALID_M1) && (slave_select_m1 == 3'b101);
assign req_s5_m2 = (ARVALID_M2 || AWVALID_M2) && (slave_select_m2 == 3'b101);

// Request signal for Master 1 read or write
assign req_RW_m1 = (ARVALID_M1) ? 1'b1 : 1'b0; // read(1) or write(0)
assign req_RW_m2 = (ARVALID_M2) ? 1'b1 : 1'b0; // read(1) or write(0)
// assign req_RW_m1 = (ARVALID_M1 || RVAILD_M1) ? 1'b1 : 1'b0; // read(1) or write(0)

// Signal for End of Transfer (for Arbiter)
assign end_m1_R = (RVALID_M1 && RREADY_M1 && RLAST_M1);
assign end_m1_W = (BVALID_M1 && BREADY_M1);
assign end_m2_R = (RVALID_M2 && RREADY_M2 && RLAST_M2);
assign end_m2_W = (BVALID_M2 && BREADY_M2);
assign end_m0 = (RVALID_M0 && RREADY_M0 && RLAST_M0);
// assign end_m1_W = (WVALID_M1 && WREADY_M1 && WLAST_M1);
// assign end_m1 = (RVALID_M1 && RREADY_M1 && RLAST_M1) || (BVALID_M1 && BREADY_M1);

// Arbiter for ROM
AXI_Arbiter arbiter_s0 (
    .ACLK(ACLK),
    .ARESETn(ARESETn),
    .req_m0(req_s0_m0), // Only request if targeting Slave 0
    .req_m1(req_s0_m1), // Only request if targeting Slave 0
	.req_m2(req_s0_m2), // Only request if targeting Slave 0
	.req_RW_m1(req_RW_m1),
	.req_RW_m2(req_RW_m2),
	.end_m0(end_m0),
	.end_m1_R(end_m1_R),
 	.end_m1_W(end_m1_W),
	.end_m2_R(end_m2_R),
	.end_m2_W(end_m2_W),
	.other_s_m1_doing(s1_m1_doing || s2_m1_doing || s3_m1_doing || s4_m1_doing || s5_m1_doing), // one of other slave m1 doing
	.other_cpu_doing(s1_cpu_doing || s2_cpu_doing || s3_cpu_doing || s4_cpu_doing || s5_cpu_doing),
	.other_dma_doing(1'b0),
	// .other_dma_doing(s1_dma_doing || s2_dma_doing || s3_dma_doing || s4_dma_doing || s5_dma_doing),
	.this_s_m1_doing(s0_m1_doing),
	.cpu_doing(s0_cpu_doing),
	.dma_doing(s0_dma_doing),
    .grant_m0(grant_s0_m0),
    .grant_m1(grant_s0_m1),
	.grant_m2(grant_s0_m2),
	.grant_RW_m1(grant_RW_s0_m1),
	.grant_RW_m2(grant_RW_s0_m2)
);

// Arbiter for IM
AXI_Arbiter arbiter_s1 (
	.ACLK(ACLK),
	.ARESETn(ARESETn),
	.req_m0(req_s1_m0), // Only request if targeting Slave 1
	.req_m1(req_s1_m1), // Only request if targeting Slave 1
	.req_m2(req_s1_m2), // Only request if targeting Slave 1
	.req_RW_m1(req_RW_m1),
	.req_RW_m2(req_RW_m2),
	.end_m0(end_m0),
	.end_m1_R(end_m1_R),
	.end_m1_W(end_m1_W),
	.end_m2_R(end_m2_R),
	.end_m2_W(end_m2_W),
	.other_s_m1_doing(s0_m1_doing || s2_m1_doing || s3_m1_doing || s4_m1_doing || s5_m1_doing),
	.other_cpu_doing(s0_cpu_doing || s2_cpu_doing || s3_cpu_doing || s4_cpu_doing || s5_cpu_doing),
	.other_dma_doing(1'b0),
	// .other_dma_doing(s0_dma_doing || s2_dma_doing || s3_dma_doing || s4_dma_doing || s5_dma_doing),
	.this_s_m1_doing(s1_m1_doing),
	.cpu_doing(s1_cpu_doing),
	.dma_doing(s1_dma_doing),
	.grant_m0(grant_s1_m0),
	.grant_m1(grant_s1_m1),
	.grant_m2(grant_s1_m2),
	.grant_RW_m1(grant_RW_s1_m1),
	.grant_RW_m2(grant_RW_s1_m2)
);

// Arbiter for DM
AXI_Arbiter arbiter_s2 (
	.ACLK(ACLK),
	.ARESETn(ARESETn),
	.req_m0(req_s2_m0), // Only request if targeting Slave 2
	.req_m1(req_s2_m1), // Only request if targeting Slave 2
	.req_m2(req_s2_m2), // Only request if targeting Slave 2
	.req_RW_m1(req_RW_m1),
	.req_RW_m2(req_RW_m2),
	.end_m0(end_m0),
	.end_m1_R(end_m1_R),
	.end_m1_W(end_m1_W),
	.end_m2_R(end_m2_R),
	.end_m2_W(end_m2_W),
	.other_s_m1_doing(s0_m1_doing || s1_m1_doing || s3_m1_doing || s4_m1_doing || s5_m1_doing),
	.other_cpu_doing(s0_cpu_doing || s1_cpu_doing || s3_cpu_doing || s4_cpu_doing || s5_cpu_doing),
	.other_dma_doing(1'b0),
	// .other_dma_doing(s0_dma_doing || s1_dma_doing || s3_dma_doing || s4_dma_doing || s5_dma_doing),
	.this_s_m1_doing(s2_m1_doing),
	.cpu_doing(s2_cpu_doing),
	.dma_doing(s2_dma_doing),
	.grant_m0(grant_s2_m0),
	.grant_m1(grant_s2_m1),
	.grant_m2(grant_s2_m2),
	.grant_RW_m1(grant_RW_s2_m1),
	.grant_RW_m2(grant_RW_s2_m2)
);

// Arbiter for DMA
AXI_Arbiter arbiter_s3 (
	.ACLK(ACLK),
	.ARESETn(ARESETn),
	.req_m0(req_s3_m0), // Only request if targeting Slave 3
	.req_m1(req_s3_m1), // Only request if targeting Slave 3
	.req_m2(req_s3_m2), // Only request if targeting Slave 3
	.req_RW_m1(req_RW_m1),
	.req_RW_m2(req_RW_m2),
	.end_m0(end_m0),
	.end_m1_R(end_m1_R),
	.end_m1_W(end_m1_W),
	.end_m2_R(end_m2_R),
	.end_m2_W(end_m2_W),
	.other_s_m1_doing(s0_m1_doing || s1_m1_doing || s2_m1_doing || s4_m1_doing || s5_m1_doing),
	.other_cpu_doing(s0_cpu_doing || s1_cpu_doing || s2_cpu_doing || s4_cpu_doing || s5_cpu_doing),
	.other_dma_doing(1'b0),
	// .other_dma_doing(s0_dma_doing || s1_dma_doing || s2_dma_doing || s4_dma_doing || s5_dma_doing),
	.this_s_m1_doing(s3_m1_doing),
	.cpu_doing(s3_cpu_doing),
	.dma_doing(s3_dma_doing),
	.grant_m0(grant_s3_m0),
	.grant_m1(grant_s3_m1),
	.grant_m2(grant_s3_m2),
	.grant_RW_m1(grant_RW_s3_m1),
	.grant_RW_m2(grant_RW_s3_m2)
);

// Arbiter for WDT
AXI_Arbiter arbiter_s4 (
	.ACLK(ACLK),
	.ARESETn(ARESETn),
	.req_m0(req_s4_m0), // Only request if targeting Slave 4
	.req_m1(req_s4_m1), // Only request if targeting Slave 4
	.req_m2(req_s4_m2), // Only request if targeting Slave 4
	.req_RW_m1(req_RW_m1),
	.req_RW_m2(req_RW_m2),
	.end_m0(end_m0),
	.end_m1_R(end_m1_R),
	.end_m1_W(end_m1_W),
	.end_m2_R(end_m2_R),
	.end_m2_W(end_m2_W),
	.other_s_m1_doing(s0_m1_doing || s1_m1_doing || s2_m1_doing || s3_m1_doing || s5_m1_doing),
	.other_cpu_doing(s0_cpu_doing || s1_cpu_doing || s2_cpu_doing || s3_cpu_doing || s5_cpu_doing),
	.other_dma_doing(1'b0),
	// .other_dma_doing(s0_dma_doing || s1_dma_doing || s2_dma_doing || s3_dma_doing || s5_dma_doing),
	.this_s_m1_doing(s4_m1_doing),
	.cpu_doing(s4_cpu_doing),
	.dma_doing(s4_dma_doing),
	.grant_m0(grant_s4_m0),
	.grant_m1(grant_s4_m1),
	.grant_m2(grant_s4_m2),
	.grant_RW_m1(grant_RW_s4_m1),
	.grant_RW_m2(grant_RW_s4_m2)
);

// Arbiter for DRAM
AXI_Arbiter arbiter_s5 (
	.ACLK(ACLK),
	.ARESETn(ARESETn),
	.req_m0(req_s5_m0), // Only request if targeting Slave 5
	.req_m1(req_s5_m1), // Only request if targeting Slave 5
	.req_m2(req_s5_m2), // Only request if targeting Slave 5
	.req_RW_m1(req_RW_m1),
	.req_RW_m2(req_RW_m2),
	.end_m0(end_m0),
	.end_m1_R(end_m1_R),
	.end_m1_W(end_m1_W),
	.end_m2_R(end_m2_R),
	.end_m2_W(end_m2_W),
	.other_s_m1_doing(s0_m1_doing || s1_m1_doing || s2_m1_doing || s3_m1_doing || s4_m1_doing),
	.other_cpu_doing(s0_cpu_doing || s1_cpu_doing || s2_cpu_doing || s3_cpu_doing || s4_cpu_doing),
	.other_dma_doing(1'b0),
	// .other_dma_doing(s0_dma_doing || s1_dma_doing || s2_dma_doing || s3_dma_doing || s4_dma_doing),
	.this_s_m1_doing(s5_m1_doing),
	.cpu_doing(s5_cpu_doing),
	.dma_doing(s5_dma_doing),
	.grant_m0(grant_s5_m0),
	.grant_m1(grant_s5_m1),
	.grant_m2(grant_s5_m2),
	.grant_RW_m1(grant_RW_s5_m1),
	.grant_RW_m2(grant_RW_s5_m2)
);

/* Master Interface for Slave */ 

// read channel
always_comb begin
	// Slave 0 (ROM: only read)	
	if (grant_s0_m0) begin // slave0 grant master0 (18)
		ARID_S0 = {4'b0, ARID_M0};
		ARADDR_S0 = ARADDR_M0;
		ARLEN_S0 = ARLEN_M0;
		ARSIZE_S0 = ARSIZE_M0;
		ARBURST_S0 = ARBURST_M0;
		ARVALID_S0 = ARVALID_M0;
		RREADY_S0 = RREADY_M0;
	end else if (grant_s0_m1 && grant_RW_s0_m1) begin // slave0 grant master1 (18)
		ARID_S0 = {4'b0, ARID_M1};
		ARADDR_S0 = ARADDR_M1;
		ARLEN_S0 = ARLEN_M1;
		ARSIZE_S0 = ARSIZE_M1;
		ARBURST_S0 = ARBURST_M1;
		ARVALID_S0 = ARVALID_M1;
		RREADY_S0 = RREADY_M1;		
	end else if (grant_s0_m2 && grant_RW_s0_m2) begin // HW3 new 	
		ARID_S0 = {4'b0, ARID_M2};
		ARADDR_S0 = ARADDR_M2;
		ARLEN_S0 = ARLEN_M2;
		ARSIZE_S0 = ARSIZE_M2;
		ARBURST_S0 = ARBURST_M2;
		ARVALID_S0 = ARVALID_M2;
		RREADY_S0 = RREADY_M2;		
	end else begin	
		ARID_S0 = `AXI_ID_BITS'b0;
		ARADDR_S0 = `AXI_ADDR_BITS'b0;
		ARLEN_S0 = `AXI_LEN_BITS'b0;
		ARSIZE_S0 = `AXI_SIZE_BITS'b0;
		ARBURST_S0 = 2'b0;
		ARVALID_S0 = 1'b0;
		RREADY_S0 = 1'b0;
	end

    // Slave 1
	if (grant_s1_m0) begin
		ARID_S1 = {4'b0, ARID_M0};
		ARADDR_S1 = ARADDR_M0;
		ARLEN_S1 = ARLEN_M0;
		ARSIZE_S1 = ARSIZE_M0;
		ARBURST_S1 = ARBURST_M0;
		ARVALID_S1 = ARVALID_M0;
		RREADY_S1 = RREADY_M0;
	end else if (grant_s1_m1 && grant_RW_s1_m1) begin
		ARID_S1 = {4'b0, ARID_M1};
		ARADDR_S1 = ARADDR_M1;
		ARLEN_S1 = ARLEN_M1;
		ARSIZE_S1 = ARSIZE_M1;
		ARBURST_S1 = ARBURST_M1;
		ARVALID_S1 = ARVALID_M1;
		RREADY_S1 = RREADY_M1;
	end else if (grant_s1_m2 && grant_RW_s1_m2) begin
		ARID_S1 = {4'b0, ARID_M2};
		ARADDR_S1 = ARADDR_M2;
		ARLEN_S1 = ARLEN_M2;
		ARSIZE_S1 = ARSIZE_M2;
		ARBURST_S1 = ARBURST_M2;
		ARVALID_S1 = ARVALID_M2;
		RREADY_S1 = RREADY_M2;
	end else begin
		ARID_S1 = `AXI_ID_BITS'b0;
		ARADDR_S1 = `AXI_ADDR_BITS'b0;
		ARLEN_S1 = `AXI_LEN_BITS'b0;
		ARSIZE_S1 = `AXI_SIZE_BITS'b0;
		ARBURST_S1 = 2'b0;
		ARVALID_S1 = 1'b0;
		RREADY_S1 = 1'b0;
	end
	// Slave 2
	if (grant_s2_m0) begin
		ARID_S2 = {4'b0, ARID_M0};
		ARADDR_S2 = ARADDR_M0;
		ARLEN_S2 = ARLEN_M0;
		ARSIZE_S2 = ARSIZE_M0;
		ARBURST_S2 = ARBURST_M0;
		ARVALID_S2 = ARVALID_M0;
		RREADY_S2 = RREADY_M0;
	end else if (grant_s2_m1 && grant_RW_s2_m1) begin
		ARID_S2 = {4'b0, ARID_M1};
		ARADDR_S2 = ARADDR_M1;
		ARLEN_S2 = ARLEN_M1;
		ARSIZE_S2 = ARSIZE_M1;
		ARBURST_S2 = ARBURST_M1;
		ARVALID_S2 = ARVALID_M1;
		RREADY_S2 = RREADY_M1;
	end else if (grant_s2_m2 && grant_RW_s2_m2) begin
		ARID_S2 = {4'b0, ARID_M2};
		ARADDR_S2 = ARADDR_M2;
		ARLEN_S2 = ARLEN_M2;
		ARSIZE_S2 = ARSIZE_M2;
		ARBURST_S2 = ARBURST_M2;
		ARVALID_S2 = ARVALID_M2;
		RREADY_S2 = RREADY_M2;
	end else begin
		ARID_S2 = `AXI_ID_BITS'b0;
		ARADDR_S2 = `AXI_ADDR_BITS'b0;
		ARLEN_S2 = `AXI_LEN_BITS'b0;
		ARSIZE_S2 = `AXI_SIZE_BITS'b0;
		ARBURST_S2 = 2'b0;
		ARVALID_S2 = 1'b0;
		RREADY_S2 = 1'b0;
	end

    // Slave 3 // DMA only write

    // Slave 4
	if (grant_s4_m0) begin
		ARID_S4 = {4'b0, ARID_M0};
		ARADDR_S4 = ARADDR_M0;
		ARLEN_S4 = ARLEN_M0;
		ARSIZE_S4 = ARSIZE_M0;
		ARBURST_S4 = ARBURST_M0;
		ARVALID_S4 = ARVALID_M0;
		RREADY_S4 = RREADY_M0;
	end else if (grant_s4_m1 && grant_RW_s4_m1) begin
		ARID_S4 = {4'b0, ARID_M1};
		ARADDR_S4 = ARADDR_M1;
		ARLEN_S4 = ARLEN_M1;
		ARSIZE_S4 = ARSIZE_M1;
		ARBURST_S4 = ARBURST_M1;
		ARVALID_S4 = ARVALID_M1;
		RREADY_S4 = RREADY_M1;
	end else if (grant_s4_m2 && grant_RW_s4_m2) begin
		ARID_S4 = {4'b0, ARID_M2};
		ARADDR_S4 = ARADDR_M2;
		ARLEN_S4 = ARLEN_M2;
		ARSIZE_S4 = ARSIZE_M2;
		ARBURST_S4 = ARBURST_M2;
		ARVALID_S4 = ARVALID_M2;
		RREADY_S4 = RREADY_M2;
	end else begin
		ARID_S4 = `AXI_ID_BITS'b0;
		ARADDR_S4 = `AXI_ADDR_BITS'b0;
		ARLEN_S4 = `AXI_LEN_BITS'b0;
		ARSIZE_S4 = `AXI_SIZE_BITS'b0;
		ARBURST_S4 = 2'b0;
		ARVALID_S4 = 1'b0;
		RREADY_S4 = 1'b0;
	end

	// Slave 5
	if (grant_s5_m0) begin
		ARID_S5 = {4'b0, ARID_M0};
		ARADDR_S5 = ARADDR_M0;
		ARLEN_S5 = ARLEN_M0;
		ARSIZE_S5 = ARSIZE_M0;
		ARBURST_S5 = ARBURST_M0;
		ARVALID_S5 = ARVALID_M0;
		RREADY_S5 = RREADY_M0;
	end else if (grant_s5_m1 && grant_RW_s5_m1) begin
		ARID_S5 = {4'b0, ARID_M1};
		ARADDR_S5 = ARADDR_M1;
		ARLEN_S5 = ARLEN_M1;
		ARSIZE_S5 = ARSIZE_M1;
		ARBURST_S5 = ARBURST_M1;
		ARVALID_S5 = ARVALID_M1;
		RREADY_S5 = RREADY_M1;
	end else if (grant_s5_m2 && grant_RW_s5_m2) begin
		ARID_S5 = {4'b0, ARID_M2};
		ARADDR_S5 = ARADDR_M2;
		ARLEN_S5 = ARLEN_M2;
		ARSIZE_S5 = ARSIZE_M2;
		ARBURST_S5 = ARBURST_M2;
		ARVALID_S5 = ARVALID_M2;
		RREADY_S5 = RREADY_M2;
	end else begin
		ARID_S5 = `AXI_ID_BITS'b0;
		ARADDR_S5 = `AXI_ADDR_BITS'b0;
		ARLEN_S5 = `AXI_LEN_BITS'b0;
		ARSIZE_S5 = `AXI_SIZE_BITS'b0;
		ARBURST_S5 = 2'b0;
		ARVALID_S5 = 1'b0;
		RREADY_S5 = 1'b0;
	end

end

// write channel
always_comb begin
	// Slave 0 (only read)

    // Slave 1
	if (grant_s1_m1 && ~grant_RW_s1_m1) begin
		AWID_S1 = {4'b0, AWID_M1};
		AWADDR_S1 = AWADDR_M1;
		AWLEN_S1 = AWLEN_M1;
		AWSIZE_S1 = AWSIZE_M1;
		AWBURST_S1 = AWBURST_M1;
		AWVALID_S1 = AWVALID_M1;
		WDATA_S1 = WDATA_M1;
		WSTRB_S1 = WSTRB_M1;
		WLAST_S1 = WLAST_M1;
		WVALID_S1 = WVALID_M1;
		BREADY_S1 = BREADY_M1;	
	end	else if (grant_s1_m2 && ~grant_RW_s1_m2) begin
		AWID_S1 = {4'b0, AWID_M2};
		AWADDR_S1 = AWADDR_M2;
		AWLEN_S1 = AWLEN_M2;
		AWSIZE_S1 = AWSIZE_M2;
		AWBURST_S1 = AWBURST_M2;
		AWVALID_S1 = AWVALID_M2;
		WDATA_S1 = WDATA_M2;
		WSTRB_S1 = WSTRB_M2;
		WLAST_S1 = WLAST_M2;
		WVALID_S1 = WVALID_M2;
		BREADY_S1 = BREADY_M2;
	end else begin
		AWID_S1 = `AXI_ID_BITS'b0;
		AWADDR_S1 = `AXI_ADDR_BITS'b0;
		AWLEN_S1 = `AXI_LEN_BITS'b0;
		AWSIZE_S1 = `AXI_SIZE_BITS'b0;
		AWBURST_S1 = 2'b0;
		AWVALID_S1 = 1'b0;
		WDATA_S1 = `AXI_DATA_BITS'b0;
		WSTRB_S1 = `AXI_STRB_BITS'b0;
		WLAST_S1 = 1'b0;
		WVALID_S1 = 1'b0;
		BREADY_S1 = 1'b0;
	end
	// Slave 2
	if (grant_s2_m1 && ~grant_RW_s2_m1) begin
		AWID_S2 = {4'b0, AWID_M1};
		AWADDR_S2 = AWADDR_M1;
		AWLEN_S2 = AWLEN_M1;
		AWSIZE_S2 = AWSIZE_M1;
		AWBURST_S2 = AWBURST_M1;
		AWVALID_S2 = AWVALID_M1;
		WDATA_S2 = WDATA_M1;
		WSTRB_S2 = WSTRB_M1;
		WLAST_S2 = WLAST_M1;
		WVALID_S2 = WVALID_M1;
		BREADY_S2 = BREADY_M1;
	end else if (grant_s2_m2 && ~grant_RW_s2_m2) begin
		AWID_S2 = {4'b0, AWID_M2};
		AWADDR_S2 = AWADDR_M2;
		AWLEN_S2 = AWLEN_M2;
		AWSIZE_S2 = AWSIZE_M2;
		AWBURST_S2 = AWBURST_M2;
		AWVALID_S2 = AWVALID_M2;
		WDATA_S2 = WDATA_M2;
		WSTRB_S2 = WSTRB_M2;
		WLAST_S2 = WLAST_M2;
		WVALID_S2 = WVALID_M2;
		BREADY_S2 = BREADY_M2;
	end else begin
		AWID_S2 = `AXI_ID_BITS'b0;
		AWADDR_S2 = `AXI_ADDR_BITS'b0;
		AWLEN_S2 = `AXI_LEN_BITS'b0;
		AWSIZE_S2 = `AXI_SIZE_BITS'b0;
		AWBURST_S2 = 2'b0;
		AWVALID_S2 = 1'b0;
		WDATA_S2 = `AXI_DATA_BITS'b0;
		WSTRB_S2 = `AXI_STRB_BITS'b0;
		WLAST_S2 = 1'b0;
		WVALID_S2 = 1'b0;
		BREADY_S2 = 1'b0;
	end
	// Slave 3
	if (grant_s3_m1 && ~grant_RW_s3_m1) begin
		AWID_S3 = {4'b0, AWID_M1};
		AWADDR_S3 = AWADDR_M1;
		AWLEN_S3 = AWLEN_M1;
		AWSIZE_S3 = AWSIZE_M1;
		AWBURST_S3 = AWBURST_M1;
		AWVALID_S3 = AWVALID_M1;
		WDATA_S3 = WDATA_M1;
		WSTRB_S3 = WSTRB_M1;
		WLAST_S3 = WLAST_M1;
		WVALID_S3 = WVALID_M1;
		BREADY_S3 = BREADY_M1;
	end else if (grant_s3_m2 && ~grant_RW_s3_m2) begin
		AWID_S3 = {4'b0, AWID_M2};
		AWADDR_S3 = AWADDR_M2;
		AWLEN_S3 = AWLEN_M2;
		AWSIZE_S3 = AWSIZE_M2;
		AWBURST_S3 = AWBURST_M2;
		AWVALID_S3 = AWVALID_M2;
		WDATA_S3 = WDATA_M2;
		WSTRB_S3 = WSTRB_M2;
		WLAST_S3 = WLAST_M2;
		WVALID_S3 = WVALID_M2;
		BREADY_S3 = BREADY_M2;
	end else begin
		AWID_S3 = `AXI_ID_BITS'b0;
		AWADDR_S3 = `AXI_ADDR_BITS'b0;
		AWLEN_S3 = `AXI_LEN_BITS'b0;
		AWSIZE_S3 = `AXI_SIZE_BITS'b0;
		AWBURST_S3 = 2'b0;
		AWVALID_S3 = 1'b0;
		WDATA_S3 = `AXI_DATA_BITS'b0;
		WSTRB_S3 = `AXI_STRB_BITS'b0;
		WLAST_S3 = 1'b0;
		WVALID_S3 = 1'b0;
		BREADY_S3 = 1'b0;
	end

	// Slave 4
	if (grant_s4_m1 && ~grant_RW_s4_m1) begin
		AWID_S4 = {4'b0, AWID_M1};
		AWADDR_S4 = AWADDR_M1;
		AWLEN_S4 = AWLEN_M1;
		AWSIZE_S4 = AWSIZE_M1;
		AWBURST_S4 = AWBURST_M1;
		AWVALID_S4 = AWVALID_M1;
		WDATA_S4 = WDATA_M1;
		WSTRB_S4 = WSTRB_M1;
		WLAST_S4 = WLAST_M1;
		WVALID_S4 = WVALID_M1;
		BREADY_S4 = BREADY_M1;
	end else if (grant_s4_m2 && ~grant_RW_s4_m2) begin
		AWID_S4 = {4'b0, AWID_M2};
		AWADDR_S4 = AWADDR_M2;
		AWLEN_S4 = AWLEN_M2;
		AWSIZE_S4 = AWSIZE_M2;
		AWBURST_S4 = AWBURST_M2;
		AWVALID_S4 = AWVALID_M2;
		WDATA_S4 = WDATA_M2;
		WSTRB_S4 = WSTRB_M2;
		WLAST_S4 = WLAST_M2;
		WVALID_S4 = WVALID_M2;
		BREADY_S4 = BREADY_M2;
	end else begin
		AWID_S4 = `AXI_ID_BITS'b0;
		AWADDR_S4 = `AXI_ADDR_BITS'b0;
		AWLEN_S4 = `AXI_LEN_BITS'b0;
		AWSIZE_S4 = `AXI_SIZE_BITS'b0;
		AWBURST_S4 = 2'b0;
		AWVALID_S4 = 1'b0;
		WDATA_S4 = `AXI_DATA_BITS'b0;
		WSTRB_S4 = `AXI_STRB_BITS'b0;
		WLAST_S4 = 1'b0;
		WVALID_S4 = 1'b0;
		BREADY_S4 = 1'b0;
	end

	// Slave 5
	if (grant_s5_m1 && ~grant_RW_s5_m1) begin
		AWID_S5 = {4'b0, AWID_M1};
		AWADDR_S5 = AWADDR_M1;
		AWLEN_S5 = AWLEN_M1;
		AWSIZE_S5 = AWSIZE_M1;
		AWBURST_S5 = AWBURST_M1;
		AWVALID_S5 = AWVALID_M1;
		WDATA_S5 = WDATA_M1;
		WSTRB_S5 = WSTRB_M1;
		WLAST_S5 = WLAST_M1;
		WVALID_S5 = WVALID_M1;
		BREADY_S5 = BREADY_M1;
	end else if (grant_s5_m2 && ~grant_RW_s5_m2) begin
		AWID_S5 = {4'b0, AWID_M2};
		AWADDR_S5 = AWADDR_M2;
		AWLEN_S5 = AWLEN_M2;
		AWSIZE_S5 = AWSIZE_M2;
		AWBURST_S5 = AWBURST_M2;
		AWVALID_S5 = AWVALID_M2;
		WDATA_S5 = WDATA_M2;
		WSTRB_S5 = WSTRB_M2;
		WLAST_S5 = WLAST_M2;
		WVALID_S5 = WVALID_M2;
		BREADY_S5 = BREADY_M2;
	end else begin
		AWID_S5 = `AXI_ID_BITS'b0;
		AWADDR_S5 = `AXI_ADDR_BITS'b0;
		AWLEN_S5 = `AXI_LEN_BITS'b0;
		AWSIZE_S5 = `AXI_SIZE_BITS'b0;
		AWBURST_S5 = 2'b0;
		AWVALID_S5 = 1'b0;
		WDATA_S5 = `AXI_DATA_BITS'b0;
		WSTRB_S5 = `AXI_STRB_BITS'b0;
		WLAST_S5 = 1'b0;
		WVALID_S5 = 1'b0;
		BREADY_S5 = 1'b0;
	end

end

/* Slave Interface for Master */

// read channel 
always_comb begin
	// Master 0 read channel
	if (grant_s0_m0) begin
		ARREADY_M0 = ARREADY_S0;
		RID_M0 = RID_S0[3:0];
		RDATA_M0 = RDATA_S0;
		RRESP_M0 = RRESP_S0;
		RLAST_M0 = RLAST_S0;
		RVALID_M0 = RVALID_S0;
	end else if (grant_s1_m0) begin
		ARREADY_M0 = ARREADY_S1;
		RID_M0 = RID_S1[3:0];
		RDATA_M0 = RDATA_S1;
		RRESP_M0 = RRESP_S1;
		RLAST_M0 = RLAST_S1;
		RVALID_M0 = RVALID_S1;
	end else if (grant_s2_m0) begin
        ARREADY_M0 = ARREADY_S2;
        RID_M0 = RID_S2[3:0];
        RDATA_M0 = RDATA_S2;
        RRESP_M0 = RRESP_S2;
        RLAST_M0 = RLAST_S2;
        RVALID_M0 = RVALID_S2;
    end else if (grant_s3_m0) begin
		ARREADY_M0 = 1'b0;
		RID_M0 = {`AXI_ID_BITS{1'b0}};
		RDATA_M0 = {`AXI_DATA_BITS{1'b0}};
		RRESP_M0 = 2'b0;
		RLAST_M0 = 1'b0;
		RVALID_M0 = 1'b0;
	end else if (grant_s4_m0) begin
		ARREADY_M0 = ARREADY_S4;
		RID_M0 = RID_S4[3:0];
		RDATA_M0 = RDATA_S4;
		RRESP_M0 = RRESP_S4;
		RLAST_M0 = RLAST_S4;
		RVALID_M0 = RVALID_S4;
	end else if (grant_s5_m0) begin
		ARREADY_M0 = ARREADY_S5;
		RID_M0 = RID_S5[3:0];
		RDATA_M0 = RDATA_S5;
		RRESP_M0 = RRESP_S5;
		RLAST_M0 = RLAST_S5;
		RVALID_M0 = RVALID_S5;
	end else begin
		ARREADY_M0 = 1'b0;
		RID_M0 = {`AXI_ID_BITS{1'b0}};
		RDATA_M0 = {`AXI_DATA_BITS{1'b0}};
		RRESP_M0 = 2'b11; 
		RLAST_M0 = 1'b0;
		RVALID_M0 = 1'b0;
	end

	// Master 1 read channel
	if (grant_s0_m1 && grant_RW_s0_m1) begin
		ARREADY_M1 = ARREADY_S0;
		RID_M1 = RID_S0[3:0];
		RDATA_M1 = RDATA_S0;
		RRESP_M1 = RRESP_S0;
		RLAST_M1 = RLAST_S0;
		RVALID_M1 = RVALID_S0;
	end else if (grant_s1_m1 && grant_RW_s1_m1) begin
		ARREADY_M1 = ARREADY_S1;
		RID_M1 = RID_S1[3:0];
		RDATA_M1 = RDATA_S1;
		RRESP_M1 = RRESP_S1;
		RLAST_M1 = RLAST_S1;
		RVALID_M1 = RVALID_S1;
	end else if (grant_s2_m1 && grant_RW_s2_m1) begin
		ARREADY_M1 = ARREADY_S2;
		RID_M1 = RID_S2[3:0];
		RDATA_M1 = RDATA_S2;
		RRESP_M1 = RRESP_S2;
		RLAST_M1 = RLAST_S2;
		RVALID_M1 = RVALID_S2;
	// end else if (grant_s3_m1 && grant_RW_s3_m1) begin // slave3 only write
	// 	ARREADY_M1 = ARREADY_S3;
	// 	RID_M1 = RID_S3;
	// 	RDATA_M1 = RDATA_S3;
	// 	RRESP_M1 = RRESP_S3;
	// 	RLAST_M1 = RLAST_S3;
	// 	RVALID_M1 = RVALID_S3;
	end else if (grant_s4_m1 && grant_RW_s4_m1) begin
		ARREADY_M1 = ARREADY_S4;
		RID_M1 = RID_S4[3:0];
		RDATA_M1 = RDATA_S4;
		RRESP_M1 = RRESP_S4;
		RLAST_M1 = RLAST_S4;
		RVALID_M1 = RVALID_S4;
	end else if (grant_s5_m1 && grant_RW_s5_m1) begin
		ARREADY_M1 = ARREADY_S5;
		RID_M1 = RID_S5[3:0];
		RDATA_M1 = RDATA_S5;
		RRESP_M1 = RRESP_S5;
		RLAST_M1 = RLAST_S5;
		RVALID_M1 = RVALID_S5;
	end else begin
		ARREADY_M1 = 1'b0;
		RID_M1 = {`AXI_ID_BITS{1'b0}};
		RDATA_M1 = {`AXI_DATA_BITS{1'b0}};
		RRESP_M1 = 2'b11; 
		RLAST_M1 = 1'b0;
		RVALID_M1 = 1'b0;
	end

	// Master 2 read channel
	if (grant_s0_m2 && grant_RW_s0_m2) begin
		ARREADY_M2 = ARREADY_S0;
		RID_M2 = RID_S0[3:0];
		RDATA_M2 = RDATA_S0;
		RRESP_M2 = RRESP_S0;
		RLAST_M2 = RLAST_S0;
		RVALID_M2 = RVALID_S0;
	end else if (grant_s1_m2 && grant_RW_s1_m2) begin
		ARREADY_M2 = ARREADY_S1;
		RID_M2 = RID_S1[3:0];
		RDATA_M2 = RDATA_S1;
		RRESP_M2 = RRESP_S1;
		RLAST_M2 = RLAST_S1;
		RVALID_M2 = RVALID_S1;
	end else if (grant_s2_m2 && grant_RW_s2_m2) begin
		ARREADY_M2 = ARREADY_S2;
		RID_M2 = RID_S2[3:0];
		RDATA_M2 = RDATA_S2;
		RRESP_M2 = RRESP_S2;
		RLAST_M2 = RLAST_S2;
		RVALID_M2 = RVALID_S2;
	// end else if (grant_s3_m2 && grant_RW_s3_m2) begin // slave3 only write
	// 	ARREADY_M2 = ARREADY_S3;
	// 	RID_M2 = RID_S3;
	// 	RDATA_M2 = RDATA_S3;
	// 	RRESP_M2 = RRESP_S3;
	// 	RLAST_M2 = RLAST_S3;
	// 	RVALID_M2 = RVALID_S3;
	end else if (grant_s4_m2 && grant_RW_s4_m2) begin
		ARREADY_M2 = ARREADY_S4;
		RID_M2 = RID_S4[3:0];
		RDATA_M2 = RDATA_S4;
		RRESP_M2 = RRESP_S4;
		RLAST_M2 = RLAST_S4;
		RVALID_M2 = RVALID_S4;
	end else if (grant_s5_m2 && grant_RW_s5_m2) begin
		ARREADY_M2 = ARREADY_S5;
		RID_M2 = RID_S5[3:0];
		RDATA_M2 = RDATA_S5;
		RRESP_M2 = RRESP_S5;
		RLAST_M2 = RLAST_S5;
		RVALID_M2 = RVALID_S5;
	end else begin
		ARREADY_M2 = 1'b0;
		RID_M2 = {`AXI_ID_BITS{1'b0}};
		RDATA_M2 = {`AXI_DATA_BITS{1'b0}};
		RRESP_M2 = 2'b11; 
		RLAST_M2 = 1'b0;
		RVALID_M2 = 1'b0;
	end

end

// write channel
always_comb begin

	// Master 1 write channel
	if (grant_s0_m1 && ~grant_RW_s0_m1) begin // ROM only read
		AWREADY_M1 = 1'b0;
		WREADY_M1 = 1'b0;
		BID_M1 = {`AXI_ID_BITS{1'b0}};
		BRESP_M1 = 2'b0;
		BVALID_M1 = 1'b0;
	end else if (grant_s1_m1 && ~grant_RW_s1_m1) begin
		AWREADY_M1 = AWREADY_S1;
		WREADY_M1 = WREADY_S1;
		BID_M1 = BID_S1[3:0];
		BRESP_M1 = BRESP_S1;
		BVALID_M1 = BVALID_S1;
	end else if (grant_s2_m1 && ~grant_RW_s2_m1) begin
		AWREADY_M1 = AWREADY_S2;
		WREADY_M1 = WREADY_S2;
		BID_M1 = BID_S2[3:0];
		BRESP_M1 = BRESP_S2;
		BVALID_M1 = BVALID_S2;
	end else if (grant_s3_m1 && ~grant_RW_s3_m1) begin
		AWREADY_M1 = AWREADY_S3;
		WREADY_M1 = WREADY_S3;
		BID_M1 = BID_S3[3:0];
		BRESP_M1 = BRESP_S3;
		BVALID_M1 = BVALID_S3;
	end else if (grant_s4_m1 && ~grant_RW_s4_m1) begin
		AWREADY_M1 = AWREADY_S4;
		WREADY_M1 = WREADY_S4;
		BID_M1 = BID_S4[3:0];
		BRESP_M1 = BRESP_S4;
		BVALID_M1 = BVALID_S4;
	end else if (grant_s5_m1 && ~grant_RW_s5_m1) begin
		AWREADY_M1 = AWREADY_S5;
		WREADY_M1 = WREADY_S5;
		BID_M1 = BID_S5[3:0];
		BRESP_M1 = BRESP_S5;
		BVALID_M1 = BVALID_S5;
	end else begin
		AWREADY_M1 = 1'b0;
		WREADY_M1 = 1'b0;
		BID_M1 = {`AXI_ID_BITS{1'b0}};
		BRESP_M1 = 2'b11; 
		BVALID_M1 = 1'b0;
	end

	// Master 2 write channel
	if (grant_s1_m2 && ~grant_RW_s1_m2) begin
		AWREADY_M2 = AWREADY_S1;
		WREADY_M2 = WREADY_S1;
		BID_M2 = BID_S1[3:0];
		BRESP_M2 = BRESP_S1;
		BVALID_M2 = BVALID_S1;
	end else if (grant_s2_m2 && ~grant_RW_s2_m2) begin
		AWREADY_M2 = AWREADY_S2;
		WREADY_M2 = WREADY_S2;
		BID_M2 = BID_S2[3:0];
		BRESP_M2 = BRESP_S2;
		BVALID_M2 = BVALID_S2;
	end else if (grant_s3_m2 && ~grant_RW_s3_m2) begin
		AWREADY_M2 = AWREADY_S3;
		WREADY_M2 = WREADY_S3;
		BID_M2 = BID_S3[3:0];
		BRESP_M2 = BRESP_S3;
		BVALID_M2 = BVALID_S3;
	end else if (grant_s4_m2 && ~grant_RW_s4_m2) begin
		AWREADY_M2 = AWREADY_S4;
		WREADY_M2 = WREADY_S4;
		BID_M2 = BID_S4[3:0];
		BRESP_M2 = BRESP_S4;
		BVALID_M2 = BVALID_S4;
	end else if (grant_s5_m2 && ~grant_RW_s5_m2) begin
		AWREADY_M2 = AWREADY_S5;
		WREADY_M2 = WREADY_S5;
		BID_M2 = BID_S5[3:0];
		BRESP_M2 = BRESP_S5;
		BVALID_M2 = BVALID_S5;
	end else begin
		AWREADY_M2 = 1'b0;
		WREADY_M2 = 1'b0;
		BID_M2 = {`AXI_ID_BITS{1'b0}};
		BRESP_M2 = 2'b11; 
		BVALID_M2 = 1'b0;
	end

end

endmodule
