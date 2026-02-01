`include "../include/AXI_define.svh"

module DMA_slave_FSM(
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

    // to DMA
    output logic [`AXI_ADDR_BITS-1:0] config_addr,
    output logic DMASRC_valid,
    output logic DMADST_valid,
    output logic DMALEN_valid,
    output logic DMA_enable
);

logic [2:0] nst;
logic [2:0] cst;

logic [`AXI_ADDR_BITS-1:0] waddr_reg;
logic [`AXI_IDS_BITS-1:0] id_reg;

// current state
always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn) 
    begin
        cst <= `DMA_WAIT_VALID;
    end
    else 
    begin
        cst <= nst;
    end
end

// next state
always_comb begin
    case(cst)
        `DMA_WAIT_VALID: begin
            if (AWVALID_S)
                nst = `DMA_GET_CONFIG;
            else
                nst = `DMA_WAIT_VALID;
        end
        `DMA_GET_CONFIG: begin
            if ((WVALID_S == 1'b1) && (WLAST_S == 1'b1))
                nst = `DMASLAVE_W_RESPONSE;
            else
                nst = `DMA_GET_CONFIG;
        end
        `DMASLAVE_W_RESPONSE: begin
            if (BREADY_S)
                nst = `DMA_WAIT_VALID;
            else
                nst = `DMASLAVE_W_RESPONSE;
        end
        default: nst = `DMA_WAIT_VALID;
    endcase
end

// register
always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn)
    begin
        waddr_reg <= `AXI_ADDR_BITS'b0;
        id_reg <= `AXI_IDS_BITS'b0;
    end
    else if ((AWVALID_S == 1'b1) && (cst == `DMA_WAIT_VALID))
    begin
        waddr_reg <= AWADDR_S;
        id_reg <= AWID_S;
    end
    else
    begin
        waddr_reg <= waddr_reg;
        id_reg <= id_reg;
    end
end

// output to DMA
assign config_addr = WDATA_S;
assign DMASRC_valid = ((WVALID_S == 1'b1) 
                    && (waddr_reg == `AXI_ADDR_BITS'h10020200)
                    && (cst == `DMA_GET_CONFIG));
assign DMADST_valid = ((WVALID_S == 1'b1) 
                    && (waddr_reg == `AXI_ADDR_BITS'h10020300)
                    && (cst == `DMA_GET_CONFIG));
assign DMALEN_valid = ((WVALID_S == 1'b1) 
                    && (waddr_reg == `AXI_ADDR_BITS'h10020400)
                    && (cst == `DMA_GET_CONFIG));                                         

always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn)
        DMA_enable <= 1'b0;
    else if ((WVALID_S == 1'b1) 
            && (waddr_reg == `AXI_ADDR_BITS'h10020100)
            && (cst == `DMA_GET_CONFIG))
        DMA_enable <= WDATA_S[0];
    else
        DMA_enable <= DMA_enable;
end

// output for AXI
assign AWREADY_S = (cst == `DMA_WAIT_VALID);
assign WREADY_S = (cst == `DMA_GET_CONFIG);
assign BID_S = id_reg;
assign BRESP_S = 2'b0;
assign BVALID_S = (cst == `DMASLAVE_W_RESPONSE);

endmodule