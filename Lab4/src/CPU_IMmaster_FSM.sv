`include "../include/def.svh"

module CPU_IMmaster_FSM (
    input ACLK,
    input ARESETn,

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

    // connect with IM cache control FSM
    input ARvalid,
    input [`AXI_ADDR_BITS-1:0] read_addr,
    output logic read_data_valid,
    output logic [`AXI_DATA_BITS-1:0] read_data,
    output logic Rlast
);

typedef enum logic [1:0] {
    sREAD_IDLE  = 2'd0, 
    sREAD_AR    = 2'd1, 
    sREAD_R     = 2'd2
} FSM_state;
FSM_state nst, cst;

logic [`AXI_ADDR_BITS-1:0] read_addr_reg;

// current state
always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn) 
        cst <= sREAD_IDLE;
    else 
        cst <= nst;
end

// next state
always_comb begin
    case(cst)
        sREAD_IDLE: begin
            if (ARvalid)
                nst = sREAD_AR;
            else
                nst = sREAD_IDLE;
        end
        sREAD_AR: begin
            if (ARREADY_M)
                nst = sREAD_R;
            else
                nst = sREAD_AR;
        end
        sREAD_R: begin
            if ((RVALID_M == 1'b1) && (RLAST_M == 1'b1))
                nst = sREAD_IDLE;
            else
                nst = sREAD_R;
        end
        default: nst = sREAD_IDLE;
    endcase
end

// output to IM cache control FSM
assign read_data_valid = ((cst == sREAD_R) && (RVALID_M == 1'b1));
assign read_data = RDATA_M;
assign Rlast = RLAST_M;

// output to AXI, read channel
assign ARID_M = `AXI_ID_BITS'b0;
assign ARADDR_M = read_addr_reg;
assign ARLEN_M = `AXI_LEN_BITS'd3;
assign ARSIZE_M = `AXI_SIZE_BITS'd2;
assign ARBURST_M = 2'b01;
assign ARVALID_M = (cst == sREAD_AR);
assign RREADY_M = (cst == sREAD_R);

// register
always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn) 
        read_addr_reg <= `AXI_ADDR_BITS'b0;
    else if (ARvalid)
        read_addr_reg <= read_addr;
    else
        read_addr_reg <= read_addr_reg;
end

endmodule