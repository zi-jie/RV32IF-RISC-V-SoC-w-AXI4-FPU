// `include "./DLA.sv"
// `include "./DLA_wrapper.sv"
// `include "./controller.sv"
// `include "./PE.sv"

module DLA_top (
    /* input */
    input logic CPU_clk,
    input logic CPU_rst, 
    input logic DLA_clk,
    input logic DLA_rst,    

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

    output logic DLA_inpt
);

    logic [31:0] r_addr;
    logic [31:0] w_addr;
    logic [31:0] w_data;
    logic [31:0] r_data;
    logic [2:0] config_w_en;  // active high
    logic [3:0] ifm0_w_en;    // active low
    logic [3:0] ifm1_w_en;    // active low
    logic [3:0] weight_w_en;  // active high
    logic       no_sync_inpt;


    DLA DLA(
        /* input */
        .clk(DLA_clk),
        .rst(!DLA_rst),
        .CPU_clk(CPU_clk),
        .CPU_rst(CPU_rst),
        .r_addr(r_addr),
        .w_addr(w_addr),
        .w_data(w_data),
        .config_w_en(config_w_en),
        .ifm0_w_en(ifm0_w_en),
        .ifm1_w_en(ifm1_w_en),
        .weight_w_en(weight_w_en),
        /* output */
        .r_data(r_data),
        .no_sync_inpt(no_sync_inpt),
        .inpt(DLA_inpt)
    );

    DLA_wrapper DLA_wrapper (
        /* input */
        .clk(DLA_clk),
        .rst(DLA_rst),
        .ARID(ARID),
        .ARADDR(ARADDR),
        .ARLEN(ARLEN),
        .ARSIZE(ARSIZE),
        .ARBURST(ARBURST),
        .ARVALID(ARVALID),
        .RREADY(RREADY),
        .AWID(AWID),
        .AWADDR(AWADDR),
        .AWLEN(AWLEN),
        .AWSIZE(AWSIZE),
        .AWBURST(AWBURST),
        .AWVALID(AWVALID),
        .WDATA(WDATA),
        .WSTRB(WSTRB),
        .WLAST(WLAST),
        .WVALID(WVALID),
        .BREADY(BREADY),

        .no_sync_inpt(no_sync_inpt),
        .r_data(r_data),

        /* output */
        .ARREADY(ARREADY),
        .RID(RID),
        .RDATA(RDATA),
        .RRESP(RRESP),
        .RLAST(RLAST),
        .RVALID(RVALID),
        .AWREADY(AWREADY),
        .WREADY(WREADY),
        .BID(BID),
        .BRESP(BRESP),
        .BVALID(BVALID),

        .r_addr(r_addr),
        .w_addr(w_addr),
        .w_data(w_data),
        .config_w_en(config_w_en),
        .ifm0_w_en(ifm0_w_en),
        .ifm1_w_en(ifm1_w_en),
        .weight_w_en(weight_w_en)
    );


endmodule