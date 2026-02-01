module tag_array_wrapper (
  input CK,
  input CS,
  input OE,
  input [1:0] WEB,
  input [4:0] A,
  input [22:0] DI,
  output logic [45:0] DO
);

logic [31:0] bweb_0, bweb_1;
assign bweb_0 = {32{WEB[0]}};
assign bweb_1 = {32{WEB[1]}};

// input
logic [31:0] DI_temp;
assign DI_temp = {9'b0, DI};

// output 
logic [31:0] DO_temp1, DO_temp2; 
assign DO = {DO_temp2[22:0], DO_temp1[22:0]};

  TS1N16ADFPCLLLVTA128X64M4SWSHOD_tag_array i_tag_array1 (
    .CLK        (CK),
    .A          (A),
    .CEB        (~CS),  // chip enable, active LOW
    .WEB        (WEB[0]),  // write:LOW, read:HIGH
    .BWEB       (bweb_0),  // bitwise write enable write:LOW
    .D          (DI_temp),  // Data into RAM
    .Q          (DO_temp1),  // Data out of RAM
    .RTSEL      (2'b01),
    .WTSEL      (2'b01),
    .SLP        (1'b0),
    .DSLP       (1'b0),
    .SD         (1'b0),
    .PUDELAY    ()
  );

  TS1N16ADFPCLLLVTA128X64M4SWSHOD_tag_array i_tag_array2 (
    .CLK        (CK),
    .A          (A),
    .CEB        (~CS),  // chip enable, active LOW
    .WEB        (WEB[1]),  // write:LOW, read:HIGH
    .BWEB       (bweb_1),  // bitwise write enable write:LOW
    .D          (DI_temp),  // Data into RAM
    .Q          (DO_temp2),  // Data out of RAM
    .RTSEL      (2'b01),
    .WTSEL      (2'b01),
    .SLP        (1'b0),
    .DSLP       (1'b0),
    .SD         (1'b0),
    .PUDELAY    ()
  );

endmodule
