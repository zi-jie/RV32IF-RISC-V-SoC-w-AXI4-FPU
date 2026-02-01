`include "../include/AXI_define.svh"
`include "DMA_reg.sv"

module DMA(
    input ACLK,
    input ARESETn,

    // from DMA slave FSM
    input [`AXI_ADDR_BITS-1:0] config_addr,
    input DMASRC_valid,
    input DMADST_valid,
    input DMALEN_valid,
    input DMA_enable,

    // from/to DMA master FSM
    output logic [`AXI_LEN_BITS-1:0] burst_len,
    input read_data_valid,
    input [`AXI_DATA_BITS-1:0] read_data,
    output logic AR_valid,
    output logic [`AXI_ADDR_BITS-1:0] read_addr,
    output logic AW_valid,
    output logic [`AXI_ADDR_BITS-1:0] write_addr,
    output logic W_valid,
    output logic [`AXI_DATA_BITS-1:0] write_data,
    output logic W_last,
    input master_W_done,
    input master_B_done,

    // to CPU
    output logic DMA_interrupt
);

logic [`AXI_ADDR_BITS-1:0] DMASRC_reg;
logic [`AXI_ADDR_BITS-1:0] DMADST_reg;
logic [`AXI_LEN_BITS-1:0] DMALEN_reg;

logic [`AXI_LEN_BITS-1:0] reading_index; // DMA master's read
logic [`AXI_LEN_BITS-1:0] writing_index; // DMA master's write

DMA_reg DMA_reg1(
    .ACLK(ACLK),
    .ARESETn(ARESETn),
    .r_index(writing_index[`DMA_REG_LEN_BITS-1:0]),
    .r_data(write_data),
    .web(read_data_valid),
    .w_index(reading_index[`DMA_REG_LEN_BITS-1:0]),
    .w_data(read_data)
);

// config register
always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn)
        DMASRC_reg <= `AXI_ADDR_BITS'b0;
    else if (DMASRC_valid)
        DMASRC_reg <= config_addr;
    else
        DMASRC_reg <= DMASRC_reg;
end

always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn)
        DMADST_reg <= `AXI_ADDR_BITS'b0;
    else if (DMADST_valid)
        DMADST_reg <= config_addr;
    else
        DMADST_reg <= DMADST_reg;
end

always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn)
        DMALEN_reg <= `AXI_LEN_BITS'b0;
    else if (DMALEN_valid)
        DMALEN_reg <= config_addr[`AXI_LEN_BITS-1:0];
    else
        DMALEN_reg <= DMALEN_reg;
end

// control register
always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn)
        reading_index <= `AXI_LEN_BITS'b0;
    else if (~DMA_enable)
        reading_index <= `AXI_LEN_BITS'b0;
    else if (read_data_valid)
        reading_index <= reading_index + `AXI_LEN_BITS'd1;
    else 
        reading_index <= reading_index;
end

always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn)
        writing_index <= `AXI_LEN_BITS'b0;
    else if (~DMA_enable)
        writing_index <= `AXI_LEN_BITS'b0;
    else if (master_W_done)
        writing_index <= writing_index + `AXI_LEN_BITS'd1;
    else 
        writing_index <= writing_index;
end

// output to DMA master FSM
assign burst_len = DMALEN_reg;
assign AR_valid = ((DMA_enable == 1'b1) 
                && (reading_index == `AXI_LEN_BITS'b0));
assign read_addr =  {24'b0, DMASRC_reg};
assign AW_valid = ((DMA_enable == 1'b1) 
                && (reading_index == `AXI_LEN_BITS'd1)
                && (reading_index > writing_index));  
assign write_addr =  {24'b0, DMADST_reg}; 
assign W_valid = ((DMA_enable == 1'b1) 
                && (reading_index > writing_index));   
assign W_last = ((DMA_enable == 1'b1) 
                && (writing_index == DMALEN_reg));        

// output to CPU
assign DMA_interrupt = ((DMA_enable == 1'b1)
                    && (writing_index > DMALEN_reg));

endmodule