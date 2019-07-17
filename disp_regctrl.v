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
    output  reg [31:0]  RDATA,  //読み出しデータ

    /* レジスタ出力 */
    output  reg         DISPON,     //disp_vramctrl, disp_bufferへ、displayをONにする
    output  reg [28:0]  DISPADDR,   //disp_vramctrlへ、表示開始アドレスの下位29bit

    /* 割り込み、FIFOフラグ */
    output   reg        DSP_IRQ,    //VBLANKによる割込み信号
    input               BUF_UNDER,
    input               BUF_OVER
    ); 

/* 以下の記述は消去して一から作り直す */

// 出力信号の固定

//レジスタの値
reg INTENBL;
reg INTCLR;
reg VBLANK;
reg FIFOOVER;
reg FIFOUNDER;

//VBLANK用
reg preVSYNC;

//ARSTでVSYNCを同期化
reg [1:0] arst_vsync;
always @(posedge ACLK) begin
    arst_vsync <= {arst_vsync[0], DSP_VSYNC_X};
end

wire VSYNC = arst_vsync[1];

//書き込みに関する記述
//表示回路は0なのでWRADDRの上位4bitが0なら1を出力する
wire    write_reg  = WREN && WRADDR[15:12]==4'h0;

//DISPADDRレジスタ
//DISPADDRへの書き込み
//assign DISPADDR = (write_reg&WRADDR[11:0]==12'h000)? WDATA[27:0]:0;

always @(posedge ACLK) begin
    if(ARST) begin
        DISPADDR <= 0;
    end
    else if(write_reg&WRADDR[11:0]==12'h000) begin
        if(BYTEEN[0]) begin
            DISPADDR[7:0] <= WDATA[7:0];
        end
        if(BYTEEN[1]) begin
            DISPADDR[15:8] <= WDATA[15:8];
        end
        if(BYTEEN[2]) begin
            DISPADDR[23:16] <= WDATA[23:16];
        end
        if(BYTEEN[3]) begin
            DISPADDR[28:24] <= WDATA[28:24];
        end
    end
end

//ctrl_wr
//write_regの条件を満たしていてWRADDR[11:2]の最下位のみ1でBYTEEN4bitの最下位ビットが1ならcontrol_regが指定されたことになる
wire    ctrlreg_wr = write_reg && WRADDR[11:2]==10'h001 && BYTEEN[0];
// コントロールレジスタ（DISPCTRL）・・DISPON
always @( posedge ACLK ) begin
    if ( ARST ) begin
        DISPON <= 1'b0;
    end
    else if ( ctrlreg_wr ) begin
        DISPON <= WDATA[0];
    end
end

// コントロールレジスタ（DISPCTRL）・・VBLANK
//クロックに差があるのでVSYNCのposedgeを取得したい感ある
always @(posedge ACLK) begin
    if(ARST) begin
        preVSYNC <= 0;
    end
    else begin
        preVSYNC <= VSYNC;
    end
end
always @(posedge ACLK) begin
    if(ARST) begin
        VBLANK <= 0;
    end
    else if(ctrlreg_wr&WDATA[1]) begin
        VBLANK <= 0;
    end
    else if(!VSYNC&preVSYNC) begin
        VBLANK <= 1;
    end
end//VBLANK

//int_wr
wire    int_wr = write_reg && WRADDR[11:2]==12'h002 && BYTEEN[0];

//INTCLR
always @(posedge ACLK) begin
    if(ARST) begin
        INTCLR <= 0;
    end
    else if(int_wr) begin
        INTCLR <= WDATA[1];
    end
    else begin
        INTCLR <= 0;
    end
end
//INTENBL
always @(posedge ACLK) begin
    if(ARST) begin
        INTENBL <= 0;
    end
    else if(int_wr) begin
        INTENBL <= WDATA[0];
    end
end //INTENBL

//DSP_IRQ
always @(posedge ACLK) begin
    if(ARST) begin
        DSP_IRQ <= 0;
    end
    else if(!VSYNC&preVSYNC&INTENBL) begin
        DSP_IRQ <= 1;
    end
    else if(WDATA[1]&int_wr) begin
        DSP_IRQ <= 0;
    end
end

//fifo_wr
wire    fifo_wr = write_reg && WRADDR[11:2]==12'h003 && BYTEEN[0];

//FIFOOVER
always @(posedge ACLK) begin
    if(ARST) begin
        FIFOOVER <= 0;
    end
    else if(fifo_wr) begin
        if(WDATA[1]) begin
            FIFOOVER <= 0;  //1ならゼロクリア
        end
        else if(BUF_OVER) begin
            FIFOOVER <= 1;
        end
    end
end //FIFOOVER

//FIFOUNDER
always @(posedge ACLK) begin
    if(ARST) begin
        FIFOUNDER <= 0;
    end
    else if(fifo_wr) begin
        if(WDATA[0]) begin
            FIFOUNDER <= 0;  //1ならゼロクリア
        end
        else if(BUF_OVER) begin
            FIFOUNDER <= 1;
        end
    end
end


//以下読み出しに関する記述
wire    read_reg  = RDEN && RDADDR[15:12]==4'h0;

//RDATA
always @(posedge ACLK) begin
    if(ARST) begin
        RDATA <= 0;
    end
    else if(read_reg&RDADDR[11:0]==12'h000) begin
        RDATA <= {3'h0, DISPADDR};
    end
    else if(read_reg&RDADDR[11:2]==10'h001) begin
        RDATA <= {30'h000, VBLANK, DISPON};
    end
    else if(read_reg&RDADDR[11:2]==10'h002) begin
        RDATA <= {31'h000, INTENBL};
    end
    else if(read_reg&RDADDR[11:2]==10'h003) begin
        RDATA <= {30'h000, FIFOOVER, FIFOUNDER};
    end
    else begin
        RDATA <=0;
    end
end

endmodule
