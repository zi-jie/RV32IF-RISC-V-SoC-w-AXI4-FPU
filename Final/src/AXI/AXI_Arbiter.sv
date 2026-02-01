module AXI_Arbiter(
    input  logic        ACLK,        // Clock signal
    input  logic        ARESETn,     // Active-low reset
    input  logic        req_m0,      // Request from Master 0
    input  logic        req_m1,      // Request from Master 1
    input  logic        req_m2,      // Request from Master 2 (DMA)
    input  logic        req_RW_m1,   // Request from Master 1 read(1), write(0)
    input  logic        req_RW_m2,   // Request from Master 2 read(1), write(0)
    input  logic        end_m0,      // End of transmission from Master 0
    input  logic        end_m1_R,      // End of transmission from Master 1
    input  logic        end_m1_W,
    input  logic        end_m2_R,      // End of transmission from Master 2
    input  logic        end_m2_W,
    input  logic        other_s_m1_doing, // other slave-m1 transacting, then this slave m1 cant do
    // input  logic        other_s_m2_doing, // other slave-DMA transacting, then this slave m2 cant do
    input  logic        other_cpu_doing, // cpu do, DMA dont do
    input  logic        other_dma_doing, // DMA do, cpu dont do
    output logic        this_s_m1_doing,
    // output logic        this_s_m2_doing, // same with dma_doing
    output logic        cpu_doing,   // master 0, 1 doing
    output logic        dma_doing,   // master 2 doing
    output logic        grant_m0,    // Grant to Master 0
    output logic        grant_m1,     // Grant to Master 1
    output logic        grant_m2,
    output logic        grant_RW_m1,  // Grant to Master 1 read(1), write(0)
    output logic        grant_RW_m2   // Grant to Master 2 read(1), write(0)
);

    // State encoding for round-robin
    typedef enum logic [2:0] {
        IDLE       = 3'b000,  // Idle state
        M0_TURN    = 3'b001,  // Grant Master 0
        M1_TURN_R  = 3'b010,  // Grant Master 1 read
        M1_TURN_W  = 3'b011,  // Grant Master 1 write
        M2_TURN_R = 3'b100,  // Grant Master 2 read
        M2_TURN_W = 3'b101   // Grant Master 2 write
    } arbiter_state_t;

    arbiter_state_t current_state, next_state;

    logic m0_req_valid, m1_req_valid; // CPU request valid (DMA not doing), (m1: M1 not doing)
    logic m2_req_valid;               // DMA request valid (cpu not doing and DMA not doing)
    assign m0_req_valid = req_m0 & ~other_dma_doing;
    assign m1_req_valid = req_m1 & ~other_s_m1_doing & ~other_dma_doing;
    assign m2_req_valid = req_m2 & ~other_dma_doing & ~other_cpu_doing;

    // State transition based on round-robin scheme
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Next state logic based on requests and current state
    always_comb begin        
        case (current_state)
            IDLE: begin
                if (m0_req_valid)
                    next_state = M0_TURN;
                else if (m1_req_valid) begin
                    if (req_RW_m1)
                        next_state = M1_TURN_R;
                    else
                        next_state = M1_TURN_W;
                end else if (m2_req_valid) begin
                    if (req_RW_m2)
                        next_state = M2_TURN_R;
                    else
                        next_state = M2_TURN_W;
                end else 
                    next_state = IDLE; // Grant M0 if M0 requests, M1 if M1 requests, or stay idle
            end
            M0_TURN: begin
                if (end_m0) begin 
                    if (m1_req_valid) begin
                        if (req_RW_m1)
                            next_state = M1_TURN_R;
                        else
                            next_state = M1_TURN_W;
                    end else if (m2_req_valid) begin
                        if (req_RW_m2)
                            next_state = M2_TURN_R;
                        else
                            next_state = M2_TURN_W;
                    end else
                        next_state = IDLE;
                end else 
                    next_state = M0_TURN; // Stay on Master 0 if still transmitting
            end
            M1_TURN_R: begin
                if (end_m1_R) begin 
                    if (m2_req_valid) begin
                        if (req_RW_m2)
                            next_state = M2_TURN_R;
                        else
                            next_state = M2_TURN_W;
                    end else if (m0_req_valid)
                        next_state = M0_TURN; // Switch to Master 0 if M0 requests
                    else 
                        next_state = IDLE;
                end else 
                    next_state = M1_TURN_R; // Stay on Master 0 if still transmitting
            end
            M1_TURN_W: begin
                if (end_m1_W) begin 
                    if (m2_req_valid) begin
                        if (req_RW_m2)
                            next_state = M2_TURN_R;
                        else
                            next_state = M2_TURN_W;
                    end else if (m0_req_valid)
                        next_state = M0_TURN; // Switch to Master 0 if M0 requests
                    else 
                        next_state = IDLE;
                end else 
                    next_state = M1_TURN_W; // Stay on Master 0 if still transmitting
            end
            M2_TURN_R: begin
                if (end_m2_R) begin 
                    if (m0_req_valid)
                        next_state = M0_TURN; // Switch to Master 0 if M0 requests
                    else if (m1_req_valid) begin
                        if (req_RW_m1)
                            next_state = M1_TURN_R;
                        else
                            next_state = M1_TURN_W;
                    end else 
                        next_state = IDLE;
                end else 
                    next_state = M2_TURN_R; // Stay on Master 0 if still transmitting
            end
            M2_TURN_W: begin
                if (end_m2_W) begin 
                    if (m0_req_valid)
                        next_state = M0_TURN; // Switch to Master 0 if M0 requests
                    else if (m1_req_valid) begin
                        if (req_RW_m1)
                            next_state = M1_TURN_R;
                        else
                            next_state = M1_TURN_W;
                    end else 
                        next_state = IDLE;
                end else 
                    next_state = M2_TURN_W; // Stay on Master 0 if still transmitting
            end
            default: next_state = IDLE;
        endcase
    end

    // Output logic
    always_comb begin
        case (current_state) 
            IDLE: begin
                grant_m0 = 1'b0;
                grant_m1 = 1'b0;
                grant_m2 = 1'b0;
            end
            M0_TURN: begin
                grant_m0 = 1'b1;
                grant_m1 = 1'b0;
                grant_m2 = 1'b0;
            end
            M1_TURN_R,
            M1_TURN_W: begin
                grant_m0 = 1'b0;
                grant_m1 = 1'b1;
                grant_m2 = 1'b0;
            end
            M2_TURN_R,
            M2_TURN_W: begin
                grant_m0 = 1'b0;
                grant_m1 = 1'b0;
                grant_m2 = 1'b1;
            end
            default: begin
                grant_m0 = 1'b0;
                grant_m1 = 1'b0;
                grant_m2 = 1'b0;
            end
        endcase
    end   

    // M1 read / write sel FIXME: check AXI.sv grant
    always_comb begin
        case (current_state) 
            M1_TURN_R: grant_RW_m1 = 1'b1; // M1 read
            M1_TURN_W: grant_RW_m1 = 1'b0; // M1 write
            default: grant_RW_m1 = 1'b0;
        endcase
    end

    // M2 read / write sel
    always_comb begin
        case (current_state) 
            M2_TURN_R: grant_RW_m2 = 1'b1; // M2 read
            M2_TURN_W: grant_RW_m2 = 1'b0; // M2 write
            default: grant_RW_m2 = 1'b0;
        endcase
    end

    // M1 doing, other slave can't do
    always_comb begin
        case (current_state) 
            M1_TURN_R: this_s_m1_doing = 1'b1; // M1 read
            M1_TURN_W: this_s_m1_doing = 1'b1; // M1 write
	        default:   this_s_m1_doing = 1'b0;
        endcase
    end

    // M2 doing, other slave can't do
    // always_comb begin
    //     case (current_state)
    //         M2_TURN_R: this_s_m2_doing = 1'b1; // M2 read
    //         M2_TURN_W: this_s_m2_doing = 1'b1; // M2 write
    //         default:    this_s_m2_doing = 1'b0;
    //     endcase
    // end

    // CPU (M0, M1) do then DMA (M2) dont do 
    always_comb begin
        case (current_state) 
            M0_TURN,
            M1_TURN_R, 
            M1_TURN_W: cpu_doing = 1'b1; 
	        default:   cpu_doing = 1'b0;
        endcase
    end

    // DMA (M2) do then CPU (M0, M1) dont do
    always_comb begin
        case (current_state) 
            M2_TURN_R, 
            M2_TURN_W: dma_doing = 1'b1; 
            default:   dma_doing = 1'b0;
        endcase
    end

endmodule
