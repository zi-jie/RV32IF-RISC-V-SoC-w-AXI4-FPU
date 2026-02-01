// `include "../sim/SRAM/SRAM_rtl.sv"
`include "../include/AXI_define.svh"

module SRAM_wrapper (
    input  logic           ACLK,
    input  logic           ARESETn,

    input  logic [`AXI_IDS_BITS-1:0]    AWID_S,         
    input  logic [`AXI_ADDR_BITS-1:0]   AWADDR_S,       
    input  logic [`AXI_LEN_BITS-1:0]    AWLEN_S,        
    input  logic [`AXI_SIZE_BITS-1:0]   AWSIZE_S,       
    input  logic [1:0]                  AWBURST_S,      
    input  logic                        AWVALID_S,
    output logic                        AWREADY_S,

    input  logic [`AXI_DATA_BITS-1:0]   WDATA_S,        
    input  logic [`AXI_STRB_BITS-1:0]   WSTRB_S,        
    input  logic                        WLAST_S,
    input  logic                        WVALID_S,
    output logic                        WREADY_S,
    
    output logic [`AXI_IDS_BITS-1:0]    BID_S,          
    output logic [1:0]                  BRESP_S,        
    output logic                        BVALID_S,
    input  logic                        BREADY_S,
    
    // Read Address Channel
    input  logic [`AXI_IDS_BITS-1:0]    ARID_S,         
    input  logic [`AXI_ADDR_BITS-1:0]   ARADDR_S,       
    input  logic [`AXI_LEN_BITS-1:0]    ARLEN_S,        
    input  logic [`AXI_SIZE_BITS-1:0]   ARSIZE_S,       
    input  logic [1:0]                  ARBURST_S,      
    input  logic                        ARVALID_S,
    output logic                        ARREADY_S,
    
    // Read Data Channel
    output logic [`AXI_IDS_BITS-1:0]    RID_S,          
    output logic [`AXI_DATA_BITS-1:0]   RDATA_S,        
    output logic [1:0]                  RRESP_S,        
    output logic                        RLAST_S,
    output logic                        RVALID_S,
    input  logic                        RREADY_S

    // SRAM
    // output logic [`AXI_ADDR_BITS-1:0]   A,
    // output logic                        WEB,
    // output logic [`AXI_DATA_BITS-1:0]   DO     
);

logic is_reading;
logic is_writing;

// R parameters
logic [`AXI_IDS_BITS-1:0]  ARID;
logic [`AXI_ADDR_BITS-1:0] ARADDR;
logic [`AXI_LEN_BITS-1:0]  ARLEN;
logic [`AXI_SIZE_BITS-1:0] ARSIZE;
logic [1:0]                ARBURST; // only INCR: 01

// W parameters
logic [`AXI_IDS_BITS-1:0]  AWID;
logic [`AXI_ADDR_BITS-1:0] AWADDR;
logic [`AXI_LEN_BITS-1:0]  AWLEN;
logic [`AXI_SIZE_BITS-1:0] AWSIZE;
logic [1:0]                AWBURST; // only INCR: 01

logic [`AXI_ADDR_BITS-1:0] R_addr, W_addr;
logic [`AXI_ADDR_BITS-1:0] Read_addr, Write_addr;

//logic [`AXI_LEN_BITS-1:0]  rcount;

// SRAM
logic [`AXI_DATA_BITS-1:0] DI, DO;
logic WEB; // read: 1, write: 0
logic [31:0] BWEB; // active low
logic [`AXI_ADDR_BITS-1:0]   A;

// Decide read/write address, WEB 
always_comb begin 
    if (is_writing) begin
        A = W_addr;
        if (WREADY_S == 1'b1 && WVALID_S == 1'b1)
            WEB = 1'b0; // write
        else
            WEB = 1'b1;
    end else begin
        // A = R_addr;
	    A = Read_addr;
        WEB = 1'b1; // read
    end
end

assign RDATA_S = DO;
assign DI = WDATA_S;
assign BWEB = {{8{~WSTRB_S[3]}}, {8{~WSTRB_S[2]}}, {8{~WSTRB_S[1]}}, {8{~WSTRB_S[0]}}};

/* Write transaction */

