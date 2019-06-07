//-----------------------------------------------------------------------------
// Title       : FIFOおよび画像出力（受講者設計対象）
// Project     : display
// Filename    : disp_buffer.v
//-----------------------------------------------------------------------------
// Description :
// 
//-----------------------------------------------------------------------------
// Revisions   :
// Date        Version  Author        Description
// 201?/??/??  1.00     ???????????   Created
//-----------------------------------------------------------------------------

module disp_buffer
  (
    // System Signals
    input               ACLK,
    input               ARST,

    /* 表示クロック、リセット */
    input               DCLK,
    input               DRST,

    /* FIFO関連信号 */
    input               DISPON,
    input               FIFORST,
    input   [63:0]      FIFOIN,
    input               FIFOWR,
    input               DSP_preDE,
    output              BUF_WREADY,
    output              BUF_OVER,
    output              BUF_UNDER,

    /* 画像出力 */
    output  reg [7:0]   DSP_R, DSP_G, DSP_B,
    output  reg         DSP_DE
    ); 


/* FIFO */
fifo_48in24out_1024depth fifo_48in24out_1024depth(
  .rst          (),
  .wr_clk       (),
  .rd_clk       (),
  .din          (),
  .wr_en        (),
  .rd_en        (),
  .dout         (),
  .full         (),
  .overflow     (),
  .empty        (),
  .valid        (),
  .underflow    (),
  .wr_data_count()
);

endmodule
