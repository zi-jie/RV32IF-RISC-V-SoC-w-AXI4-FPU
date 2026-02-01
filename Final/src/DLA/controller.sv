// state: 

// IDLE_ : wait cpu enable

// CONV : do conv, pipeline, one output psum element per cycle / should know (0)op type conv/depth/pool/... (1)height/width (one of them or both?), (2)last channel, (3)first column?->to decide if DLA should move last 2 col to first 2 col
  //focus on PE_buffer loading--control addr and stall
  //input : both IFM and PE_buffer
  //compute component : pool->addr
  //output : psum buffer addr


//!
  ///////////////////////////////////////////to be discuss///////////////////////////////////
  // a interupt to CPU?
  // residual buffer use dubble buffer => save area and power, harder to implement 

//config
  /*
  SF => 16bits?
  height, width is tile height, width
  can only do 3*3 conv
  maybe can ignore => padding(fix to 1), stride(fix to 1), width(same as height)
  first_channel be used to rst reg
  kernel size => 0 for 1*1, 2 for 3*3
    | en    | buf_sel | height/width | ignore_column | padding | stride | kernel_size | first_channel | do_conv | do_Residual | top tile | left tile | buttom tile | right tile | do_ReLU | do_pool | do_Req | shift_bits | bias   | mantissa        
    | 1bits | 1bit    | 6bits        | 2bits         | 3bits   | 3bits  | 2bits       | 1bits         | 1bits   | 1bits       | 1bits    | 1bits     | 1bits       | 1bits      | 1bits   | 1bits   | 1bits  | 4bits      | 16bits | 16bits(?) 
    |0      |1        |2            7|8             9|10     12|13    15|16         17|18             |19       |20           |21        |22         |23           |24          |25       |26       |27      |28        31|32    47|48      63 
  whole pic : 216*216
  output x->54~108 y->0~53 (left tile high)
  IFM x~53~109 y ->0~54




  */

  //! remove it from pipeline
 
