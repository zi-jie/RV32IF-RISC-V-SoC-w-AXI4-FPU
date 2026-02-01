`include "CPU.sv"
`include "../include/AXI_define.svh"

module CPU_wrapper (
    input  logic                        ACLK,
    input  logic                        ARESETn,
    // Master interface 1 (AW channel)
    output logic [`AXI_ID_BITS-1:0]     AWID_M1,
    output logic [`AXI_ADDR_BITS-1:0]   AWADDR_M1,
    output logic [`AXI_LEN_BITS-1:0]    AWLEN_M1,
    output logic [`AXI_SIZE_BITS-1:0]   AWSIZE_M1,
    output logic [1:0]                  AWBURST_M1,
    output logic                        AWVALID_M1,
    input  logic                        AWREADY_M1,
    // Master interface 1 (W channel)
    output logic [`AXI_DATA_BITS-1:0]   WDATA_M1,
    output logic [`AXI_STRB_BITS-1:0]   WSTRB_M1,
    output logic                        WLAST_M1,
    output logic                        WVALID_M1,
    input  logic                        WREADY_M1,
    // Master interface 1 (B channel)
    input  logic [`AXI_ID_BITS-1:0]     BID_M1,
    input  logic [1:0]                  BRESP_M1,
    input  logic                        BVALID_M1,
    output logic                        BREADY_M1,
    // Master interface 0 (AR channel)
    output logic [`AXI_ID_BITS-1:0]     ARID_M0,
    output logic [`AXI_ADDR_BITS-1:0]   ARADDR_M0,
    output logic [`AXI_LEN_BITS-1:0]    ARLEN_M0,
    output logic [`AXI_SIZE_BITS-1:0]   ARSIZE_M0,
    output logic [1:0]                  ARBURST_M0,
    output logic                        ARVALID_M0,
    input  logic                        ARREADY_M0,
    // Master interface 0 (R channel)
    input  logic [`AXI_ID_BITS-1:0]     RID_M0,
    input  logic [`AXI_DATA_BITS-1:0]   RDATA_M0,
    input  logic [1:0]                  RRESP_M0,
    input  logic                        RLAST_M0,
    input  logic                        RVALID_M0,
    output logic                        RREADY_M0,
    // Master interface 1 (AR channel)
    output logic [`AXI_ID_BITS-1:0]     ARID_M1,
    output logic [`AXI_ADDR_BITS-1:0]   ARADDR_M1,
    output logic [`AXI_LEN_BITS-1:0]    ARLEN_M1,
    output logic [`AXI_SIZE_BITS-1:0]   ARSIZE_M1,
    output logic [1:0]                  ARBURST_M1,
    output logic                        ARVALID_M1,
    input  logic                        ARREADY_M1,
    // Master interface 1 (R channel)
    input  logic [`AXI_ID_BITS-1:0]     RID_M1,
    input  logic [`AXI_DATA_BITS-1:0]   RDATA_M1,
    input  logic [1:0]                  RRESP_M1,
    input  logic                        RLAST_M1,
    input  logic                        RVALID_M1,
    output logic                        RREADY_M1
);
// Master 0: AR, R
// Master 1: AW, W, B, AR, R

// CPU CPU1(
//     .clk(ACLK),
//     .rst(~ARESETn),
//     .IM_stall(cpu_IM_stall),
//     .DM_stall(cpu_DM_stall),
//     .INST(cpu_INST), 
//     .DM_DI(cpu_DM_DI),
//     .DM_A(cpu_DM_A),
//     .PC(cpu_PC), // IM Address 
//     .DM_DO(cpu_DM_DO),
//     .DM_BWEB(cpu_DM_BWEB),
//     .DM_next_RW(cpu_DM_next_RW)
// );
    // State encoding for round-robin
    typedef enum logic [3:0] {
        IDLE          = 4'd0,
        READ_ADDR     = 4'd1,
        READ_DATA     = 4'd2,
        READ_DATA_2   = 4'd3,
        WRITE_ADDR    = 4'd4,
        WRITE_DATA    = 4'd5,
        WRITE_DATA_2  = 4'd6,
        WRITE_RESP    = 4'd7,
        WRITE_RESP_2  = 4'd8
    } FSM_state;

    FSM_state current_state_m0, next_state_m0;
    FSM_state current_state_m1, next_state_m1;

    /* CPU */
    logic cpu_IM_stall, cpu_DM_stall;
    logic [31:0] cpu_INST; // IM DO
    logic [31:0] cpu_PC;   // IM A
    logic [31:0] cpu_DM_DI, cpu_DM_DO;
    logic [31:0] cpu_DM_A;
    logic [3:0] cpu_DM_BWEB;
    logic [1:0]  cpu_DM_next_RW; // 2: read, 1: write, 0: idle
    logic [1:0]  cpu_DM_next_RW_reg; // save signal for single Store(write)
    
    logic cpu_IM_handshake;

    assign cpu_IM_handshake = RVALID_M0 && RREADY_M0;

    // assign cpu_IM_stall = ~((RVALID_M0 && RREADY_M0)); //FIXME: RLAST
    assign cpu_IM_stall = (current_state_m0 != IDLE) && ~(RVALID_M0 && RREADY_M0) || 
                          ((current_state_m0 == IDLE) && (cpu_DM_stall || cpu_PC == 32'd0));
    // assign cpu_DM_stall = ~((RVALID_M1 && RREADY_M1) || (WVALID_M1 && WREADY_M1));
    // assign cpu_DM_stall = (current_state_m1 != IDLE) && (cpu_DM_next_RW != 2'd0); 
    assign cpu_DM_stall  = 
        ((current_state_m1 inside {READ_ADDR, READ_DATA, READ_DATA_2}) && ~(RVALID_M1 && RREADY_M1)) ||
        ((current_state_m1 inside {WRITE_ADDR, WRITE_DATA, WRITE_RESP, WRITE_RESP_2}) && ~(BVALID_M1 && BREADY_M1) && (cpu_DM_next_RW != 2'd0));
    // idle: 0, read: 2, write: 1

    /* Master 1 */
    logic [`AXI_LEN_BITS-1:0] AWLEN_m1_reg; 

CPU CPU1(
    .clk(ACLK),
    .rst(~ARESETn),
    .IM_stall(cpu_IM_stall),
    .DM_stall(cpu_DM_stall),
    .IM_handshake(cpu_IM_handshake),
    .INST(cpu_INST), 
    .DM_DI(cpu_DM_DI),
    .DM_A(cpu_DM_A),
    .PC(cpu_PC), // IM Address 
    .DM_DO(cpu_DM_DO),
    .DM_BWEB(cpu_DM_BWEB),
    .DM_next_RW(cpu_DM_next_RW)
);

/* Master 0: IM only read transaction */

    // output
    assign ARID_M0 = `AXI_ID_BITS'd1; // ID: master0(1), master1(2)
    assign ARLEN_M0 = `AXI_LEN_BITS'b0; // len = 1
    assign ARSIZE_M0 = `AXI_SIZE_BITS'b010; // 4 bytes
    assign ARBURST_M0 = 2'b01; // INCR
    assign ARADDR_M0 = cpu_PC;
    // input
    assign cpu_INST = RDATA_M0; 

    // stage register
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) 
            current_state_m0 <= IDLE;
        else
            current_state_m0 <= next_state_m0;
    end

    // Next state logic
    always_comb begin
        case (current_state_m0)
            IDLE: begin
                if (cpu_DM_stall)
                    next_state_m0 = IDLE;
                else
                    next_state_m0 = READ_ADDR;
            end
            READ_ADDR: begin
                if (ARVALID_M0 && ARREADY_M0) 
                    next_state_m0 = READ_DATA;
                else
                    next_state_m0 = READ_ADDR;
            end
            READ_DATA: begin
                if (RVALID_M0) 
                    next_state_m0 = READ_DATA_2;
                else
                    next_state_m0 = READ_DATA;
            end
            READ_DATA_2: begin
                if (RLAST_M0 && RVALID_M0 && RREADY_M0) begin //FIXME: maybe RREADY vip
                    if (cpu_DM_stall)
                        next_state_m0 = IDLE;
                    else
                        next_state_m0 = READ_ADDR;
                end else
                    next_state_m0 = READ_DATA_2;
            end
        endcase
    end

    // Output logic: AR, R channel
    always_comb begin
        case (current_state_m0)
            READ_ADDR: begin
                ARVALID_M0 = 1'b1;
                RREADY_M0 = 1'b0;
            end
            READ_DATA: begin
                ARVALID_M0 = 1'b0;
                RREADY_M0 = 1'b0;                
            end  
            READ_DATA_2: begin
                ARVALID_M0 = 1'b0;
                RREADY_M0 = 1'b1;
            end
            default: begin
                ARVALID_M0 = 1'b0;
                RREADY_M0 = 1'b0;
            end            
        endcase
    end

    // // stage register
    // always_ff @(posedge ACLK or negedge ARESETn) begin
    //     if (!ARESETn) 
    //         current_state_m0 <= READ_ADDR;
    //     else
    //         current_state_m0 <= next_state_m0;
    // end

    // // Next state logic
    // always_comb begin
    //     case (current_state_m0)
    //         READ_ADDR: begin
    //             if (ARVALID_M0 && ARREADY_M0) 
    //                 next_state_m0 = READ_DATA;
    //             else
    //                 next_state_m0 = READ_ADDR;
    //         end
    //         READ_DATA: begin
    //             if (RLAST_M0 && RVALID_M0 && RREADY_M0) 
    //                 next_state_m0 = READ_ADDR;
    //             else
    //                 next_state_m0 = READ_DATA;
    //         end
    //     endcase
    // end

    // // Output logic: AR, R channel
    // always_comb begin
    //     case (current_state_m0)
    //         READ_ADDR: begin
    //             ARVALID_M0 = 1'b1;
    //             RREADY_M0 = 1'b0;
    //         end  
    //         READ_DATA: begin
    //             ARVALID_M0 = 1'b0;
    //             RREADY_M0 = 1'b1;
    //         end
    //         default: begin
    //             ARVALID_M0 = 1'b0;
    //             RREADY_M0 = 1'b0;
    //         end            
    //     endcase
    // end

    /* Master 1: DM read and write transaction */
    
    assign cpu_DM_DO = RDATA_M1;

    // For Write transaction, save CPU_DM_next_RW
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) 
            cpu_DM_next_RW_reg <= 2'd0;
        else if (current_state_m1 == WRITE_ADDR)
            cpu_DM_next_RW_reg <= cpu_DM_next_RW;
        else
            cpu_DM_next_RW_reg <= cpu_DM_next_RW_reg;
    end
    
    // stage register
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) 
            current_state_m1 <= IDLE;
        else
            current_state_m1 <= next_state_m1;
    end

    // Next state logic
    always_comb begin 
        case (current_state_m1)
            IDLE: begin
                if (~cpu_IM_stall) begin // avoid DM_stall early 1 stage
                    if (cpu_DM_next_RW == 2'd2)
                        next_state_m1 = READ_ADDR;  
                    else if (cpu_DM_next_RW == 2'd1)
                        next_state_m1 = WRITE_ADDR;
                end else 
                    next_state_m1 = IDLE;
            end
            READ_ADDR: begin
                if (ARVALID_M1 && ARREADY_M1) 
                    next_state_m1 = READ_DATA;
                else
                    next_state_m1 = READ_ADDR;
            end
            READ_DATA: begin
                if (RVALID_M1) next_state_m1 = READ_DATA_2;
                else           next_state_m1 = READ_DATA;
            end
            READ_DATA_2: begin
                if (RLAST_M1 && RVALID_M1 && RREADY_M1) begin
                    if (cpu_DM_next_RW == 2'd2) // read: 2, write: 1, idle: 0
                        next_state_m1 = READ_ADDR;
                    else if (cpu_DM_next_RW == 2'd1)
                        next_state_m1 = WRITE_ADDR;
                    else
                        next_state_m1 = IDLE;
                end else
                    next_state_m1 = READ_DATA_2;
            end
            WRITE_ADDR: begin
                if (AWVALID_M1 && AWREADY_M1) 
                    next_state_m1 = WRITE_DATA;
                else
                    next_state_m1 = WRITE_ADDR;
            end
            // WRITE_DATA: begin
            //     if (WVALID_M1 && WREADY_M1) 
            //         next_state_m1 = WRITE_DATA_2;
            //     else
            //         next_state_m1 = WRITE_DATA;
            // end
            WRITE_DATA: begin
                if (WLAST_M1 && WVALID_M1 && WREADY_M1) 
                    next_state_m1 = WRITE_RESP;
                else
                    next_state_m1 = WRITE_DATA;
            end
            WRITE_RESP: begin
                if (BVALID_M1)
                    next_state_m1 = WRITE_RESP_2;
                else
                    next_state_m1 = WRITE_RESP;
            end
            WRITE_RESP_2: begin // Write transaction: use CPU_DM_next_RW_reg
                if (BVALID_M1 && BREADY_M1) begin
                    if (cpu_DM_next_RW_reg == 2'd2) // read: 2, write: 1, idle: 0
                        next_state_m1 = READ_ADDR;
                    else if (cpu_DM_next_RW_reg == 2'd1)
                        next_state_m1 = WRITE_ADDR;
                    else
                        next_state_m1 = IDLE;
                end else
                    next_state_m1 = WRITE_RESP_2;
            end  
            default: next_state_m1 = IDLE;
        endcase
    end

    // // Next state logic
    // always_comb begin 
    //     case (current_state_m1)
    //         IDLE: begin
    //             if (ARVALID_M1 && ARREADY_M1) // Read first (If both read and write valid) 
    //                 next_state_m1 = READ_DATA;
    //             else if (AWVALID_M1 && AWREADY_M1) 
    //                 next_state_m1 = WRITE_DATA;
    //             else if (ARVALID_M1)
    //                 next_state_m1 = READ_ADDR;
    //             else if (AWVALID_M1)
    //                 next_state_m1 = WRITE_ADDR;
    //             else
    //                 next_state_m1 = IDLE;
    //         end
    //         READ_ADDR: begin
    //             if (ARVALID_M1 && ARREADY_M1) 
    //                 next_state_m1 = READ_DATA;
    //             else
    //                 next_state_m1 = READ_ADDR;
    //         end
    //         READ_DATA: begin
    //             if (RLAST_M1 && RVALID_M1 && RREADY_M1) begin
    //                 if (cpu_DM_next_RW == 2'd2) // read: 2, write: 1, idle: 0
    //                     next_state_m1 = READ_ADDR;
    //                 else if (cpu_DM_next_RW == 2'd1)
    //                     next_state_m1 = WRITE_ADDR;
    //                 else
    //                     next_state_m1 = IDLE;
    //             end else
    //                 next_state_m1 = READ_DATA;
    //         end
    //         WRITE_ADDR: begin
    //             if (AWVALID_M1 && AWREADY_M1) 
    //                 next_state_m1 = WRITE_DATA;
    //             else
    //                 next_state_m1 = WRITE_ADDR;
    //         end
    //         WRITE_DATA: begin
    //             if (WLAST_M1 && WVALID_M1 && WREADY_M1) 
    //                 next_state_m1 = WRITE_RESP;
    //             else
    //                 next_state_m1 = WRITE_DATA;
    //         end
    //         WRITE_RESP: begin
    //             if (BVALID_M1 && BREADY_M1) begin
    //                 if (cpu_DM_next_RW == 2'd2) // read: 2, write: 1, idle: 0
    //                     next_state_m1 = READ_ADDR;
    //                 else if (cpu_DM_next_RW == 2'd1)
    //                     next_state_m1 = WRITE_ADDR;
    //                 else
    //                     next_state_m1 = IDLE;
    //             end else
    //                 next_state_m1 = WRITE_RESP;
    //         end  
    //         default: next_state_m1 = IDLE;
    //     endcase
    // end

    // Output logic

    // AR channel
    always_comb begin
        if (current_state_m1 == READ_ADDR) begin
            ARID_M1 = `AXI_ID_BITS'd2; 
            ARADDR_M1 = cpu_DM_A;
            ARLEN_M1 = `AXI_LEN_BITS'b0;
            ARSIZE_M1 = `AXI_SIZE_BITS'b010; // 4 bytes 
            ARBURST_M1 = 2'b01; // INCR
            ARVALID_M1 = 1'b1;
        end else begin
            ARID_M1 = 'b0;
            ARLEN_M1 = 'b0;
            ARSIZE_M1 = 'b0;
            ARBURST_M1 = 2'b00;
            ARVALID_M1 = 1'b0;
        end 
    end

    // R channel
    // always_comb begin
    //     if (current_state_m1 == READ_DATA) begin
    //         RREADY_M1 = 1'b0;
    //         // RDATA_M1 = cpu_DM_DO;
    //     end else begin
    //         RREADY_M1 = 1'b0;
    //         // RDATA_M1 = 'b0;
    //     end
    // end

    // R channel: READ_DATA_2
    always_comb begin
        if (current_state_m1 == READ_DATA_2) 
            RREADY_M1 = 1'b1;
        else
            RREADY_M1 = 1'b0;
    end

    // AW channel
    always_comb begin
        if (current_state_m1 == WRITE_ADDR) begin
            AWID_M1 = `AXI_ID_BITS'd2; 
            AWADDR_M1 = cpu_DM_A;
            AWLEN_M1 = `AXI_LEN_BITS'b0;
            AWSIZE_M1 = `AXI_SIZE_BITS'b010; // 4 bytes
            AWBURST_M1 = 2'b01; // INCR
            AWVALID_M1 = 1'b1;
        end else begin
            AWID_M1 = 'b0;
            AWADDR_M1 = 'b0;
            AWLEN_M1 = 'b0;
            AWSIZE_M1 = 'b0;
            AWBURST_M1 = 2'b00;
            AWVALID_M1 = 1'b0;
        end
    end 

    // always_comb begin
    //     if (current_state_m1 == WRITE_DATA || current_state_m1 == WRITE_ADDR)
    //         WVALID_M1 = 1'b1;
    //     else 
    //         WVALID_M1 = 1'b0;
    // end

    // W channel
    always_comb begin
        if (current_state_m1 == WRITE_DATA) begin
            WDATA_M1 = cpu_DM_DI;
            WSTRB_M1 = ~cpu_DM_BWEB; // active high
            WLAST_M1 = (AWLEN_m1_reg == 0) ? 1'b1 : 1'b0;
            WVALID_M1 = 1'b1;
        end else begin
            WDATA_M1 = 'b0;
            WSTRB_M1 = 'b0;
            WLAST_M1 = 'b0;
            WVALID_M1 = 1'b0;
        end
    end
    // Calculate AWLEN
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (ARESETn == 1'b0) begin
            AWLEN_m1_reg <= 'b0;
        end else if (current_state_m1 == WRITE_ADDR) begin
            AWLEN_m1_reg <= AWLEN_M1; 
        end else if (current_state_m1 == WRITE_DATA) begin
            if (AWLEN_m1_reg > 0)
                AWLEN_m1_reg <= AWLEN_m1_reg - 'b1;
            else
                AWLEN_m1_reg <= 'b0;
        end else 
            AWLEN_m1_reg <= 'b0;
    end

    // B channel: BVLID
    always_comb begin
        if (current_state_m1 == WRITE_RESP_2)
            BREADY_M1 = 1'b1; // BREADY after BVALID
        else
            BREADY_M1 = 1'b0;
    end

endmodule
