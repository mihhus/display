//-----------------------------------------------------------------------------
// Title       : レジスタ制御（受講者設計対象）
// Project     : display
// Filename    : disp_regctrl.v
//-----------------------------------------------------------------------------
// Description :
// 
//-----------------------------------------------------------------------------
// Revisions   :
// Date        Version  Author        Description
// 201?/??/??  1.00     ???????????   Created
//-----------------------------------------------------------------------------

module disp_regctrl
  (
    // System Signals
    input               ACLK,
    input               ARST,

    /* VSYNC */
    input               DSP_VSYNC_X, //syncgenよりV方向のSync

    /* レジスタバス */
    input       [15:0]  WRADDR, //上位4bitで自ブロックに対する書き込み化を判断し、下位12bitでレジスタを選択する
    input       [3:0]   BYTEEN, //バイト単位での書き込みイネーブル
    input               WREN,   //書き込みイネーブル
    input       [31:0]  WDATA,  //書き込みデータ
    input       [15:0]  RDADDR, //4bitで自ブロックに対する読み出しか否かを判断し、下位12bitでレジスタを選択する
    input               RDEN,   //読み出しイネーブル
    output      [31:0]  RDATA,  //読み出しデータ

    /* レジスタ出力 */
    output  reg         DISPON,     //disp_vramctrl, disp_bufferへ、displayをONにする
    output      [28:0]  DISPADDR,   //disp_vramctrlへ、表示開始アドレスの下位29bit

    /* 割り込み、FIFOフラグ */
    output              DSP_IRQ,    //VBLANKによる割込み信号
    input               BUF_UNDER,
    input               BUF_OVER
    ); 

/* 以下の記述は消去して一から作り直す */

// 出力信号の固定
assign RDATA    = 32'b0;
assign DISPADDR = 29'h0;
assign DSP_IRQ  = 1'b0;

wire    write_reg  = WREN && WRADDR[15:12]==4'h0;
wire    ctrlreg_wr = (write_reg && WRADDR[11:2]==10'h001 && BYTEEN[0]);

// コントロールレジスタ（DISPCTRL）・・DISPON
always @( posedge ACLK ) begin
    if ( ARST )
        DISPON <= 1'b0;
    else if ( ctrlreg_wr )
        DISPON <= WDATA[0];
end

endmodule
