#include <stdint.h>

#define DMA_ENABLE_ADDR        0x10020100
#define DMA_SOURCE_ADDR        0x10020200
#define DMA_DEST_ADDR          0x10020300
#define DMA_LENGTH_ADDR        0x10020400

#define DLA_CONFIG_H_ADDR        0x60000004
#define DLA_CONFIG_L_ADDR        0x60000000
#define DLA_INTERRUPT_ADDR       0x60000008
#define DLA_WEIGHT_ADDR0          0x60300000
#define DLA_WEIGHT_ADDR1          0x60300004
#define DLA_WEIGHT_ADDR2          0x60300008
#define DLA_WEIGHT_ADDR3          0x6030000c
#define DLA_WEIGHT_ADDR4          0x60300010

#define SIM_END_ADDR              0x0002fffc

#define TEST_START_ADDR0          0x20101000
#define TEST_START_ADDR1          0x20101010
#define TEST_START_ADDR2          0x20101020
#define TEST_START_ADDR3          0x20101030
#define TEST_START_ADDR4          0x20101040
#define TEST_START_ADDR5          0x20101050
#define TEST_START_ADDR6          0x20101060

#define CSR_MSTATUS 0x300      // mstatus CSR address
#define CSR_MIE     0x304      // mie CSR address

#define MSTATUS_MIE (1 << 3)   // MIE bit in mstatus
#define MIE_MEIE    (1 << 11)  // MEIE bit in mie
#define MIP_MEIP (1 << 11) // External interrupt pending
#define MIP_MTIP (1 << 7)  // Timer interrupt pending
#define MIP 0x344

volatile unsigned int *WDT_addr = (int *) 0x10010000;
volatile unsigned int *dma_addr_boot = (int *) 0x10020000;

extern int last_channel;

void DMA_process(uint32_t src, uint32_t dst, uint32_t length) {
    // Enable MIE in mstatus
    asm volatile("csrrs x0, %0, %1" :: "i"(CSR_MSTATUS), "r"(MSTATUS_MIE));

    // Enable MEIE in mie
    asm volatile("csrrs x0, %0, %1" :: "i"(CSR_MIE), "r"(MIE_MEIE));
    
    *(volatile uint32_t *)DMA_SOURCE_ADDR = src;   // Set source address
    *(volatile uint32_t *)DMA_DEST_ADDR = dst;     // Set destination address
    *(volatile uint32_t *)DMA_LENGTH_ADDR = length; // Set transfer length
    *(volatile uint32_t *)DMA_ENABLE_ADDR = 1;     // Start DMA

    asm volatile("wfi");                           // Wait for DMA completion (interrupt)
}

void DLA_process(int config_heigh, int config_low){
  *(volatile uint32_t *)DLA_CONFIG_H_ADDR = config_heigh;
  *(volatile uint32_t *)DLA_CONFIG_L_ADDR = config_low;
  return;
}

void timer_interrupt_handler(void) {
  asm("csrsi mstatus, 0x0"); // MIE of mstatus
  WDT_addr[0x40] = 0; // WDT_en
  asm("j _start");
}

void external_interrupt_handler(void) {
	volatile unsigned int *dma_addr_boot = (int *) 0x10020000;
  uint32_t mcause_r;
  asm volatile("csrr %0, mcause" : "=r"(mcause_r));
	asm("csrsi mstatus, 0x0"); // MIE of mstatus
  if (mcause_r == 0x80000010) { //todo
    dma_addr_boot[0x40] = 0; // disable DMA
  }
  else {
    *(volatile uint32_t *)DLA_INTERRUPT_ADDR = 0; // disable DLA
  }
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

int last_channel = 0;
int main(){
  extern unsigned char ifm;
  extern unsigned int weight;

  int dma_src_config_main = 0;
  int dma_dest_config_main = 0;
  int* weight_addr = &weight;
  uint32_t ifm_address = (uint32_t)&ifm;

  // chunk mode, width=7(bytes), height=7(bytes), row stride = 8
  // dma_src_config_main = 0x200701d; 
  // chunk mode, width=7(bytes), height=7(bytes), row stride = 64
  // dma_dest_config_main = 0x1000701d;
  // DMA_process(&ifm, 0x60100000, dma_src_config_main, dma_dest_config_main);
  DMA_process(ifm_address, 0x60100000, 1);
  DMA_process(ifm_address + 8, 0x60100040, 1);
  DMA_process(ifm_address + 16, 0x60100080, 1);
  DMA_process(ifm_address + 24, 0x601000c0, 1);
  DMA_process(ifm_address + 32, 0x60100100, 1);
  DMA_process(ifm_address + 40, 0x60100140, 1);
  DMA_process(ifm_address + 48, 0x60100180, 1);

//  DMA_process(&weight, 0x60300000, 0x50, 0x50);

  // 1st channel weight 
//   for(int i=0; i<5; i++){
//     *(DLA_weight+i) = *(weight_addr+i);
//   }
  *(volatile uint32_t *)DLA_WEIGHT_ADDR0 = *(weight_addr);
  *(volatile uint32_t *)DLA_WEIGHT_ADDR1 = *(weight_addr + 1);
  *(volatile uint32_t *)DLA_WEIGHT_ADDR2 = *(weight_addr + 2);
  *(volatile uint32_t *)DLA_WEIGHT_ADDR3 = *(weight_addr + 3);
  *(volatile uint32_t *)DLA_WEIGHT_ADDR4 = *(weight_addr + 4);

  DLA_process(0x0, 0x1EE2419);
  asm volatile("wfi");

  DMA_process(0x60400000, TEST_START_ADDR0, 3);
  DMA_process(0x60400080, TEST_START_ADDR1, 3);
  DMA_process(0x60400100, TEST_START_ADDR2, 3);
  DMA_process(0x60400180, TEST_START_ADDR3, 3);
  DMA_process(0x60400200, TEST_START_ADDR4, 3);
  DMA_process(0x60400280, TEST_START_ADDR5, 3);
  DMA_process(0x60400300, TEST_START_ADDR6, 3);

  *(volatile uint32_t *)SIM_END_ADDR = -1;
  last_channel = 1;

  return 0;
}