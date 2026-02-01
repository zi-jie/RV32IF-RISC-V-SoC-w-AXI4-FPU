// stage:
// mul : 9 MAC 
// add : 1.conv add 9 mac result (maybe split to 2 stage ?)/ 
// LReLU : output = (last_channel)? LReLU(input) : input;
// Requan : output = (normalize)? (input-bias) >> Var : input; //if normalize == last_channel?
// WB : write to psum buffer
// POOL : do max pool (no idea about how to implement now) 

// rm requan
// `include "./compute_component/mul_arr.sv"
// `include "./compute_component/adder1.sv"
// `include "./compute_component/adder2.sv"
// `include "./compute_component/LReLU.sv"
// `include "./compute_component/Requan1.sv"
// `include "./compute_component/Requan2.sv"
// `include "./compute_component/Requan3.sv"
// `include "./compute_component/max_pool.sv"

// `include "./pipeline_regs/mem_mul.sv"
// `include "./pipeline_regs/mul_adder1.sv"
// `include "./pipeline_regs/adder1_adder2.sv"
// `include "./pipeline_regs/adder2_LReLU.sv"
// `include "./pipeline_regs/LReLU_Requan1.sv"
// `include "./pipeline_regs/Requan1_Requan2.sv"
// `include "./pipeline_regs/Requan2_Requan3.sv"
// `include "./pipeline_regs/Requan3_wb.sv"

// // `include "./mem/psum_buf_wrapper.sv"
// `include "./mem/psum_buf_dual_wrapper.sv"
`include "../../include/peremeters.svh"
module PE (
  input rst, //! rst should be enabled when change layer, too 
  input clk,
  input stall,
  input [`BYTE - 1:0] ifm [`MAC_NUM - 1 : 0],
  input [`BYTE - 1:0] weight [`MAC_NUM - 1 : 0],
  input do_LReLU,
  input do_requan,
  input first_channel,
  input psum_sel,
  input row_change,
  input channel_change,
  //pooling
  input [`OUT_BUF_BITS - 2:0]index, //! don't pass lsb
  input [5:0]outsize,
  //RQ
  input [`HWORD - 1:0] bias,
  input [9:0] mantissa,
  input [3:0] shift_bits,
  //wb
  input pe_buffer_sel, //from RQ(1) or pool(0)
  input [10:0]psum_raddr,
  input [10:0]psum_waddr,
  input [3:0] pe_wen,
  output [`WORD - 1:0] psum
);

// declaration
  //mul_arr
  logic [`BYTE - 1:0] mul_ifm [`MAC_NUM - 1 : 0];
  logic [`HWORD - 1:0] mul_mul_result[`MAC_NUM - 1 : 0];
  //adder1
  logic [`HWORD - 1:0] add1_mul_result[`MAC_NUM - 1 : 0];
  logic [19:0] add1_add1_result [2 : 0];
  //adder2
  logic [19:0] add2_add1_result [2 : 0];
  logic [`HWORD - 1:0] add2_add2_result;
  //LReLU
  logic [`HWORD - 1:0] LReLU_add2_result;
  logic [`HWORD - 1:0] LReLU_LReLU_result;
  //Requan1
  logic [`HWORD - 1:0] Requan1_LReLU_result;
  logic [`HWORD - 1:0] Requan1_RQ1_result;
  //Requan2
  logic [`HWORD - 1:0] Requan2_RQ1_result;
  logic [25        :0] Requan2_RQ2_result;
  //Requan3
  logic [25        :0] Requan3_RQ2_result;
  logic [`HWORD - 1:0] Requan3_RQ3_result;
  //wb
  logic [`HWORD - 1:0] wb_RQ3_result;
  logic [`HWORD - 1:0] pool_result;

//ifm reg
  mem_mul mem_mul(.clk(clk), .rst(rst), .stall(stall), .ifm_mem_in(ifm), .ifm_mem_result(mul_ifm));

//mul_arr
  mul_arr mul_arr(.ifm(mul_ifm), .weight(weight), .mul_result(mul_mul_result));
  mul_adder1 mul_adder1(.clk(clk), .rst(rst), .stall(stall), .mul_result_in(mul_mul_result), .mul_result(add1_mul_result));

//adder1
  logic [`HWORD - 1:0] adder1_2_mul_result [3 : 0];
  assign adder1_2_mul_result[0] = 16'h0;
  assign adder1_2_mul_result[1] = 16'h0;
  assign adder1_2_mul_result[2] = add1_mul_result[8];
  assign adder1_2_mul_result[3] = (first_channel)? 16'h0 : 
                                    (psum_sel)? psum[15:0]:psum[31:16];
  adder1 adder1_0(.mul_result(add1_mul_result[3:0]), .add1_result(add1_add1_result[0]));
  adder1 adder1_1(.mul_result(add1_mul_result[7:4]), .add1_result(add1_add1_result[1]));
  adder1 adder1_2(.mul_result(adder1_2_mul_result), .add1_result(add1_add1_result[2]));
  adder1_adder2 adder1_adder2(.clk(clk), .rst(rst), .stall(stall), .adder1_result_in(add1_add1_result), .adder1_result(add2_add1_result));

