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
assign DSP_IRQ  = 1'b0;

//レジスタの値
reg INTENBL;

//表示回路は0なのでWRADDRの上位4bitが0なら1を出力する
wire    write_reg  = WREN && WRADDR[15:12]==4'h0;

//DISPADDRレジスタ
//DISPADDRへの書き込み
assign DISPADDR = (write_reg&WRADDR[11:2]&WRADDR[11:0]==12'h000)? WDATA[27:0]:0;

//ctrl_wr
//write_regの条件を満たしていてWRADDR[11:2]の最下位のみ1でBYTEEN4bitの最下位ビットが1ならcontrol_regが指定されたことになる
wire    ctrlreg_wr = (write_reg && WRADDR[11:2]==10'h001 && BYTEEN==2'b00);
// コントロールレジスタ（DISPCTRL）・・DISPON
always @( posedge ACLK ) begin
    if ( ARST )
        DISPON <= 1'b0;
    else if ( ctrlreg_wr )
        DISPON <= WDATA[0];
end
// コントロールレジスタ（DISPCTRL）・・VBLANK

//int_wr
wire    int_wr = write_reg && WRADDR[11:3]==12'h001 && BYTEEN==2'b00;

always @(posedge ACLK) begin
    if(ARST)
        INTENBL <= 0;
    end
    else if(int_wr)
        INTENBL <= WDATA[0];
end
endmodule
