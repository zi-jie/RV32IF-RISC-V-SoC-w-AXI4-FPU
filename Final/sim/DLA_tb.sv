// `include "monitor.sv"
`define CPU_CYCLE     1.0 // 100Mhz
`define DLA_CYCLE     1.0
`define MAX           1000 // 3000000
`timescale 1ns/10ps

`ifdef SYN
`include "top_syn.v"
// `include "../mem/SRAM_A/IFM.v"
// `include "../mem/SRAM_B/PSUM_BUF.v"
`timescale 1ns/10ps
// `include "/usr/cad/CBDK/CBDK018_UMC_Faraday_v1.0/orig_lib/fsa0m_a/2009Q2v2.0/GENERIC_CORE/FrontEnd/verilog/fsa0m_a_generic_core_21.lib.src"
`include "/usr/cad/CBDK/Executable_Package/Collaterals/IP/stdcell/N16ADFP_StdCell/VERILOG/N16ADFP_StdCell.v"
`include "/usr/cad/CBDK/Executable_Package/Collaterals/IP/stdio/N16ADFP_StdIO/VERILOG/N16ADFP_StdIO.v"
`elsif PR
`include "top_pr.v"
// `include "../mem/SRAM_A/IFM.v"
// `include "../mem/SRAM_B/PSUM_BUF.v"
`timescale 1ns/10ps
// `include "/usr/cad/CBDK/CBDK018_UMC_Faraday_v1.0/orig_lib/fsa0m_a/2009Q2v2.0/GENERIC_CORE/FrontEnd/verilog/fsa0m_a_generic_core_21.lib.src"
`include "/usr/cad/CBDK/Executable_Package/Collaterals/IP/stdcell/N16ADFP_StdCell/VERILOG/N16ADFP_StdCell.v"
`include "/usr/cad/CBDK/Executable_Package/Collaterals/IP/stdio/N16ADFP_StdIO/VERILOG/N16ADFP_StdIO.v"
`else
//`include "top.sv"
// `include "IFM_rtl.sv"
// `include "PSUM_BUF_rtl.sv"
`include "SRAM/SRAM_rtl.sv"
`endif

`include "../src/DLA/DLA.sv"
`include "../src/DLA/controller.sv"
`include "../src/DLA/PE.sv"

`define out_word(addr) \
  {DLA.PE_arr[0].PE.psum_buf_dual0.PSUM_BUF_i.Memory_byte1[addr], \
   DLA.PE_arr[0].PE.psum_buf_dual0.PSUM_BUF_i.Memory_byte0[addr], \
   DLA.PE_arr[0].PE.psum_buf_dual0.PSUM_BUF_i.Memory_byte3[addr], \
   DLA.PE_arr[0].PE.psum_buf_dual0.PSUM_BUF_i.Memory_byte2[addr]}
