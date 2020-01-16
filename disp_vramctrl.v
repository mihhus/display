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

    // Read Address, アドレス渡し
    output  [31:0]  ARADDR,
    output          ARVALID,
    input           ARREADY,
    // Read Data, データ渡しここがRREADYになってるとFIFOにデータが書き込まれる
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

    reg [3:0] CUR;
    reg [3:0] NXT;

    reg [15:0] COUNT;

//1画面が終了するまでのトランザクション数
//各解像度の時の画素数/8(１トランザクションで送れる画素数)=必要なトランザクション数+1してる
//ステートレジスタの比較うんぬんの兼ね合いでWATCH_DOGSが１増えている必要がある
//RESOL==0 VGA, RESOL==1 XGA, RESOL==2 SXGA
    wire    [15:0] WATCH_DOGS = (RESOL==2'b00)? 16'h12C1:(RESOL==2'b01)?16'h3001:16'h5001; //16'd4800, 786432, 1310720
//1トランザクション毎のアドレスの進み方
    wire    [8:0] STEP = 9'h100;
//ステート名定義
parameter S_IDLE = 4'b0001, S_SETADDR = 4'b0010, S_READ = 4'b0100, S_WAIT = 4'b1000;

//ARチャネルの送信側
//ARADDR 8*32=256が1トランザクションなので
assign ARADDR = COUNT*STEP+DISPADDR;

//ARVALID
assign ARVALID = (CUR==S_SETADDR) ? 1 : 0;

//ステートレジスタ
always @(posedge ACLK) begin
    if(ARST) begin
        CUR <= S_IDLE;
    end
    else begin
        CUR <= NXT;
    end
end //CUR

//NXT
always @* begin
    case(CUR)
        S_IDLE: if(VRSTART) begin   //待機
                    NXT <= S_SETADDR;
                end
                else begin
                    NXT <= S_IDLE;
                end
        S_SETADDR: if(ARREADY) begin    //ARチャネルにアドレスを発行
                        NXT <= S_READ;
                    end
                    else begin
                        NXT <= S_SETADDR;
                    end
        S_READ: if(RLAST&RVALID) begin  //VRAMを読み出し、FIFOにつく
                    if(COUNT==WATCH_DOGS-1) begin//一画面分終了したらS_IDLEに戻る, カウンタが必要
                        NXT <= S_IDLE;
                    end
                    else if(BUF_WREADY) begin   //バッファに余裕があればS_SETADDRに移動
                        NXT <= S_SETADDR;
                    end
                    else begin  //一画面分終了しておらず，バッファに余裕がなければS_WAITに移動
                        NXT <= S_WAIT;
                    end
                end
                else begin
                    NXT <=S_READ;
                end
        S_WAIT: if(BUF_WREADY) begin
                    NXT <= S_SETADDR;
                end
                else begin
                    NXT <= S_WAIT;
                end
        default:
            NXT <= S_IDLE;
    endcase
end //NXT;

//RREADY
assign RREADY = (CUR==S_READ&!ARST) ? 1 : 0;

//COUNT
always @(posedge ACLK) begin
    if(ARST) begin
        COUNT <= 0;
    end
    else if(CUR==S_SETADDR&ARREADY) begin
        COUNT <= COUNT + 1;
    end
    else if(COUNT==WATCH_DOGS&CUR==S_IDLE) begin
        COUNT <= 0;
    end
end//COUNT
endmodule
