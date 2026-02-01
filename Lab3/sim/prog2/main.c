#include <stdint.h>

#define MIP_MEIP (1 << 11) // External interrupt pending
#define MIP_MTIP (1 << 7)  // Timer interrupt pending
#define MIP 0x344

volatile unsigned int *WDT_addr = (int *) 0x10010000;
volatile unsigned int *dma_addr_boot = (int *) 0x10020000;

void timer_interrupt_handler(void) {
  asm("csrsi mstatus, 0x0"); // MIE of mstatus
  WDT_addr[0x40] = 0; // WDT_en
  asm("j _start");
}

void external_interrupt_handler(void) {
	volatile unsigned int *dma_addr_boot = (int *) 0x10020000;
	asm("csrsi mstatus, 0x0"); // MIE of mstatus
	dma_addr_boot[0x40] = 0; // disable DMA
} 

void trap_handler(void) {
    uint32_t mip;
    asm volatile("csrr %0, %1" : "=r"(mip) : "i"(MIP));
	
    if ((mip & MIP_MTIP) >> 7) {
        timer_interrupt_handler();
    }

    if ((mip & MIP_MEIP) >> 11) {
        external_interrupt_handler();
    }
}

int main(void) {
    extern unsigned char _binary_image_bmp_start;
    extern unsigned int _binary_image_bmp_size;
    extern unsigned char _test_start;

    unsigned char* image_data = &_binary_image_bmp_start;
    unsigned int* size = &_binary_image_bmp_size;
    char* gray_data = &_test_start;

    uint32_t offset = image_data[10];
    int k1 = 11;
    int k2 = 59;
    int k3 = 30;

    for (uint32_t i = 0; i < offset; i++) {
        gray_data[i] = image_data[i];
    }

    for (uint32_t i = offset; i < size; i += 3) {
        unsigned char blue = image_data[i];
        unsigned char green = image_data[i + 1];
        unsigned char red = image_data[i + 2];

        int gray = k1 * blue + k2 * green + k3 * red;

        gray_data[i] = gray / 100;
        gray_data[i + 1] = gray / 100;
        gray_data[i + 2] = gray / 100;
    }
    return 0;
}