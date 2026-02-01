// -----------------------------------------
// 3*3 conv_relu_residual (data from text3)
// IFM: 13*13*3 
// Kernel: 4 
// -----------------------------------------

#define IFM_W_H 13
#define POOL_W_H 3
#define INT16_MIN (-32768)
int calcConv3(int start_i_x, int start_i_y, int wCnt, int (*ifm)[16]);
int addSat(int val);
int leakyReLU(int val);
int requant(int val);

int padL = 0;
int padR = 0;
int padT = 0;
int padB = 0;

// extern int weight_data[][3][3];
// extern int ifm_data0[][16];
// extern int ifm_data1[][16];
// extern int ifm_data2[][16];


int ifm_data0[][16] = {
    105,   74,   81,  -42,  122,   24,  -57,  -51,   57,   17,  -64,  -88,  110, 0, 0, 0,
    -19,  121, -113,  113,   81, -115,    6,   98,  -16,  -95,   19, -106,  104, 0, 0, 0,
     47,  125,   34,  -13,  -28,   45,    8, -102, -107,  -10,  125,  -80,    5, 0, 0, 0,
     81, -106,   26,  -16,  -45,  124,   -9,   66,   10,  -54,  -54,   79,  -22, 0, 0, 0,
    -49,  -40,  104,  -37,   59,  -96,  -90,   13,  -44, -121,  -72,   58,  -98, 0, 0, 0,
     65,    2,   65,  -10,  -16,  -64,  -32,  -29,  -99,   87,   36,   78,   54, 0, 0, 0,
    -25,   92,   43,   37,  -39,  -45, -120,   92,    2,   80,  124,  -20,  -33, 0, 0, 0,
    -78,   96,   29,  -91,  -69,  -94,   91,  -80,  -57, -118, -104,  -84,    0, 0, 0, 0,
    -52,  -46,  -88, -119,  103,  -72,   -3,   -3,  106, -120,  -55,  -47,   66, 0, 0, 0,
     -1, -115,  -23,  -83,  -85,    4,  -58,  -88,   14, -109,  -30,   63,   82, 0, 0, 0,
     39,   51,   95,  -72,   -5,   25,   17,  -67,   40,  -21,   97,  -64,   18, 0, 0, 0,
    126,   83, -113,   89,    9,   76,  -97,  -24,  -78,   24,  -57,  -42,   73, 0, 0, 0,
     66,  -22,  -28,   85,   16,  -92,   59,   83,   37,  -95,   39,  -92,   30, 0, 0, 0
};

int ifm_data1[][16] = {
     46,  111,   36, -101,  116,   60,   47,   -2, -113,  -97,  -68,  -95,  -59, 0x00, 0x00, 0x00,
    -55,  -36,   61,  119, -124,   12, -107,  -91,  -11, -121,  115,   62,   33, 0x00, 0x00, 0x00,
     66,   97,   70,   65,    4,  -88,   91,  -40,  -63, -125,   35, -127,  116, 0x00, 0x00, 0x00,
     57,   31, -123,    8,  -84,  -77, -120, -116,   67,  -31,  -15,   76,  -55, 0x00, 0x00, 0x00,
     94, -108,  119,   -8,   47,  -12,  -40,  120, -107,  -27,  -65,  124,   98, 0x00, 0x00, 0x00,
    -66,  -51,  -73,  -22,  -61,   82,  -29,  -85,  106,   86,  -44, -116,   98, 0x00, 0x00, 0x00,
    -60,  123,  -58,  102,   82,  114,  -95,  114, -107,  -67,  -37,   -1,  -72, 0x00, 0x00, 0x00,
     67,  115,  -87, -103,   97,  -91,  -73,  124,   23,   99,   -1,    5,  -64, 0x00, 0x00, 0x00,
    -27,    4,  119,   13,   53,  -20,   18,   17,   80,  -53,  -43,    3,  -67, 0x00, 0x00, 0x00,
     67,  -95,  -48,  -62,  -51,  -20,   78,   46,  -14,   55,  -74,   11, -119, 0x00, 0x00, 0x00,
    -94,  -19,  -93,   16,  -12,  -99,  -53,  -93,  -78,  -51,  103,   96,   32, 0x00, 0x00, 0x00,
    -36,   94,   24,  -60,  127,  -47,   56,  -22,  -35,  118,  116,   -4,   82, 0x00, 0x00, 0x00,
    -62,   -7, -118,  -88,   33,  -15,  -62,  -19,   32,   -7,  -13,   54,   -4, 0x00, 0x00, 0x00
};

