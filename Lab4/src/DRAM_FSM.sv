// `include "../include/AXI_define.svh"
`include "../include/def.svh"

module DRAM_FSM(
    input ACLK,
    input ARESETn,
    // DRAM port
    input [`DRAM_DATA_BITS-1:0] DRAM_rdata,
    input DRAM_rdata_valid,
    output logic DRAM_CSn,
    output logic [3:0] DRAM_WEn,
    output logic DRAM_RASn,
    output logic DRAM_CASn,
    output logic [`DRAM_ADDR_BITS-1:0] DRAM_addr,
    output logic [`DRAM_DATA_BITS-1:0] DRAM_wdata,

    // from DRAM slave FSM
    input chip_enable,
    input read_write_sel,
    input [`DRAM_SLAVE_ADDR_BITS-1:0] R_W_addr,
    input [`DRAM_DATA_BITS-1:0] write_data,
    input [3:0] WEn_to_DRAM_FSM,
    input R_W_finish,

    // to DRAM slave FSM
    output logic get_addr, // get read addr, or get write data and addr
    output logic read_data_valid,
    output logic [`DRAM_DATA_BITS-1:0] read_data,
    output logic DRAM_write_done,
    output DRAM_idle
);

logic [3:0] nst;
logic [3:0] cst;

logic [2:0] delay_count_down_reg;
logic R_W_finish_reg;

// for row hit
logic [`DRAM_ADDR_BITS-1:0] act_row;
logic [`DRAM_ADDR_BITS-1:0] now_row;
logic [`DRAM_ADDR_BITS-1:0] now_col;

assign now_row = R_W_addr[22:12];
assign now_col = {1'b0,R_W_addr[11:2]};

// current state
always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn) 
    begin
        cst <= `DRAM_WAIT_ENABLE;
    end
    else 
    begin
        cst <= nst;
    end
end

// next state
always_comb begin
    case(cst)
        `DRAM_WAIT_ENABLE: begin
            if (chip_enable)
                nst = `DRAM_ACT;
            else
                nst = `DRAM_WAIT_ENABLE;
        end
        `DRAM_ACT: begin
            nst = `ACT_DELAY_COUNT_DOWN;
        end
        `ACT_DELAY_COUNT_DOWN: begin
            if (delay_count_down_reg == 3'b0)
            begin
                if (read_write_sel == 1'b0)
                    nst = `DRAM_READ;
                else
                    nst = `DRAM_WRITE;
            end
            else
                nst = `ACT_DELAY_COUNT_DOWN;
        end
        `DRAM_READ: begin
            nst = `DRAM_WAIT_OUTPUT_VALID;
        end
        `DRAM_WAIT_OUTPUT_VALID: begin
            if (DRAM_rdata_valid)
            begin
                if ((R_W_finish_reg == 1'b0) 
                    && (act_row == now_row))
                    nst = `DRAM_READ;
                else
                    nst = `DRAM_PRE;
            end
            else
                nst = `DRAM_WAIT_OUTPUT_VALID;
        end
        `DRAM_WRITE: begin
            nst = `WRITE_DELAY_COUNT_DOWN;
        end
        `WRITE_DELAY_COUNT_DOWN: begin
            if (delay_count_down_reg == 3'b0)
            begin
                if ((R_W_finish_reg == 1'b0) 
                    && (act_row == now_row))
                    nst = `DRAM_WRITE;
                else
                    nst = `DRAM_PRE;
            end
            else
                nst = `WRITE_DELAY_COUNT_DOWN;
        end
        `DRAM_PRE: begin
            nst = `PRE_DELAY_COUNT_DOWN;
        end
        `PRE_DELAY_COUNT_DOWN: begin
            if (delay_count_down_reg == 3'b0)
            begin
                if (R_W_finish_reg == 1'b0)
                    nst = `DRAM_ACT;
                else
                    nst = `DRAM_WAIT_ENABLE;  
            end
                //nst = `DRAM_WAIT_ENABLE;
            else
                nst = `PRE_DELAY_COUNT_DOWN;
        end
        default: begin
            nst = `DRAM_WAIT_ENABLE;
        end
    endcase
end

// output to DRAM slave FSM
always_comb begin
    case (cst)
        `DRAM_READ: get_addr = 1'b1;
        `DRAM_WRITE: get_addr = 1'b1;
        default: get_addr = 1'b0;
    endcase
end

assign read_data_valid = DRAM_rdata_valid;
assign read_data = DRAM_rdata;

always_comb begin
    case(cst)
        `WRITE_DELAY_COUNT_DOWN: begin
            if (delay_count_down_reg == 3'b0)
                DRAM_write_done = 1'b1;
            else
                DRAM_write_done = 1'b0;
        end
        default: DRAM_write_done = 1'b0;
    endcase
end

assign DRAM_idle = (cst == `DRAM_WAIT_ENABLE);

// output to DRAM
assign DRAM_CSn = (cst == `DRAM_WAIT_ENABLE);

always_comb begin
    case(cst)
        `DRAM_WRITE: DRAM_WEn = ~WEn_to_DRAM_FSM;
        `DRAM_PRE: DRAM_WEn = 4'h0;
        default: DRAM_WEn = 4'hf;
    endcase
end

always_comb begin
    case(cst)
        `DRAM_ACT: DRAM_RASn = 1'b0;
        `DRAM_PRE: DRAM_RASn = 1'b0;
        default: DRAM_RASn = 1'b1;
    endcase
end

always_comb begin
    case(cst)
        `DRAM_READ: DRAM_CASn = 1'b0;
        `DRAM_WRITE: DRAM_CASn = 1'b0;
        default: DRAM_CASn = 1'b1;
    endcase
end

always_comb begin
    case(cst)
        `DRAM_ACT: DRAM_addr = now_row;
        `DRAM_READ: DRAM_addr = now_col;
        `DRAM_WRITE: DRAM_addr = now_col;
        `DRAM_PRE: DRAM_addr = act_row;
        default: DRAM_addr = `DRAM_ADDR_BITS'b0;
    endcase
end

assign DRAM_wdata = write_data;

// register
always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn) 
        delay_count_down_reg <= 3'b0;
    else 
    begin
        if (delay_count_down_reg == 3'b0)
            delay_count_down_reg <= 3'd3;
        else if (cst == `ACT_DELAY_COUNT_DOWN
                || cst == `WRITE_DELAY_COUNT_DOWN
                || cst == `PRE_DELAY_COUNT_DOWN)
            delay_count_down_reg <= delay_count_down_reg - 3'd1;
        else
            delay_count_down_reg <= delay_count_down_reg;
    end
end

always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn) 
        R_W_finish_reg <= 1'b0;
    else 
    begin
        if (((cst == `DRAM_WAIT_OUTPUT_VALID) && (R_W_finish == 1'b1))
            || ((cst == `WRITE_DELAY_COUNT_DOWN) && (R_W_finish == 1'b1)))
            R_W_finish_reg <= 1'b1;
        else if ((cst == `PRE_DELAY_COUNT_DOWN) 
                && (delay_count_down_reg == 3'b0))
            R_W_finish_reg <= 1'b0;
        else
            R_W_finish_reg <= R_W_finish_reg;
    end
end

always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn) 
        act_row <= `DRAM_ADDR_BITS'b0;
    else 
    begin
        if (cst == `DRAM_ACT)
            act_row <= now_row;
        else if ((cst == `PRE_DELAY_COUNT_DOWN) 
                && (delay_count_down_reg == 3'b0))
            act_row <= `DRAM_ADDR_BITS'b0;
        else
            act_row <= act_row;
    end
end

endmodule