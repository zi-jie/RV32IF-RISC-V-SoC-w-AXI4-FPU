`include "../include/def.svh"

module CPU_DMmaster_FSM (
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

    // connect with DM cache control FSM
    input ARvalid,
    input [`AXI_ADDR_BITS-1:0] read_addr,
    input AWvalid,
    input [`AXI_ADDR_BITS-1:0] write_addr,
    input [`AXI_DATA_BITS-1:0] write_data,
    input [`AXI_STRB_BITS-1:0] write_bweb,
    output logic read_data_valid,
    output logic [`AXI_DATA_BITS-1:0] read_data,
    output logic Rlast,
    output logic write_done
);

typedef enum logic [1:0] {
    sREAD_IDLE = 2'd0, 
    sREAD_AR   = 2'd1, 
    sREAD_R    = 2'd2
} READ_FSM;
READ_FSM rch_nst, rch_cst;

typedef enum logic [1:0] {
    sWRITE_IDLE = 2'd0, 
    sWRITE_AW   = 2'd1, 
    sWRITE_W    = 2'd2, 
    sWRITE_B    = 2'd3
} WRITE_FSM;
WRITE_FSM wch_nst, wch_cst;

logic [`AXI_ADDR_BITS-1:0] read_addr_reg;
logic [`AXI_ADDR_BITS-1:0] write_addr_reg;
logic [`AXI_DATA_BITS-1:0] write_data_reg;
logic [`AXI_STRB_BITS-1:0] write_bweb_reg;

// current state
always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn) 
    begin
        rch_cst <= sREAD_IDLE;
        wch_cst <= sWRITE_IDLE;
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
        sREAD_IDLE: begin
            if (ARvalid)
                rch_nst = sREAD_AR;
            else
                rch_nst = sREAD_IDLE;
        end
        sREAD_AR: begin
            if (ARREADY_M)
                rch_nst = sREAD_R;
            else
                rch_nst = sREAD_AR;
        end
        sREAD_R: begin
            if ((RVALID_M == 1'b1) && (RLAST_M == 1'b1))
                rch_nst = sREAD_IDLE;
            else
                rch_nst = sREAD_R;
        end
        default: rch_nst = sREAD_IDLE;
    endcase
end

// write channel next state
always_comb begin
    case(wch_cst)
        sWRITE_IDLE: begin
            if (AWvalid)
                wch_nst = sWRITE_AW;
            else
                wch_nst = sWRITE_IDLE;
        end
        sWRITE_AW: begin
            if (AWREADY_M)
                wch_nst = sWRITE_W;
            else
                wch_nst = sWRITE_AW;
        end
        sWRITE_W: begin
            if (WREADY_M == 1'b1)
                wch_nst = sWRITE_B;
            else
                wch_nst = sWRITE_W;
        end
        sWRITE_B: begin
            if (BVALID_M)
            begin
                if (AWvalid)
                    wch_nst = sWRITE_AW;
                else
                    wch_nst = sWRITE_IDLE;
            end
            else
                wch_nst = sWRITE_B;
        end
        default: wch_nst = sWRITE_IDLE;
    endcase
end

// output to DM cache control FSM
assign read_data_valid = ((rch_cst == sREAD_R) && (RVALID_M == 1'b1));
assign read_data = RDATA_M;
assign Rlast = RLAST_M;
assign write_done = ((wch_cst == sWRITE_IDLE) || 
                    ((wch_cst == sWRITE_B) && (BVALID_M == 1'b1)));

// output to AXI, write channel
assign AWID_M = `AXI_ID_BITS'b0;
assign AWADDR_M = write_addr_reg;
assign AWLEN_M = `AXI_LEN_BITS'd0;
assign AWSIZE_M = `AXI_SIZE_BITS'd2;
assign AWBURST_M = 2'b01;
assign AWVALID_M = (wch_cst == sWRITE_AW);

assign WDATA_M = write_data_reg;
assign WSTRB_M = ~write_bweb_reg;
assign WLAST_M = (wch_cst == sWRITE_W);
assign WVALID_M = (wch_cst == sWRITE_W);

assign BREADY_M = (wch_cst == sWRITE_B);

// output to AXI, read channel
assign ARID_M = `AXI_ID_BITS'b0;
assign ARADDR_M = read_addr_reg;
assign ARLEN_M = `AXI_LEN_BITS'd3;
assign ARSIZE_M = `AXI_SIZE_BITS'd2;
assign ARBURST_M = 2'b01;
assign ARVALID_M = (rch_cst == sREAD_AR);
assign RREADY_M = (rch_cst == sREAD_R);

// register for read channel
always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn) 
        read_addr_reg <= `AXI_ADDR_BITS'b0;
    else if (ARvalid)
        read_addr_reg <= read_addr;
    else
        read_addr_reg <= read_addr_reg;
end

// register for write channel
always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn) begin
        write_addr_reg <= `AXI_ADDR_BITS'b0;
        write_data_reg <= `AXI_DATA_BITS'b0;
        write_bweb_reg <= `AXI_STRB_BITS'b0;
    end
    else if (AWvalid) begin
        write_addr_reg <= write_addr;
        write_data_reg <= write_data;
        write_bweb_reg <= write_bweb;
    end
    else begin
        write_addr_reg <= write_addr_reg;
        write_data_reg <= write_data_reg;
        write_bweb_reg <= write_bweb_reg;
    end
end

endmodule