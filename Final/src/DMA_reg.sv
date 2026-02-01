// `include "../include/AXI_define.svh"
`include "../include/def.svh"

module DMA_reg(
    input ACLK,
    input ARESETn,

    // read data from reg
    input [`DMA_REG_LEN_BITS-1:0] r_index,
    output logic [`AXI_DATA_BITS-1:0] r_data,

    // write data to reg
    input web,
    input [`DMA_REG_LEN_BITS-1:0] w_index,
    input [`AXI_DATA_BITS-1:0] w_data
);

logic [`AXI_DATA_BITS-1:0] reg_x [0:`DMA_REG_LENGTH-1];
assign r_data = reg_x[r_index];

integer i;
always@(posedge ACLK or negedge ARESETn) begin
    if (~ARESETn)
    begin
        for (i = 0; i < `DMA_REG_LENGTH; i = i + 1)
            reg_x[i] <= `AXI_DATA_BITS'b0;
    end
    else
    begin
        if (web == 1)
        begin
            reg_x[w_index] <= w_data;
        end
    end
end

endmodule