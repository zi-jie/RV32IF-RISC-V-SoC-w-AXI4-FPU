`define AXI_ID_BITS 4
`define AXI_IDS_BITS 8
`define AXI_ADDR_BITS 32
`define AXI_LEN_BITS 13
`define AXI_SIZE_BITS 3
`define AXI_DATA_BITS 32
`define AXI_STRB_BITS 4
`define AXI_LEN_ONE 4'h0
`define AXI_SIZE_BYTE 3'b000
`define AXI_SIZE_HWORD 3'b001
`define AXI_SIZE_WORD 3'b010
`define AXI_BURST_INC 2'h1
`define AXI_STRB_WORD 4'b1111
`define AXI_STRB_HWORD 4'b0011
`define AXI_STRB_BYTE 4'b0001
`define AXI_RESP_OKAY 2'h0
`define AXI_RESP_SLVERR 2'h2
`define AXI_RESP_DECERR 2'h3

`define AXI_ADDR_HALF_BITS 16

// For bridge
`define IDLE 2'b00
`define WRONG_ADDR 2'b01
`define M0S0 2'b10
`define M1S1 2'b11

// master read/write state
`define M_IDLE 3'b000
`define M_RCH_AR 3'b010
`define M_RCH_R 3'b001
`define M_WCH_AW 3'b100
`define M_WCH_W 3'b011
`define M_WCH_B 3'b111

// ROM, ROM FSM
`define ROM_DATA_BITS 32
`define ROM_ADDR_BITS 12
`define RCH_WAIT_ARVALID 1'b0
`define RCH_OUTPUT_DATA 1'b1

// slave read/write state
// `define RCH_WAIT_ARVALID 1'b0
// `define RCH_OUTPUT_DATA 1'b1
`define WCH_WAIT_AWVALID 2'b00
`define WCH_WRITE_DATA 2'b01
`define WCH_WRITE_RESPONSE 2'b10

// DRAM
`define DRAM_DATA_BITS 32
`define DRAM_SLAVE_ADDR_BITS 32
`define DRAM_ADDR_BITS 11

// DRAM slave FSM
`define WAIT_VALID 3'b000
`define AR_REQUEST_HANDSHAKE 3'b001
`define PASS_ADDR_TO_DRAM_FSM 3'b010
`define WAIT_DATA_FROM_DRAM_FSM 3'b011
`define AW_REQUEST_HANDSHAKE 3'b100
`define PASS_WDATA_TO_DRAM_FSM 3'b101
`define WAIT_DRAM_FSM_WRITE_DONE 3'b110
`define WRITE_RESPONSE 3'b111

// DRAM FSM
`define DRAM_WAIT_ENABLE 4'b0000
`define DRAM_ACT 4'b0001
`define DRAM_READ 4'b0010
`define DRAM_WAIT_OUTPUT_VALID 4'b0011
`define DRAM_WRITE 4'b0100
`define DRAM_PRE 4'b0101
`define ACT_DELAY_COUNT_DOWN 4'b1001 
`define WRITE_DELAY_COUNT_DOWN 4'b1100
`define PRE_DELAY_COUNT_DOWN 4'b1101

// DMA slave FSM
`define DMA_WAIT_VALID 2'b00
`define DMA_GET_CONFIG 2'b01
`define DMASLAVE_W_RESPONSE 2'b10

// DMA
`define DMA_REG_LENGTH 8
`define DMA_REG_LEN_BITS 3

// DMA master, read channel FSM
`define DMA_WAIT_R_REQUEST 2'b00
`define DMA_AR_VALID 2'b01
`define DMA_GET_READ_DATA 2'b10

// DMA master, write channel FSM
`define DMA_WAIT_W_REQUEST 2'b00
`define DMA_AW_VALID 2'b01
`define DMA_WRITE_DATA 2'b10
`define DMAMASTER_W_RESPONSE 2'b11

// aFIFO
`define DATASIZE 32
`define ADDRSIZE 2