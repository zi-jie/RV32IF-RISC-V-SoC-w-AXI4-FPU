`include "../sim/monitor.sv"
`include "../sim/CYCLE_MAX.sv"
`timescale 1ns/10ps
// reset define
// `define RST_NS        1005
// clock define (don't modify)
`define DRAM_CYCLE    5.0
`define ROM_CYCLE     50.1
`define AXI_CYCLE     2.5


`ifdef SYN
`include "CHIP_syn.v"
`include "data_array/data_array_rtl.sv"
`include "tag_array/tag_array_rtl.sv"
`include "SRAM/SRAM_rtl.sv"
`include "../mem/PSUM_BUF_DualPort_16/PSUM_BUF_rtl_16.sv"
`timescale 1ns/10ps
// `include "/usr/cad/CBDK/CBDK018_UMC_Faraday_v1.0/orig_lib/fsa0m_a/2009Q2v2.0/GENERIC_CORE/FrontEnd/verilog/fsa0m_a_generic_core_21.lib.src"
`include "/usr/cad/CBDK/Executable_Package/Collaterals/IP/stdcell/N16ADFP_StdCell/VERILOG/N16ADFP_StdCell.v"
`include "/usr/cad/CBDK/Executable_Package/Collaterals/IP/stdio/N16ADFP_StdIO/VERILOG/N16ADFP_StdIO.v"
`elsif PR
`include "../pr/CHIP_pr.v"
`include "SRAM/SRAM_rtl.sv"
`include "data_array/data_array_rtl.sv"
`include "tag_array/tag_array_rtl.sv"
`timescale 1ns/10ps
// `include "/usr/cad/CBDK/CBDK018_UMC_Faraday_v1.0/orig_lib/fsa0m_a/2009Q2v2.0/GENERIC_CORE/FrontEnd/verilog/fsa0m_a_generic_core_21.lib.src"
`include "/usr/cad/CBDK/Executable_Package/Collaterals/IP/stdcell/N16ADFP_StdCell/VERILOG/N16ADFP_StdCell.v"
`include "/usr/cad/CBDK/Executable_Package/Collaterals/IP/stdio/N16ADFP_StdIO/VERILOG/N16ADFP_StdIO.v"
`else
`include "CHIP.v"
`include "../sim/SRAM/SRAM_rtl.sv"
`include "../sim/data_array/data_array_rtl.sv"
`include "../sim/tag_array/tag_array_rtl.sv"
`endif

`include "../sim/ROM/ROM.v"
`include "../sim/DRAM/DRAM.sv"

// `include "IFM_rtl.sv"
// `include "PSUM_BUF_rtl.sv"


// `define mem_word(addr) \
//   {TOP.DM1.i_SRAM.Memory_byte3[addr], \
//    TOP.DM1.i_SRAM.Memory_byte2[addr], \
//    TOP.DM1.i_SRAM.Memory_byte1[addr], \
//    TOP.DM1.i_SRAM.Memory_byte0[addr]}
`define mem_word(addr) \
  {chip.u_TOP.DM1.i_SRAM.MEMORY[addr >> 5][(addr&6'b011111)]}

`ifdef DLA_prog1
`define dram_word(addr) \
  {i_DRAM.Memory_byte0[addr], \
   i_DRAM.Memory_byte1[addr], \
   i_DRAM.Memory_byte2[addr], \
   i_DRAM.Memory_byte3[addr]}
`else
`define dram_word(addr) \
  {i_DRAM.Memory_byte3[addr], \
   i_DRAM.Memory_byte2[addr], \
   i_DRAM.Memory_byte1[addr], \
   i_DRAM.Memory_byte0[addr]}
`endif


`ifdef SYN
  `define out_word(addr) \
    {TOP.dla.DLA.PE_arr_0__PE.psum_buf_dual0.PSUM_BUF_i.Memory_byte3[addr], \
    TOP.dla.DLA.PE_arr_0__PE.psum_buf_dual0.PSUM_BUF_i.Memory_byte2[addr], \
    TOP.dla.DLA.PE_arr_0__PE.psum_buf_dual0.PSUM_BUF_i.Memory_byte1[addr], \
    TOP.dla.DLA.PE_arr_0__PE.psum_buf_dual0.PSUM_BUF_i.Memory_byte0[addr]}
