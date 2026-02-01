module AXI_Decoder(
    input  logic [`AXI_ADDR_BITS/2-1:0] address_high, // high 16 bits
    output logic [1:0]                  slave_select,
    output logic                        default_slave
);

    // Address high bits for each slave
    localparam logic [`AXI_ADDR_BITS/2-1:0] SLAVE0_HIGH = 'h0000;
    localparam logic [`AXI_ADDR_BITS/2-1:0] SLAVE1_HIGH = 'h0001;

    // Decode logic
    always_comb begin
        default_slave = 0;
        case (address_high)
            SLAVE0_HIGH: begin
                slave_select = 2'b01; // Select Slave 0
            end
            SLAVE1_HIGH: begin
                slave_select = 2'b10; // Select Slave 1
            end
            default: begin
                slave_select = 2'b00; // No valid slave selected
                default_slave = 1;    // Indicate this is for the default slave
            end
        endcase
    end

endmodule
