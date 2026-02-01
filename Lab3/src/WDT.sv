`include "../src/aFIFO/aFIFO.sv"

module WDT (
    input  logic        WDEN,    // Watchdog Enable, in clk domain
    input  logic        WDLIVE,   // Watchdog Reset, in clk domain
    input  logic [31:0] WTOCNT,  // Watchdog Timeout Count, in clk domain
    input  logic        clk,
    input  logic        rst,
    input  logic        clk2,
    input  logic        rst2,
    output logic        WTO      // Watchdog Timeout Output, in clk domain
);

    // FIFO signals for crossing clock domains
    logic fifo_wpush;
    logic fifo_rpop;
    logic [31:0] fifo_wdata;
    logic [31:0] fifo_rdata;
    logic fifo_wfull;
    logic fifo_rempty;
    logic [31:0] prev_WTOCNT;

    // clk2 domain signals
    logic [31:0] counter_clk2;
    logic WTO_clk2;
    logic WTO_stage1;
    logic WDEN_clk2;
    logic WDEN_stage1;
    logic WDLIVE_clk2;
    logic WDLIVE_stage1;
    logic [31:0] WTOCNT_clk2;

    logic WDEN_reg;
    logic WDen_clk1_1FF, WDen_clk1_2FF;
    logic WDen_clk2_1FF, WDen_clk2_2FF;
    logic WDLIVE_reg;
    logic WDlive_clk1_1FF, WDlive_clk1_2FF;
    logic WDlive_clk2_1FF, WDlive_clk2_2FF;

    // 2-stage synchronizer for WDEN and WDLIVE
    // always_ff @(posedge clk2 or posedge rst2) begin
    //     if (rst2) begin
    //         WDEN_clk2 <= 1'b0;
    //         WDLIVE_clk2 <= 1'b0;
    //         WDEN_stage1 <= 1'b0;
    //         WDLIVE_stage1 <= 1'b0;
    //     end else begin
    //         {WDEN_clk2, WDEN_stage1} <= {WDEN_stage1, WDEN};
    //         {WDLIVE_clk2, WDLIVE_stage1} <= {WDLIVE_stage1, WDLIVE};
    //     end
    // end
    // always_ff @(posedge clk2 or posedge rst2) begin
    //     if (rst2) begin
    //         WDEN_clk2 <= 1'b0;
    //         WDEN_stage1 <= 1'b0;
    //     end
    //     else begin
    //         {WDEN_clk2, WDEN_stage1} <= {WDEN_stage1, WDEN};
    //     end
    // end
    // WDEN --> WDEN_clk2
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            WDEN_reg <= 1'b0;
        end
        else if (WDEN_reg == WDen_clk1_2FF) begin
            WDEN_reg <= WDEN;
        end
        else begin
            WDEN_reg <= WDEN_reg;
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            WDen_clk1_1FF <= 1'b0;
            WDen_clk1_2FF <= 1'b0;
        end
        else begin
            WDen_clk1_1FF <= WDen_clk2_2FF;
            WDen_clk1_2FF <= WDen_clk1_1FF;
        end
    end

    always_ff @(posedge clk2 or posedge rst2) begin
        if (rst2) begin
            WDen_clk2_1FF <= 1'b0;
            WDen_clk2_2FF <= 1'b0;
        end
        else begin
            WDen_clk2_1FF <= WDEN_reg;
            WDen_clk2_2FF <= WDen_clk2_1FF;
        end
    end

    assign WDEN_clk2 = WDen_clk2_2FF;

    // WDLIVE --> WDLIVE_clk2
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            WDLIVE_reg <= 1'b0;
        end
        else if (WDLIVE_reg == WDlive_clk1_2FF) begin
            WDLIVE_reg <= WDLIVE;
        end
        else begin
            WDLIVE_reg <= WDLIVE_reg;
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            WDlive_clk1_1FF <= 1'b0;
            WDlive_clk1_2FF <= 1'b0;
        end
        else begin
            WDlive_clk1_1FF <= WDlive_clk2_2FF;
            WDlive_clk1_2FF <= WDlive_clk1_1FF;
        end
    end

    always_ff @(posedge clk2 or posedge rst2) begin
        if (rst2) begin
            WDlive_clk2_1FF <= 1'b0;
            WDlive_clk2_2FF <= 1'b0;
        end
        else begin
            WDlive_clk2_1FF <= WDLIVE_reg;
            WDlive_clk2_2FF <= WDlive_clk2_1FF;
        end
    end

    assign WDLIVE_clk2 = WDlive_clk2_2FF;

    //FIXME: if inst set WTOCNT, then WDEN
    // aFIFO for WTOCNT
    assign fifo_wpush = |WTOCNT && !fifo_wfull && (prev_WTOCNT != WTOCNT); // don't sent same data 
    assign fifo_wdata = WTOCNT;
    assign fifo_rpop = !fifo_rempty;  // Pop FIFO if not empty
    // assign WTOCNT_clk2 = fifo_rpop ? fifo_rdata : 32'd0;  // Counter value is FIFO read data
    always_ff @(posedge clk2 or posedge rst2) begin
        if (rst2) begin
            WTOCNT_clk2 <= 32'h0;
        end else begin
            if (fifo_rpop)
                WTOCNT_clk2 <= fifo_rdata;
            else 
                WTOCNT_clk2 <= WTOCNT_clk2; 
        end
    end

    // for 1 cycle later WTOCNT
    always_ff @(posedge clk or posedge rst) begin
        if (rst) 
            prev_WTOCNT <= 32'd0;
        else 
            prev_WTOCNT <= WTOCNT;
    end

    // FIFO module instantiation
    aFIFO afifo1 (
        .wclk(clk),         // Write clock domain (clk)
        .rclk(clk2),        // Read clock domain (clk2)
        .wrst(rst),         // Reset for clk domain
        .rrst(rst2),        // Reset for clk2 domain
        .wdata(fifo_wdata), // FIFO write data
        .rdata(fifo_rdata), // FIFO read data
        .wpush(fifo_wpush), // FIFO write push signal
        .rpop(fifo_rpop),   // FIFO read pop signal
        .wfull(fifo_wfull), // FIFO full flag
        .rempty(fifo_rempty)// FIFO empty flag
    );

    // // FIFO signals for crossing clock domains
    // logic fifo_wpush_WDLIVE;
    // logic fifo_rpop_WDLIVE;
    // logic [31:0] fifo_wdata_WDLIVE;
    // logic [31:0] fifo_rdata_WDLIVE;
    // logic fifo_wfull_WDLIVE;
    // logic fifo_rempty_WDLIVE;

    // // aFIFO for WTOCNT
    // assign fifo_wpush = |WTOCNT && !fifo_wfull; 
    // assign fifo_wdata = WTOCNT;
    // assign fifo_rpop = !fifo_rempty;  // Pop FIFO if not empty
    // // assign WTOCNT_clk2 = fifo_rpop ? fifo_rdata : 32'd0;  // Counter value is FIFO read data
    // always_ff @(posedge clk2 or posedge rst2) begin
    //     if (rst2) begin
    //         WTOCNT_clk2 <= 32'h0;
    //     end else begin
    //         if (fifo_rpop)
    //             WTOCNT_clk2 <= fifo_rdata;
    //         else 
    //             WTOCNT_clk2 <= WTOCNT_clk2; 
    //     end
    // end

    // // aFIFO for WDLIVE
    // // FIFO module instantiation
    // aFIFO afifo_WDLIVE (
    //     .wclk(clk),         // Write clock domain (clk)
    //     .rclk(clk2),        // Read clock domain (clk2)
    //     .wrst(rst),         // Reset for clk domain
    //     .rrst(rst2),        // Reset for clk2 domain
    //     .wdata(fifo_wdata_WDLIVE), // FIFO write data
    //     .rdata(fifo_rdata_WDLIVE), // FIFO read data
    //     .wpush(fifo_wpush_WDLIVE), // FIFO write push signal
    //     .rpop(fifo_rpop_WDLIVE),   // FIFO read pop signal
    //     .wfull(fifo_wfull_WDLIVE), // FIFO full flag
    //     .rempty(fifo_rempty_WDLIVE)// FIFO empty flag
    // );  

    // // signal for WDEN
    // logic fifo_wpush_WDEN;
    // logic fifo_rpop_WDEN;
    // logic [31:0] fifo_wdata_WDEN;
    // logic [31:0] fifo_rdata_WDEN;
    // logic fifo_wfull_WDEN;
    // logic fifo_rempty_WDEN;

    // // aFIFO for WDEN
    // // FIFO module instantiation
    // aFIFO afifo_WDEN (
    //     .wclk(clk),         // Write clock domain (clk)
    //     .rclk(clk2),        // Read clock domain (clk2)
    //     .wrst(rst),         // Reset for clk domain
    //     .rrst(rst2),        // Reset for clk2 domain
    //     .wdata(fifo_wdata_WDEN), // FIFO write data
    //     .rdata(fifo_rdata_WDEN), // FIFO read data
    //     .wpush(fifo_wpush_WDEN), // FIFO write push signal
    //     .rpop(fifo_rpop_WDEN),   // FIFO read pop signal
    //     .wfull(fifo_wfull_WDEN), // FIFO full flag
    //     .rempty(fifo_rempty_WDEN)// FIFO empty flag
    // );


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
