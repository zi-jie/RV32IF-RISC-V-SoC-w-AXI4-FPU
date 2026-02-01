`include "../include/AXI_define.svh"

module DMA_master_FSM(
    input ACLK,
    input ARESETn,

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

    // connect with DMA
    input [`AXI_LEN_BITS-1:0] burst_len,
    output logic read_data_valid,
    output logic [`AXI_DATA_BITS-1:0] read_data,
    input AR_valid,
    input [`AXI_ADDR_BITS-1:0] read_addr,
    input AW_valid,
    input [`AXI_ADDR_BITS-1:0] write_addr,
    input W_valid,
    input [`AXI_DATA_BITS-1:0] write_data,
    input W_last,
    output logic master_W_done,
    output logic master_B_done
);

logic [1:0] rch_nst;
logic [1:0] rch_cst;
logic [1:0] wch_nst;
logic [1:0] wch_cst;

// current state
always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn) 
    begin
        rch_cst <= `DMA_WAIT_R_REQUEST;
        wch_cst <= `DMA_WAIT_W_REQUEST;
    end
    else 
    begin
        rch_cst <= rch_nst;
        wch_cst <= wch_nst;
    end
end

// read channel next state
always_comb begin
    case(rch_cst)
        `DMA_WAIT_R_REQUEST: begin
            if (AR_valid)
                rch_nst = `DMA_AR_VALID;
            else
                rch_nst = `DMA_WAIT_R_REQUEST;
        end
        `DMA_AR_VALID: begin
            if (ARREADY_M)
                rch_nst = `DMA_GET_READ_DATA;
            else
                rch_nst = `DMA_AR_VALID;
        end
        `DMA_GET_READ_DATA: begin
            if ((RVALID_M == 1'b1) && (RLAST_M == 1'b1))
                rch_nst = `DMA_WAIT_R_REQUEST;
            else
                rch_nst = `DMA_GET_READ_DATA;
        end
        default: rch_nst = `DMA_WAIT_R_REQUEST;
    endcase
end

// write channel next state
always_comb begin
    case(wch_cst)
        `DMA_WAIT_W_REQUEST: begin
            if (AW_valid)
                wch_nst = `DMA_AW_VALID;
            else
                wch_nst = `DMA_WAIT_W_REQUEST;
        end
        `DMA_AW_VALID: begin
            if (AWREADY_M)
                wch_nst = `DMA_WRITE_DATA;
            else
                wch_nst = `DMA_AW_VALID;
        end
        `DMA_WRITE_DATA: begin
            if ((W_valid == 1'b1) && (WREADY_M == 1'b1) && (W_last == 1'b1))
                wch_nst = `DMAMASTER_W_RESPONSE;
            else
                wch_nst = `DMA_WRITE_DATA;
        end
        `DMAMASTER_W_RESPONSE: begin
            if (BVALID_M)
                wch_nst = `DMA_WAIT_W_REQUEST;
            else    
                wch_nst = `DMAMASTER_W_RESPONSE;
        end
        default: wch_nst = `DMA_WAIT_W_REQUEST;
    endcase
end

// output to DMA
assign read_data_valid = ((rch_cst == `DMA_GET_READ_DATA) 
                        && (RVALID_M == 1'b1));
assign read_data = RDATA_M;
assign master_W_done = ((wch_cst == `DMA_WRITE_DATA)
                    && (W_valid == 1'b1) && (WREADY_M == 1'b1));
assign master_B_done = ((wch_cst == `DMAMASTER_W_RESPONSE)
                    && (BVALID_M == 1'b1));

// output to AXI, write channel
assign AWID_M = `AXI_ID_BITS'b0;
assign AWADDR_M = write_addr;
assign AWLEN_M = burst_len;
assign AWSIZE_M = `AXI_SIZE_BITS'd2;
assign AWBURST_M = 2'b01;
assign AWVALID_M = (wch_cst == `DMA_AW_VALID);

assign WDATA_M = write_data;
assign WSTRB_M = `AXI_STRB_BITS'hf;
assign WLAST_M = W_last;
assign WVALID_M = ((wch_cst == `DMA_WRITE_DATA) && (W_valid));

assign BREADY_M = (wch_cst == `DMAMASTER_W_RESPONSE);

// output to AXI, read channel
assign ARID_M = `AXI_ID_BITS'b0;
assign ARADDR_M = read_addr;
assign ARLEN_M = burst_len;
assign ARSIZE_M = `AXI_SIZE_BITS'd2;
assign ARBURST_M = 2'b01;
assign ARVALID_M = (rch_cst == `DMA_AR_VALID);

assign RREADY_M = (rch_cst == `DMA_GET_READ_DATA);

endmodule