int ifm_data2[][16] = {
     -45,  -34,   33,  -99,  -96,   51,   25,   14, -122, -125,   55,   44,  -11, 0x00, 0x00, 0x00,
     -92,  -37,  -15, -109, -101, -104,  115,   -7,  -85,  -68,   65,  -87,   68, 0x00, 0x00, 0x00,
      85,  117,  -18, -125,  -47,  -68,  -88,   73,   75,  -63,  111,  126,  -92, 0x00, 0x00, 0x00,
     -45,   58,   47,   53,   48,   22,  -55,  111,  124,  -81,  -87,  -10,  -19, 0x00, 0x00, 0x00,
     -65,   -5, -120,  -42,  -25,   74,   40,  107,  -43,  -39, -120,  105, -124, 0x00, 0x00, 0x00,
    -119,  -25,  -96,  -56,  -42,   61,  -73,  -12,  117,  -18,    7,   67,   43, 0x00, 0x00, 0x00,
      49,  -54,  -47,   -9,  -55,  -91,   10, -110, -121,  -51,   -7,  -17,  -39, 0x00, 0x00, 0x00,
      57,  -30,  117, -123,  -21,   48,   51, -123,  118,   65,    8,   -8,   63, 0x00, 0x00, 0x00,
     -83,   22,   50,   10,  103,   -9,  101,  -94,  102,  122,   61,   65,  -63, 0x00, 0x00, 0x00,
     -58,  -52,  -13,   17,  105,   90,  121,  -29,   75,   -4,  114,   27,   51, 0x00, 0x00, 0x00,
      69,   65,   24,  -25,   17,  -44, -115,  -78,  -18,  100,  -39,   81,   -6, 0x00, 0x00, 0x00,
      97,   45, -117,  -53,  -24,    9,   31,  -23,   26,  -37,  -35,  -98,   76, 0x00, 0x00, 0x00,
      38,  -91,  -25,   48,  -59,  -77,   47,  -63,  -66,    1,  -20,   32,   47, 0x00, 0x00, 0x00
};

int weight_data[4][3][3] = {
    45, 91, -97, -28, 86, 3, -62, -25, -78,
    36, -21, 119, 93, 84, 90, 108, 89, -99,
    -56, 109, 109, -45, 73, 112, 92, -76, 50,
    70, 82, 122, 105, -84, 27, -120, -94, -15
};

inline int addSat(int val){
    if(val > 32767)
        val = 32767;
    else if(val < -32768)
        val = -32768;
    return val;
}

inline int calcConv3(int start_i_x, int start_i_y, int wCnt, int (*ifm)[16]){
    int wx_start = 0;
    int wx_end = 3;
    int wy_start = 0;
    int wy_end = 3;
    wx_start += padT;
    wy_start += padL;
    wx_end -= padB;
    wy_end -= padR;
    int res = 0;
    for(int i = wx_start; i < wx_end; i++){
        for(int j = wy_start; j < wy_end; j++){
            res += weight_data[wCnt][i][j] * ifm[start_i_x + (i - wx_start)][start_i_y + (j - wy_start)];
        }
    }

    // saturation
    // res = addSat(res);
    return res;
    //for(int i = start, i < )
}

inline int leakyReLU(int val){
    if(val >= 0)
        return val;

    else
        return ((val * 51) >> 9);
}

inline int requant(int val){
    return (((val - 14745) * 155) >> 16);
}

void DMA_process(int src_addr, int dest_addr, int src_config, int dest_config){
  asm("lui a5, 0x50000"); // dma_addr = 0x50000000
  
  asm("sw a0, 0(a5)"); // src_addr
  asm("sw a1, 4(a5)"); // dest_addr
  asm("sw a2, 8(a5)"); // src_config 
  asm("sw a3, 12(a5)"); // dest_config  
  
  asm("addi t0, x0, 1");
  asm("sw t0, 16(a5)"); // dma_en 
  return;
}

void DLA_process(int config_high, int config_low){
  int* DLA_config = 0x60000000;
  *(DLA_config+1) = config_high;

  *(DLA_config) = config_low;
  return;
}