`else
  `define out_word(addr) \
    {TOP.dla.DLA.PE_arr[0].PE.psum_buf_dual0.PSUM_BUF_i.Memory_byte3[addr], \
    TOP.dla.DLA.PE_arr[0].PE.psum_buf_dual0.PSUM_BUF_i.Memory_byte2[addr], \
    TOP.dla.DLA.PE_arr[0].PE.psum_buf_dual0.PSUM_BUF_i.Memory_byte1[addr], \
    TOP.dla.DLA.PE_arr[0].PE.psum_buf_dual0.PSUM_BUF_i.Memory_byte0[addr]}
`endif

`define ifm1_word(addr) \
  {TOP.dla.DLA.IFM_MEM0.IFM_i.Memory_byte3[addr], \
   TOP.dla.DLA.IFM_MEM0.IFM_i.Memory_byte2[addr], \
   TOP.dla.DLA.IFM_MEM0.IFM_i.Memory_byte1[addr], \
   TOP.dla.DLA.IFM_MEM0.IFM_i.Memory_byte0[addr]}
`define ifm2_word(addr) \
  {TOP.dla.DLA.IFM_MEM1.IFM_i.Memory_byte3[addr], \
   TOP.dla.DLA.IFM_MEM1.IFM_i.Memory_byte2[addr], \
   TOP.dla.DLA.IFM_MEM1.IFM_i.Memory_byte1[addr], \
   TOP.dla.DLA.IFM_MEM1.IFM_i.Memory_byte0[addr]}

/*`define rom_word(addr) \
  {i_ROM.Memory_byte3[addr], \
   i_ROM.Memory_byte2[addr], \
   i_ROM.Memory_byte1[addr], \
   i_ROM.Memory_byte0[addr]}*/

`define SIM_END 'h3fff
`define SIM_END_CODE -32'd1

`ifdef DLA
  `define TEST_START 'h40400  
`elsif RTL_DLA
  `define TEST_START 'h40400  
`elsif SYN_DLA
  `define TEST_START 'h40400  
`else
  `define TEST_START 'h40000
`endif

`define PRINT_START 'h4000

