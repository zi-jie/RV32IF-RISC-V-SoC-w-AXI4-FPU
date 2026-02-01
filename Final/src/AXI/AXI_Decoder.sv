module AXI_Decoder(
    input  logic [31:0] address,        // Need full 32-bit address
    output logic [2:0]  slave_select,   // 3 bits for 6 slaves
    output logic        default_slave
);

    // Split address into high and low parts
    wire [15:0] addr_high = address[31:16];
    wire [15:0] addr_low  = address[15:0];

    // Define address ranges
    localparam logic [15:0] ROM_HIGH   = 16'h0000;
    localparam logic [15:0] IM_HIGH    = 16'h0001;
    localparam logic [15:0] DM_HIGH    = 16'h0002;
    localparam logic [15:0] DMA_HIGH   = 16'h1002;
    localparam logic [15:0] WDT_HIGH   = 16'h1001;
    localparam logic [15:0] DRAM_HIGH  = 16'h2000;
    localparam logic [15:0] DRAM_HIGH_END   = 16'h201F;
    localparam logic [15:0] DLA_CONFIG_HIGH   = 16'h6000; // config_w_en: 0x6000_0000 - 0x6000_0008
    localparam logic [15:0] DLA_DATA_HIGH     = 16'h6010; // ifm0, ifm1, weight w_en
    localparam logic [15:0] DLA_DATA_HIGH_END = 16'h6040; // 0x1804_0000 - 0x180C_3FFF

    // Definev low end addresses
    localparam logic [15:0] DMA_END    = 16'h0400;  // DMA ends at 0x400
    localparam logic [15:0] WDT_END    = 16'h03FF;  // WDT ends at 0x3FF
    localparam logic [15:0] DLA_END    = 16'h3FFF;  // 0x1804_0000 - 0x180C_3FFF

    //FIXME: DLA address range 

    // Decode logic
    always_comb begin
        // Default assignments
        slave_select = 3'b000;
        default_slave = 1'b0;

        case (addr_high)
            ROM_HIGH: begin
                // ROM: 0x0000_0000 ~ 0x0000_1FFF
                if (addr_low <= 16'h1FFF) begin
                    slave_select = 3'b000;
                end else begin
                    default_slave = 1'b1;
                end
            end           
            IM_HIGH: begin
                // IM: 0x0001_0000 ~ 0x0001_FFFF
                slave_select = 3'b001;
            end
            DM_HIGH: begin
                // DM: 0x0002_0000 ~ 0x0002_FFFF
                slave_select = 3'b010;
            end
            DMA_HIGH: begin
                // DMA: 0x1002_0000 ~ 0x1002_0400
                if (addr_low <= DMA_END) begin
                    slave_select = 3'b011;
                end else begin
                    default_slave = 1'b1;
                end
            end
            WDT_HIGH: begin
                // WDT: 0x1001_0000 ~ 0x1001_03FF
                if (addr_low <= WDT_END) begin
                    slave_select = 3'b100;
                end else begin
                    default_slave = 1'b1;
                end
            end
            DLA_CONFIG_HIGH: begin
                // DLA_CONFIG: 0x6000_0000 ~ 0x6000_0008
                if (addr_low <= 16'h0008) 
                    slave_select = 3'b110; // DLA
            end
            default: begin
                // 0x1804_0000 - 0x180C_3FFF
                if (addr_high >= DLA_DATA_HIGH && addr_high <= DLA_DATA_HIGH_END) begin
                    //if (addr_low <= DLA_END)
                    //if (addr_low <= DLA_END)
                        slave_select = 3'b110; // DLA
                end else if (addr_high >= DRAM_HIGH && addr_high <= DRAM_HIGH_END) begin
                    slave_select = 3'b101;
                end else begin 
                    // slave_select = 3'b111;
                    default_slave = 1'b1;
                end
            end
        endcase
    end

endmodule