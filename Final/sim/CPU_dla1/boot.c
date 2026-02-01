
//extern int DMA_busy;
extern unsigned int const DMA_addr[];
void rom_DMA_process(int src_addr, int dest_addr, int src_config, int dest_config){
  asm("lui a5, 0x50000"); // dma_addr = 0x50000000
  
  asm("sw a0, 0(a5)"); // src_addr
  asm("sw a1, 4(a5)"); // dest_addr
  asm("sw a2, 8(a5)"); // src_config 
  asm("sw a3, 12(a5)"); // dest_config  
  
  asm("addi t0, x0, 1");
  asm("sw t0, 16(a5)"); // dma_en 
}

// inline unsigned int get_DMA_status(void) {
//   asm("lui a5, 0x50000"); // dma_addr = 0x50000000
//   asm("addi a5, a5, 16")
  
// }

void boot() {
  extern unsigned int _dram_i_start;
  extern unsigned int _dram_i_end;
  extern unsigned int _imem_start;

  extern unsigned int __sdata_start;
  extern unsigned int __sdata_end;
  extern unsigned int __sdata_paddr_start;

  extern unsigned int __data_start;
  extern unsigned int __data_end;
  extern unsigned int __data_paddr_start;

  extern unsigned int _isr_start;
  extern unsigned int _isr_end;

  int *dram_i_start = &_dram_i_start;
  int *data_paddr_start = &__data_paddr_start;
  int *sdata_paddr_start = &__sdata_paddr_start;

  int isr_count = (&_isr_end-&_isr_start);
  int imem_count = (&_dram_i_end-&_dram_i_start)-(&_isr_end-&_isr_start);
  int data_count = &__data_end-&__data_start;
  int sdata_count = &__sdata_end-&__sdata_start;

  int dma_src_config;
  int dma_dest_config;
  int i=0;


  // Enable Global Interrupt
  asm("csrsi mstatus, 0x8"); // MIE of mstatus

  // Enable Local Interrupt
  asm("li t6, 0x800");
  asm("csrs mie, t6"); // MEIE of mie 


/*  
  dma_src_config = 0 + 64<<2;
  dma_dest_config = 0 + 64<<2;
  while(imem_count>0){
    if(imem_count>=64){
      DMA_process(_dram_i_start+64*i, _imem_start+64*i, dma_src_config, dma_dest_config);
    }
    else {
      dma_src_config = 0 + imem_count<<2;
      dma_dest_config = 0 + imem_count<<2;
      DMA_process(_dram_i_start+64*i, _imem_start+64*i, dma_src_config, dma_dest_config);
    }
    imem_count -= 64;
    i++;
  }
*/
  
  // CPU move isr inst from dram_i to imem 
  for(int k=0; k<=isr_count; k++)
  {
    *(&_isr_start+k) = dram_i_start[k];  
  }
  
  // CPU move sdata from dram_d to dmem
  for(int j=0; j<=(&__sdata_end-&__sdata_start); j++)
  {
    *(&__sdata_start+j) = sdata_paddr_start[j];
  }
  
  // Call DMA to move main inst from dram_i to imem
  dma_src_config = 0 + 64<<4; // (64*4) << 2
  dma_dest_config = 0 + 64<<4; // (64*4) << 2
  i=0; 
  while(imem_count>0){
    if(imem_count>=64){
      rom_DMA_process(&_dram_i_start+isr_count+64*i, &_imem_start+64*i, dma_src_config, dma_dest_config);
      asm("wfi");
    }
    else {
      dma_src_config = 0 + imem_count<<4;
      dma_dest_config = 0 + imem_count<<4;
      rom_DMA_process(&_dram_i_start+isr_count+64*i, &_imem_start+64*i, dma_src_config, dma_dest_config);
      asm("wfi");
    }
    imem_count -= 64;
    i++;
  }



  // Call DMA to move data from dram_d to dmem
  dma_src_config = 0 + 64<<4;
  dma_dest_config = 0 + 64<<4;
  i=0;
  while(data_count>0){
    if(data_count>=64){
      rom_DMA_process(&__data_paddr_start+64*i, &__data_start+64*i, dma_src_config, dma_dest_config);
      asm("wfi");
    }
    else {
      dma_src_config = 0 + data_count<<4;
      dma_dest_config = 0 + data_count<<4;
      rom_DMA_process(&__data_paddr_start+64*i, &__data_start+64*i, dma_src_config, dma_dest_config);
      asm("wfi");
    }
    data_count -= 64;
    i++;
  }

/*
  for(int k=0; k<=(&__data_end-&__data_start); k++)
  {
 *(&__data_start+k) = data_paddr_start[k];
  }  
*/ 
/*
  dma_src_config = 0 + 64<<2;
  dma_dest_config = 0 + 64<<2;
  i=0;
  while(sdata_count>0){
    if(sdata_count>=64){
      DMA_process(__sdata_paddr_start+64*i, __sdata_start+64*i, dma_src_config, dma_dest_config);
      while(DMA_busy){
        asm("wfi");
      }
    }
    else {
      dma_src_config = 0 + sdata_count<<2;
      dma_dest_config = 0 + sdata_count<<2;
      DMA_process(__sdata_paddr_start+64*i, __sdata_start+64*i, dma_src_config, dma_dest_config);
      while(DMA_busy){
        asm("wfi");
      }
    }
    sdata_count -= 64;
    i++;
  } */
  /*
  for(int j=0; j<=(&__sdata_end-&__sdata_start); j++)
  {
 *(&__sdata_start+j) = sdata_paddr_start[j];
  }
  */
  return; 
}
