//-----------------------------------------------------------------------------
// Title       : VRAM制御（受講者設計対象）
// Project     : display
// Filename    : disp_vramctrl.v
//-----------------------------------------------------------------------------
// Description :
// 
//-----------------------------------------------------------------------------
// Revisions   :
// Date        Version  Author        Description
// 201?/??/??  1.00     ???????????   Created
//-----------------------------------------------------------------------------

module disp_vramctrl
(
    // System Signals
    input           ACLK,
    input           ARST,

    // Read Address
    output  [31:0]  ARADDR,
    output          ARVALID,
    input           ARREADY,
    // Read Data 
    input           RLAST,
    input           RVALID,
    output          RREADY,

    /* 解像度切り替え */
    input   [1:0]   RESOL,

    /* 他ブロックからの信号 */
    input           VRSTART,   //syncgenより VRAM読み出し開始信号
    input           DISPON,    //disp_regctrl, disp_bufferより表示ON
    input   [28:0]  DISPADDR,  //disp_regctrlより表示開始のアドレスの下位２９ビット
    input           BUF_WREADY //disp_bufferより　FIFOへの書き込み可能
);

//AXIで各種信号をやり取りする Masterとして

//FIFOへ書き込み

endmodule