module top_tb;

  logic cpu_clk;
  logic axi_clk;
  logic dram_clk;
  logic rom_clk;
  logic rst;
  logic [31:0] GOLDEN[4096];
  logic [7:0] Memory_byte0[32768];
  logic [7:0] Memory_byte1[32768];
  logic [7:0] Memory_byte2[32768];
  logic [7:0] Memory_byte3[32768];
  //HW4
  logic [31:0] ROM_out;
  logic [31:0] DRAM_Q;
  logic ROM_enable;
  logic ROM_read;
  logic [11:0] ROM_address;
  logic DRAM_CSn;
  logic [3:0]DRAM_WEn;
  logic DRAM_RASn;
  logic DRAM_CASn;
  logic [10:0] DRAM_A;
  logic [31:0] DRAM_D; 
  logic DRAM_valid;

  logic [9:0] data_counter;
  // logic DRAM_rst;
  integer gf, i, num;
  integer golden_after_truncate;
  integer output_size;
  logic [31:0] temp;
  integer err;
  string prog_path;
  logic cpu_rst ;
  logic axi_rst ;
  logic rom_rst ;
  logic dram_rst;
  
  
  // clock generater
  always #(`CPU_CYCLE/2)    cpu_clk     = ~cpu_clk;
  always #(`AXI_CYCLE/2)    axi_clk     = ~axi_clk;
  always #(`DRAM_CYCLE/2)   dram_clk    = ~dram_clk;
  always #(`ROM_CYCLE/2)    rom_clk     = ~rom_clk;
  
  // module instantiation
  // top TOP(
  CHIP chip(
    .cpu_clk		    (cpu_clk      ), // CPU CLOCK DOMAIN
    .axi_clk		    (axi_clk      ),
    .rom_clk        (rom_clk      ),
    .dram_clk       (dram_clk     ),
    .cpu_rst		    (cpu_rst      ),
    .axi_rst		    (axi_rst      ),
    .rom_rst        (rom_rst      ),
    .dram_rst       (dram_rst     ),
    .ROM_out        (ROM_out      ),
    .DRAM_Q         (DRAM_Q       ), 
    .ROM_read       (ROM_read     ),
    .ROM_enable     (ROM_enable   ),
    .ROM_address    (ROM_address  ),
    .DRAM_CSn       (DRAM_CSn     ),
    .DRAM_WEn       (DRAM_WEn     ),
    .DRAM_RASn      (DRAM_RASn    ),
    .DRAM_CASn      (DRAM_CASn    ),
    .DRAM_A         (DRAM_A       ),
    .DRAM_D         (DRAM_D       ),
    .DRAM_valid     (DRAM_valid   )
  );

  ROM i_ROM(
    .CK             (rom_clk      ), // ROM CLOCK DOMAIN
    .CS             (ROM_enable   ),
    .OE             (ROM_read     ),
    .A              (ROM_address  ),
    .DO             (ROM_out      )
  );

   DRAM i_DRAM(
    .CK             (dram_clk     ), // DRAM CLOCK DOMAIN
    .Q              (DRAM_Q       ),
    .RST            (dram_rst     ),
    .CSn            (DRAM_CSn     ),
    .WEn            (DRAM_WEn     ),
    .RASn           (DRAM_RASn    ),
    .CASn           (DRAM_CASn    ),
    .A              (DRAM_A       ),
    .D              (DRAM_D       ),
    .VALID          (DRAM_valid   )
  );
  
  // reset release sequence (DRAM -> ROM -> SRAM -> AXI -> CPU)
  initial begin
    // $monitor("Task%c: %c%c%c%c%c%c%c%c%c Run times:%d  Task%c: %c%c%c%c%c%c Run times:%d  Task%c: %c%c%c%c%c%c%c Run times:%d\n  Sim_time:%t", 
    // TOP.DM1.i_SRAM.Memory_byte0[15616],

    // TOP.DM1.i_SRAM.Memory_byte0[15617],
    // TOP.DM1.i_SRAM.Memory_byte0[15618],
    // TOP.DM1.i_SRAM.Memory_byte0[15619],
    // TOP.DM1.i_SRAM.Memory_byte0[15620],
    // TOP.DM1.i_SRAM.Memory_byte0[15621],
    // TOP.DM1.i_SRAM.Memory_byte0[15622],
    // TOP.DM1.i_SRAM.Memory_byte0[15623],
    // TOP.DM1.i_SRAM.Memory_byte0[15624],
    // TOP.DM1.i_SRAM.Memory_byte0[15625],

    // TOP.DM1.i_SRAM.Memory_byte0[15626],

    // TOP.DM1.i_SRAM.Memory_byte0[15627],

    // TOP.DM1.i_SRAM.Memory_byte0[15628],
    // TOP.DM1.i_SRAM.Memory_byte0[15629],
    // TOP.DM1.i_SRAM.Memory_byte0[15630],
    // TOP.DM1.i_SRAM.Memory_byte0[15631],
    // TOP.DM1.i_SRAM.Memory_byte0[15632],
    // TOP.DM1.i_SRAM.Memory_byte0[15633],

    // TOP.DM1.i_SRAM.Memory_byte0[15634],

    // TOP.DM1.i_SRAM.Memory_byte0[15635],

    // TOP.DM1.i_SRAM.Memory_byte0[15636],
    // TOP.DM1.i_SRAM.Memory_byte0[15637],
    // TOP.DM1.i_SRAM.Memory_byte0[15638],
    // TOP.DM1.i_SRAM.Memory_byte0[15639],
    // TOP.DM1.i_SRAM.Memory_byte0[15640],
    // TOP.DM1.i_SRAM.Memory_byte0[15641],
    // TOP.DM1.i_SRAM.Memory_byte0[15642],

    // TOP.DM1.i_SRAM.Memory_byte0[15643],
    // $time);
    dram_rst = 1;
    rom_rst  = 1;
    axi_rst  = 1;
    cpu_rst  = 1;
    @(posedge dram_clk)
    #(2); // small number 
    dram_rst = 0;
    @(posedge rom_clk)
    #(2); // small number 
    rom_rst = 0;
    @(posedge axi_clk)
    #(2); // small number 
    axi_rst = 0;
    @(posedge cpu_clk)
    #(2); // small number 
    cpu_rst = 0;
  end

  initial begin
    // reset
    cpu_clk         = 0;  
    axi_clk         = 0;
    dram_clk        = 0;
    rom_clk         = 0; 
    data_counter    = 0;
    $value$plusargs("prog_path=%s", prog_path);
    // wait for dram reset = 0 
    wait(dram_rst)
    wait(~dram_rst)
    $readmemh({prog_path, "/rom0.hex"}, i_ROM.Memory_byte0);
    $readmemh({prog_path, "/rom1.hex"}, i_ROM.Memory_byte1);
    $readmemh({prog_path, "/rom2.hex"}, i_ROM.Memory_byte2);
    $readmemh({prog_path, "/rom3.hex"}, i_ROM.Memory_byte3);
    $readmemh({prog_path, "/dram0.hex"}, i_DRAM.Memory_byte0);
    $readmemh({prog_path, "/dram1.hex"}, i_DRAM.Memory_byte1);
    $readmemh({prog_path, "/dram2.hex"}, i_DRAM.Memory_byte2);
    $readmemh({prog_path, "/dram3.hex"}, i_DRAM.Memory_byte3);

    //dla rm
    // $readmemh("../mem/testData/test1/ifm00.hex", TOP.dla.DLA.IFM_MEM0.IFM_i.Memory_byte0);
    // $readmemh("../mem/testData/test1/ifm01.hex", TOP.dla.DLA.IFM_MEM0.IFM_i.Memory_byte1);
    // $readmemh("../mem/testData/test1/ifm02.hex", TOP.dla.DLA.IFM_MEM0.IFM_i.Memory_byte2);
    // $readmemh("../mem/testData/test1/ifm03.hex", TOP.dla.DLA.IFM_MEM0.IFM_i.Memory_byte3);

    // $readmemh("../mem/testData/test1/ifm04.hex", TOP.dla.DLA.IFM_MEM1.IFM_i.Memory_byte0);
    // $readmemh("../mem/testData/test1/ifm05.hex", TOP.dla.DLA.IFM_MEM1.IFM_i.Memory_byte1);
    // $readmemh("../mem/testData/test1/ifm06.hex", TOP.dla.DLA.IFM_MEM1.IFM_i.Memory_byte2);
    // $readmemh("../mem/testData/test1/ifm07.hex", TOP.dla.DLA.IFM_MEM1.IFM_i.Memory_byte3);

    num = 0;
    gf = $fopen({prog_path, "/golden.hex"}, "r");
    while (!$feof(gf)) begin
      $fscanf(gf, "%h\n", GOLDEN[num]);
      num++;
    end
    $fclose(gf);

    while (1) begin
      @(negedge cpu_clk)
      if (`mem_word(`SIM_END) == `SIM_END_CODE) break;
    end	
    $display("\nDone\n");
    err = 0;

    `ifdef DLA_prog1
    for (i = 0; i < num; i++) begin
      golden_after_truncate = (num % 5 == 4)? `dram_word(`TEST_START + i) : {24'h0, `dram_word(`TEST_START + i)[7:0]};
      if (golden_after_truncate !== GOLDEN[i]) begin
        $display("afafa%h", num%5);
        $display("DRAM[%4d] = %h, expect = %h", `TEST_START + i, golden_after_truncate, GOLDEN[i]);
        err = err + 1;
      end else begin
        $display("DRAM[%4d] = %h, pass", `TEST_START + i, golden_after_truncate);
      end
    end
    `else
    for (i = 0; i < num; i++) begin
      if (`dram_word(`TEST_START + i) !== GOLDEN[i]) begin
        $display("DRAM[%4d] = %h, expect = %h", `TEST_START + i, `dram_word(`TEST_START + i), GOLDEN[i]);
        err = err + 1;
      end else begin
        $display("DRAM[%4d] = %h, pass", `TEST_START + i, `dram_word(`TEST_START + i));
      end
    end
    `endif 
    result(err, num);
    //mem_monitor; // get memory value
    $finish;
  end

  `ifdef SYN
    initial $sdf_annotate("../syn/CHIP_syn.sdf", chip);
  `elsif PR
    initial $sdf_annotate("../pr/CHIP_pr.sdf", chip);
  `endif

  initial begin
    `ifdef FSDB
      $fsdbDumpfile("chip.fsdb");
      //$fsdbDumpvars(0, TOP);
    $fsdbDumpvars;
    `elsif FSDB_ALL
      $fsdbDumpfile("chip.fsdb");
      // $fsdbDumpvars("+struct", "+mda", i_DRAM);
      $fsdbDumpvars("+struct", "+mda", chip);
      // $fsdbDumpvars("+struct", i_DRAM);
    `endif
    // if reach maximum simulation time
    #(`CPU_CYCLE*`MAX)
    `ifdef DLA_prog1
    for (i = 0; i < num; i++) begin
      golden_after_truncate = (i % 4 != 3)? `dram_word(`TEST_START + i) : {24'h0, `dram_word(`TEST_START + i)[31:24]};
      if (golden_after_truncate !== GOLDEN[i]) begin
        $display("DRAM[%4d] = %h, expect = %h", `TEST_START + i, golden_after_truncate, GOLDEN[i]);
        err = err + 1;
      end else begin
        $display("DRAM[%4d] = %h, pass", `TEST_START + i, golden_after_truncate);
      end
    end
    `else
    for (i = 0; i < num; i++) begin
      if (`dram_word(`TEST_START + i) !== GOLDEN[i]) begin
        $display("DRAM[%4d] = %h, expect = %h", `TEST_START + i, `dram_word(`TEST_START + i), GOLDEN[i]);
        err = err + 1;
      end else begin
        $display("DRAM[%4d] = %h, pass", `TEST_START + i, `dram_word(`TEST_START + i));
      end
    end
    `endif
    $display("SIM_END(%5d) = %h, expect = %h", `SIM_END, `dram_word(`SIM_END), `SIM_END_CODE);
    result(num, num);
    //mem_monitor; // get memory value
    $finish;
  end

  task result;
    input integer err;
    input integer num;
    integer rf;
    begin
    //  `ifdef SYN
    //    rf = $fopen({prog_path, "/result_syn.txt"}, "w");
    //  `elsif PR
    //    rf = $fopen({prog_path, "/result_pr.txt"}, "w");
    //  `else
    //    rf = $fopen({prog_path, "/result_rtl.txt"}, "w");
    //  `endif
    //  $fdisplay(rf, "%d,%d", num - err, num);
    //output_size = 13;
    //for (i = 0; i <= output_size; i++)begin
    //  for (int j = 0; j <= output_size/2; j++)
    //    begin
    //      $display("out[%4h] = %h", j + 32*i, `out_word(j + 32*i));
    //    end
    //end
    //for (i = 0; i <= output_size; i++)begin
    //  for (int j = 0; j <= 15; j++)
    //    begin
    //      $display("ifm0[%4h] = %h", j + 16*i, `ifm1_word(j + 16*i));
    //    end
    //end
    //for (i = 0; i <= output_size; i++)begin
    //  for (int j = 0; j <= 15; j++)
    //    begin
    //      $display("ifm1[%4h] = %h", j + 16*i, `ifm2_word(j + 16*i));
    //    end
    //end
      if (err === 0) begin
        $display("\n");
        $display("\n");
        $display("        **************************               ");
        $display("        *                        *       |\__||  ");
        $display("        *  Congratulations !!    *      / O.O  | ");
        $display("        *                        *    /_____   | ");
        $display("        *  Simulation PASS!!     *   /^ ^ ^ \\  |");
        $display("        *                        *  |^ ^ ^ ^ |w| ");
        $display("        **************************   \\m___m__|_|");
        $display("\n");
      end else begin
        $display("\n");
        $display("\n");
        $display("        **************************               ");
        $display("        *                        *       |\__||  ");
        $display("        *  OOPS!!                *      / X,X  | ");
        $display("        *                        *    /_____   | ");
        $display("        *  Simulation Failed!!   *   /^ ^ ^ \\  |");
        $display("        *                        *  |^ ^ ^ ^ |w| ");
        $display("        **************************   \\m___m__|_|");
        $display("         Totally has %d errors                     ", err); 
        $display("\n");
      end
      $display("                  %10s %10s", "CYCLE", "FREQ");
      $display("        DRAM    : %10f %10f", `DRAM_CYCLE, (1000/`DRAM_CYCLE));
      $display("        ROM     : %10f %10f", `ROM_CYCLE, (1000/`ROM_CYCLE));
      $display("        CPU     : %10f %10f", `CPU_CYCLE, (1000/`CPU_CYCLE));
      $display("        AXI     : %10f %10f", `AXI_CYCLE, (1000/`AXI_CYCLE));
    end
  endtask
  
  //int unsigned fo_ROM, fo_DRAM, fo_IM, fo_DM;
  //initial begin
  //  fo_ROM   = $fopen("ROM.txt", "w");
  //  fo_DRAM  = $fopen("DRAM.txt", "w");
  //  fo_IM    = $fopen("IM.txt", "w");
  //  fo_DM    = $fopen("DM.txt", "w");
  //end
  
  // get memory value
  // task mem_monitor;
  //   begin
  //     `DUMP_MEM(fo_ROM,   i_ROM.Memory_byte,          0, 2**12-1, %h) // ./build/ROM.txt
  //     `DUMP_MEM(fo_DRAM,  i_DRAM.Memory_byte,         0, 2**21-1, %h) // ./build/DRAM.txt
  //     `DUMP_MEM(fo_IM,    TOP.IM1.i_SRAM.Memory_byte, 0, 16384-1, %h) // ./build/IM.txt
  //     `DUMP_MEM(fo_DM,    TOP.DM1.i_SRAM.Memory_byte, 0, 16384-1, %h) // ./build/DM.txt
  //   end
  // endtask

endmodule
