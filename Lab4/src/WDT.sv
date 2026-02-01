module WDT (
    input  logic        WDEN_clk2,    
    input  logic        WDLIVE_clk2,  
    input  logic [31:0] WTOCNT_clk2,  
    input  logic        clk,
    input  logic        rst,
    input  logic        clk2,
    input  logic        rst2,
    output logic        WTO      // Watchdog Timeout Output, in clk domain
);

    logic WTO_clk2, WTO_stage1;
    logic [31:0] counter_clk2;

    // Sequential logic for counter_clk2
    always_ff @(posedge clk2 or posedge rst2) begin
        if (rst2) begin
            // Reset condition
            counter_clk2 <= 32'h0;
            WTO_clk2 <= 1'b0;
        end else begin
            if (WDEN_clk2) begin  // Timer enabled
                if (WDLIVE_clk2) begin
                    // Restart condition
                    counter_clk2 <= 32'h0;
                    WTO_clk2 <= 1'b0;
                end else begin
                    // Normal counting operation
                    if (counter_clk2 > WTOCNT_clk2) begin
                        // Timeout condition
                        WTO_clk2 <= 1'b1;
                        counter_clk2 <= counter_clk2;  // Stop counting
                    end
                    else begin
                        counter_clk2 <= counter_clk2 + 1;
                        WTO_clk2 <= 1'b0;
                    end
                end
            end else begin
                // Timer disabled
                counter_clk2 <= 32'h0;
                WTO_clk2 <= 1'b0;
            end
        end
    end

    // WTO_clk2 to clk domain
    always_ff @(posedge clk or posedge rst) begin
        if (rst)  {WTO, WTO_stage1} <= 0;
        else      {WTO, WTO_stage1} <= {WTO_stage1, WTO_clk2};
    end

endmodule