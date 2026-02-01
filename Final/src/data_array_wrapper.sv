module data_array_wrapper (
  input CK,
  input CS, 
  input OE,
  input [15:0] WEB,
  input [4:0] A,
  input [31:0] DI,
  input active_way, // for write
  input [1:0] active_block, // for write
  input [1:0] read_block, // for read
  output logic [63:0] DO
);

// write enable
logic web0, web1, web2, web3;
assign web0 = (WEB[3:0] == 4'b1111);
assign web1 = (WEB[7:4] == 4'b1111);
assign web2 = (WEB[11:8] == 4'b1111);
assign web3 = (WEB[15:12] == 4'b1111);

// bit write enable
logic [31:0] bweb0, bweb1, bweb2, bweb3;
assign bweb0 = {{8{WEB[3]}}, {8{WEB[2]}}, {8{WEB[1]}}, {8{WEB[0]}}};
assign bweb1 = {{8{WEB[7]}}, {8{WEB[6]}}, {8{WEB[5]}}, {8{WEB[4]}}};
assign bweb2 = {{8{WEB[11]}}, {8{WEB[10]}}, {8{WEB[9]}}, {8{WEB[8]}}};
assign bweb3 = {{8{WEB[15]}}, {8{WEB[14]}}, {8{WEB[13]}}, {8{WEB[12]}}};

logic [63:0] bweb0_64, bweb1_64, bweb2_64, bweb3_64;
assign bweb0_64 = (active_way == 1'b1)? 
                  {bweb0, {32{1'b1}}}: {{32{1'b1}}, bweb0};
assign bweb1_64 = (active_way == 1'b1)? 
                  {bweb1, {32{1'b1}}}: {{32{1'b1}}, bweb1};                 
assign bweb2_64 = (active_way == 1'b1)? 
                  {bweb2, {32{1'b1}}}: {{32{1'b1}}, bweb2};
assign bweb3_64 = (active_way == 1'b1)? 
                  {bweb3, {32{1'b1}}}: {{32{1'b1}}, bweb3};

// data input
logic [63:0] di64;
assign di64 = (active_way == 1'b1)? {DI, 32'b0}: {32'b0, DI};

// data output
logic [63:0] do0, do1, do2, do3;
always_comb begin
  case(read_block)
    2'b00: DO = do0;
    2'b01: DO = do1;
    2'b10: DO = do2;
    2'b11: DO = do3;
  endcase
end

// 0
  TS1N16ADFPCLLLVTA128X64M4SWSHOD_data_array i_data_array1_1 (
    .CLK        (CK),
    .A          (A),
    .CEB        (~CS),  // chip enable, active LOW
    .WEB        (web0),  // 1bit, write:LOW, read:HIGH
    .BWEB       (bweb0_64),  // 64bits, bitwise write enable write:LOW
    .D          (di64),  // Data into RAM
    .Q          (do0),  // Data out of RAM
    .RTSEL      (2'b01),
    .WTSEL      (2'b01),
    .SLP        (1'b0),
    .DSLP       (1'b0),
    .SD         (1'b0),
    .PUDELAY    ()
  );
  
// 1  
  TS1N16ADFPCLLLVTA128X64M4SWSHOD_data_array i_data_array1_2 (
    .CLK        (CK),
    .A          (A),
    .CEB        (~CS),  // chip enable, active LOW
    .WEB        (web1),  // write:LOW, read:HIGH
    .BWEB       (bweb1_64),  // bitwise write enable write:LOW
    .D          (di64),  // Data into RAM
    .Q          (do1),  // Data out of RAM
    .RTSEL      (2'b01),
    .WTSEL      (2'b01),
    .SLP        (1'b0),
    .DSLP       (1'b0),
    .SD         (1'b0),
    .PUDELAY    ()
  );

// 2
  TS1N16ADFPCLLLVTA128X64M4SWSHOD_data_array i_data_array2_1 (
    .CLK        (CK),
    .A          (A),
    .CEB        (~CS),  // chip enable, active LOW
    .WEB        (web2),  // write:LOW, read:HIGH
    .BWEB       (bweb2_64),  // bitwise write enable write:LOW
    .D          (di64),  // Data into RAM
    .Q          (do2),  // Data out of RAM
    .RTSEL      (2'b01),
    .WTSEL      (2'b01),
    .SLP        (1'b0),
    .DSLP       (1'b0),
    .SD         (1'b0),
    .PUDELAY    ()
  );

// 3 
  TS1N16ADFPCLLLVTA128X64M4SWSHOD_data_array i_data_array2_2 (
    .CLK        (CK),
    .A          (A),
    .CEB        (~CS),  // chip enable, active LOW
    .WEB        (web3),  // write:LOW, read:HIGH
    .BWEB       (bweb3_64),  // bitwise write enable write:LOW
    .D          (di64),  // Data into RAM
    .Q          (do3),  // Data out of RAM
    .RTSEL      (2'b01),
    .WTSEL      (2'b01),
    .SLP        (1'b0),
    .DSLP       (1'b0),
    .SD         (1'b0),
    .PUDELAY    ()
  );

endmodule
