module AXI_Arbiter(
    input  logic        ACLK,        // Clock signal
    input  logic        ARESETn,     // Active-low reset
    input  logic        req_m0,      // Request from Master 0
    input  logic        req_m1,      // Request from Master 1
    input  logic        req_RW_m1,   // Request from Master 1 read(1), write(0)
    input  logic        end_m0,      // End of transmission from Master 0
    input  logic        end_m1_R,      // End of transmission from Master 1
    input  logic        end_m1_W,
    input  logic        another_s_doing,
    output logic        this_s_doing,
    output logic        grant_m0,    // Grant to Master 0
    output logic        grant_m1,     // Grant to Master 1
    output logic        grant_RW_m1  // Grant to Master 1 read(1), write(0)
);

    // State encoding for round-robin
    typedef enum logic [1:0] {
        IDLE = 2'b00,     // Idle state
        M0_TURN = 2'b01,  // Grant Master 0
        M1_TURN_R = 2'b10,   // Grant Master 1 read
        M1_TURN_W = 2'b11   // Grant Master 1 write
        } arbiter_state_t;

    arbiter_state_t current_state, next_state;

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
                if (req_m0)
                    next_state = M0_TURN;
                else if (req_m1 && !(another_s_doing)) begin
                    if (req_RW_m1)
                        next_state = M1_TURN_R;
                    else
                        next_state = M1_TURN_W;
                end else 
                    next_state = IDLE; // Grant M0 if M0 requests, M1 if M1 requests, or stay idle
            end
            M0_TURN: begin
                if (end_m0) begin 
                    if (req_m1 && !(another_s_doing)) begin
                        if (req_RW_m1)
                            next_state = M1_TURN_R;
                        else
                            next_state = M1_TURN_W;
                    end else 
                        next_state = IDLE;
                end else 
                    next_state = M0_TURN; // Stay on Master 0 if still transmitting
            end
            M1_TURN_R: begin
                if (end_m1_R) begin 
                    if (req_m0)
                        next_state = M0_TURN; // Switch to Master 1 if M0 transmission ends
                    else 
                        next_state = IDLE;
                end else 
                    next_state = M1_TURN_R; // Stay on Master 0 if still transmitting
            end
            M1_TURN_W: begin
                if (end_m1_W) begin 
                    if (req_m0)
                        next_state = M0_TURN; // Switch to Master 1 if M0 transmission ends
                    else 
                        next_state = IDLE;
                end else 
                    next_state = M1_TURN_W; // Stay on Master 0 if still transmitting
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
            end
            M0_TURN: begin
                grant_m0 = 1'b1;
                grant_m1 = 1'b0;
            end
            M1_TURN_R,
            M1_TURN_W: begin
                grant_m0 = 1'b0;
                grant_m1 = 1'b1;
            end
        endcase
    end   

    // M1 read / write sel FIXME: check AXI.sv grant
    always_comb begin
        case (current_state) 
            M1_TURN_R: grant_RW_m1 = 1'b1; // M1 read
            M1_TURN_W: grant_RW_m1 = 1'b0; // M1 write
        endcase
    end

    always_comb begin
        case (current_state) 
            M1_TURN_R: this_s_doing = 1'b1; // M1 read
            M1_TURN_W: this_s_doing = 1'b1; // M1 write
	    default:   this_s_doing = 1'b0;
        endcase
    end


    // always_comb begin
    //     case (current_state)
    //         IDLE: begin
    //             grant_m0 = 1'b0;
    //             grant_m1 = 1'b0;
    //         end
    //         M0_TURN: begin
    //             if (end_m0) grant_m0 = 1'b0; // grant_m0 = !end_m0;
    //             else        grant_m0 = 1'b1;   
    //             grant_m1 = 1'b0;
    //         end
    //         M1_TURN: begin
    //             grant_m0 = 1'b0;
    //             if (end_m1) grant_m1 = 1'b0; // end
    //             else        grant_m1 = 1'b1; // orgin
    //         end
    //     endcase
    // end

    // Next state logic based on requests and current state
    // always_comb begin
    //     // Default grant signals
    //     grant_m0 = 1'b0;
    //     grant_m1 = 1'b0;
        
    //     case (current_state)
    //         M0_TURN: begin
    //             if (req_m0) begin
    //                 grant_m0 = 1'b1; // Grant Master 0
    //                 next_state = M1_TURN; // Switch to Master 1 next
    //             end else if (req_m1) begin
    //                 grant_m1 = 1'b1; // Grant Master 1 if M0 didn't request
    //                 next_state = M0_TURN;
    //             end else begin
    //                 next_state = M0_TURN; // Stay with Master 0 if no requests
    //             end
    //         end
    //         M1_TURN: begin
    //             if (req_m1) begin
    //                 grant_m1 = 1'b1; // Grant Master 1
    //                 next_state = M0_TURN; // Switch to Master 0 next
    //             end else if (req_m0) begin
    //                 grant_m0 = 1'b1; // Grant Master 0 if M1 didn't request
    //                 next_state = M1_TURN;
    //             end else begin
    //                 next_state = M1_TURN; // Stay with Master 1 if no requests
    //             end
    //         end
    //         default: next_state = M0_TURN;
    //     endcase
    // end

endmodule