int main(){

  int res[4][IFM_W_H][IFM_W_H];
  char fin_res[4][IFM_W_H][16];
  unsigned int *tmpTest = (int*)0x20003520;

  int QQ = 0;


  int dma_src_config_main = 0;
  int dma_dest_config_main = 0;
  // int* DLA_weight = 0x60300000;
  int* DMA_en = 0x50000010;
  // char* DLA_interrupt = 0x60000008;
  extern unsigned int _yolo_test_start[];
  // char* DLA_ofm = 0x60400000;

  // mantissa = 155, bias = 14745
  // int dla_config_high = 0x9B3999;

    for(int l = 0; l < 4; l++){
        for(int i = 0; i < IFM_W_H; i++){
            for(int j = 0; j < IFM_W_H; j++){
                padL = (j == 0);
                padR = (j == IFM_W_H - 1);
                padT = (i == 0);
                padB = (i == IFM_W_H - 1);
                int start_x = (i == 0) ? i : i - 1;
                int start_y = (j == 0) ? j : j - 1;
                // int start_x = (i == IFM_W_H - 1) ? i - 1 : i;
                // int start_y = (j == IFM_W_H - 1) ? j - 1 : j;
                res[l][i][j] = calcConv3(start_x, start_y, l, ifm_data0);
                res[l][i][j] = addSat(res[l][i][j]);
            }
        }
    }
    QQ += 1;

    for(int l = 0; l < 4; l++){
        for(int i = 0; i < IFM_W_H; i++){
            for(int j = 0; j < IFM_W_H; j++){
                padL = (j == 0);
                padR = (j == IFM_W_H - 1);
                padT = (i == 0);
                padB = (i == IFM_W_H - 1);
                int start_x = (i == 0) ? i : i - 1;
                int start_y = (j == 0) ? j : j - 1;
                // int start_x = (i == IFM_W_H - 1) ? i - 1 : i;
                // int start_y = (j == IFM_W_H - 1) ? j - 1 : j;
                res[l][i][j] += calcConv3(start_x, start_y, l, ifm_data1);
                res[l][i][j] = addSat(res[l][i][j]);
            }
        }
    }

    QQ += 1;
    for(int l = 0; l < 4; l++){
        for(int i = 0; i < IFM_W_H; i++){
            for(int j = 0; j < IFM_W_H; j++){
                padL = (j == 0);
                padR = (j == IFM_W_H - 1);
                padT = (i == 0);
                padB = (i == IFM_W_H - 1);
                int start_x = (i == 0) ? i : i - 1;
                int start_y = (j == 0) ? j : j - 1;
                // int start_x = (i == IFM_W_H - 1) ? i - 1 : i;
                // int start_y = (j == IFM_W_H - 1) ? j - 1 : j;
                res[l][i][j] += calcConv3(start_x, start_y, l, ifm_data2);
                res[l][i][j] = addSat(res[l][i][j]);
                res[l][i][j] = leakyReLU(res[l][i][j]);
                res[l][i][j] =    addSat(res[l][i][j]);
                fin_res[l][i][j] = requant(res[l][i][j]) & 0xff;
                // res[l][i][j] =    addSat(res[l][i][j]);
            }
        }
    }
    QQ += 1;

  // Call DMA to move all weight data from data mem to DLA  
  // stream mode, size=36(bytes)
  // dma_src_config_main = 0x90; 
  // // stream mode, size=36(bytes)
  // dma_dest_config_main = 0x90;
  // DMA_process(&weight_data, DLA_weight, dma_src_config_main, dma_dest_config_main);

  // asm("wfi");


  // --------------1st Channel--------------

  // Call DMA to move ifm0 from data mem to DLA 
  // size | mode = 208 | 0(stream mode)
  // {10000_0000000000_00011010000_00}
  // dma_src_config_main = 0x340; 
  // // row_stride | height | width | mode = 64 | 13 | 16 | 1(chunk mode)
  // // {0001000000_0000001101_0000010000_01}
  // dma_dest_config_main = 0x1000D041;
  // DMA_process(&ifm_data0, 0x60100000, dma_src_config_main, dma_dest_config_main);
  // asm("wfi");

  // // {1111_000_1111_01_1_10_001_001_00_001100_0_1}
  // DLA_process(dla_config_high, 0xF1EE2431);
  // asm("wfi");


  // // --------------2nd Channel--------------
  
  // // Call DMA to move ifm1 from data mem to DLA 
  // // size | mode = 208 | 0(stream mode)
  // dma_src_config_main = 0x340; 
  // // chunk mode, width=13(bytes), height=13(bytes), row stride = 64
  // dma_dest_config_main = 0x1000D041;
  // DMA_process(&ifm_data1, 0x60200000, dma_src_config_main, dma_dest_config_main);
  // asm("wfi");
  // //asm("wfi");
  // // {1111_000_1111_01_0_10_001_001_00_001100_1_1}
  // DLA_process(dla_config_high, 0xF1EA2433);
  // asm("wfi");


  // // --------------3rd Channel--------------
  
  
  // // Call DMA to move ifm2 from data mem to DLA 
  // // size | mode = 208 | 0(stream mode)
  // dma_src_config_main = 0x340; 
  // // chunk mode, width=13(bytes), height=13(bytes), row stride = 64
  // dma_dest_config_main = 0x1000D041;
  // DMA_process(&ifm_data2, 0x60100000, dma_src_config_main, dma_dest_config_main);

  // asm("wfi");
  
  // // {1111_101_1111_01_0_10_001_001_00_001100_0_1}
  // DLA_process(dla_config_high, 0xFBEA2431);
  // dla_busy = 1;
  
  // asm("wfi");
//  while((*DMA_en) || (dla_busy)){
//    //wait for DMA    
//  }
      // row_stride | height | width | mode = 128 | 13 | 16 | 1(chunk mode)
    // {1000000_0000110100_}

    
    // row_stride | height | width | mode = 16 | 13 | 16 | 1(chunk mode)
    dma_src_config_main = 0x0400D041;

//  row_stride = 16 | sizeHigh = 0 | sizeLow = 169 | mode = 0 (stream mode)
//   0000010000_0000000000_001010_1001_00
//   dma_src_config_main = 0x040002A4;

  // row_stride |      size      | mode = 0 | 208 | 0(stream mode)
  dma_dest_config_main = 0x340;
  for(int i=0; i<4; i++){
    DMA_process(fin_res[i], _yolo_test_start+i*52, dma_src_config_main, dma_dest_config_main);
    asm("wfi");
  }
    QQ += 1;
    *tmpTest = 0xefbeadde;


//  asm("wfi");
//

  return 0;
}
