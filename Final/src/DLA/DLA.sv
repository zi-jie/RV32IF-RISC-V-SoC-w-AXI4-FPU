`include "../../include/peremeters.svh"
// `include "./weight_reg.sv"
// `include "./PE_buffer.sv"
// `include "./ifm_wrapper.sv"
module DLA(
    input clk,
    input rst,
    input CPU_clk,
    input CPU_rst,
    //to read output
    input [`BANDWIDTH - 1 : 0]r_addr, 
    //to write weight or config
    input [`BANDWIDTH - 1 : 0]w_addr, 
    input [`BANDWIDTH - 1 : 0]w_data, 
    input logic [2:0]  config_w_en, // active high
    input logic [3:0]  ifm0_w_en,   // active low
    input logic [3:0]  ifm1_w_en,   // active low
    input logic [3:0]  weight_w_en, // active high
    
    output [`BANDWIDTH - 1 : 0]r_data, 
    output no_sync_inpt,
    output logic inpt //interrupt
);
//controller
logic [31:0] op_config;
logic stall;
logic dla_active;

logic [2*`IFM_SIZE_BITS-3:0]IFM_r_addr; //-2 for align

logic [`IFM_SIZE_BITS-1:0]pe_buf_r_addr; //-2 for align
logic [`IFM_SIZE_BITS+1:0]pe_buf_w_addr;
logic [3:0]pe_buf_w_en;

logic [2*`IFM_SIZE_BITS-2:0]out_r_addr; //-1 for align
logic [2*`IFM_SIZE_BITS-2:0]out_w_addr; //-2 for align
logic do_LReLU;
logic do_pool;
logic do_RQ;
logic first_channel;
logic bottom_channel;
logic DLA_EN;
logic psum_buf_reset;
logic [5:0] outsize;

//mem out 
logic [`PE_NUM-1:0][`BANDWIDTH - 1 : 0] r_data_for_PE_arr; 
assign r_data = r_data_for_PE_arr[r_addr[12:11]];
logic [1:0] test;
assign test = r_addr[12:11];

//IFM_MEM
logic [`WORD - 1:0] IFM0_out;
logic [`WORD - 1:0] IFM1_out;
logic buf_sel;

//PE_buf
logic [3:0] out_w_en;
logic [`BYTE - 1:0] IFM_window[`MAC_NUM - 1:0];
logic pe_buf_rst;
logic shift;

//wei mem
logic [`BYTE-1:0] weight [(`MAC_NUM*`PE_NUM) - 1 : 0] ;
logic [1:0] op_config_wen;
logic inpt_in;
logic inpt_wen;
logic psum_sel;

//pool_buf
logic [4:0] index;
logic [1:0] kerSize;

//RQ
logic [3:0] shift_bits;
logic [9:0] mantissa;
logic [`HWORD - 1:0] bias;

// 2DFF
logic twoDFF_one;
logic twoDFF_two;
logic inpt_w;

assign no_sync_inpt = inpt_w;
assign inpt = twoDFF_two;

controller controller(
        .clk(clk),
        .rst(rst),
        .op_config_in(w_data),
        .op_config_wen(config_w_en[1:0]),
        .inpt_in(w_data[0]),
        .inpt_wen(config_w_en[2]),

        .buf_sel(buf_sel),

        .do_LReLU(do_LReLU),
        .do_pool(do_pool),
        .do_RQ(do_RQ),
        .first_channel(first_channel),

        .stall(stall),
        .shift(shift),
        .pe_buf_rst(pe_buf_rst),

        .IFM_r_addr(IFM_r_addr),

        .pe_buf_r_addr(pe_buf_r_addr),
        .pe_buf_w_addr(pe_buf_w_addr),
        .pe_buf_w_en(pe_buf_w_en),
        .bottom_channel(bottom_channel),
        .DLA_EN(DLA_EN),
                    
        .out_r_addr(out_r_addr),
        .out_w_addr(out_w_addr),
        .out_w_en(out_w_en),
        .psum_sel(psum_sel),
        .psum_buf_reset(psum_buf_reset),
        .dla_active(dla_active),

        .pool_index(index),
        .kerSize(kerSize),
        .outsize(outsize),

        .mantissa(mantissa),
        .bias(bias),
        .shift_bits(shift_bits),

        .inpt(inpt_w)
);

//yiteng IFM write, dont need read, CS
//modify wen
logic [2*`IFM_SIZE_BITS-3:0]IFM0_r_addr;  //-2 for align
logic [2*`IFM_SIZE_BITS-3:0]IFM1_r_addr; //-2 for align
assign IFM0_r_addr = (ifm0_w_en == 4'hf) ?  IFM_r_addr : r_addr;
assign IFM1_r_addr = (ifm1_w_en == 4'hf) ?  IFM_r_addr : r_addr;
ifm_wrapper IFM_MEM0(.CK(clk), .CS(1'b1), .OE(1'b1), .WEB(ifm0_w_en), .A(IFM0_r_addr), .DI(w_data), .DO(IFM0_out)); // 64*64*8 (height*width*bits_per_element) -> SRAM
ifm_wrapper IFM_MEM1(.CK(clk), .CS(1'b1), .OE(1'b1), .WEB(ifm1_w_en), .A(IFM1_r_addr), .DI(w_data), .DO(IFM1_out)); 

logic [`WORD - 1:0] IFM_out;
logic [`WORD - 1:0] pe_wdata;
assign IFM_out = (buf_sel)? IFM1_out : IFM0_out;
assign pe_wdata = (!bottom_channel)? IFM_out : 32'h0;
PE_buffer PE_buffer(.clk(clk), .rst(psum_buf_reset), .row_change(shift), .read_addr(pe_buf_r_addr),
                    .write_addr(pe_buf_w_addr), .wen(pe_buf_w_en), .write_data(pe_wdata), .IFM(IFM_window));

logic [`BYTE-1:0] weight_reg_wdata [3 : 0];
assign weight_reg_wdata[0] = w_data[7:0];
assign weight_reg_wdata[1] = w_data[15:8];
assign weight_reg_wdata[2] = w_data[23:16];
assign weight_reg_wdata[3] = w_data[31:24];

