module DLA_wrapper (
    /* input */
    input logic clk,
    input logic rst,

    input logic [ 7:0] ARID,
    input logic [31:0] ARADDR,
    input logic [ 3:0] ARLEN,
    input logic [ 2:0] ARSIZE,
    input logic [ 1:0] ARBURST,
    input logic        ARVALID,
    input logic        RREADY,
    input logic [ 7:0] AWID,
    input logic [31:0] AWADDR,
    input logic [ 3:0] AWLEN,
    input logic [ 2:0] AWSIZE,
    input logic [ 1:0] AWBURST,
    input logic        AWVALID,
    input logic [31:0] WDATA,
    input logic [ 3:0] WSTRB,
    input logic        WLAST,
    input logic        WVALID,
    input logic        BREADY,

    // DLA
    input logic [31:0] r_data,
    input logic        no_sync_inpt,

    /* output */
    output logic        ARREADY,
    output logic [ 7:0] RID,
    output logic [31:0] RDATA,
    output logic [ 1:0] RRESP,
    output logic        RLAST,
    output logic        RVALID,
    output logic        AWREADY,
    output logic        WREADY,
    output logic [ 7:0] BID,
    output logic [ 1:0] BRESP,
    output logic        BVALID,

    // DLA
    output logic [31:0] r_addr,
    output logic [31:0] w_addr,
    output logic [31:0] w_data,
    output logic [2:0]  config_w_en, // active high
    output logic [3:0]  ifm0_w_en,   // active low
    output logic [3:0]  ifm1_w_en,   // active low
    output logic [3:0]  weight_w_en  // active high
);

  logic [31:0] A;

  logic [ 7:0] arid_r;
  logic [13:0] araddr_r;
  logic [ 3:0] arlen_r;
  logic [ 2:0] arsize_r;
  logic [ 1:0] arburst_r;

  logic [ 7:0] awid_r;
  logic [13:0] awaddr_r;
  logic [ 2:0] awsize_r;
  logic [ 1:0] awburst_r;
  logic [ 3:0] awlen_r_fix;

  logic [31:0] wdata_r;
  logic        wlast_r;

  logic [31:0] rdata_r;

  typedef enum logic [3:0] {
    INIT = 4'd0, 
    R_WAIT_VALID = 4'd1, 
    W_WAIT_VALID = 4'd2, 
    R_GET_DATA = 4'd3, 
    R_SEND_ADDR = 4'd4, 
    R_WAIT_READY = 4'd5, 
    W_WAIT_DATA = 4'd6, 
    W_WRITE_DATA = 4'd7, 
    W_WAIT_READY = 4'd8} FSM_state;
  FSM_state state;

  assign r_addr = A;
  assign w_addr = A;
  assign w_data = wdata_r;

  assign ARREADY = state == R_WAIT_VALID;
  assign RID     = arid_r;
  assign RRESP   = {1'b0, state != R_WAIT_READY};
  assign RVALID  = state == R_WAIT_READY;
  assign RLAST   = state == R_WAIT_READY && arlen_r == 4'd0;
  assign RDATA   = rdata_r;

  assign AWREADY = state == W_WAIT_VALID;
  assign WREADY  = state == W_WAIT_DATA;
  assign BID     = awid_r;

  assign BRESP  = {1'b0, !(state == W_WAIT_READY)};
  assign BVALID = state == W_WAIT_READY;

  // state
  always_ff @(posedge clk) begin
    if(rst) begin
      state <= INIT;
    end
    else begin
      unique case(state)
        INIT:         state <= R_WAIT_VALID;
        R_WAIT_VALID: state <= ARVALID ? R_SEND_ADDR : W_WAIT_VALID;
        W_WAIT_VALID: state <= AWVALID ? W_WAIT_DATA : R_WAIT_VALID;
        R_SEND_ADDR:  state <= R_GET_DATA;
        R_GET_DATA:   state <= R_WAIT_READY;
        R_WAIT_READY: state <= ~RREADY ? R_WAIT_READY :
                               (arlen_r > 4'd0) ? R_GET_DATA :
                               AWVALID ? W_WAIT_VALID : R_WAIT_VALID; 
        W_WAIT_DATA:  state <= ~WVALID ? W_WAIT_DATA : W_WRITE_DATA;
        W_WRITE_DATA: state <= wlast_r ? W_WAIT_READY : W_WAIT_DATA;
        W_WAIT_READY: state <= ~BREADY ? W_WAIT_READY :
                               ARVALID ? R_WAIT_VALID : W_WAIT_VALID;
        default:      state <= INIT;
      endcase
    end
  end
 
  // arid_r, arsize_r, arburst_r
  always_ff @(posedge clk) begin
    if(rst) begin
      arid_r    <= 8'd0;
      arsize_r  <= 3'd0;
      arburst_r <= 2'd0;
    end
    else if(state == R_WAIT_VALID) begin
      arid_r    <= ARID;
      arsize_r  <= ARSIZE;
      arburst_r <= ARBURST;
    end
  end

  // awid_r, awsize_r, awbutst_r
  always_ff @(posedge clk) begin
    if(rst) begin
      awid_r      <= 8'd0;
      awsize_r    <= 3'd0;
      awburst_r   <= 2'd0;
      awlen_r_fix <= 4'd0;
    end
    else if(state == W_WAIT_VALID) begin
      awid_r      <= AWID;
      awsize_r    <= AWSIZE;
      awburst_r   <= AWBURST;
      awlen_r_fix <= AWLEN;
    end
  end

  // A
  always_ff @(posedge clk) begin
    if(rst) begin
      A <= 32'd0;
    end  
    else if(state == R_WAIT_VALID && ARVALID) begin
      A <= (ARADDR == 32'h6000_0008) ? ARADDR : {2'd0, ARADDR[31:2]};
    end
    else if(state == W_WAIT_VALID && AWVALID) begin
      unique if(AWADDR >= 32'h6000_0000 && AWADDR <= 32'h6000_0008) begin
        A <= AWADDR;
      end
      else begin
        A <= {2'd0, AWADDR[31:2]};
      end
    end
    else if(state == R_GET_DATA) begin
      A <= A + 32'd1;
    end
    else if(state == W_WRITE_DATA && ~wlast_r) begin
      A <= (A >= 32'h6000_0000 && A <= 32'h6000_0008) ? A + 32'd4 : A + 32'd1;
    end
  end

  // arlen_r
  always_ff @(posedge clk) begin
    if(rst) begin
      arlen_r     <= 4'd0;
    end
    else if(state == R_WAIT_VALID) begin
      arlen_r     <= ARLEN;
    end
    else if(state == R_WAIT_READY && RREADY && arlen_r != 4'd0) begin 
      arlen_r <= arlen_r - 4'd1;
    end
  end

  // rdata_r
  always_ff @(posedge clk) begin
    if(rst) begin
      rdata_r <= 32'd0;
    end
    else if(state == R_GET_DATA) begin
      rdata_r <= (A == 32'h6000_0008) ? {31'd0, no_sync_inpt} : r_data;
    end
  end

  // wdata_r, wlast_r
  always_ff @(posedge clk) begin
    if(rst) begin
      wdata_r <= 32'd0;
      wlast_r <= 1'b0;
    end
    else if(state == W_WAIT_DATA && WVALID) begin
      wdata_r <= WDATA;
      wlast_r <= WLAST;
    end
    else begin
      wdata_r <= 32'd0;
      wlast_r <= 1'b0;
    end
  end 

  // config_w_en, active high
  always_ff @(posedge clk) begin
    if(rst) begin
      config_w_en <= 3'd0;
    end
    else if(state == W_WAIT_DATA && WVALID) begin
      unique case(A)
        32'h6000_0000: config_w_en <= 3'b001;
        32'h6000_0004: config_w_en <= 3'b010;
        32'h6000_0008: config_w_en <= 3'b100;
        default:       config_w_en <= 3'b000;
      endcase
    end
    else begin
      config_w_en <= 3'd0;
    end
  end

  // ifm0_w_en, active low
  always_ff @(posedge clk) begin
    if(rst) begin
      ifm0_w_en <= 4'b1111;
    end
    else if(state == W_WAIT_DATA && WVALID) begin
      unique if(A >= 32'h18040000 && A <= 32'h18043fff) begin
        ifm0_w_en <= ~WSTRB;
      end
      else begin
        ifm0_w_en <= 4'b1111;
      end
    end
    else begin
      ifm0_w_en <= 4'b1111;
    end
  end

  // ifm1_w_en, active low
  always_ff @(posedge clk) begin
    if(rst) begin
      ifm1_w_en <= 4'b1111;
    end
    else if(state == W_WAIT_DATA && WVALID) begin
      unique if(A >= 32'h18080000 && A <= 32'h18083fff) begin
        ifm1_w_en <= ~WSTRB;
      end
      else begin
        ifm1_w_en <= 4'b1111;
      end 
    end
    else begin
      ifm1_w_en <= 4'b1111;
    end
  end

  // weight_w_en, active high
  always_ff @(posedge clk) begin
    if(rst) begin
      weight_w_en <= 4'b0000;
    end
    else if(state == W_WAIT_DATA && WVALID) begin
      unique if(A >= 32'h180c0000 && A <= 32'h180c3fff) begin
        weight_w_en <= WSTRB;
      end
      else begin
        weight_w_en <= 4'b0000;
      end       
    end
    else begin
      weight_w_en <= 4'b0000;
    end
  end

endmodule