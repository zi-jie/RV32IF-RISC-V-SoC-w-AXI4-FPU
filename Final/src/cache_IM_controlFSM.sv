`include "../include/def.svh"

module cache_IM_controlFSM(
    input clk,
    input rst,
    
    // connect with CPU
    input [31:0] PC,
    output logic [31:0] cpu_INST,
    output logic INST_valid, // HW3's IM_handshake
    output logic cpu_IM_stall,

    // connect with IM master FSM
    output logic ARvalid,
    output logic [`AXI_ADDR_BITS-1:0] read_addr_M, // also to cache L1C_inst
    input read_data_valid_M,
    input [`AXI_DATA_BITS-1:0] read_data_M,
    input Rlast,

    // connect with cache L1C_inst
    input hit,
    input [`AXI_DATA_BITS-1:0] read_data_C,  
    output logic [`AXI_ADDR_BITS-1:0] RW_addr_C,
    output logic [`AXI_DATA_BITS-1:0] write_data_C,
    output logic WEB_C, // LOW: write, HIGH: read
    output logic read_req_hit,
    output logic read_req_miss_last,

    // connect with cache DM control FSM
    input DM_stall
);

typedef enum logic [2:0] {
    sIDLE       = 3'd0, 
    sREAD_ADDR  = 3'd1, 
    sREAD_CHECK = 3'd2, 
    sREAD_AXI   = 3'd3, 
    sREAD_FINISH = 3'd4
} FSM_state;
FSM_state nst, cst;

logic [1:0] write_block_C;
logic [31:0] cpu_INST_reg;
logic save_inst;

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
            if (DM_stall)
                nst = sIDLE;
            else
                nst = sREAD_ADDR;
        end
        sREAD_ADDR: begin
            nst = sREAD_CHECK;
        end
        sREAD_CHECK: begin
            if (hit) begin
                if (DM_stall)
                    nst = sIDLE;
                else
                    nst = sREAD_ADDR;
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
            if (DM_stall)
                nst = sIDLE;
            else
                nst = sREAD_ADDR;
        end
        default: nst = sIDLE;
    endcase
end

// output to CPU
assign cpu_INST = (cst == sREAD_CHECK)? read_data_C: cpu_INST_reg;
assign INST_valid = (((cst == sREAD_CHECK) && (hit == 1'b1))
                    || (cst == sREAD_FINISH));
assign cpu_IM_stall = (cst inside {sREAD_ADDR, sREAD_AXI})
                    || ((cst == sIDLE) && ((DM_stall == 1'b1)|| (PC == 32'b0)))
                    || ((cst == sREAD_CHECK) && (hit == 1'b0));

// output to IM master FSM
assign ARvalid = ((cst == sREAD_CHECK) && (hit == 1'b0));
assign read_addr_M = {PC[31:4], 4'b0};

// output to cache L1C_inst
assign RW_addr_C = (cst == sREAD_AXI)? // sREAD_AXI: write address
                    {PC[31:4], write_block_C, 2'b0}: PC;
assign write_data_C = read_data_M;
assign WEB_C = (read_data_valid_M)? 1'b0: 1'b1;
assign read_req_hit = (cst == sREAD_CHECK) && (hit == 1'b1);
assign read_req_miss_last = (cst == sREAD_FINISH);    

// register
always@(posedge clk or posedge rst) begin
    if (rst) 
        write_block_C <= 2'b0;
    else if ((cst == sREAD_AXI) && (read_data_valid_M == 1'b1))
        write_block_C <= write_block_C + 2'd1;
    else
        write_block_C <= write_block_C;
end

assign save_inst = ((PC[3:2] == write_block_C) 
                && (read_data_valid_M == 1'b1));
always@(posedge clk or posedge rst) begin
    if (rst) 
        cpu_INST_reg <= 32'b0;
    else if (save_inst)
        cpu_INST_reg <= read_data_M;
    else
        cpu_INST_reg <= cpu_INST_reg;
end

endmodule