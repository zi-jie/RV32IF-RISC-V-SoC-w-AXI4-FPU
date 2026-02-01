#include <stdint.h>

#define DMA_ENABLE_ADDR        0x10020100
#define DMA_SOURCE_ADDR        0x10020200
#define DMA_DEST_ADDR          0x10020300
#define DMA_LENGTH_ADDR        0x10020400

#define CSR_MSTATUS 0x300      // mstatus CSR address
#define CSR_MIE     0x304      // mie CSR address

#define MSTATUS_MIE (1 << 3)   // mstatus MIE bit
#define MIE_MEIE    (1 << 11)  // mie MEIE bit

// External variables from the linker script
extern unsigned int _dram_i_start;
extern unsigned int _dram_i_end;
extern unsigned int _imem_start;

extern unsigned int __sdata_start;
extern unsigned int __sdata_end;
extern unsigned int __sdata_paddr_start;

extern unsigned int __data_start;
extern unsigned int __data_end;
extern unsigned int __data_paddr_start;

// Configure and start DMA
void configure_and_start_dma(uint32_t src, uint32_t dst, uint32_t length) {
    asm volatile("csrrs x0, %0, %1" :: "i"(CSR_MSTATUS), "r"(MSTATUS_MIE));
    asm volatile("csrrs x0, %0, %1" :: "i"(CSR_MIE), "r"(MIE_MEIE));
    
    *(volatile uint32_t *)DMA_SOURCE_ADDR = src;   // Set source address
    *(volatile uint32_t *)DMA_DEST_ADDR = dst;     // Set destination address
    *(volatile uint32_t *)DMA_LENGTH_ADDR = length; // Set transfer length
    *(volatile uint32_t *)DMA_ENABLE_ADDR = 1;     // Start DMA

    asm volatile("wfi");                           // Wait for DMA completion (interrupt)
}

// System boot logic
void boot() {
    // Copy instruction segment from DRAM to internal memory
    configure_and_start_dma((uint32_t)&_dram_i_start, (uint32_t)&_imem_start,
                            (uint32_t)(&_dram_i_end - &_dram_i_start));

    // Copy .data segment to internal memory
    configure_and_start_dma((uint32_t)&__data_paddr_start, (uint32_t)&__data_start,
                            (uint32_t)(&__data_end - &__data_start));

    // Copy .sdata segment to internal memory
    configure_and_start_dma((uint32_t)&__sdata_paddr_start, (uint32_t)&__sdata_start,
                            (uint32_t)(&__sdata_end - &__sdata_start));
}
