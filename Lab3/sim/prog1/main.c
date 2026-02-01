#include <stdint.h>
#include <stddef.h>
#define MAX_ELEMENTS 128

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

int main() {
    extern int array_size;
    extern const int16_t array_addr;
    extern int16_t _test_start;

    int16_t sort_array[array_size];
    int16_t tmp;

    if (array_size > MAX_ELEMENTS) {
        array_size = MAX_ELEMENTS;
    }

    for (int i = 0; i < array_size; i++) {
        sort_array[i] = *(&array_addr + i);
    }

    for (int i = 0; i < array_size - 1; i++) {
        for (int j = 0; j < array_size - 1 - i; j++) {
            if (sort_array[j] > sort_array[j + 1]) {
                tmp = sort_array[j];
                sort_array[j] = sort_array[j + 1];
                sort_array[j + 1] = tmp;
            }
        }
    }

    for (int i = 0; i < array_size; i++) {
        *(&_test_start + i) = sort_array[i];
    }

    return 0;
}
