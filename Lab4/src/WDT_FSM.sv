`include "../include/def.svh"

module WDT_FSM(
    input ACLK,
	input ARESETn,
	input [`AXI_IDS_BITS-1:0] AWID_S,
    input [`AXI_ADDR_BITS-1:0] AWADDR_S,             
    input AWVALID_S,
    output logic AWREADY_S,         
    input WLAST_S,     
    input WVALID_S,        
    output logic WREADY_S,      
    output logic [`AXI_IDS_BITS-1:0] BID_S,
    output logic [1:0] BRESP_S,       
    output logic BVALID_S,       
    input BREADY_S,       
    input [`AXI_IDS_BITS-1:0] ARID_S,     
    input [`AXI_ADDR_BITS-1:0] ARADDR_S,   
    input [`AXI_LEN_BITS-1:0] ARLEN_S,           
    input ARVALID_S,      
    output logic ARREADY_S,      
    output logic [`AXI_IDS_BITS-1:0] RID_S,      
    output logic [1:0] RRESP_S,       
    output logic RLAST_S,       
    output logic RVALID_S,       
    input RREADY_S,
    output logic R_doing,
    output logic W_doing,
    output logic [`AXI_ADDR_BITS-1:0] R_ADDR_S,
    output logic [`AXI_ADDR_BITS-1:0] W_ADDR_S,
    output logic previous_ar
);

logic rch_nst;
logic rch_cst;
logic [1:0] wch_nst;
logic [1:0] wch_cst;