//adder2
  adder2 adder2(.add1_result(add2_add1_result), .add2_result(add2_add2_result));
  adder2_LReLU adder2_LReLU(.clk(clk), .rst(rst), .stall(stall), .adder2_result_in(add2_add2_result), .adder2_result(LReLU_add2_result));

//LReLU
  LReLU LReLU(.add2_result(LReLU_add2_result), .do_LReLU(do_LReLU), .LR_result(LReLU_LReLU_result));
  LReLU_Requan1 LReLU_Requan1(.clk(clk), .rst(rst), .stall(stall), .LReLU_result_in(LReLU_LReLU_result), .LReLU_result(Requan1_LReLU_result));

//Requan1
  Requan1 Requan1(.LR_result(Requan1_LReLU_result), .bias(bias), .do_requan(do_requan), .RQ1_result(Requan1_RQ1_result));
  Requan1_Requan2 Requan1_Requan2(.clk(clk), .rst(rst), .stall(stall), .Requan1_result_in(Requan1_RQ1_result), .Requan1_result(Requan2_RQ1_result));
  
//Requan2
  Requan2 Requan2(.RQ1_result(Requan2_RQ1_result), .mantissa(mantissa), .do_requan(do_requan), .RQ2_result(Requan2_RQ2_result));
  Requan2_Requan3 Requan2_Requan3(.clk(clk), .rst(rst), .stall(stall), .Requan2_result_in(Requan2_RQ2_result), .Requan2_result(Requan3_RQ2_result));
  
//Requan3
  Requan3 Requan3(.RQ2_result(Requan3_RQ2_result), .shift_bits(shift_bits), .do_requan(do_requan), .RQ3_result(Requan3_RQ3_result));
  Requan3_wb Requan3_wb(.clk(clk), .rst(rst), .stall(stall), .Requan3_result_in(Requan3_RQ3_result), .Requan3_result(wb_RQ3_result));

//wb
  logic [`WORD - 1:0] wb_wdata_in;

  logic [`OUT_BUF_BITS - 2:0] index_buf;
  logic pool_rst;
  logic even_row;
  always_ff @( posedge clk /*or negedge rst*/) begin
    //initialize
    if(!rst | channel_change) begin
      even_row <= 1'h1;
      index_buf <= 5'h0;
    end
    else begin
      if((index == 5'h0) & (index_buf != 5'h0)) even_row <= ~even_row;
      index_buf <= index;
    end  
  end
  assign pool_rst = (!even_row & ((index == outsize[5:1]) & (index_buf == outsize[5:1]))) | channel_change;
  max_pool max_pool(.clk(clk), .rst(rst & !pool_rst), .Requan_result(wb_RQ3_result), .index(index), .wen(wb_RQ3_result != 16'b0), .pool_result(pool_result));
  assign wb_wdata_in = (pe_buffer_sel)? ((do_requan)? {pool_result[7:0], pool_result[7:0],pool_result[7:0], pool_result[7:0]} : {pool_result, pool_result}) : 
                       (do_requan)?{wb_RQ3_result[7:0], wb_RQ3_result[7:0],wb_RQ3_result[7:0],wb_RQ3_result[7:0]} : {wb_RQ3_result, wb_RQ3_result} ;
  //psum_buf_wrapper psum_buf(.CK(clk), .CS(1'b1), .OE(1'b1), .WEB(pe_wen), .A(psum_waddr), .DI(wb_wdata_in), .DO(psum));
  
  // B is write port
  // psum_buf_wrapper_dual psum_buf_dual0(.CK(clk), .CSA(1'b1), .CSB(1'b1), .OEA(1'b1), .OEB(1'b1),
  //                                      .WEAN(4'hf), .WEBN(pe_wen), .A(psum_raddr), .B(psum_waddr), .DIA(32'b0), .DIB(wb_wdata_in), .DOA(psum), .DOB()); //dual port
  psum_buf_wrapper_dual_16 psum_buf_dual0(.CK(clk), .CSA(1'b1), .CSB(1'b1), .OEA(1'b1), .OEB(1'b1),
                                       .WEAN(pe_wen), .WEBN(4'hf),
                                       .A(psum_waddr), .B(psum_raddr),
                                       .DIA(wb_wdata_in), .DIB(32'b0),
                                       .DOA(), .DOB(psum)); //dual port
  //yiteng for wrapper, read only
endmodule