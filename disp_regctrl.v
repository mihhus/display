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
    input               DSP_VSYNC_X,

    /* レジスタバス */
    input       [15:0]  WRADDR,
    input       [3:0]   BYTEEN,
    input               WREN,
    input       [31:0]  WDATA,
    input       [15:0]  RDADDR,
    input               RDEN,
    output      [31:0]  RDATA,

    /* レジスタ出力 */
    output  reg         DISPON,
    output      [28:0]  DISPADDR,

    /* 割り込み、FIFOフラグ */
    output              DSP_IRQ,
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
