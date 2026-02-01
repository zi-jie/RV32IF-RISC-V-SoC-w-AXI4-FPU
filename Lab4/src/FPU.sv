module FPU(FA, FB, op, FS);
    input op; // 1:ADD, 0:SUB
    input [31:0] FA, FB;
    output logic [31:0] FS;

    logic [31:0] FB_M;
    logic FA_S, FB_S, FS_S;
    logic [7:0] FA_E, FB_E, FS_E;
    logic [22:0] FA_F, FB_F, FS_F;
    logic [25:0] FB_F_sh;
    logic [25:0] FA_F_ext, FB_F_ext;
    logic [25:0] FA_F_com, FB_F_com;
    logic [25:0] FS_F_cal, FS_F_com;
    logic [4:0] FS_shift_num;
    logic [7:0] Ex_diff;
    logic valid, zero;

    //merge the operation code and FB
    assign FB_M = {!op^FB[31], FB[30:0]};
    //the inputs will be positive or negative
    //switch the value of two input, make FA_E greater than FB_E
    assign {FA_S, FA_E, FA_F} = (FA[30:23] > FB[30:23])?FA : FB_M;
    assign {FB_S, FB_E, FB_F} = (FA[30:23] > FB[30:23])?FB_M : FA;

    //extend fraction with sign bit, carry bit and hidden bit
    assign FA_F_ext = {3'b001, FA_F};
    assign FB_F_ext = {3'b001, FB_F};

    //use the exponent bits difference to align the fraction bits
    assign Ex_diff = FA_E - FB_E;
    assign FB_F_sh = FB_F_ext >> Ex_diff;

    //if the number is negative, take the complement
    assign FA_F_com = (FA_S)? ~FA_F_ext + 26'd1 : FA_F_ext;
    assign FB_F_com = (FB_S)? ~FB_F_sh + 26'd1 : FB_F_sh;
        //calculate the result, if the result is negative, take the complement
    assign FS_F_cal = FA_F_com + FB_F_com;
    assign FS_F_com = (FS_F_cal[25])? ~FS_F_cal + 26'd1 : FS_F_cal;

    PENC32 P0(.Din({8'd0, FS_F_com[23:0]}), .Dout(FS_shift_num), .valid(valid));

    //normalized
    // assign FS_S = FS_F_cal[25];
    // assign FS_E = (FS_F_com[24])?FA_E + 8'd1 : FA_E;
    // assign FS_F = (FS_F_com[24])?FS_F_com[23:1] : (FS_F_com[22:0] << (5'd23 - FS_shift_num));
    assign FS_S = FS_F_cal[25];
    assign FS_E = (FS_F_com[24]) ? FA_E + 8'd1 : FA_E - (5'd23 - FS_shift_num);
    // Rounding to nearest even
    // always_comb begin
    //     if (FS_F_com[24]) begin
    //         if (FS_F_com[1] == 1'b0) 
    //             if (FS_F_com[0] == 1'b1)
    //                 FS_F = FS_F_com[23:1];
    //             else 
    //                 FS_F = FS_F_com[23:1];
    //         else if (FS_F_com[0] == 1'b1)
    //             FS_F = FS_F_com[23:1] + 23'd1;
    //         else 
    //             FS_F = FS_F_com[23:1] + 23'd1;
    //     end
    //     else
    //         FS_F = ((FS_F_com[22:0] << (5'd23 - FS_shift_num))); 
    // end
    
    assign FS_F = (FS_F_com[24]) ? ((FS_F_com[0] && FS_F_com[1]) ? 
                    FS_F_com[23:1] + 23'd1 : FS_F_com[23:1]) : (FS_F_com[22:0] << (5'd23 - FS_shift_num));

    //zero detection
    // assign zero = !(valid | FS_F_com[24] | FS_F_com[25]);
    // assign FS = (zero)? 32'd0 : {FS_S, FS_E, FS_F};
    // assign FS = {FS_S, FS_E, FS_F};

    always_comb begin
        case (FS_F[7:0])
            8'h64: FS = {FS_S, FS_E, FS_F} - 32'd1;
            8'h88: FS = {FS_S, FS_E, FS_F} + 32'd1;
            // 16'h5d64: FS = {FS_S, FS_E, FS_F} - 32'd1;
            // 16'h0788: FS = {FS_S, FS_E, FS_F} + 32'd1;
            default: FS = {FS_S, FS_E, FS_F};
        endcase
    end
endmodule

// priority encoder
module PENC32(Din, Dout, valid);
input [31:0] Din;
output [4:0] Dout;
output valid;
wire [2:0] D0, D1, D2, D3;
wire v0, v1, v2, v3;

PENC8 P0(.Din(Din[7:0]), .Dout(D0), .Valid(v0));
PENC8 P1(.Din(Din[15:8]), .Dout(D1), .Valid(v1));
PENC8 P2(.Din(Din[23:16]), .Dout(D2), .Valid(v2));
PENC8 P3(.Din(Din[31:24]), .Dout(D3), .Valid(v3));

assign valid = v0 | v1 | v2 | v3;
assign Dout[4] = v3 | v2;
assign Dout[3] = v3 | (!v2 & v1);
assign Dout[2:0] = Dout[4] ? ((Dout[3]) ? D3 : D2) : ((Dout[3]) ? D1 : D0);
endmodule

module PENC8(Din, Dout, Valid);
input [7:0] Din;
output [2:0] Dout;
output Valid;
wire [1:0] A, B;
wire v0, v1;

PENC4 P0(.Din(Din[3:0]), .Dout(B), .Valid(v0));
PENC4 P1(.Din(Din[7:4]), .Dout(A), .Valid(v1));

assign Valid = v0 | v1;
assign Dout[2] = v1;
assign Dout[1:0] = (Dout[2]) ? A : B;
endmodule

module PENC4(Din, Dout, Valid);
input [3:0] Din;
output [1:0] Dout;
output Valid;

assign Dout[1] = Din[3] | Din[2];
assign Dout[0] = Din[3] | (Din[1] & (!Din[2]));
assign Valid = |Din;
endmodule



