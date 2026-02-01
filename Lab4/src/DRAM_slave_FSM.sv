// `include "../include/AXI_define.svh"
`include "../include/def.svh"

module DRAM_slave_FSM(
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

    input [`AXI_IDS_BITS-1:0] ARID_S,     
    input [`AXI_ADDR_BITS-1:0] ARADDR_S,       
    input [`AXI_LEN_BITS-1:0] ARLEN_S,       
    input [`AXI_SIZE_BITS-1:0] ARSIZE_S,       
    input [1:0] ARBURST_S,      
    input ARVALID_S,      
    output logic ARREADY_S,      
    output logic [`AXI_IDS_BITS-1:0] RID_S,
    output logic [`AXI_DATA_BITS-1:0] RDATA_S,       
    output logic [1:0] RRESP_S,       
    output logic RLAST_S,       
    output logic RVALID_S,       
    input RREADY_S,

    // from DRAM FSM
    input get_addr, // get read addr, or get write data and addr
    input read_data_valid,
    input [`DRAM_DATA_BITS-1:0] read_data,
    input DRAM_write_done,
    input DRAM_idle,

    // to DRAM FSM
    output logic chip_enable,
    output logic read_write_sel,
    output logic [`DRAM_SLAVE_ADDR_BITS-1:0] R_W_addr,
    output logic [`DRAM_DATA_BITS-1:0] write_data,
    output logic [3:0] WEn_to_DRAM_FSM,
    output logic R_W_finish
);

logic [2:0] nst;
logic [2:0] cst;

// read's register
logic read_data_valid_reg;
logic [`DRAM_DATA_BITS-1:0] read_data_reg;

// write's register
logic [`DRAM_DATA_BITS-1:0] write_data_reg;
logic [`AXI_STRB_BITS-1:0] web_reg;

// read.write register 
logic [`AXI_LEN_BITS:0] len_reg;
logic [`AXI_ADDR_BITS-1:0] addr_reg;
logic [`AXI_IDS_BITS-1:0] id_reg;

// current state
always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn) 
    begin
        cst <= `WAIT_VALID;
    end
    else 
    begin
        cst <= nst;
    end
end

// next state
always_comb begin
    case(cst)
        `WAIT_VALID: begin
            if (AWVALID_S && DRAM_idle)
                nst = `AW_REQUEST_HANDSHAKE;
            else if (ARVALID_S && DRAM_idle)
                nst = `AR_REQUEST_HANDSHAKE;
            else
                nst = `WAIT_VALID;
        end
        `AR_REQUEST_HANDSHAKE: begin
            nst = `PASS_ADDR_TO_DRAM_FSM;
        end
        `PASS_ADDR_TO_DRAM_FSM: begin
            if (get_addr)
                nst = `WAIT_DATA_FROM_DRAM_FSM;
            else
                nst = `PASS_ADDR_TO_DRAM_FSM;
        end
        `WAIT_DATA_FROM_DRAM_FSM: begin
            if ((read_data_valid == 1'b1 || read_data_valid_reg == 1'b1) 
                && (RREADY_S == 1'b1)) 
            begin
                if (len_reg == `AXI_LEN_BITS'b0)
                    nst = `WAIT_VALID;
                else
                    nst = `PASS_ADDR_TO_DRAM_FSM;
            end
            else
            begin
                nst = `WAIT_DATA_FROM_DRAM_FSM;
            end
        end
        `AW_REQUEST_HANDSHAKE: begin
            nst = `PASS_WDATA_TO_DRAM_FSM;
        end
        `PASS_WDATA_TO_DRAM_FSM: begin
            if (get_addr)
                nst = `WAIT_DRAM_FSM_WRITE_DONE;
            else
                nst = `PASS_WDATA_TO_DRAM_FSM;
        end
        `WAIT_DRAM_FSM_WRITE_DONE: begin
            if (DRAM_write_done)
            begin
                if (WLAST_S)
                    nst = `WRITE_RESPONSE;
                else
                    nst = `PASS_WDATA_TO_DRAM_FSM;
            end
            else
            begin
                nst = `WAIT_DRAM_FSM_WRITE_DONE;
            end
        end
        `WRITE_RESPONSE: begin
            if (BREADY_S)
                nst = `WAIT_VALID;
            else
                nst = `WRITE_RESPONSE;
        end
        default: begin
            nst = `WAIT_VALID;
        end
    endcase
end

// output
// DRAM chip enable
always_comb begin
    case (cst)
        `AR_REQUEST_HANDSHAKE: chip_enable = 1'b1;
        `AW_REQUEST_HANDSHAKE: chip_enable = 1'b1;
        default: chip_enable = 1'b0;
    endcase
end

// read or write select, 0:read, 1:write
always_comb begin
    case (cst)
        `AW_REQUEST_HANDSHAKE: read_write_sel = 1'b1;
        `PASS_WDATA_TO_DRAM_FSM: read_write_sel = 1'b1;
        `WAIT_DRAM_FSM_WRITE_DONE: read_write_sel = 1'b1;
        `WRITE_RESPONSE: read_write_sel = 1'b1;
        default: read_write_sel = 1'b0;
    endcase
end

