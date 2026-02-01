// `include "data_array_wrapper.sv"
// `include "tag_array_wrapper.sv"
// `include "../include/AXI_define.svh"
`include "../include/def.svh"

module L1C_inst(
  input clk,
  input rst,
  // // Core to CPU wrapper
  // input [`DATA_BITS-1:0] core_addr,
  // input core_req,	// im_OE
  // input [`DATA_BITS-1:0] I_out,
  // input I_wait,
  // input rvalid_m0_i,	// NEW
  // input rready_m0_i,
  // input core_wait_CD_i,
  // // CPU wrapper to core
  // output logic [`DATA_BITS-1:0] core_out,	// im_DO
  // output logic core_wait,	// ON when L1CI_state is not IDLE
  // // CPU wrapper to Mem
  // output logic I_req,	// ON when L1CI_state is READ_MISS, like im_OE
  // output logic [`DATA_BITS-1:0] I_addr // when L1CI_state is READ_MISS, send to wrapper
  input [`AXI_ADDR_BITS-1:0] RW_addr_C,
  input [`AXI_DATA_BITS-1:0] write_data_C,
  input WEB_C,
  input read_req_hit,
  input read_req_miss_last,
  output logic hit,
  output logic [`AXI_DATA_BITS-1:0] read_data_C
);

  logic [`CACHE_TAG_BITS-1:0] tag;
  logic [`CACHE_INDEX_BITS-1:0] set_index;
  logic [`CACHE_BLOCK_BITS-1:0] block_offset;
  logic [`CACHE_TAG_BITS-1:0] tag_reg;
  logic [`CACHE_INDEX_BITS-1:0] set_index_reg;
  logic [`CACHE_BLOCK_BITS-1:0] block_offset_reg;

  logic [`CACHE_DATA_OUT_BITS-1:0] DA_out;
  logic [`CACHE_DATA_IN_BITS-1:0] DA_in;
  logic [`CACHE_WRITE_BITS-1:0] WEB_DA; // 16 bit

  logic [`CACHE_TAG_OUT_BITS-1:0] TA_out_temp;
  logic [`CACHE_TAG_BITS-1:0] TA_out_0;
  logic [`CACHE_TAG_BITS-1:0] TA_out_1;
  logic [`CACHE_TAG_BITS-1:0] TA_in;
  logic [1:0] WEB_TA;
  
  logic [`CACHE_LINES-1:0] last_flag;
  logic [`CACHE_LINES-1:0] valid_0;
  logic [`CACHE_LINES-1:0] valid_1;

  logic hit_0, hit_1;
  logic TA_web_0, TA_web_1;

  logic DA_read;
  logic TA_read;


  assign tag = RW_addr_C[31:9];
  assign set_index = RW_addr_C[8:4];
  assign block_offset = RW_addr_C[3:2];
  
  // address register
  always@(posedge clk or posedge rst) begin
    if (rst) 
    begin
      tag_reg <= `CACHE_TAG_BITS'b0;
      set_index_reg <= `CACHE_INDEX_BITS'b0;
      block_offset_reg <= `CACHE_BLOCK_BITS'b0;
    end
    else 
    begin
      tag_reg <= tag;
      set_index_reg <= set_index;
      block_offset_reg <= block_offset;
    end
  end
 
  // valid register
  always@(posedge clk or posedge rst) begin
    if (rst)
      valid_0 <= {`CACHE_LINES{1'b0}}; //`CACHE_LINES'(0);
      // valid_0 <= `CACHE_LINES'b0;
    else if (~TA_web_0)
      valid_0[set_index] <= 1'b1;
    else
      valid_0 <= valid_0;
  end

  always@(posedge clk or posedge rst) begin
    if (rst)
      valid_1 <= {`CACHE_LINES{1'b0}};
      // valid_1 <= `CACHE_LINES'b0;
    else if (~TA_web_1)
      valid_1[set_index] <= 1'b1;
    else
      valid_1 <= valid_1;
  end

  // last access way, 0 for the first way, 1 for the second way
  always@(posedge clk or posedge rst) begin
    if (rst)
      last_flag <= 1'b0;
    else if (read_req_hit)
      last_flag[set_index] <= (hit_0)? 1'b0: 1'b1;
    else if (read_req_miss_last)
      last_flag[set_index] <= ~last_flag[set_index];
    else
      last_flag <= last_flag;
  end
  
  // hit
  assign TA_out_0 = (valid_0[set_index_reg])? TA_out_temp[22:0]: 23'b0;
  assign TA_out_1 = (valid_1[set_index_reg])? TA_out_temp[45:23]: 23'b0;
  assign hit_0 = ((valid_0[set_index_reg] == 1'b1)
                && (TA_out_0 == tag_reg));
  assign hit_1 = ((valid_1[set_index_reg] == 1'b1)
                && (TA_out_1 == tag_reg));            
  assign hit = hit_0 || hit_1;

  // data to cache control FSM, to CPU
  assign read_data_C = (hit_0)? DA_out[31:0]: DA_out[63:32];

  // to data array wrapper
  assign DA_in = write_data_C;
  always_comb begin
    if (~WEB_C) begin
      case(block_offset)
        2'b00: WEB_DA = 16'hfff0;
        2'b01: WEB_DA = 16'hff0f;
        2'b10: WEB_DA = 16'hf0ff;
        2'b11: WEB_DA = 16'h0fff;
      endcase
    end
    else
      WEB_DA = 16'hffff;
  end

  // to tag array wrapper
  assign TA_in = tag;
  assign TA_web_0 = (~WEB_C && (last_flag[set_index] == 1'b1))? 1'b0: 1'b1;
  assign TA_web_1 = (~WEB_C && (last_flag[set_index] == 1'b0))? 1'b0: 1'b1;
  assign WEB_TA = {TA_web_1, TA_web_0};

  data_array_wrapper DA(
    .A(set_index), // 5 bit
    .DO(DA_out), // 64 bit
    .DI(DA_in), // 32 bit
    .CK(clk),
    .WEB(WEB_DA),	// 16 bit, each bit control 1 byte, 128=16*8 bits
    .OE(DA_read), // no need?
    .CS(1'b1),
    .active_way(~last_flag[set_index]), // 1 bit for 2 way, 0: way 0, 1: way 1
    .active_block(block_offset), // 2bit for 4 block
    .read_block(block_offset_reg)
  );
   
  tag_array_wrapper TA(
    .A(set_index),
    .DO(TA_out_temp), // 46 bit, Data out of RAM
    .DI(TA_in), // 23 bit, Data into RAM
    .CK(clk),
    .WEB(WEB_TA), // 2 bit, for 2 way, write:LOW, read:HIGH
    .OE(TA_read), // no need?
    .CS(1'b1)
  );
  
  // redundant logic?
  // logic DA_read;
  // logic TA_read;
  // logic [`DATA_BITS-1:0] core_addr_t;
  // logic [`DATA_BITS-1:0] core_addr_t_n;
 
endmodule

