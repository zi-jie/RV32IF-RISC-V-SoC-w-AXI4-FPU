`include "../include/def.svh"

module cache_DM_controlFSM(
    input clk,
    input rst,

    // connect with CPU
    input [31:0] DM_A,
    input [31:0] DM_DI,
    input [3:0] DM_BWEB,
    output logic [31:0] DM_DO,
    output logic cpu_DM_stall,
    input [1:0] cpu_DM_next_RW,

    // connect with DM master FSM
    output logic ARvalid,
    output logic [`AXI_ADDR_BITS-1:0] read_addr_M, // also to cache L1C_inst
    output logic AWvalid,
    output logic [`AXI_ADDR_BITS-1:0] write_addr_M,
    output logic [`AXI_DATA_BITS-1:0] write_data_M,
    output logic [`AXI_STRB_BITS-1:0] bweb_M,
    input read_data_valid_M,
    input [`AXI_DATA_BITS-1:0] read_data_M,
    input Rlast,
    input AXI_write_done,

    // connect with cache L1C_data
    input hit,
    input [`AXI_DATA_BITS-1:0] read_data_C,  
    output logic [`AXI_ADDR_BITS-1:0] RW_addr_C,
    output logic [`AXI_DATA_BITS-1:0] write_data_C,
    output logic [3:0] WEB_C, // LOW: write, HIGH: read
    output logic read_req_hit,
    output logic read_req_miss_last,
    output logic write_req_hit,

    // connect with cache IM control FSM
    input IM_stall
);

typedef enum logic [2:0] {
    sIDLE = 3'd0, 
    sREAD_ADDR = 3'd1, 
    sREAD_CHECK = 3'd2, 
    sREAD_AXI = 3'd3, 
    sREAD_FINISH = 3'd4, 
    sWRITE_ADDR = 3'd5, 
    sWRITE_CHECK = 3'd6
} FSM_state; 

FSM_state nst, cst;

logic [1:0] write_block_C; // only for READ
logic [31:0] DM_DO_reg;
logic save_data_M,  save_data_C;

// current state
always@(posedge clk or posedge rst) begin
    if (rst) 
        cst <= sIDLE;
    else 
        cst <= nst;
end

// next state
always_comb begin
    case(cst)
        sIDLE: begin
            if (IM_stall) begin
                nst = sIDLE;
            end
            else begin
                if (cpu_DM_next_RW == 2'd2 && AXI_write_done == 1'b1)
                    nst = sREAD_ADDR;
                else if (cpu_DM_next_RW == 2'd1 && AXI_write_done == 1'b1)
                    nst = sWRITE_ADDR;
                else
                    nst = sIDLE;
            end
        end
        sREAD_ADDR: begin
            nst = sREAD_CHECK;
        end
        sREAD_CHECK: begin
             if (hit) begin
                if (cpu_DM_next_RW == 2'd2 && AXI_write_done == 1'b1)
                    nst = sREAD_ADDR;
                else if (cpu_DM_next_RW == 2'd1 && AXI_write_done == 1'b1)
                    nst = sWRITE_ADDR;
                else
                    nst = sIDLE;
            end
            else
                nst = sREAD_AXI;
        end
        sREAD_AXI: begin
            if ((Rlast == 1'b1) && (read_data_valid_M == 1'b1))
                nst = sREAD_FINISH;
            else
                nst = sREAD_AXI;
        end
        sREAD_FINISH: begin
            if (cpu_DM_next_RW == 2'd2 && AXI_write_done == 1'b1)
                nst = sREAD_ADDR;
            else if (cpu_DM_next_RW == 2'd1 && AXI_write_done == 1'b1)
                nst = sWRITE_ADDR;
            else
                nst = sIDLE;
        end
        sWRITE_ADDR: begin
            nst = sWRITE_CHECK;
        end
        sWRITE_CHECK: begin
            if (cpu_DM_next_RW == 2'd2 && AXI_write_done == 1'b1)
                nst = sREAD_ADDR;
            else if (cpu_DM_next_RW == 2'd1 && AXI_write_done == 1'b1)
                nst = sWRITE_ADDR;
            else
                nst = sIDLE;
        end
        default: nst = sIDLE;
    endcase
end

// output to CPU
assign DM_DO = (cst == sREAD_CHECK)? read_data_C: DM_DO_reg;
assign cpu_DM_stall = (cst inside {sREAD_ADDR, sREAD_AXI, sWRITE_ADDR})
                    || ((cst == sREAD_CHECK) && (hit == 1'b0))
                    || (AXI_write_done == 1'b0 && cpu_DM_next_RW != 2'b0);

// output to IM master FSM
assign ARvalid = ((cst == sREAD_CHECK) && (hit == 1'b0));
assign read_addr_M = {DM_A[31:4], 4'b0};
assign AWvalid = (cst == sWRITE_ADDR);
assign write_addr_M = DM_A;
assign write_data_M = DM_DI;
assign bweb_M = DM_BWEB;

// output to cache L1C_data
assign RW_addr_C = (cst == sREAD_AXI)? // sREAD_AXI: write address
                    {DM_A[31:4], write_block_C, 2'b0}: DM_A;
assign write_data_C = (cst == sREAD_AXI)? read_data_M: DM_DI;
assign WEB_C = (read_data_valid_M == 1'b1)? 4'b0:
                (cst == sWRITE_CHECK && hit == 1'b1)? DM_BWEB: 4'hf;
assign read_req_hit = (cst == sREAD_CHECK) && (hit == 1'b1);
assign read_req_miss_last = (cst == sREAD_FINISH);    
assign write_req_hit = (cst == sWRITE_CHECK) && (hit == 1'b1);

// register
always@(posedge clk or posedge rst) begin
    if (rst) 
        write_block_C <= 2'b0;
    else if ((cst == sREAD_AXI) && (read_data_valid_M == 1'b1))
        write_block_C <= write_block_C + 2'd1;
    else
        write_block_C <= write_block_C;
end

assign save_data_M = ((DM_A[3:2] == write_block_C) 
                && (read_data_valid_M == 1'b1));
assign save_data_C = ((cst == sREAD_CHECK) && (hit == 1'b1));
always@(posedge clk or posedge rst) begin
    if (rst)
        DM_DO_reg <= 32'b0;
    else if (save_data_M)
        DM_DO_reg <= read_data_M;
    else if (save_data_C)
        DM_DO_reg <= read_data_C;
    else
        DM_DO_reg <= DM_DO_reg;
end
endmodule