logic [`AXI_IDS_BITS-1:0] ARID_reg;
logic [`AXI_ADDR_BITS-1:0] ARADDR_reg;
logic [`AXI_LEN_BITS-1:0] ARLEN_reg;
logic [`AXI_IDS_BITS-1:0] AWID_reg;
logic [`AXI_ADDR_BITS-1:0] AWADDR_reg;

logic read_delay;
always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn)
        read_delay <= 1'b0;
    else if ((WLAST_S == 1'b1) && (WVALID_S == 1'b1))
        read_delay <= 1'b1;
    else 
        read_delay <= 1'b0;
end

always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn)
        previous_ar <= 1'b0;
    else
    begin
        if (rch_cst == `RCH_WAIT_ARVALID && (ARVALID_S == 1'b1) && (wch_cst != `WCH_WRITE_DATA))
            previous_ar <= 1'b1;
        else
            previous_ar <= 1'b0;
    end
end


assign R_doing = (rch_cst == `RCH_OUTPUT_DATA);
assign W_doing = (wch_cst == `WCH_WRITE_DATA);
assign R_ADDR_S = ARADDR_reg;
assign W_ADDR_S = AWADDR_reg;

// current state
always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn) 
    begin
        rch_cst <= `RCH_WAIT_ARVALID;
        wch_cst <= `WCH_WAIT_AWVALID;
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
        `RCH_WAIT_ARVALID: begin
            if ((ARVALID_S == 1'b1) && (wch_cst != `WCH_WRITE_DATA))
                rch_nst = `RCH_OUTPUT_DATA;
            else 
                rch_nst = `RCH_WAIT_ARVALID;
        end
        `RCH_OUTPUT_DATA: begin
            if (ARLEN_reg == `AXI_LEN_BITS'b0 && (RREADY_S == 1'b1) && (wch_cst != `WCH_WRITE_DATA) && (read_delay != 1'b1)) // (RVALID_S=1)
                rch_nst = `RCH_WAIT_ARVALID;
            else
                rch_nst = `RCH_OUTPUT_DATA;
        end
    endcase
end

// write channel next state
always_comb begin
    case(wch_cst)
        `WCH_WAIT_AWVALID: begin
            if ((AWVALID_S == 1'b1) && (rch_cst != `RCH_OUTPUT_DATA))
                wch_nst = `WCH_WRITE_DATA;
            else
                wch_nst = `WCH_WAIT_AWVALID;
        end
        `WCH_WRITE_DATA: begin
            if ((WLAST_S == 1'b1) && (WVALID_S == 1'b1))
                wch_nst = `WCH_WRITE_RESPONSE;
            else
                wch_nst = `WCH_WRITE_DATA;
        end
        default: begin //WCH_WRITE_RESPONSE
            if (BREADY_S)
                wch_nst = `WCH_WAIT_AWVALID;
            else
                wch_nst = `WCH_WRITE_RESPONSE;
        end
    endcase
end

// read channel output
always_comb begin
    case(rch_cst)
        `RCH_WAIT_ARVALID: begin
            if (wch_cst != `WCH_WRITE_DATA)
                ARREADY_S = 1'b1;
            else 
                ARREADY_S = 1'b0;
            RVALID_S = 1'b0;
            RID_S = `AXI_IDS_BITS'b0; 
            RRESP_S = 2'b0;
            RLAST_S = 1'b0;
        end
        `RCH_OUTPUT_DATA: begin
            ARREADY_S = 1'b0;
            if ((wch_cst != `WCH_WRITE_DATA) && (read_delay != 1'b1))
                RVALID_S = 1'b1;
            else 
                RVALID_S = 1'b0;
            RID_S = ARID_reg;
            RRESP_S = 2'b0;
            if (ARLEN_reg == `AXI_LEN_BITS'b0)
                RLAST_S = 1'b1;
            else 
                RLAST_S = 1'b0;
        end
    endcase
end

// write channel output
always_comb begin
    case(wch_cst)
        `WCH_WAIT_AWVALID: begin
            if (rch_cst != `RCH_OUTPUT_DATA)
                AWREADY_S = 1'b1;
            else
                AWREADY_S = 1'b0;
            WREADY_S = 1'b0;
            BVALID_S = 1'b0;
            BID_S = `AXI_IDS_BITS'b0;
            BRESP_S = 2'b0;
        end
        `WCH_WRITE_DATA: begin
            AWREADY_S = 1'b0;
            WREADY_S = 1'b1;
            BVALID_S = 1'b0;
            BID_S = `AXI_IDS_BITS'b0;
            BRESP_S = 2'b0;
        end
        default: begin //WCH_WRITE_RESPONSE
            AWREADY_S = 1'b0;
            WREADY_S = 1'b0;
            BVALID_S = 1'b1;
            BID_S = AWID_reg;
            BRESP_S = 2'b0;
        end
    endcase
end

always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn)
    begin
        ARID_reg <= `AXI_IDS_BITS'b0;
        ARADDR_reg <= `AXI_ADDR_BITS'b0;
        ARLEN_reg <= `AXI_LEN_BITS'b0;
    end
    else 
    begin
        if ((rch_cst == `RCH_WAIT_ARVALID) && (ARVALID_S == 1))
        begin
            ARID_reg <= ARID_S;
            ARADDR_reg <= ARADDR_S;
            ARLEN_reg <= ARLEN_S;
        end
        else if ((rch_cst == `RCH_OUTPUT_DATA) && (RREADY_S == 1) && (wch_cst != `WCH_WRITE_DATA) && (read_delay != 1'b1))
        begin
            ARID_reg <= ARID_reg;
            ARADDR_reg <= ARADDR_reg + 32'd4;
            ARLEN_reg <= ARLEN_reg - 4'd1;
        end
        else
        begin
            ARID_reg <= ARID_reg;
            ARADDR_reg <= ARADDR_reg;
            ARLEN_reg <= ARLEN_reg;
        end
    end 
end

always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn)
    begin
        AWID_reg <= `AXI_IDS_BITS'b0;
        AWADDR_reg <= `AXI_ADDR_BITS'b0;
    end
    else 
    begin
        if ((wch_cst == `WCH_WAIT_AWVALID) && (AWVALID_S == 1'b1)) 
        begin
            AWID_reg <= AWID_S;
            AWADDR_reg <= AWADDR_S;
        end
        else 
        begin
            AWID_reg <= AWID_reg;
            AWADDR_reg <= AWADDR_reg + 32'd4;
        end
    end
end

endmodule
