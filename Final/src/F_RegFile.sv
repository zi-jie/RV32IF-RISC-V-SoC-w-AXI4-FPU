module F_RegFile (
    input logic clk,
    input logic wb_en, // Write-back enable
    input logic [31:0] wb_data, // Data to write back
    input logic [4:0] rd_index, // Index of the destination register
    input logic [4:0] rs1_index, // Index of the source register 1
    input logic [4:0] rs2_index, // Index of the source register 2
    output logic [31:0] rs1_data_out, // Data from source register 1
    output logic [31:0] rs2_data_out  // Data from source register 2
);

    // Register array 32x32
    logic [31:0] registers [0:31];

    // Write-back operation
    always_ff @(posedge clk) begin
        // if (wb_en && (rd_index != 5'd0)) begin  // Check if rd is not x0
        if (wb_en) begin  // Check if rd is not x0
            if (rd_index == 5'd0)
                registers[rd_index] <= 32'b0;
            else
                registers[rd_index] <= wb_data;
            // registers[rd_index] <= wb_data;
        end
    end

    // Read data from source registers
    // assign rs1_data_out = registers[rs1_index];
    // assign rs2_data_out = registers[rs2_index];
    always_comb begin
        if (rs1_index == 5'd0) 
            rs1_data_out = 32'b0;
        else 
            rs1_data_out = registers[rs1_index];

        if (rs2_index == 5'd0)
            rs2_data_out = 32'b0;
        else
            rs2_data_out = registers[rs2_index];
    end


    // always_ff @(posedge clk) begin
    //     if (wb_en && rd_index != 5'd0) begin  // Check if rd is not x0
    //         registers[rd_index] <= wb_data;
    //     end
        // if (rst) begin
        //     registers[0] <= 32'b0; // Reset x0 to 0 when reset is active
        // end
        // else if (wb_en && rd_index != 5'd0) begin  // Check if rd is not x0
        //     registers[rd_index] <= wb_data;
        // end


endmodule
