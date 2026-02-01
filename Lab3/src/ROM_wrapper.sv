`include "../include/AXI_define.svh"
`include "ROM_FSM.sv"

module ROM_wrapper(
    input ACLK,
    input ARESETn,

    // connect with AXI
    input [`AXI_IDS_BITS-1:0] ARID_S0,     
    input [`AXI_ADDR_BITS-1:0] ARADDR_S0,       
    input [`AXI_LEN_BITS-1:0] ARLEN_S0,       
    input [`AXI_SIZE_BITS-1:0] ARSIZE_S0,       
    input [1:0] ARBURST_S0,      
    input ARVALID_S0,      
    output logic ARREADY_S0,      
    output logic [`AXI_IDS_BITS-1:0] RID_S0,
    output logic [`AXI_DATA_BITS-1:0] RDATA_S0,       
    output logic [1:0] RRESP_S0,       
    output logic RLAST_S0,       
    output logic RVALID_S0,       
    input RREADY_S0,

    // connect with ROM, top's input/output
    input [`ROM_DATA_BITS-1:0] ROM_out,
    output logic ROM_read,
    output logic ROM_enable,
    output logic [`ROM_ADDR_BITS-1:0] ROM_address
);

logic R_doing;
logic [`ROM_ADDR_BITS-1:0] R_addr;
logic previous_ar;
logic previous_r;
logic [`ROM_DATA_BITS-1:0] ROM_out_reg;

assign ROM_read = (R_doing)? 1'b1:1'b0;
assign ROM_enable = ((ARVALID_S0 == 1'b1) || R_doing)? 1'b1:1'b0;
assign RDATA_S0 = (previous_r)? ROM_out_reg:ROM_out; //previous_ar || previous_r

always_comb begin
    if ((ARVALID_S0 == 1'b1) && (R_doing == 1'b0))
        ROM_address = ARADDR_S0[`ROM_ADDR_BITS+1:2];
    else if (previous_ar || ((R_doing == 1'b1) && (RREADY_S0 == 1'b1)))
        ROM_address = R_addr + `ROM_ADDR_BITS'd1;
    else 
        ROM_address = R_addr;
end

always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn)
        ROM_out_reg <= `ROM_DATA_BITS'b0;
    else if (previous_ar || (RREADY_S0 != 1) || (R_doing != 1))
        ROM_out_reg <= ROM_out;
    else
        ROM_out_reg <= ROM_out_reg;
end

ROM_FSM ROM_fsm(
    .ACLK(ACLK),
    .ARESETn(ARESETn),
    .ARID_S(ARID_S0),     
    .ARADDR_S(ARADDR_S0[`ROM_ADDR_BITS+1:2]),   
    .ARLEN_S(ARLEN_S0),           
    .ARVALID_S(ARVALID_S0),      
    .ARREADY_S(ARREADY_S0),      
    .RID_S(RID_S0),      
    .RRESP_S(RRESP_S0),       
    .RLAST_S(RLAST_S0),       
    .RVALID_S(RVALID_S0),       
    .RREADY_S(RREADY_S0),
    .R_doing(R_doing),
    .R_ADDR_S(R_addr),
    .previous_ar(previous_ar),
    .previous_r(previous_r)
);

endmodule