//define 
  `define DLA_EN      op_config[0]
  `define BUF_SEL     op_config[1]
  `define FIRST_CHAN  op_config[18]
  `define DO_CONV     op_config[19]
  `define DO_RESI     op_config[20]
  `define DO_RELU     op_config[25]
  `define DO_POOL     op_config[26]
  `define DO_REQU     op_config[27]
  `define IGNORE_COL  op_config[9:8]
  `define IFM_SIZE    op_config[7:2]  // actually output size
  `define KER_SIZE    op_config[17:16]
  `define TOP_TILE    op_config[21]
  `define LEFT_TILE   op_config[22]
  `define BOT_TILE    op_config[23]
  `define RIGHT_TILE  op_config[24]
  `define SHIFT_BITS  op_config[31:28]
  `define BIAS        op_config[47:32]
  `define MANTISSA    op_config[57:48]  //63:48, but only need 10 bits
  `ifdef DLA
        //                            bias   shift_b  P   r   l  Res first stri  ignore     buf
    `define DLA_CONF {6'h0,10'h9B,16'h3999,32'b1111_1_1_1_0_0_1_1_0_1_1_10_001_001_00_000111_0_1}
        //                    manti                 RQ  RL  b   t  con  ker    pad     h/w     en
  `else
    `define DLA_CONF 64'b0
  `endif
`include "../../include/peremeters.svh"
module controller #(
    //OP_STATE parameters
    parameter OP_IDLE        = 3'h0,
    parameter OP_CONV_1      = 3'h1, //1*1 conv
    parameter OP_CONV_3      = 3'h2, //3*3 conv
    parameter OP_CONV_3_POOL = 3'h3,
    parameter OP_REQ         = 3'h4, //requantise
    parameter OP_ADD         = 3'h5, //residual (may not used)
    //state
    parameter S_IDLE           = 3'h0,
    parameter S_load_PEbuf_fir = 3'h4,
    parameter S_load_PEbuf_sec = 3'h5,
    parameter S_load_PEbuf_thi = 3'h6,
    parameter S_conv           = 3'h7
  )(
    input clk,
    input rst,
    input [31:0]op_config_in,
    input [1:0]op_config_wen,
    input inpt_in,
    input inpt_wen,
    
    output buf_sel, //choose ifm bffer
    output do_LReLU,
    output do_pool,
    output do_RQ,

    output stall,
    output shift, //for pe_buf
    output pe_buf_rst,
    output first_channel,
    output [1:0] kerSize,

    output logic [9:0]IFM_r_addr,

    output logic [`IFM_SIZE_BITS-1:0]pe_buf_r_addr,
    output logic [`IFM_SIZE_BITS+1:0]pe_buf_w_addr,
    output logic [3:0]pe_buf_w_en,

    output logic [10:0]out_r_addr,
    output logic [10:0]out_w_addr,
    output logic [3:0]out_w_en,
    output logic psum_sel,
    output logic bottom_channel,
    output logic DLA_EN,
    output logic psum_buf_reset,
    output logic [5:0]outsize,

    output logic [4:0]pool_index,
    output logic dla_active,
    
    output logic [`HWORD - 1:0] bias,
    output logic [9:0] mantissa,
    output logic [3:0] shift_bits,

    output logic inpt
);
//layer config 
  //yiteng, op_config and inpt only need write
  logic [63:0]op_config ;
  assign kerSize = op_config[17:16];
  assign buf_sel = `BUF_SEL;
  assign do_LReLU = `DO_RELU;
  assign do_pool = `DO_POOL;
  assign do_RQ = `DO_REQU;

  assign first_channel = `FIRST_CHAN;
  assign mantissa = `MANTISSA;//`MANTISSA;
  assign shift_bits = `SHIFT_BITS;//`SHIFT_BITS;
  assign bias = `BIAS;//`BIAS;

//op
  logic op_done;
  logic [2:0] op_state;
  logic [2:0] op_next_state;

//control
  logic [5:0] ofm_x_pointer; //on output buffer
  logic [5:0] ofm_y_pointer; //on output buffer
  logic [5:0] load_pe_x_pointer; //addr for PE buffer(and IFM after some modified)
  logic [1:0] load_pe_y_pointer; //addr for PE buffer(and IFM after some modified)
  logic [5:0] ifm_x_pointer;
  logic [5:0] ifm_y_pointer;
  logic [5:0] ifm_y_pointer_buf;
  logic [2:0] state;
  logic [2:0] next_state;

  //conv3_pool
    logic [2:0] conv3_pool_op_next;
    logic conv3_pool_stall;
    logic conv3_pool_shift;
    logic conv3_pool_op_done;
    logic [3:0] conv3_pool_PE_wen ;
    logic [3:0] conv3_pool_out_wen ;

  //conv1
    logic [2:0] conv1_op_next;
    logic conv1_stall;
    logic conv1_shift;
    logic conv1_op_done;
    logic [3:0] conv1_PE_wen ;
    logic [3:0] conv1_out_wen ;

  //conv3
    logic [2:0] conv3_op_next;
    logic conv3_stall;
    logic conv3_shift;
    logic conv3_op_done;
    logic [3:0] conv3_PE_wen ;
    logic [3:0] conv3_out_wen ;

//wb_signals_pipeline
  logic op_done_in_mem1; 
  logic op_done_in_mem2; 
  logic op_done_in_mem3; 
  logic op_done_in_add1; 
  logic op_done_in_add2; 
  logic op_done_in_LReLU; 
  logic op_done_in_Requan1; 
  logic op_done_in_Requan2; 
  logic op_done_in_Requan3; 
  logic op_done_in_wb; 
  logic [3:0] out_w_en_in_mem1;
  logic [3:0] out_w_en_in_mem2;
  logic [3:0] out_w_en_in_mem3;
  logic [3:0] out_w_en_in_add1;
  logic [3:0] out_w_en_in_add2;
  logic [3:0] out_w_en_in_LReLU;
  logic [3:0] out_w_en_in_Requan1;
  logic [3:0] out_w_en_in_Requan2;
  logic [3:0] out_w_en_in_Requan3;
  logic [3:0] out_w_en_in_wb;
  logic [10:0] out_w_addr_in_mem1;
  logic [10:0] out_w_addr_in_mem2;
  logic [10:0] out_w_addr_in_mem3;
  logic [10:0] out_w_addr_in_add1;
  logic [10:0] out_w_addr_in_add2;
  logic [10:0] out_w_addr_in_LReLU;
  logic [10:0] out_w_addr_in_Requan1;
  logic [10:0] out_w_addr_in_Requan2;
  logic [10:0] out_w_addr_in_Requan3;
  logic [10:0] out_w_addr_in_wb;
  logic psum_sel_in_add1;
  logic psum_sel_in_add2;
  logic psum_sel_in_LReLU;
  logic psum_sel_in_Requan1;
  logic psum_sel_in_Requan2;
  logic psum_sel_in_Requan3;
  logic psum_sel_in_wb;
  logic psum_sel_in_mem1;
  logic psum_sel_in_mem2;
  logic psum_sel_in_mem3;

  assign op_done_in_mem1 = (op_state == OP_CONV_3)?          conv3_op_done : 
                           (op_state == OP_CONV_3_POOL)?     conv3_pool_op_done : 
                           (op_state == OP_CONV_1)? conv1_op_done : 1'h0 ; 
  assign out_w_en_in_mem1 = (op_state == OP_CONV_3)? conv3_out_wen : 
                           (op_state == OP_CONV_3_POOL)? conv3_pool_out_wen : 
                           (op_state == OP_CONV_1)? conv1_out_wen : 4'hf ;
  assign out_w_addr_in_mem1 = {ofm_y_pointer, ofm_x_pointer[5:1]};
  assign psum_sel_in_mem1 = ~ofm_x_pointer[0];
  assign bottom_channel = `BOT_TILE & (ifm_y_pointer_buf == (`IFM_SIZE+6'h2 - {5'h0, `TOP_TILE}));
  assign DLA_EN = `DLA_EN;
  assign psum_buf_reset = rst & (op_state != OP_IDLE);
  assign outsize = `IFM_SIZE;
  always_ff @( posedge clk /*or negedge rst*/) begin
    //initialize
    if(!rst) begin
      op_done_in_mem2 <= 1'h0;
      op_done_in_mem3 <= 1'h0;
      op_done_in_add1 <= 1'h0;
      op_done_in_add2 <= 1'h0;
      op_done_in_LReLU <= 1'h0;
      op_done_in_Requan1 <= 1'h0;
      op_done_in_Requan2 <= 1'h0;
      op_done_in_Requan3 <= 1'h0;
      op_done_in_wb <= 1'h0;
      out_w_en_in_mem2 <= 4'hf;
      out_w_en_in_mem3 <= 4'hf;
      out_w_en_in_add1 <= 4'hf;
      out_w_en_in_add2 <= 4'hf;
      out_w_en_in_LReLU <= 4'hf;
      out_w_en_in_Requan1 <= 4'hf;
      out_w_en_in_Requan2 <= 4'hf;
      out_w_en_in_Requan3 <= 4'hf;
      out_w_en_in_wb <= 4'hf;
      out_w_addr_in_mem2 <= 11'h0;
      out_w_addr_in_mem3 <= 11'h0;
      out_w_addr_in_add1 <= 11'h0;
      out_w_addr_in_add2 <= 11'h0;
      out_w_addr_in_LReLU <= 11'h0;
      out_w_addr_in_Requan1 <= 11'h0;
      out_w_addr_in_Requan2 <= 11'h0;
      out_w_addr_in_Requan3 <= 11'h0;
      out_w_addr_in_wb <= 11'h0;
      psum_sel_in_mem2   <= 1'h0;
      psum_sel_in_mem3   <= 1'h0;
      psum_sel_in_add1   <= 1'h0;
      psum_sel_in_add2   <= 1'h0;
      psum_sel_in_LReLU  <= 1'h0;
      psum_sel_in_Requan1 <= 1'h0;
      psum_sel_in_Requan2 <= 1'h0;
      psum_sel_in_Requan3 <= 1'h0;
    end
    else begin
      if(!stall)begin
        op_done_in_mem2 <= op_done_in_mem1;
        op_done_in_mem3 <= op_done_in_mem2;
        op_done_in_add1 <= op_done_in_mem3;
        op_done_in_add2 <= op_done_in_add1;
        op_done_in_LReLU <= op_done_in_add2;
        op_done_in_Requan1 <= op_done_in_LReLU;
        op_done_in_Requan2 <= op_done_in_Requan1;
        op_done_in_Requan3 <= op_done_in_Requan2;
        op_done_in_wb <= op_done_in_Requan3;
        out_w_en_in_mem2 <= out_w_en_in_mem1;
        out_w_en_in_mem3 <= out_w_en_in_mem2;
        out_w_en_in_add1 <= out_w_en_in_mem3;
        out_w_en_in_add2 <= out_w_en_in_add1;
        out_w_en_in_LReLU <= out_w_en_in_add2;
        out_w_en_in_Requan1 <= out_w_en_in_LReLU;
        out_w_en_in_Requan2 <= out_w_en_in_Requan1;
        out_w_en_in_Requan3 <= out_w_en_in_Requan2;
        out_w_en_in_wb <= out_w_en_in_Requan3;
        out_w_addr_in_mem2 <= out_w_addr_in_mem1;
        out_w_addr_in_mem3 <= out_w_addr_in_mem2;
        out_w_addr_in_add1 <= out_w_addr_in_mem3;
        out_w_addr_in_add2 <= out_w_addr_in_add1;
        out_w_addr_in_LReLU <= out_w_addr_in_add2;
        out_w_addr_in_Requan1 <= out_w_addr_in_LReLU;
        out_w_addr_in_Requan2 <= out_w_addr_in_Requan1;
        out_w_addr_in_Requan3 <= out_w_addr_in_Requan2;
        out_w_addr_in_wb <= out_w_addr_in_Requan3;
        psum_sel_in_mem2   <= psum_sel_in_mem1;
        psum_sel_in_mem3   <= psum_sel_in_mem2;
        psum_sel_in_add1   <= psum_sel_in_mem3;
        psum_sel_in_add2   <= psum_sel_in_add1;
        psum_sel_in_LReLU  <= psum_sel_in_add2;
        psum_sel_in_Requan1 <= psum_sel_in_LReLU;
        psum_sel_in_Requan2 <= psum_sel_in_Requan1;
        psum_sel_in_Requan3 <= psum_sel_in_Requan2;
        psum_sel_in_wb     <= psum_sel_in_Requan3;
      end
      else begin
        op_done_in_mem2 <= op_done_in_mem2;
        op_done_in_mem3 <= op_done_in_mem3;
        op_done_in_add1 <= op_done_in_add1;
        op_done_in_add2 <= op_done_in_add2;
        op_done_in_LReLU <= op_done_in_LReLU;
        op_done_in_Requan1 <= op_done_in_Requan1;
        op_done_in_Requan2 <= op_done_in_Requan2;
        op_done_in_Requan3 <= op_done_in_Requan3;
        op_done_in_wb <= op_done_in_wb;
        out_w_en_in_mem2 <= out_w_en_in_mem2;
        out_w_en_in_mem3 <= out_w_en_in_mem3;
        out_w_en_in_add1 <= out_w_en_in_add1;
        out_w_en_in_add2 <= out_w_en_in_add2;
        out_w_en_in_LReLU <= out_w_en_in_LReLU;
        out_w_en_in_Requan1 <= out_w_en_in_Requan1;
        out_w_en_in_Requan2 <= out_w_en_in_Requan2;
        out_w_en_in_Requan3 <= out_w_en_in_Requan3;
        out_w_en_in_wb <= out_w_en_in_wb;
        out_w_addr_in_mem2 <= out_w_addr_in_mem2;
        out_w_addr_in_mem3 <= out_w_addr_in_mem3;
        out_w_addr_in_add1 <= out_w_addr_in_add1;
        out_w_addr_in_add2 <= out_w_addr_in_add2;
        out_w_addr_in_LReLU <= out_w_addr_in_LReLU;
        out_w_addr_in_Requan1 <= out_w_addr_in_Requan1;
        out_w_addr_in_Requan2 <= out_w_addr_in_Requan2;
        out_w_addr_in_Requan3 <= out_w_addr_in_Requan3;
        out_w_addr_in_wb <= out_w_addr_in_wb;
        psum_sel_in_mem2 <= psum_sel_in_mem2;
        psum_sel_in_mem3 <= psum_sel_in_mem3;
        psum_sel_in_add1   <=  psum_sel_in_add1;
        psum_sel_in_add2   <=  psum_sel_in_add2;
        psum_sel_in_LReLU  <=  psum_sel_in_LReLU;
        psum_sel_in_Requan1 <=  psum_sel_in_Requan1;
        psum_sel_in_Requan2 <=  psum_sel_in_Requan2;
        psum_sel_in_Requan3 <=  psum_sel_in_Requan3;
        psum_sel_in_wb     <=  psum_sel_in_wb;
      end
    end  
  end

//cntl  assignment
  assign pe_buf_rst = (op_state == OP_IDLE);
  assign stall  = (op_state == OP_CONV_3)?          conv3_stall : 
                  (op_state == OP_CONV_3_POOL)?     conv3_pool_stall : 
                  (op_state == OP_CONV_1)? conv1_stall : 1'h0 ;
  assign shift  = (op_state == OP_CONV_3)?          conv3_shift : 
                  (op_state == OP_CONV_3_POOL)?     conv3_pool_shift : 
                  (op_state == OP_CONV_1)? conv1_shift : 1'h0 ;
  assign op_done = (op_state == OP_CONV_3)?          conv3_op_done : 
                   (op_state == OP_CONV_3_POOL)?     conv3_pool_op_done : 
                   (op_state == OP_CONV_1)? conv1_op_done : 1'h0 ; 

logic [32:0]cnt;
//layer config & inpt
    always_ff @( posedge clk /*or negedge rst*/) begin
      //initialize
      if(!rst) begin
        //                            bias   shift_b  P   r   l  Res first stri  ignore     buf
        //op_config <= 64'b0;
        op_config <= `DLA_CONF;
        //                    manti                 RQ  RL  b   t  con  ker    pad     h/w     en
        inpt <= 1'h0;
        cnt <= 0;
        dla_active <= 1'h0;
      end
      // else if(inpt && (cnt == 0) ) begin
        // //                            bias   shift_b  P   r   l  Res first stri  ignore     buf
        // op_config <= {6'h0,10'h10,16'h1000,32'b1100_1_1_0_1_1_1_1_0_1_0_10_001_001_00_001000_1_1}; //disable first channel
        // //                    manti                 RQ  RL  b   t  con  ker    pad     h/w     en
        // inpt <= 1'h0;  
        // cnt <= cnt + 1;
      // end
      else begin
        //dla_active
        if(DLA_EN) dla_active <= 1'h1;
        else if(op_done_in_wb) dla_active <= 1'b0;

        //op_config
        if(op_config_wen[0])begin
          op_config[31:0] <= op_config_in;
        end
        else if(op_config_wen[1])begin
          op_config[63:32] <= op_config_in;
        end
        //inpt
        else begin
          if(op_done_in_wb) inpt <= 1'h1;
          else if(inpt_wen) inpt <= inpt_in;
        end
        if(op_state != OP_IDLE) `DLA_EN <= 1'h0; // turn off the enable
      end  
    end

//x,y_pointer
  //ofm and pe_buf_read
    always_ff @( posedge clk /*or negedge rst*/) begin
      //initialize
      if(!rst) begin
        ofm_x_pointer <= 6'h0;
        ofm_y_pointer <= 6'h0;
      end
      else if(state == S_IDLE) begin
        ofm_x_pointer <= 6'h0;
        ofm_y_pointer <= 6'h0;
      end
      else if(stall)begin
        ofm_x_pointer <= ofm_x_pointer;
        ofm_y_pointer <= ofm_y_pointer;
      end 
      else if((ofm_x_pointer == `IFM_SIZE + 6'h1 ))begin
        ofm_x_pointer <= 6'h0;
        ofm_y_pointer <= ofm_y_pointer + 6'h1;
      end  
      else begin
        ofm_x_pointer <= ofm_x_pointer + 6'h1;
        ofm_y_pointer <= ofm_y_pointer;
      end  
    end

  //pe_buf_write and ifm
    always_ff @( posedge clk /*or negedge rst*/) begin
      //initialize
      if(!rst) begin
        load_pe_x_pointer <= {5'h0, `LEFT_TILE};
        ifm_y_pointer <= 6'h0;
        ifm_y_pointer_buf <= 6'h0;
      end
      else if(state == S_IDLE) begin
        load_pe_x_pointer <= {5'h0, `LEFT_TILE};
        ifm_y_pointer <= 6'h0;
        ifm_y_pointer_buf <= ifm_y_pointer;
      end
      else if((ifm_x_pointer + 6'h2 < `IFM_SIZE))begin
        load_pe_x_pointer <= load_pe_x_pointer + 6'h4;
        ifm_y_pointer <= ifm_y_pointer;
        ifm_y_pointer_buf <= ifm_y_pointer;
      end 
      else if((load_pe_y_pointer != 2'h3)|shift)begin
        load_pe_x_pointer <= {5'h0, `LEFT_TILE};
        ifm_y_pointer <= ifm_y_pointer + 6'h1;
        ifm_y_pointer_buf <= ifm_y_pointer;
      end  
      else  begin
        load_pe_x_pointer <= load_pe_x_pointer;
        ifm_y_pointer <= ifm_y_pointer;
        ifm_y_pointer_buf <= ifm_y_pointer;
      end
    end
    assign load_pe_y_pointer = state[1:0];
    assign ifm_x_pointer = load_pe_x_pointer - {5'h0, `LEFT_TILE};

//op state
  always_ff @( posedge clk /*or negedge rst*/) begin
    //initialize
    if(!rst) begin
      op_state <= OP_IDLE;
    end
    else if(op_done)begin
      op_state <= OP_IDLE;
    end  
    else if(`DLA_EN)begin
      op_state <= op_next_state;
    end  
  end
  assign op_next_state = (`DO_CONV)? 
                          ((`KER_SIZE == 0)? OP_CONV_1 : 
                            (`DO_POOL)? OP_CONV_3_POOL : OP_CONV_3):
                          (`DO_RESI)? OP_ADD : OP_IDLE;

//state
  always_ff @( posedge clk /*or negedge rst*/) begin
    //initialize
    if(!rst) begin
      state <= S_IDLE;
    end
    else begin
      state <= next_state;
    end  
  end

  always_comb begin
    unique case (op_state)
      OP_IDLE:        next_state = S_IDLE;
      OP_CONV_3:      next_state = conv3_op_next;
      OP_CONV_1:      next_state = conv1_op_next;
      OP_CONV_3_POOL: next_state = conv3_pool_op_next;
      default:        next_state = S_IDLE;
    endcase
  end

//conv1 state
  always_comb begin
    unique case (state)
      S_IDLE:           conv1_op_next = S_load_PEbuf_fir;
      S_load_PEbuf_fir: conv1_op_next = (ifm_x_pointer + 6'h2 < `IFM_SIZE)? S_load_PEbuf_fir : S_load_PEbuf_sec;
      S_load_PEbuf_sec: conv1_op_next = (ifm_x_pointer + 6'h2 < `IFM_SIZE)? S_load_PEbuf_sec : S_load_PEbuf_thi;
      S_load_PEbuf_thi: conv1_op_next = (ifm_x_pointer + 6'h2 < `IFM_SIZE)? S_load_PEbuf_thi : S_conv;
      S_conv:           conv1_op_next = (ofm_y_pointer     < `IFM_SIZE + 6'h1)? S_conv : S_IDLE;
      default: conv1_op_next = 3'h0;
    endcase
      conv1_PE_wen = ((state == S_IDLE)|(state==S_conv && (ifm_y_pointer > (`IFM_SIZE+6'h2))))? 4'h0:
                      (ifm_x_pointer + 6'h2 < `IFM_SIZE)?4'hf : 4'hf >> ((ifm_x_pointer + 6'h2 - `IFM_SIZE ) % 4);
  end

  assign conv1_stall   = (state != S_conv);
  assign conv1_shift   = (ofm_x_pointer == `IFM_SIZE + 6'h1); // push up PE windows
  assign conv1_op_done = (ofm_y_pointer >= `IFM_SIZE + 6'h1);
  assign conv1_out_wen = (state != S_conv | ofm_x_pointer == `IFM_SIZE + 6'h1 | ofm_y_pointer == `IFM_SIZE + 6'h1)? 4'hf: 
                         (!`DO_REQU)? 
                            ((ofm_x_pointer[0])? 4'b0011 : 4'b1100):
                             ~(4'b0001 << ofm_x_pointer[1:0]);//DO_RQ


//conv3 state

  always_comb begin
    unique case (state)
      S_IDLE:           conv3_op_next = (`TOP_TILE)? S_load_PEbuf_sec : S_load_PEbuf_fir;
      S_load_PEbuf_fir: conv3_op_next = (ifm_x_pointer + 6'h2 < `IFM_SIZE)? S_load_PEbuf_fir : S_load_PEbuf_sec;
      S_load_PEbuf_sec: conv3_op_next = (ifm_x_pointer + 6'h2 < `IFM_SIZE)? S_load_PEbuf_sec : S_load_PEbuf_thi;
      S_load_PEbuf_thi: conv3_op_next = (ifm_x_pointer + 6'h2 < `IFM_SIZE)? S_load_PEbuf_thi : S_conv;
      S_conv:           conv3_op_next = (ofm_y_pointer     < `IFM_SIZE + 6'h1)? S_conv : S_IDLE;
      default: conv3_op_next = 3'h0;
    endcase
    

    //mem_addr
      //PE_buf
      conv3_PE_wen = ((state == S_IDLE)|(state==S_conv && (ifm_y_pointer > (`IFM_SIZE+6'h2))))? 4'h0:
                     (ifm_x_pointer + {5'h0,`LEFT_TILE} + {5'h0,`RIGHT_TILE} + 6'h1 < `IFM_SIZE)?4'hf : 
                     4'hf >> ((ifm_x_pointer - `IFM_SIZE + 6'h1 + {5'h0,`LEFT_TILE} + {5'h0,`RIGHT_TILE}) % 4);
  end

  assign conv3_stall   = (state != S_conv);
  assign conv3_shift   = (ofm_x_pointer == `IFM_SIZE + 6'h1); // push up PE windows
  assign conv3_op_done = (ofm_y_pointer >= `IFM_SIZE + 6'h1);
  assign conv3_out_wen = (state != S_conv | ofm_x_pointer == `IFM_SIZE + 6'h1 | ofm_y_pointer == `IFM_SIZE + 6'h1)? 4'hf: 
                         (!`DO_REQU)? 
                           ((ofm_x_pointer[0])? 4'b0011 : 4'b1100):
                           ~(4'b0001 << ofm_x_pointer[1:0]);//DO_RQ

//conv3_pool state

  always_comb begin
    unique case (state)
      S_IDLE:           conv3_pool_op_next = (`TOP_TILE)? S_load_PEbuf_sec : S_load_PEbuf_fir;
      S_load_PEbuf_fir: conv3_pool_op_next = (ifm_x_pointer + 6'h2 < `IFM_SIZE)? S_load_PEbuf_fir : S_load_PEbuf_sec;
      S_load_PEbuf_sec: conv3_pool_op_next = (ifm_x_pointer + 6'h2 < `IFM_SIZE)? S_load_PEbuf_sec : S_load_PEbuf_thi;
      S_load_PEbuf_thi: conv3_pool_op_next = (ifm_x_pointer + 6'h2 < `IFM_SIZE)? S_load_PEbuf_thi : S_conv;
      S_conv:           conv3_pool_op_next = (ofm_y_pointer     < `IFM_SIZE + 6'h1)? S_conv : S_IDLE;
      default: conv3_pool_op_next = 3'h0;
    endcase
    

    //mem_addr
      //PE_buf
      conv3_pool_PE_wen = ((state == S_IDLE)|(state==S_conv && (ifm_y_pointer > (`IFM_SIZE+6'h2))))? 4'h0:
                          (ifm_x_pointer + {5'h0,`LEFT_TILE} + {5'h0,`RIGHT_TILE} + 6'h1 < `IFM_SIZE)?4'hf : 
                          4'hf >> ((ifm_x_pointer - `IFM_SIZE + 6'h1 + {5'h0,`LEFT_TILE} + {5'h0,`RIGHT_TILE}) % 4);
  end

  assign conv3_pool_stall   = (state != S_conv);
  assign conv3_pool_shift   = (ofm_x_pointer == `IFM_SIZE + 6'h1);
  assign conv3_pool_op_done = (ofm_y_pointer >= `IFM_SIZE + 6'h1);
  assign conv3_pool_out_wen = (state != S_conv | ofm_x_pointer == `IFM_SIZE + 6'h1 | !ofm_x_pointer[0] | !ofm_y_pointer[0])? 4'hf: 
                         (!`DO_REQU)? 
                           ((ofm_x_pointer[1])? 4'b0011 : 4'b1100):
                           ~(4'b0001 << ofm_x_pointer[2:1]);//DO_RQ

//addr
  //IFM
  assign IFM_r_addr = {ifm_y_pointer,ifm_x_pointer[5:2]};

  //PE
  always_ff @( posedge clk /*or negedge rst*/) begin
    //initialize
    if(!rst) begin
      pe_buf_r_addr <= 6'h0;
      pe_buf_w_addr <= 8'h0;
      pe_buf_w_en <= 4'h0;
    end
    else begin
      pe_buf_r_addr <= ofm_x_pointer + {4'h0,`IGNORE_COL};
      pe_buf_w_addr <= {load_pe_y_pointer, load_pe_x_pointer};
      pe_buf_w_en <= (op_state == OP_CONV_3)?          conv3_PE_wen : 
                       (op_state == OP_CONV_3_POOL)?     conv3_pool_PE_wen : 
                       (op_state == OP_CONV_1)? conv1_PE_wen : 4'h0 ;
    end  
  end

  //OFM
  assign out_r_addr = out_w_addr_in_mem3;
  assign out_w_addr = (`DO_POOL & !`DO_REQU )? {1'h0,out_w_addr_in_wb[10:6], 1'h0, out_w_addr_in_wb[4:1]} : 
                      (`DO_POOL & `DO_REQU  )? {1'h0,out_w_addr_in_wb[10:6], 2'h0, out_w_addr_in_wb[4:2]} : //!
                      (!`DO_POOL & `DO_REQU )? {out_w_addr_in_wb[10:5], 1'h0, out_w_addr_in_wb[4:1]} :
                      out_w_addr_in_wb; //`!DO_POOL & `!DO_RELU
  assign out_w_en   = out_w_en_in_wb;
  assign psum_sel = psum_sel_in_add1;
  assign pool_index = out_w_addr_in_wb[4:0];
  
endmodule
