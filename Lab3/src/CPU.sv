`include "ALU.sv"
`include "Controller.sv"
// `include "Cycle_Reg.sv"
`include "Decoder.sv"
`include "F_RegFile.sv"
`include "FPU.sv"
`include "Imm_Ext.sv"
// `include "Inst_Reg.sv"
`include "CSR_Reg.sv"
`include "JB_Unit.sv"
`include "LD_Filter.sv"
`include "mux2.sv"
`include "mux3.sv"
`include "Reg_D.sv"
`include "Reg_E.sv"
`include "Reg_M.sv"
`include "Reg_PC.sv"
`include "Reg_W.sv"
`include "RegFile.sv"
// `include "SRAM_wrapper.sv"

module CPU (
    input logic clk,
    input logic rst, 
    input logic DMA_interrupt, // DMA
    input logic WDT_interrupt, // WDT
    input logic IM_stall,
    input logic DM_stall,
    input logic IM_handshake,
    input logic [31:0] INST, // IM DO
    input logic [31:0] DM_DO, // DM DO
    output logic [31:0] DM_A, // DM A
    output logic [31:0] PC,  // IM A
    output logic [31:0] DM_DI,
    output logic [3:0] DM_BWEB, // active low
    // IM always read
    output logic [1:0] DM_next_RW // read: 2, write: 1, idle: 0
);

    //IF stage
    // logic jb;
    logic [31:0] jb_pc;
    logic [31:0] current_pc;
    logic [31:0] next_pc;

    // logic stall;
    // logic F_im_CEB;
    // logic F_im_WEB;
    // logic [31:0] F_im_BWEB;
    logic [31:0] IF_inst;
    logic [31:0] IF_inst_reg;
    logic [31:0] IF_inst_pc;
    logic [31:0] IF_inst_stall;
    logic DM_stall_out; // 1 cycle later DM_stall (for saving Instruction)

    //ID stage
    logic [31:0] ID_pc;
    logic [31:0] ID_inst;

    logic [31:0] ID_sext_imm;

    logic [4:0] ID_op;
    logic [2:0] ID_f3;
    logic [1:0] ID_f7;
    logic [4:0] ID_rs1_idx;
    logic [4:0] ID_rs2_idx;
    logic [4:0] ID_rd_idx;
    logic [1:0] ID_imm;     // imm[27], imm[21]
    logic [3:0] ID_imm_csr; // imm[28], imm[26], imm[22], imm[20]
    logic ID_valid_inst;

    // logic W_wb_en;
    // logic [31:0] W_wb_data;
    // logic [4:0] W_rd_idx;
    logic [31:0] ID_rs1_data;
    logic [31:0] ID_rs2_data;

    // logic W_f_wb_en;
    logic [31:0] ID_frs1_data;
    logic [31:0] ID_frs2_data;

    // logic D_rs1_data_sel, D_rs2_data_sel;
    // logic D_frs1_data_sel, D_frs2_data_sel;
    logic [31:0] ID_rs1_d, ID_rs2_d;
    logic [31:0] ID_frs1_d, ID_frs2_d;

    // EXE stage
    logic [31:0] EX_pc;
    logic [31:0] EX_rs1_d, EX_rs2_d;
    logic [31:0] EX_frs1_d, EX_frs2_d;
    logic [31:0] EX_sext_imm;

    logic [31:0] EX_new_rs1_d, EX_new_rs2_d;
    logic [31:0] EX_new_frs1_d, EX_new_frs2_d;
    logic [31:0] EX_alu_op1, EX_alu_op2;
    logic [31:0] EX_alu_out;

    logic [31:0] EX_fpu_out;

    logic [31:0] EX_out;

    logic [31:0] EX_rs2_out;
    logic E_rs2_out_sel;

    logic [31:0] EX_cycle;
    // logic [31:0] EX_inst;
    // logic [31:0] EX_csr_out;

    logic [31:0] EX_jb_op2;
    // logic [31:0] jb_pc;

    // MEM stage
    logic [31:0] MM_alu_out;
    logic [31:0] MM_rs2_d;
    logic [31:0] MM_ld_data;
    logic [31:0] MM_dm_di;
    logic [31:0] MM_dm_di_new; // CSR forwarding select mux output

    // WB stage
    logic [31:0] WB_alu_out;
    logic [1:0]  WB_alu_out_01;
    logic [31:0] WB_ld_data;
    logic [31:0] WB_ld_data_f;
    logic [31:0] WB_wb_data;
    logic [31:0] WB_wb_data_new;
    logic [31:0] WB_csr_out;
    logic [31:0] csr_pc;

    // Controller
    // logic [31:0] F_im_BWEB;
    // logic F_im_CEB;
    // logic F_im_WEB;

    logic D_WFI;
    logic D_MRET;

    logic D_rs1_data_sel;
    logic D_rs2_data_sel;
    logic D_frs1_data_sel;
    logic D_frs2_data_sel;

    logic [1:0] E_rs1_data_sel;
    logic [1:0] E_rs2_data_sel;
    logic [1:0] E_frs1_data_sel;
    logic [1:0] E_frs2_data_sel;
    logic E_alu_op1_sel;
    logic E_alu_op2_sel;
    logic E_jb_op2_sel;
    logic E_FPU_add;
    // logic [1:0] E_out_sel;
    logic E_out_sel;

    logic [4:0] E_op;
    logic [2:0] E_f3;
    logic [1:0] E_f7;
    // logic [4:0] E_rd;
    logic [4:0] E_rs1;
    logic [1:0] E_imm;

    logic [31:0] M_dm_BWEB;
    logic M_dm_CEB;
    logic M_dm_WEB;
    logic M_rs2_data_sel;

    logic W_wb_en;
    logic W_f_wb_en;
    logic [4:0] W_rd_index;
    logic [2:0] W_f3;
    logic [1:0] W_wb_data_sel;

    logic [4:0] W_op;
    logic [4:0] W_rs1;
    logic [1:0] W_imm;
    logic [3:0] W_imm_csr;
    logic W_valid_inst;
    logic [31:0] W_rs1_uimm_data;

    logic stall;
    logic jb;
    logic stall_out;
    logic jb_out;

    // CSR reg
    logic interrupt_taken;
    logic interrupt_taken_reg;
    logic [31:0] csr_rs1_data_out;

    /* IF stage */
    // mux2 IF_Mux2 (
    //     .sel(jb),
    //     .in0(current_pc + 32'd4),
    //     .in1(jb_pc),
    //     .out(next_pc)
    // );

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            interrupt_taken_reg <= 1'b0;
        end else if (interrupt_taken && (IM_stall || DM_stall)) begin
            interrupt_taken_reg <= interrupt_taken;
        end else if (!IM_stall && !DM_stall) begin
            interrupt_taken_reg <= 1'b0;
        end else begin
            interrupt_taken_reg <= interrupt_taken_reg;
        end
    end


    always_comb begin
        if (interrupt_taken) 
            next_pc = csr_pc;
        else if (interrupt_taken_reg) // a transation interrupt_taken
            next_pc = csr_pc;
        else if (jb)
            next_pc = jb_pc;
        else if (D_MRET)
            next_pc = csr_pc;    
        else
            next_pc = current_pc + 32'd4;
    end

    Reg_PC IF_Peg_PC (
        .clk(clk),
        .rst(rst),
        .D_WFI(D_WFI),
        .stall(stall),
        .IM_stall(IM_stall),
        .DM_stall(DM_stall),
        .next_pc(next_pc),
        .current_pc(current_pc)
    );

    // for saving Instruction: avoid grant_s0_m1 = 1 then Inst be flushed
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            IF_inst_reg <= 32'd0;
            IF_inst_pc <= 32'd0;
        end else if (IM_handshake)begin
            IF_inst_reg <= INST; // IF_inst / INST
            IF_inst_pc <= current_pc;
        end else begin
            IF_inst_reg <= IF_inst_reg;
            IF_inst_pc <= IF_inst_pc;           
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            DM_stall_out <= 1'b0;
        end else begin
            DM_stall_out <= DM_stall; // 1 cycle later DM_stall
        end
    end


    always_comb begin
        if (DM_stall == 1'b0 && IM_stall == 1'b0 && DM_stall_out == 1'b1 
            && (current_pc == IF_inst_pc)) 
            IF_inst = IF_inst_reg;
        else
            IF_inst = INST;
    end

    assign PC = current_pc;
    // assign IF_inst = INST;

    // SRAM_wrapper IM1 (
    //     .CLK(clk),
    //     .RST(rst),
    //     .CEB(1'b0),
    //     .WEB(1'b1),
    //     .BWEB(32'hffffffff),
    //     .A(current_pc[15:2]),
    //     .DI(32'd0),
    //     .DO(IF_inst)
    // );

    /* ID stage */
    Reg_D ID_Reg_D (
        .clk(clk),
        .rst(rst),
        .interrupt_taken(interrupt_taken),
        .interrupt_taken_reg(interrupt_taken_reg),
        .D_MRET(D_MRET),
        .D_WFI(D_WFI),
        .stall(stall),
        .IM_stall(IM_stall),
        .DM_stall(DM_stall),
        .jb(jb),
        .pc_in(current_pc),
        .inst_in(IF_inst),
        .pc_out(ID_pc),
        .inst_out(ID_inst)
    );

    // 1 cycle later jb, stall
    // always_ff @ (posedge clk or posedge rst) begin
    //     if (rst) begin
    //         jb_out <= 1'b0;
    //         stall_out <= 1'b0;
    //         IF_inst_stall <= 32'd0; // NOP
    //     end
    //     else begin
    //         jb_out <= jb;
    //         stall_out <= stall;
    //         IF_inst_stall <= IF_inst;
    //     end            
    // end

    // always_comb begin
    //     if (jb_out || (ID_pc == 32'b0))
    //         ID_inst = 32'h00000013; // NOP
    //     else if (stall_out)
    //         ID_inst = IF_inst_stall;
    //     else
    //         ID_inst = IF_inst;
    // end

    Imm_Ext ID_Imm_Ext (
        // .inst(ID_inst),
        .inst(ID_inst),
        .imm_ext_out(ID_sext_imm)
    );

    Decoder ID_Decoder (
        // .inst(ID_inst),
        .inst(ID_inst),
        .dc_out_opcode(ID_op),
        .dc_out_func3(ID_f3),
        .dc_out_func7(ID_f7),
        .dc_out_rs1_index(ID_rs1_idx),
        .dc_out_rs2_index(ID_rs2_idx),
        .dc_out_rd_index(ID_rd_idx),
        .dc_out_imm(ID_imm),
        .dc_out_imm_csr(ID_imm_csr),
        .dc_out_valid_inst(ID_valid_inst)
    );

    RegFile ID_RegFile (
        .clk(clk),
        .wb_en(W_wb_en),
        // .wb_en(W_wb_en && ~(ID_pc == 32'h01a0)),
        .wb_data(WB_wb_data),
        .rd_index(W_rd_index),
        .rs1_index(ID_rs1_idx),
        .rs2_index(ID_rs2_idx),
        .csr_rs1_index(W_rs1),
        .rs1_data_out(ID_rs1_data),
        .rs2_data_out(ID_rs2_data),
        .csr_rs1_data_out(csr_rs1_data_out)
    );

    mux2 ID_Mux2_rs1 (
        .sel(D_rs1_data_sel),
        // .sel(D_rs1_data_sel && ~(ID_pc == 32'h01a0)),
        .in0(ID_rs1_data),
        .in1(WB_wb_data),
        .out(ID_rs1_d)
    );

    mux2 ID_Mux2_rs2 (
        .sel(D_rs2_data_sel),
        .in0(ID_rs2_data),
        .in1(WB_wb_data),
        .out(ID_rs2_d)
    );

    F_RegFile ID_F_RegFile (
        .clk(clk),
        .wb_en(W_f_wb_en),
        .wb_data(WB_wb_data),
        .rd_index(W_rd_index),
        .rs1_index(ID_rs1_idx),
        .rs2_index(ID_rs2_idx),
        .rs1_data_out(ID_frs1_data),
        .rs2_data_out(ID_frs2_data)
    );

    mux2 ID_Mux2_frs1 (
        .sel(D_frs1_data_sel),
        .in0(ID_frs1_data),
        .in1(WB_wb_data),
        .out(ID_frs1_d)
    );

    mux2 ID_Mux2_frs2 (
        .sel(D_frs2_data_sel),
        .in0(ID_frs2_data),
        .in1(WB_wb_data),
        .out(ID_frs2_d)
    );

    /* EX stage */
    Reg_E EX_Reg_E (
        .clk(clk),
        .rst(rst),
        .D_WFI(D_WFI),
        .D_MRET(D_MRET),
        .interrupt_taken_reg(interrupt_taken_reg),
        .stall(stall),
        .IM_stall(IM_stall),
        .DM_stall(DM_stall),
        .jb(jb),
        .pc_in(ID_pc),
        .rs1_data_in(ID_rs1_d),
        .rs2_data_in(ID_rs2_d),
        .frs1_data_in(ID_frs1_d),
        .frs2_data_in(ID_frs2_d),
        .sext_imm_in(ID_sext_imm),
        .pc_out(EX_pc),
        .rs1_data_out(EX_rs1_d),
        .rs2_data_out(EX_rs2_d),
        .frs1_data_out(EX_frs1_d),
        .frs2_data_out(EX_frs2_d),
        .sext_imm_out(EX_sext_imm)
    );

    // ALU
    mux3 EX_Mux3_rs1 (
        .sel(E_rs1_data_sel),
        .in0(WB_wb_data),
        .in1(MM_alu_out),
        .in2(EX_rs1_d),
        .out(EX_new_rs1_d)
    );

    mux3 EX_Mux3_rs2 (
        .sel(E_rs2_data_sel),
        .in0(WB_wb_data),
        .in1(MM_alu_out),
        .in2(EX_rs2_d),
        .out(EX_new_rs2_d)
    );

    mux2 EX_Mux2_alu_op1 (
        .sel(E_alu_op1_sel),
        .in0(EX_new_rs1_d),
        .in1(EX_pc),
        .out(EX_alu_op1)
    );

    mux2 EX_Mux2_alu_op2 (
        .sel(E_alu_op2_sel),
        .in0(EX_new_rs2_d),
        .in1(EX_sext_imm),
        .out(EX_alu_op2)
    );

    ALU EX_ALU (
        .opcode(E_op),
        .func3(E_f3),
        .func7(E_f7),
        .operand1(EX_alu_op1),
        .operand2(EX_alu_op2),
        .alu_out(EX_alu_out)
    );

    // FPU
    mux3 EX_Mux3_frs1 (
        .sel(E_frs1_data_sel),
        .in0(WB_wb_data),
        .in1(MM_alu_out),
        .in2(EX_frs1_d),
        .out(EX_new_frs1_d)
    );

    mux3 EX_Mux3_frs2 (
        .sel(E_frs2_data_sel),
        .in0(WB_wb_data),
        .in1(MM_alu_out),
        .in2(EX_frs2_d),
        .out(EX_new_frs2_d)
    );

    FPU EX_FPU (
        .op(E_FPU_add),
        .FA(EX_new_frs1_d),
        .FB(EX_new_frs2_d),
        .FS(EX_fpu_out)
    );

    // ALU, FPU, CSR sel
     // ALU, FPU
    mux2 EX_Mux2_out (
        .sel(E_out_sel),
        .in0(EX_alu_out),
        .in1(EX_fpu_out),
        .out(EX_out)
    );
    // mux3 EX_Mux3_out (
    //     .sel(E_out_sel),
    //     .in0(EX_alu_out),
    //     .in1(EX_fpu_out),
    //     .in2(EX_csr_out),
    //     .out(EX_out)
    // );

    always_comb begin
        if (E_op == 5'b01001) 
            E_rs2_out_sel = 1'b1; // frs2
        else
            E_rs2_out_sel = 1'b0; // rs2
    end

    mux2 EX_Mux2_rs2_sel (
        .sel(E_rs2_out_sel),
        .in0(EX_new_rs2_d),
        .in1(EX_new_frs2_d),
        .out(EX_rs2_out)
    );

    // JB unit
    mux2 EX_Mux2_jb_unit (
        .sel(E_jb_op2_sel),
        .in0(EX_new_rs1_d),
        .in1(EX_pc),
        .out(EX_jb_op2)
    );

    JB_Unit EX_JB_Unit (
        .operand1(EX_sext_imm),
        .operand2(EX_jb_op2),
        .jb_out(jb_pc)
    );

    /* MM stage */
    Reg_M MM_Reg_M (
        .clk(clk),
        .rst(rst),
        .D_WFI(D_WFI),
        .IM_stall(IM_stall),
        .DM_stall(DM_stall),
        .alu_out_in(EX_out),
        .rs2_data_in(EX_rs2_out),
        .alu_out_out(MM_alu_out),
        .rs2_data_out(MM_rs2_d)
    );

    // for store shift
    always_comb begin 
        case (MM_alu_out[1:0])
            2'b11: MM_dm_di = {MM_rs2_d[7:0], 24'd0};
            2'b10: MM_dm_di = {MM_rs2_d[15:0], 16'd0};
            2'b01: MM_dm_di = {MM_rs2_d[23:0], 8'd0};
            2'b00: MM_dm_di = MM_rs2_d;
            default: MM_dm_di = MM_rs2_d;
        endcase
    end

    always_comb begin 
        case (MM_alu_out[1:0])
            2'b11: WB_wb_data_new = {WB_wb_data[7:0], 24'd0};
            2'b10: WB_wb_data_new = {WB_wb_data[15:0], 16'd0};
            2'b01: WB_wb_data_new = {WB_wb_data[23:0], 8'd0};
            2'b00: WB_wb_data_new = WB_wb_data;
            default: WB_wb_data_new = WB_wb_data;
        endcase
    end

    // Mux2 for CSR forwarding
    mux2 MM_Mux2_rs2 (
        .sel(M_rs2_data_sel),
        .in0(MM_dm_di),
        .in1(WB_wb_data_new),
        .out(MM_dm_di_new)
    );

    assign DM_A = MM_alu_out;
    assign DM_DI = MM_dm_di_new;
    assign MM_ld_data = DM_DO;
    assign DM_WEB = M_dm_WEB;
    assign DM_BWEB = {M_dm_BWEB[24], M_dm_BWEB[16], M_dm_BWEB[8], M_dm_BWEB[0]};

    // SRAM_wrapper DM1 (
    //     .CLK(clk),
    //     .RST(rst),
    //     .CEB(1'b0),
    //     .WEB(M_dm_WEB),
    //     .BWEB(M_dm_BWEB),
    //     .A(MM_alu_out[15:2]),
    //     .DI(MM_dm_di),
    //     .DO(MM_ld_data)
    // );

    /* WB stage */
    Reg_W WB_Reg_W (
        .clk(clk),
        .rst(rst),
        .D_WFI(D_WFI),
        .IM_stall(IM_stall),
        .DM_stall(DM_stall),
        .alu_out_in(MM_alu_out),
        .alu_out_out(WB_alu_out),
        .ld_data_in(MM_ld_data),
        .ld_data_out(WB_ld_data)
    );

    LD_Filter WB_LD_Filter (
        .func3(W_f3),
        .ld_data(WB_ld_data),
        .WB_alu_out_01(WB_alu_out[1:0]),
        .ld_data_f(WB_ld_data_f)
    );

    // CSR: inst/cycle reg
    CSR_Reg WB_CSR_Reg (
        .clk(clk),
        .rst(rst),
        .current_pc(current_pc),
        .IM_stall(IM_stall),
        .DM_stall(DM_stall),
        .interrupt_taken_reg(interrupt_taken_reg),
        .ext_interrupt(DMA_interrupt), // DMA
        .timer_interrupt(WDT_interrupt), // WDT
        .wfi(D_WFI),
        .mret(D_MRET),
        .W_op(W_op),
        .W_rs1(W_rs1),
        .rd_index(W_rd_index),
        .func3(W_f3),
        .imm(W_imm),
        .imm_csr(W_imm_csr),  
        .csr_rs1_data_out(csr_rs1_data_out),
        .valid_inst(W_valid_inst),
        .interrupt_taken(interrupt_taken),
        .csr_out(WB_csr_out),
        .csr_pc(csr_pc)
    );

    mux3 WB_Mux3_wb_data (
        .sel(W_wb_data_sel),
        .in0(WB_ld_data_f),
        .in1(WB_alu_out),
        .in2(WB_csr_out),
        .out(WB_wb_data)
    );

    // mux2 WB_Mux2_wb_data (
    //     .sel(W_wb_data_sel),
    //     .in0(WB_ld_data_f),
    //     .in1(WB_alu_out),
    //     .out(WB_wb_data)
    // );

    /* Controller */
    Controller controller (
        .clk(clk),
        .rst(rst),
        .opcode(ID_op),
        .funct3(ID_f3),
        .rs1_index(ID_rs1_idx),
        .rs2_index(ID_rs2_idx),
        .rd_index(ID_rd_idx),
        .func7(ID_f7),
        .imm(ID_imm), // imm[7], imm[1] 
        .imm_csr(ID_imm_csr), // imm[8], imm[6], imm[2], imm[0]
        .valid_inst(ID_valid_inst),      

        .interrupt_taken(interrupt_taken),
        .EX_out(EX_out),

        .alu_out_0(EX_alu_out[0]),
        .MM_alu_out_01(MM_alu_out[1:0]),

        // .F_im_BWEB(F_im_BWEB),     // Instruction Memory write enable
        // .F_im_CEB(F_im_CEB),       // Instruction Memory chip enable
        // .F_im_WEB(F_im_WEB),       // Instruction Memory write enable

        .D_WFI(D_WFI),             // Wait for interrupt
        .D_MRET(D_MRET),           // Return from traps

        .D_rs1_data_sel(D_rs1_data_sel),   // Register file read source 1 select
        .D_rs2_data_sel(D_rs2_data_sel),   // Register file read source 2 select
        .D_frs1_data_sel(D_frs1_data_sel), // Floating-point register file read source 1 select
        .D_frs2_data_sel(D_frs2_data_sel), // Floating-point register file read source 2 select

        .E_rs1_data_sel(E_rs1_data_sel),   // Execute stage source 1 data select
        .E_rs2_data_sel(E_rs2_data_sel),   // Execute stage source 2 data select
        .E_frs1_data_sel(E_frs1_data_sel), // Execute stage floating-point source 1 data select
        .E_frs2_data_sel(E_frs2_data_sel), // Execute stage floating-point source 2 data select
        .E_alu_op1_sel(E_alu_op1_sel),     // ALU operand 1 select
        .E_alu_op2_sel(E_alu_op2_sel),     // ALU operand 2 select
        .E_jb_op2_sel(E_jb_op2_sel),       // Jump/branch operand 2 select
        .E_FPU_add(E_FPU_add),             // Floating-point add/sub select
        .E_out_sel(E_out_sel),             // ALU / FPU / CSR

        .E_op(E_op),           // Execute operation
        .E_f3(E_f3),           // Function code (funct3)
        .E_f7(E_f7),           // Function code (funct7)
        // .E_rd(E_rd),           // Destination register index
        // .E_rs1(E_rs1),         // Source register 1 index
        // .E_imm(E_imm),         // Immediate value

        .M_dm_BWEB(M_dm_BWEB), // Data Memory write enable
        .M_dm_CEB(M_dm_CEB),   // Data Memory chip enable
        .M_dm_WEB(M_dm_WEB),   // Data Memory write enable
        .M_rs2_data_sel(M_rs2_data_sel), // CSR / other

        .W_wb_en(W_wb_en),             // Reg Write-back enable
        .W_f_wb_en(W_f_wb_en),         // F-reg write-back enable
        .W_op(W_op),                   // Operation code
        .W_rs1(W_rs1),                 // for CSR reg
        .W_rd_index(W_rd_index),       // Write-back register index
        .W_f3(W_f3),                   // Function code (funct3)
        .W_wb_data_sel(W_wb_data_sel), // Write-back data select

        .W_imm(W_imm),
        .W_imm_csr(W_imm_csr),
        .W_valid_inst(W_valid_inst),
        // .W_rs1_uimm_data(W_rs1_uimm_data),

        .IM_stall(IM_stall),
        .DM_stall(DM_stall),
        .DM_next_RW(DM_next_RW),
        .stall(stall), // Stall signal
        .jb(jb)        // Jump or branch success
    );

endmodule