//addr
logic [10:0] real_psum_raddr;
assign real_psum_raddr = (dla_active)? out_r_addr : r_addr[10:0];
//yiteng 
weight_reg weight_reg(.clk(clk), .rst(rst), .wen(weight_w_en), .w_addr(w_addr[8:0]), .write_data(weight_reg_wdata), .weight(weight)); // (9*PE_NUM)*8 (width*bits_per_element) -> reg

genvar PE_cnt;
logic [7:0] finalWeight [`PE_NUM - 1:0][8:0];
//                                           1*1 : 3*3

generate
  for(PE_cnt = 0 ; PE_cnt < `PE_NUM ; PE_cnt++)begin : PE_arr
    assign finalWeight[PE_cnt][0] = (kerSize == 2'b0) ? weight[PE_cnt] : weight[9*PE_cnt + 0];
    assign finalWeight[PE_cnt][1] = (kerSize == 2'b0) ? 8'b0           : weight[9*PE_cnt + 1];
    assign finalWeight[PE_cnt][2] = (kerSize == 2'b0) ? 8'b0           : weight[9*PE_cnt + 2];
    assign finalWeight[PE_cnt][3] = (kerSize == 2'b0) ? 8'b0           : weight[9*PE_cnt + 3];
    assign finalWeight[PE_cnt][4] = (kerSize == 2'b0) ? 8'b0           : weight[9*PE_cnt + 4];
    assign finalWeight[PE_cnt][5] = (kerSize == 2'b0) ? 8'b0           : weight[9*PE_cnt + 5];
    assign finalWeight[PE_cnt][6] = (kerSize == 2'b0) ? 8'b0           : weight[9*PE_cnt + 6];
    assign finalWeight[PE_cnt][7] = (kerSize == 2'b0) ? 8'b0           : weight[9*PE_cnt + 7];
    assign finalWeight[PE_cnt][8] = (kerSize == 2'b0) ? 8'b0           : weight[9*PE_cnt + 8];

    PE PE(.clk(clk), .rst(rst), .stall(stall), .ifm(IFM_window), .weight(finalWeight[PE_cnt][8:0]), .do_LReLU(do_LReLU), .do_requan(do_RQ), .bias(bias), .shift_bits(shift_bits), .psum_sel(psum_sel),
     .row_change(shift), .outsize(outsize), .channel_change(inpt), .mantissa(mantissa),
      .first_channel(first_channel), .index(index), .psum_raddr(real_psum_raddr), .psum_waddr(out_w_addr), .pe_wen(out_w_en), .pe_buffer_sel(do_pool), .psum(r_data_for_PE_arr[PE_cnt]));

  end
endgenerate

//PE2
//                                                    1*1 : 3*3
// assign finalWeight[9]  = (kerSize == 2'b0) ? weight[1] : weight[9];
// assign finalWeight[10] = (kerSize == 2'b0) ? 8'b0      : weight[10];
// assign finalWeight[11] = (kerSize == 2'b0) ? 8'b0      : weight[11];
// assign finalWeight[12] = (kerSize == 2'b0) ? 8'b0      : weight[12];
// assign finalWeight[13] = (kerSize == 2'b0) ? 8'b0      : weight[13];
// assign finalWeight[14] = (kerSize == 2'b0) ? 8'b0      : weight[14];
// assign finalWeight[15] = (kerSize == 2'b0) ? 8'b0      : weight[15];
// assign finalWeight[16] = (kerSize == 2'b0) ? 8'b0      : weight[16];
// assign finalWeight[17] = (kerSize == 2'b0) ? 8'b0      : weight[17];


// Synchronizer
always_ff @(posedge CPU_clk) begin
    if(CPU_rst) begin
        twoDFF_one <= 1'b0;
        twoDFF_two <= 1'b0;
    end
    else begin
        twoDFF_one <= inpt_w;
        twoDFF_two <= twoDFF_one;
    end
end

endmodule
