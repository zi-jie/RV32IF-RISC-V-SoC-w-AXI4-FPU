// `include "../include/AXI_define.svh"
`include "../include/def.svh"

module ROM_FSM(
    input ACLK,
    input ARESETn,

    input [`AXI_IDS_BITS-1:0] ARID_S,     
    input [`ROM_ADDR_BITS-1:0] ARADDR_S,   
    input [`AXI_LEN_BITS-1:0] ARLEN_S,           
    input ARVALID_S,      
    output logic ARREADY_S,      
    output logic [`AXI_IDS_BITS-1:0] RID_S,      
    output logic [1:0] RRESP_S,       
    output logic RLAST_S,       
    output logic RVALID_S,       
    input RREADY_S,

    output logic R_doing,
    output logic [`ROM_ADDR_BITS-1:0] R_ADDR_S,
    output logic previous_ar,
    output logic previous_r
);

logic rch_nst;
logic rch_cst;
logic [`AXI_IDS_BITS-1:0] ARID_reg;
logic [`ROM_ADDR_BITS-1:0] ARADDR_reg;
logic [`AXI_LEN_BITS-1:0] ARLEN_reg;

assign R_doing = (rch_cst == `RCH_OUTPUT_DATA);
assign R_ADDR_S = ARADDR_reg;

always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn)
        previous_ar <= 1'b0;
    else
    begin
        if ((rch_cst == `RCH_WAIT_ARVALID) && (ARVALID_S == 1'b1))
            previous_ar <= 1'b1;
        else
            previous_ar <= 1'b0;
    end
end

always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn)
        previous_r <= 1'b0;
    else 
    begin
        if (previous_ar  
            || ((rch_cst == `RCH_OUTPUT_DATA) && (RREADY_S == 1'b1)))
            previous_r <= 1'b1;
        else 
            previous_r <= 1'b0;
    end
end

// current state
always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn) 
    begin
        rch_cst <= `RCH_WAIT_ARVALID;
    end
    else 
    begin
        rch_cst <= rch_nst;
    end
end

// read channel next state
always_comb begin
    case(rch_cst)
        `RCH_WAIT_ARVALID: begin
            if (ARVALID_S == 1'b1)
                rch_nst = `RCH_OUTPUT_DATA;
            else 
                rch_nst = `RCH_WAIT_ARVALID;
        end
        `RCH_OUTPUT_DATA: begin
            if ((ARLEN_reg == `AXI_LEN_BITS'b0) && (RREADY_S == 1'b1))
                rch_nst = `RCH_WAIT_ARVALID;
            else
                rch_nst = `RCH_OUTPUT_DATA;
        end
    endcase
end

// read channel output
always_comb begin
    case(rch_cst)
        `RCH_WAIT_ARVALID: begin
            ARREADY_S = 1'b1;
            RVALID_S = 1'b0;
            RID_S = `AXI_IDS_BITS'b0; 
            RRESP_S = 2'b0;
            RLAST_S = 1'b0;
        end
        `RCH_OUTPUT_DATA: begin
            ARREADY_S = 1'b0;
            RVALID_S = 1'b1;
            RID_S = ARID_reg;
            RRESP_S = 2'b0;
            if (ARLEN_reg == `AXI_LEN_BITS'b0)
                RLAST_S = 1'b1;
            else 
                RLAST_S = 1'b0;
        end
    endcase
end

always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn)
    begin
        ARID_reg <= 0;
        ARADDR_reg <= `ROM_ADDR_BITS'b0;
        ARLEN_reg <= `AXI_LEN_BITS'b0;
    end
    else 
    begin
        if ((rch_cst == `RCH_WAIT_ARVALID) && (ARVALID_S == 1'b1))
        begin
            ARID_reg <= ARID_S;
            ARADDR_reg <= ARADDR_S;
            ARLEN_reg <= ARLEN_S;
        end
        else if ((rch_cst == `RCH_OUTPUT_DATA) && (RREADY_S == 1'b1))
        begin
            ARID_reg <= ARID_reg;
            ARADDR_reg <= ARADDR_reg + `ROM_ADDR_BITS'd1;
            ARLEN_reg <= ARLEN_reg - `AXI_LEN_BITS'd1;
        end
        else
        begin
            ARID_reg <= ARID_reg;
            ARADDR_reg <= ARADDR_reg;
            ARLEN_reg <= ARLEN_reg;
        end
    end 
end

endmodule