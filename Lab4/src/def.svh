//================================================
// Auther:      Chen Yun-Ru (May)
// Filename:    def.svh
// Description: Hart defination
// Version:     0.1
//================================================
// `ifndef DEF_SVH
// `define DEF_SVH

// CPU
`define DATA_BITS 32
`define INS_SIZE 32
`define NOP 32'b0
`define DATA_SIZE 32
`define OPCODE 6:0

// OPCODE types
`define RTYPE 	7'b0110011
`define LOAD	7'b0000011
`define ITYPE	7'b0010011
`define JALR	7'b1100111
`define STYPE	7'b0100011
`define BTYPE	7'b1100011
`define AUIPC	7'b0010111
`define LUI		7'b0110111
`define JAL		7'b1101111
`define CSR		7'b1110011


// Cache
`define CACHE_BLOCK_BITS 2
`define CACHE_INDEX_BITS 5
`define CACHE_TAG_BITS 23
`define CACHE_TAG_OUT_BITS 46
`define CACHE_DATA_BITS 128
`define CACHE_DATA_OUT_BITS 64
`define CACHE_DATA_IN_BITS 32
// `define CACHE_LINES 2**(`CACHE_INDEX_BITS)
`define CACHE_LINES 32
`define CACHE_WRITE_BITS 16
`define CACHE_TYPE_BITS 3
`define CACHE_BYTE `CACHE_TYPE_BITS'b000
`define CACHE_HWORD `CACHE_TYPE_BITS'b001
`define CACHE_WORD `CACHE_TYPE_BITS'b010
`define CACHE_BYTE_U `CACHE_TYPE_BITS'b100
`define CACHE_HWORD_U `CACHE_TYPE_BITS'b101

//Read Write data length
`define WRITE_LEN_BITS 2
`define BYTE `WRITE_LEN_BITS'b00
`define HWORD `WRITE_LEN_BITS'b01
`define WORD `WRITE_LEN_BITS'b10


// from axi_define
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

// `endif
