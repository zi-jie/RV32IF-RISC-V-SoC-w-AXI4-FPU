
extern unsigned int sctrl_addr[];
extern unsigned char mtime_addr[];
extern unsigned int DMA_addr[];
extern unsigned char DLA_addr[];

extern unsigned int _sctrl_test_start[];


const int sctrl_size = 64;
const int sctrl_max_count = 8;
unsigned int* copy_addr = (unsigned int*)_sctrl_test_start;
int copy_count;


void interrupt_dead_loop(){
  asm("j interrupt_dead_loop");
}

void sctrl_interrupt(){
  for (int i = 0; i < sctrl_size; i++) { // Copy data from sensor controller to DM
    copy_addr[i] = sctrl_addr[i];
    //*(copy_addr + i) = sctrl_addr[i];
  }
  copy_addr += sctrl_size; // Update copy address
  copy_count++;    // Increase copy count
  sctrl_addr[0x80] = 1; // Enable sctrl_clear
  sctrl_addr[0x80] = 0; // Disable sctrl_clear
  sctrl_addr[0x40] = 1; // Enable sctrl_en
  if (copy_count == sctrl_max_count) {
    asm("li t6, 0x80");
    asm("csrc mstatus, t6"); // Disable MPIE of mstatus
  }
  return;
}

void dma_interrupt(){
  //Load DMA Base Address
  asm("lui a5, 0x50000");

  //Clean DMA Enable MMIO Register
  asm("sw x0, 16(a5)");
  return;
}

void dla_interrupt(){
  int dma_src_config_dla = 0;
  int dma_dest_config_dla = 0;
  char* DLA_interrupt = 0x60000008;
  *DLA_interrupt = 0;
  return;
}

void mtime_interrupt(){
  long long int compare;
  // mtimecompare
  compare = mtime_addr[0x1000];
  mtime_addr[0x1000] = compare*2;
  return;
}