// read or write address
always_comb begin
    case (cst)
        `PASS_ADDR_TO_DRAM_FSM: R_W_addr = addr_reg;
        `WAIT_DATA_FROM_DRAM_FSM: R_W_addr = addr_reg;
        `PASS_WDATA_TO_DRAM_FSM: R_W_addr = addr_reg;
        `WAIT_DRAM_FSM_WRITE_DONE: R_W_addr = addr_reg;
        default: R_W_addr = `DRAM_SLAVE_ADDR_BITS'b0;
    endcase
end

// write data
always_comb begin
    case (cst)
        `PASS_WDATA_TO_DRAM_FSM: write_data = write_data_reg;
        `WAIT_DRAM_FSM_WRITE_DONE: write_data = write_data_reg;
        default: write_data = `DRAM_DATA_BITS'b0;
    endcase
end

// bit write enable
always_comb begin
    case (cst)
        `PASS_WDATA_TO_DRAM_FSM: WEn_to_DRAM_FSM = web_reg;
        `WAIT_DRAM_FSM_WRITE_DONE: WEn_to_DRAM_FSM = web_reg;
        default: WEn_to_DRAM_FSM = `AXI_STRB_BITS'b0;
    endcase
end

// read.write finish
always_comb begin
    case (cst)
        `WAIT_DATA_FROM_DRAM_FSM: begin
            if (len_reg == `AXI_LEN_BITS'd0)
                R_W_finish = 1'b1;
            else
                R_W_finish = 1'b0;
        end
        `WAIT_DRAM_FSM_WRITE_DONE: begin
            if (WLAST_S)
                R_W_finish = 1'b1;
            else
                R_W_finish = 1'b0;
        end
        default: R_W_finish = 1'b0;
    endcase
end

// AXI AR
always_comb begin
    case(cst)
        `AR_REQUEST_HANDSHAKE: ARREADY_S = 1'b1;
        default: ARREADY_S = 1'b0;
    endcase
end

// AXI R
always_comb begin
    case(cst)
        `WAIT_DATA_FROM_DRAM_FSM: begin
            RID_S = id_reg;
            if (read_data_valid)
                RDATA_S = read_data;
            else
                RDATA_S = read_data_reg;
            RRESP_S = 2'b0;
            if (len_reg == `AXI_LEN_BITS'b0)
                RLAST_S = 1'b1;
            else
                RLAST_S = 1'b0;
            if (read_data_valid || read_data_valid_reg)
                RVALID_S = 1'b1;
            else
                RVALID_S = 1'b0;
        end
        default: begin
            RID_S = `AXI_IDS_BITS'b0;
            RDATA_S = `AXI_DATA_BITS'b0;
            RRESP_S = 2'b0;
            RLAST_S = 1'b0;
            RVALID_S = 1'b0;
        end
    endcase
end

// AXI AW
always_comb begin
    case(cst)
        `AW_REQUEST_HANDSHAKE: AWREADY_S = 1'b1;
        default: AWREADY_S = 1'b0;
    endcase
end

// AXI W
always_comb begin
    case(cst)
        `WAIT_DRAM_FSM_WRITE_DONE: begin
            if (DRAM_write_done)
                WREADY_S = 1'b1;
            else
                WREADY_S = 1'b0;
        end
        default: WREADY_S = 1'b0;
    endcase
end

// AXI B
always_comb begin
    case(cst)
        `WRITE_RESPONSE: begin
            BID_S = id_reg;
            BRESP_S = 2'b0;
            BVALID_S = 1'b1;
        end
        default: begin
            BID_S = `AXI_IDS_BITS'b0;
            BRESP_S = 2'b00;
            BVALID_S = 1'b0;
        end
    endcase
end

// register
always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn)
        read_data_valid_reg <= 1'b0;
    else if (read_data_valid)
        read_data_valid_reg <= 1'b1;
    else if (cst != `WAIT_DATA_FROM_DRAM_FSM)
        read_data_valid_reg <= 1'b0;
    else
        read_data_valid_reg <= read_data_valid_reg;
end

always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn)
        read_data_reg <= `AXI_DATA_BITS'b0;
    else if (read_data_valid)
        read_data_reg <= read_data;
    else
        read_data_reg <= read_data_reg;
end

always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn) begin
        write_data_reg <= `AXI_DATA_BITS'b0;
        web_reg <= `AXI_STRB_BITS'b0;
    end
    else if (AWVALID_S || WVALID_S) begin
        write_data_reg <= WDATA_S;
        web_reg <= WSTRB_S;
    end
    else begin
        write_data_reg <= write_data_reg; 
        web_reg <= web_reg;
    end
end

always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn)
        id_reg <= `AXI_IDS_BITS'b0;
    else if (ARVALID_S)
        id_reg <= ARID_S;
    else if (AWVALID_S)
        id_reg <= AWID_S;
    else
        id_reg <= id_reg;
end

always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn) begin
        len_reg <= 0;
        addr_reg <= `AXI_ADDR_BITS'b0;
    end
    else if (ARVALID_S) begin
        len_reg <= ARLEN_S + 1;
        addr_reg <= ARADDR_S;
    end
    else if (AWVALID_S) begin
        len_reg <= AWLEN_S + 1;
        addr_reg <= AWADDR_S;
    end
    else if (get_addr) begin
        len_reg <= len_reg - 1;
        addr_reg <= addr_reg + `AXI_ADDR_BITS'd4;
    end
    else begin
        len_reg <= len_reg;
        addr_reg <= addr_reg;
    end
end

endmodule