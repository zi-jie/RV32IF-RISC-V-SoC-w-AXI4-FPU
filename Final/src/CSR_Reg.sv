module CSR_Reg (
    input logic clk,             // Clock signal
    input logic rst,    
    input logic [31:0] current_pc, // Current PC         
    input logic IM_stall,
    input logic DM_stall,
    input logic interrupt_taken_reg,
    // input logic ext_interrupt,   // External interrupt signal
    input logic DMA_interrupt, 
    input logic DLA_interrupt,
    input logic timer_interrupt, // Timer interrupt signal
    input logic wfi,             // Wait for interrupt signal
    input logic mret,            // return from traps
    input logic [4:0] W_op,       // W_op
    input logic [4:0] W_rs1,      // W_rs1
    input logic [4:0] rd_index,            // rd == x0 --> csr don't do
    input logic [2:0] func3,      // funct3 (W_f3)
    input logic [1:0] imm,        // imm 27, 21
    input logic [3:0] imm_csr,    // imm 28, 26, 22, 20
    input logic [31:0] csr_rs1_data_out, // Data from CSR source register 1
    input logic valid_inst,       // valid instruction (W_valid_inst)
    output logic interrupt_taken, // interrupt taken
    output logic [31:0] csr_out,
    output logic [31:0] csr_pc    // mepc for interrupt, return
);

    // logic valid_inst;
    logic [63:0] instret;
    logic [63:0] cycle;
    // New CSR Reg
    logic [31:0] mcause;
    logic [31:0] mstatus;
    logic [31:0] mie;
    logic [31:0] mtvec;
    logic [31:0] mepc;
    logic [31:0] mip;

    logic [31:0] rs1_uimm_data; // Data from rs1 / uimm(inst[19:15] zero extended)

    // logic interrupt_taken;
    logic csr_taken;
    logic ext_interrupt;

    assign ext_interrupt = DLA_interrupt || DMA_interrupt;

    // controll signals
    // assign interrupt_taken = mstatus[3] && (ext_interrupt || timer_interrupt); 
    assign interrupt_taken = mstatus[3] && (ext_interrupt && mie[11] || timer_interrupt && mie[7]); // MIE and MEIE / MTIE
    // CSR inst taken: rd != 0 and MPP = machine mode 
    // assign csr_taken = (rd_index != 5'd0) && mstatus[1:0] == 2'b11 && W_op == 5'b11100;
    // logic interrupt_taken_reg;

    // assign csr_taken = mstatus[12:11] == 2'b11 && W_op == 5'b11100; 
    assign csr_taken = W_op == 5'b11100; 

    // Use uimm or rs1 data
    assign rs1_uimm_data = func3[2] ? {27'd0, W_rs1} : csr_rs1_data_out;

    // CSR to rd
    always_comb begin
        if (!imm_csr[3]) begin // cycle, instret imm[28] = 0
            case (imm) 
                2'b11: csr_out = instret[63:32];
                2'b01: csr_out = (instret[31:0] - 32'd1);
                2'b10: csr_out = cycle[63:32];
                2'b00: csr_out = (cycle[31:0] - 32'd4); //WB late 4 cycles
                default: csr_out = 32'd0;
            endcase
        end else begin // mstatus, mie, mtvec, mepc, mip
            case ({imm_csr[2], imm_csr[1], imm_csr[0]}) // imm 26, 22, 20 
                // 3'b000: csr_out = mstatus;
                3'b000: csr_out = {19'd0, mstatus[12:11], 3'd0, mstatus[7], 3'd0, mstatus[3], 3'd0};
                // 3'b010: csr_out = mie;
                3'b010: csr_out = {20'd0, mie[11], 3'd0, mie[7], 7'd0};
                3'b100: csr_out = mcause;
                3'b011: csr_out = mtvec;
                3'b101: csr_out = mepc;
                // 3'b110: csr_out = mip;
                3'b110: csr_out = {20'd0, mip[11], 3'd0, mip[7], 7'd0};
                default: csr_out = 32'd0;
            endcase
        end
    end

    // mcause 
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            mcause <= 32'd0;
        end else if (interrupt_taken) begin // if MRET mcause don't change
            if (DLA_interrupt)   mcause <= 32'h80000011;
            else if (DMA_interrupt)   mcause <= 32'h80000010; 
            else if (timer_interrupt) mcause <= 32'h80000007;
        end else if (csr_taken && imm_csr[2:0] == 3'b100 && (IM_stall == 0 && DM_stall == 0)) begin // csr instruction op[6:2] = 11100 and rd != 0
            case (func3) 
                3'b001: mcause <= rs1_uimm_data;                // CSRRW
                3'b010: mcause <= mcause | rs1_uimm_data;         // CSRRS
                3'b011: mcause <= mcause & ~rs1_uimm_data;        // CSRRC
                3'b101: mcause <= rs1_uimm_data;                // CSRRWI
                3'b110: mcause <= mcause | rs1_uimm_data;         // CSRRSI
                3'b111: mcause <= mcause & ~rs1_uimm_data;        // CSRRCI
                default: mcause <= mcause;
            endcase 
        end
    end

    // mstatus: 12, 11, 7, 3 (other hardwire 0)
    always_ff @(posedge clk or posedge rst) begin
        // mstatus[12:11] <= 2'b11; // hardwire 11 
        if (rst) begin
            mstatus <= 32'd0;
            // mstatus <= 32'h0000_0008;   
        end else if (interrupt_taken) begin 
            mstatus[7] <= mstatus[3];
            mstatus[3] <= 1'b0;
            mstatus[12:11] <= 2'b11;   
        end else if (mret) begin // MRET: interupt reture
            mstatus[7] <= 1'b1;
            mstatus[3] <= mstatus[7];
            mstatus[12:11] <= 2'b11;
        end else if (csr_taken && imm_csr[2:0] == 3'b000 && (IM_stall == 0 && DM_stall == 0)) begin // rd != 0 and MPP = machine mode
            case (func3)
                3'b001: {mstatus[12:11], mstatus[7], mstatus[3]} <= {rs1_uimm_data[12:11], rs1_uimm_data[7], rs1_uimm_data[3]};                // CSRRW
                3'b010: {mstatus[12:11], mstatus[7], mstatus[3]} <= {mstatus[12:11], mstatus[7], mstatus[3]} | {rs1_uimm_data[12:11], rs1_uimm_data[7], rs1_uimm_data[3]};      // CSRRS
                3'b011: {mstatus[12:11], mstatus[7], mstatus[3]} <= {mstatus[12:11], mstatus[7], mstatus[3]} & ~{rs1_uimm_data[12:11], rs1_uimm_data[7], rs1_uimm_data[3]};     // CSRRC
                3'b101: {mstatus[12:11], mstatus[7], mstatus[3]} <= {rs1_uimm_data[12:11], rs1_uimm_data[7], rs1_uimm_data[3]};                // CSRRWI
                3'b110: {mstatus[12:11], mstatus[7], mstatus[3]} <= {mstatus[12:11], mstatus[7], mstatus[3]} | {rs1_uimm_data[12:11], rs1_uimm_data[7], rs1_uimm_data[3]};      // CSRRSI
                3'b111: {mstatus[12:11], mstatus[7], mstatus[3]} <= {mstatus[12:11], mstatus[7], mstatus[3]} & ~{rs1_uimm_data[12:11], rs1_uimm_data[7], rs1_uimm_data[3]};     // CSRRCI
                default: mstatus <= mstatus;
                // 3'b001: mstatus <= rs1_uimm_data;                // CSRRW
                // 3'b010: mstatus <= mstatus | rs1_uimm_data;      // CSRRS
                // 3'b011: mstatus <= mstatus & ~rs1_uimm_data;     // CSRRC
                // 3'b101: mstatus <= rs1_uimm_data;                // CSRRWI
                // 3'b110: mstatus <= mstatus | rs1_uimm_data;      // CSRRSI
                // 3'b111: mstatus <= mstatus & ~rs1_uimm_data;     // CSRRCI
                // default: mstatus <= mstatus;
            endcase 
        end 
    end

    // mtvec 
    assign mtvec = 32'h0001_0000;

    // mip 
    assign mip[11] = ext_interrupt && mie[11]; 
    assign mip[7]  = timer_interrupt && mie[7]; // connect to interrupt signal and check MEIE/MTIE
    assign mip[31:12] = 20'd0;
    assign mip[10:8] = 3'd0;
    assign mip[6:0] = 7'd0;

    // mie
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            mie <= 32'd0;
        end else if (csr_taken && imm_csr[2:0] == 3'b010 && (IM_stall == 0 && DM_stall == 0)) begin // csr instruction op[6:2] = 11100 and rd != 0
            case (func3)
                3'b001: {mie[11], mie[7]} <= {rs1_uimm_data[11], rs1_uimm_data[7]};                // CSRRW
                3'b010: {mie[11], mie[7]} <= {mie[11], mie[7]} | {rs1_uimm_data[11], rs1_uimm_data[7]};          // CSRRS
                3'b011: {mie[11], mie[7]} <= {mie[11], mie[7]} & ~{rs1_uimm_data[11], rs1_uimm_data[7]};         // CSRRC
                3'b101: {mie[11], mie[7]} <= {rs1_uimm_data[11], rs1_uimm_data[7]};                // CSRRWI
                3'b110: {mie[11], mie[7]} <= {mie[11], mie[7]} | {rs1_uimm_data[11], rs1_uimm_data[7]};          // CSRRSI
                3'b111: {mie[11], mie[7]} <= {mie[11], mie[7]} & ~{rs1_uimm_data[11], rs1_uimm_data[7]};         // CSRRCI
                // 3'b001: mie <= rs1_uimm_data;                // CSRRW
                // 3'b010: mie <= mie | rs1_uimm_data;          // CSRRS
                // 3'b011: mie <= mie & ~rs1_uimm_data;         // CSRRC
                // 3'b101: mie <= rs1_uimm_data;                // CSRRWI
                // 3'b110: mie <= mie | rs1_uimm_data;          // CSRRSI
                // 3'b111: mie <= mie & ~rs1_uimm_data;         // CSRRCI
                default: mie <= mie;
            endcase 
        end
    end

    // mepc
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            mepc <= 32'd0;
        end else if (interrupt_taken) begin // interrupt taken
            mepc <= current_pc; // because WFI at ID decoder, so pc + 4 = current_pc
            // if (wfi) // in WFI mode
            //     mepc <= pc + 32'd4;
            // else
            //     mepc <= pc;
        end else if ((csr_taken && imm_csr[2:0] == 3'b101) && (IM_stall == 0 && DM_stall == 0)) begin // csr instruction op[6:2] = 11100 and rd != 0
            case (func3) 
                3'b001: mepc <= rs1_uimm_data;                // CSRRW
                3'b010: mepc <= mepc | rs1_uimm_data;         // CSRRS
                3'b011: mepc <= mepc & ~rs1_uimm_data;        // CSRRC
                3'b101: mepc <= rs1_uimm_data;                // CSRRWI
                3'b110: mepc <= mepc | rs1_uimm_data;         // CSRRSI
                3'b111: mepc <= mepc & ~rs1_uimm_data;        // CSRRCI
                default: mepc <= mepc;
            endcase 
        end
    end

    // PC out for interrupt taken and return
    always_comb begin
        if (interrupt_taken || interrupt_taken_reg) begin
            csr_pc = mtvec;
        end else if (mret) begin
            csr_pc = mepc;
        end else begin
            csr_pc = 32'd0;
        end
    end

/*------------------------- Old Registers -------------------------*/

    // Inst_Reg: Internal 64-bit counter
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            instret <= 64'd0;  // Reset counter to 0
        end else if (valid_inst && (IM_stall == 0 && DM_stall == 0)) begin
            instret <= instret + 1;  // Increment the instruction retire counter
        end else begin
            instret <= instret;  // Do not increment the counter
        end
    end

    // Cycle Reg
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            cycle <= 64'd0;  // Reset counter to 0
        end else begin
            cycle <= cycle + 1;  // Increment the cycle counter on each clock cycle
        end
    end

endmodule
