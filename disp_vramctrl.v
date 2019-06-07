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

    reg [3:0] state_reg;
    reg [3:0] state_generator;

//ステート名定義
parameter S_IDLE = 4'b0001, S_SETADDR = 4'b0010, S_READ = 4'b0100, S_WAIT = 4'b1000;

//VGAの時の画素数/8(１トランザクションで送れる画素数)
parameter watch_dogs = 16'h9600; //16'd38400

//ステートレジスタ
always @(posedge ACLK) begin
    if(ARST) begin
        state_reg <= S_IDLE;
    end
    else
        state_reg <= state_generator;
    begin
end //state_reg

//state_generator
always @* begin
    case(state_reg)
        S_IDLE: if(VRSTART) begin
                    state_generator <= S_SETADDR;
                end
        S_SETADDR:

        S_READ: if(RLAST&RREADY) begin
                    if(counter==watch_dogs) //一画面分終了したらS_IDLEに戻る, カウンタが必要
                        state_generator <= S_IDLE;
                    end
                    else if(BUF_WREADY) begin
                        state_generator <= S_SETADDR;
                    end
                    else begin
                        state_generator <= S_WAIT;
                    end
                end
        S_WAIT: if(BUF_WREADY) begin
                    state_generator <= S_SETADDR;
                end
        default:
            state_generator <= S_IDLE;
    endcase
end //state_generator;

//counter
always @* begin
    if(ACLK) begin
        counter <= 0;
    end
    else if(state_reg==S_SETADDR/*S_SETADDR->S_READになる条件と同じものを書く*/) begin
        counter <= counter + 1;
    end
end//counter


//ARADDR
always @(posedge ACLK) begin
    if(ARST==1) begin
        ARADDR <= 0;
    end
    else begin

    end
end //ARADDR
endmodule