module top_tb;
  logic dla_clk;
  logic dla_rst;
  logic dla_config;
  logic inpt;
  integer i;
  integer j;
  integer ifm_height = 4;
  assign dla_config = 32'b0000_0_0_0_1_1_1_1_0_1_1_10_001_001_00_001100_0_1;
  /*
    dlaConfig = {
        'en' :              {'val': 1,'len' : 1},
        'buf_sel' :         {'val': 0, 'len': 1},
        'ifm_height/width': {'val': 8, 'len': 6},
        'ignore_column':    {'val': 0, 'len': 2},
        'padding':          {'val': 0, 'len': 3},
        'stride':           {'val': 1, 'len': 3},
        'kernel_size':      {'val': 2, 'len': 2},
        'first_channel':    {'val': 1, 'len': 1}, //!
        'do_conv':          {'val': 1, 'len': 1},
        'do_residual':      {'val': 0, 'len': 1},
        'top_tile':         {'val': 1, 'len': 1},
        'left_tile':        {'val': 1, 'len': 1},
        'bottom_tile':      {'val': 1, 'len': 1},
        'right_tile':       {'val': 1, 'len': 1},
        'do_ReLU':          {'val': 0, 'len': 1},
        'do_pool':          {'val': 0, 'len': 1},
        'do_Req':           {'val': 0, 'len': 1},
        'Reserved':         {'val': 0, 'len': 4}
    }
  */

  // clock generater
  always #(`DLA_CYCLE/2)    dla_clk = ~dla_clk;

  //DLA
  DLA DLA(.clk(dla_clk), .rst(!dla_rst), .CPU_clk(dla_clk), .CPU_rst(!dla_rst), .r_addr(0), .r_data(0), .w_addr(0), .w_data(0), .config_w_en(0), 
          .ifm0_w_en(4'hf), .ifm1_w_en(4'hf), .weight_w_en(0), .inpt(inpt));

  initial begin
    dla_rst = 1;
    @(posedge dla_clk)
    #(2);
    dla_rst = 0;
  end
  // read test
  initial begin
    // reset
    dla_clk = 0;  
    $readmemh("../testData/test4/ifm7/ifm70.hex", DLA.IFM_MEM0.IFM_i.Memory_byte0);
    $readmemh("../testData/test4/ifm7/ifm71.hex", DLA.IFM_MEM0.IFM_i.Memory_byte1);
    $readmemh("../testData/test4/ifm7/ifm72.hex", DLA.IFM_MEM0.IFM_i.Memory_byte2);
    $readmemh("../testData/test4/ifm7/ifm73.hex", DLA.IFM_MEM0.IFM_i.Memory_byte3);
    
    // $readmemh("../testData/test1/ifm04.hex", DLA.IFM_MEM1.IFM_i.Memory_byte0);
    // $readmemh("../testData/test1/ifm05.hex", DLA.IFM_MEM1.IFM_i.Memory_byte1);
    // $readmemh("../testData/test1/ifm06.hex", DLA.IFM_MEM1.IFM_i.Memory_byte2);
    // $readmemh("../testData/test1/ifm07.hex", DLA.IFM_MEM1.IFM_i.Memory_byte3);

    // $readmemh("../mem/testData/test3/ifm1/ifm10.hex", DLA.IFM_MEM1.IFM_i.Memory_byte0);
    // $readmemh("../mem/testData/test3/ifm1/ifm11.hex", DLA.IFM_MEM1.IFM_i.Memory_byte1);
    // $readmemh("../mem/testData/test3/ifm1/ifm12.hex", DLA.IFM_MEM1.IFM_i.Memory_byte2);
    // $readmemh("../mem/testData/test3/ifm1/ifm13.hex", DLA.IFM_MEM1.IFM_i.Memory_byte3);

    // $readmemh("../mem/testData/test0/golden0.hex", psum0.Memory_byte0);
    // $readmemh("../mem/testData/test0/golden1.hex", psum0.Memory_byte1);
    // $readmemh("../mem/testData/test0/golden2.hex", psum0.Memory_byte2);
    // $readmemh("../mem/testData/test0/golden3.hex", psum0.Memory_byte3);

  end

  `ifdef SYN
    initial $sdf_annotate("../syn/top_syn.sdf", TOP);
  `elsif PR
    initial $sdf_annotate("../pr/top_pr.sdf", TOP);
  `endif

  initial begin
    `ifdef FSDB
      $fsdbDumpfile("top.fsdb");
      $fsdbDumpvars(0, DLA);
      $fsdbDumpvars;
    `elsif FSDB_ALL
       $fsdbDumpfile("top.fsdb");
       //$fsdbDumpvars("+struct", "+mda", DLA.IFM_MEM0);
       //$fsdbDumpvars("+struct", "+mda", DLA.IFM_MEM1);
       //$fsdbDumpvars("+struct", "+mda", DLA.weight_reg);
       //$fsdbDumpvars("+struct", "+mda", DLA.PE_arr[0].PE.psum_buf_dual0);
       $fsdbDumpvars("+struct", "+mda", DLA);
       //$fsdbDumpvars("+struct", i_DRAM);
    `endif    
    if(inpt) $finish;
    #(`DLA_CYCLE*`MAX)
    // $display("test %h : %h %h %h %h", 86*105+3*74+(-25)*(-19)+(-78)*121, 86*105, 3*74, (-25)*47, (-78)*121);
    for (i = 0; i <= ifm_height; i++)begin
      for (j = 0; j <= ifm_height/2; j++)
        begin
          $display("out[%4h] = %h", j + 32*i, `out_word(j + 32*i));
        end
    end
    $finish;

    // // if reach maximum simulation time
    // #(`CPU_CYCLE*`MAX)
    // for (i = 0; i < num; i++) begin
    //   if (`dram_word(`TEST_START + i) !== GOLDEN[i]) begin
    //     $display("DRAM[%4d] = %h, expect = %h", `TEST_START + i, `dram_word(`TEST_START + i), GOLDEN[i]);
    //     err=err+1;
    //   end else begin
    //     $display("DRAM[%4d] = %h, pass", `TEST_START + i, `dram_word(`TEST_START + i));
    //   end
    // end
    // $display("SIM_END(%5d) = %h, expect = %h", `SIM_END, `dram_word(`SIM_END), `SIM_END_CODE);
    // result(num, num);
    // mem_monitor; // get memory value
    // $finish;
  end
endmodule