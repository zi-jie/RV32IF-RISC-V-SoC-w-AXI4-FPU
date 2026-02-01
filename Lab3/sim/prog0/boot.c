#include <stdint.h>

#define DMA_ENABLE_ADDR        0x10020100
#define DMA_SOURCE_ADDR        0x10020200
#define DMA_DEST_ADDR          0x10020300
#define DMA_LENGTH_ADDR        0x10020400

#define CSR_MSTATUS 0x300      // mstatus CSR addr
#define CSR_MIE     0x304      // mie CSR addr

#define MSTATUS_MIE (1 << 3)   // mstatus MIE
#define MIE_MEIE    (1 << 11)  // mie MEIE 

extern unsigned int _dram_i_start;
extern unsigned int _dram_i_end;
extern unsigned int _imem_start;

extern unsigned int __sdata_start;
extern unsigned int __sdata_end;
extern unsigned int __sdata_paddr_start;

extern unsigned int __data_start;
extern unsigned int __data_end;
extern unsigned int __data_paddr_start;

void configure_and_start_dma(uint32_t src, uint32_t dst, uint32_t length) {

    asm volatile("csrrs x0, %0, %1" :: "i"(CSR_MSTATUS), "r"(MSTATUS_MIE));

    asm volatile("csrrs x0, %0, %1" :: "i"(CSR_MIE), "r"(MIE_MEIE));
    
    *(volatile uint32_t *)DMA_SOURCE_ADDR = src;   
    *(volatile uint32_t *)DMA_DEST_ADDR = dst;     
    *(volatile uint32_t *)DMA_LENGTH_ADDR = length;
    *(volatile uint32_t *)DMA_ENABLE_ADDR = 1;     

    asm volatile("wfi");                           
}

void boot() {
    configure_and_start_dma((uint32_t)&_dram_i_start, (uint32_t)&_imem_start,
                            (uint32_t)(&_dram_i_end - &_dram_i_start));

    configure_and_start_dma((uint32_t)&__data_paddr_start, (uint32_t)&__data_start,
                            (uint32_t)(&__data_end - &__data_start));

    configure_and_start_dma((uint32_t)&__sdata_paddr_start, (uint32_t)&__sdata_start,
                            (uint32_t)(&__sdata_end - &__sdata_start));
}