// AWVALID and ARVALID = 1 together, Read first

// Write Address Channel: AWVALID
always_ff @(posedge ACLK or negedge ARESETn) begin
    if (ARESETn == 1'b0) begin
        AWREADY_S <= 1'b0;
        is_writing <= 1'b0;
    end else if (AWVALID_S == 1'b1 && ARVALID_S == 1'b0 && !AWREADY_S && !is_reading && !is_writing) begin
        AWREADY_S <= 1'b1;
        is_writing <= 1'b1;
    end else if (WLAST_S) begin
        AWREADY_S <= 1'b0;
        is_writing <= 1'b0;
    end else begin
        AWREADY_S <= 1'b0;  
        is_writing <= is_writing;  
    end
end

// Parameter transfer: AWREADY
always_ff @(posedge ACLK or negedge ARESETn) begin
    if (ARESETn == 1'b0) begin
        AWID <= 'b0;
        AWADDR <= 'b0;
        //AWLEN <= 'b0;
        AWSIZE <= 'b0;
        AWBURST <= 'b0;
    // AW, AR valid both = 1, read first, write wait
    end else if (AWVALID_S == 1'b1 && ARVALID_S == 1'b0 && !AWREADY_S && !is_reading && !is_writing) begin
        AWID <= AWID_S;
        AWADDR <= (AWADDR_S >> AWSIZE_S) << AWSIZE_S; // alingment
        //AWLEN <= AWLEN_S;
        AWSIZE <= AWSIZE_S;
        AWBURST <= AWBURST_S;
    end
end

// Write Data Channel: WREADY
always_ff @(posedge ACLK or negedge ARESETn) begin
    if (ARESETn == 1'b0) begin
        WREADY_S <= 1'b0;
    end else if (AWVALID_S == 1'b1 && AWREADY_S == 1'b1) begin
        WREADY_S <= 1'b1; 
    end else if (WLAST_S) begin
        WREADY_S <= 1'b0;
    end 
end

always_comb begin
    if (WVALID_S == 1'b1 && WREADY_S == 1'b1) 
        Write_addr = W_addr + 2**(AWSIZE); 
    else 
        Write_addr = Write_addr;
end

// Calculate Write address
always_ff @(posedge ACLK or negedge ARESETn) begin
    if (ARESETn == 1'b0) begin
        AWLEN <= 'b0;
        W_addr <= 'b0;
    end else if (AWVALID_S == 1'b1 && ARVALID_S == 1'b0 && !AWREADY_S && !is_reading && !is_writing) begin
        AWLEN <= AWLEN_S; 
        W_addr <= (AWADDR_S >> AWSIZE_S) << AWSIZE_S; // parameter transfer
    end else if (WVALID_S == 1'b1 && WREADY_S == 1'b1) begin
        if (AWLEN > 0) begin
            AWLEN <= AWLEN - 'b1;
            W_addr <= W_addr + 2**AWSIZE; // Number_Bytes = 2 ^ AxSIZE
        end else begin
            AWLEN <= 'b0;
            W_addr <= 'b0;
        end
    end
end

// assign WLAST_S = (AWLEN == 0) && (WVALID_S == 1'b1 && WREADY_S == 1'b1) && is_writing;

// B channel
always_ff @(posedge ACLK or negedge ARESETn) begin
    if (ARESETn == 1'b0) begin
        BID_S <= 'b0;
        BRESP_S <= 2'b00;
        BVALID_S <= 1'b0;
    end else if (WLAST_S == 1'b1 && WVALID_S == 1'b1 && WREADY_S == 1'b1) begin
        BID_S <= AWID;
        BRESP_S <= 2'b00;
        BVALID_S <= 1'b1;
    end else if (BREADY_S == 1'b1 && BVALID_S == 1'b1) begin
        BID_S <= 'b0;
        BRESP_S <= 2'b00;
        BVALID_S <= 1'b0;
    end
end

/* Read transaction */

// Read Address Channel: ARVALID
always_ff @(posedge ACLK or negedge ARESETn) begin 
    if (ARESETn == 1'b0) begin
        ARREADY_S <= 1'b0;
        is_reading <= 1'b0;
    end else if (ARVALID_S == 1'b1 && !ARREADY_S && !is_reading && !is_writing) begin
        ARREADY_S <= 1'b1;
        is_reading <= 1'b1;
    end else if (RLAST_S && RVALID_S && RREADY_S) begin
        ARREADY_S <= 1'b0;
        is_reading <= 1'b0;
    end else begin
        ARREADY_S <= 1'b0;  
        is_reading <= is_reading;  
    end
end

// Parameter transfer: ARREADY
always_ff @(posedge ACLK or negedge ARESETn) begin
    if (ARESETn == 1'b0) begin
        ARID <= 'b0;
        ARADDR <= 'b0;
        //ARLEN <= 'b0;
        ARSIZE <= 'b0;
        ARBURST <= 'b0;
    end else if (ARVALID_S == 1'b1 && !ARREADY_S && !is_reading && !is_writing) begin
        ARID <= ARID_S;
        // ARADDR <= ARADDR_S;
        ARADDR <= (ARADDR_S >> ARSIZE_S) << ARSIZE_S; // alingment
        //ARLEN <= ARLEN_S;
        ARSIZE <= ARSIZE_S;
        ARBURST <= ARBURST_S;
    end
end

// Read Data Channel: RVAILD
always_ff @(posedge ACLK or negedge ARESETn) begin
    if (ARESETn == 1'b0) begin
        RVALID_S <= 1'b0;
        RID_S <= 'b0;
    end else if (ARVALID_S == 1'b1 && ARREADY_S == 1'b1) begin
        RVALID_S <= 1'b1; // must wait for both ARVALID and ARREADY to be asserted before asserts RVALID
        RID_S <= ARID;
    end else if (RLAST_S && RVALID_S && RREADY_S) begin
        RVALID_S <= 1'b0;
        RID_S <= 'b0;
    end 
end

/*
always_ff @(posedge ACLK or negedge ARESETn) begin
    if (ARESETn == 1'b0) 
        Read_addr <= 'b0;
    else if (RVALID_S == 1'b1 && RREADY_S == 1'b1) 
	    Read_addr = R_addr + 2**(ARSIZE); 
    else 
        Read_addr <= Read_addr;
end
*/

always_comb begin
    if (RVALID_S == 1'b1 && RREADY_S == 1'b1 && (ARLEN > 0)) begin
	    Read_addr = R_addr + 2**(ARSIZE); 
    end else
        Read_addr = R_addr;
end  

// Calculate Read address
always_ff @(posedge ACLK or negedge ARESETn) begin
    if (ARESETn == 1'b0) begin
        R_addr <= 'b0;
        ARLEN <= 'b0;
        RRESP_S <= 2'b00;
    end else if (ARVALID_S == 1'b1 && !ARREADY_S && !is_reading && !is_writing) begin
        R_addr <= (ARADDR_S >> ARSIZE_S) << ARSIZE_S; // parameter transfer
        ARLEN <= ARLEN_S;
        RRESP_S <= 2'b00;
    end else if (RVALID_S == 1'b1 && RREADY_S == 1'b1) begin
        RRESP_S <= 2'b00;
        if (ARLEN > 0) begin
            ARLEN <= ARLEN - 'b1;
            R_addr <= R_addr + 2**(ARSIZE); // Number_Bytes = 2 ^ AxSIZE
        end else begin
            ARLEN <= 'b0;
            // R_addr <= 'b0;
            R_addr <= R_addr;
        end
    end
end

// assign RLAST_S = (ARLEN == 0) && (RVALID_S == 1'b1 && RREADY_S == 1'b1) && is_reading;
assign RLAST_S = (ARLEN == 0) && (RVALID_S == 1'b1) && is_reading;

//FIXME: check A[15:2]?
TS1N16ADFPCLLLVTA512X45M4SWSHOD i_SRAM(
	.SLP(1'b0),
    .DSLP(1'b0),
    .SD(1'b0),
    .PUDELAY(),
    .CLK(ACLK), 
    .CEB(1'b0), 
    .WEB(WEB),
    .A(A[15:2]), 
    .D(DI),
    .BWEB(BWEB),
    .RTSEL(2'b01),
    .WTSEL(2'b01),
    .Q(DO)
);

endmodule
