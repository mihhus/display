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


//画像入力はαRGBの8bit*4種類*2画素=64が送られてくるのでαを除いて48bitを形成する
//画像出力は24bitをそれぞれRGBに切り分けてそうしんする

//FIFO関連信号
wire    [10:0] counter;
wire    rst = ARST | DRST | FIFORST;
wire    [23:0] dout;
wire    [47:0] din = {FIFOIN[55:32] + FIFOIN[23:0]};

//wr_data_counterが書き込まれた数なら1024-counterでFIFO残りサイズがわかるはず
assign  BUF_WREADY = (10'h400-counter >= 256) ? 1 : 0;

//FIFOに接続するが使用しない
wire    full;
wire    over;
wire    empty;
wire    vaild;

//DSP_DE
always @* begin
    DSP_DE <= DSP_preDE;
end //DSP_DE
/* FIFO */
fifo_48in24out_1024depth fifo_48in24out_1024depth(
    .rst          (rst),
    .wr_clk       (ACLK),
    .rd_clk       (DCLK),
    .din          (din),
    .wr_en        (FIFOWR),
    .rd_en        (DSP_preDE),
    .dout         (dout),
    .full         (full),
    .overflow     (BUF_OVER),
    .empty        (empty),
    .valid        (valid),
    .underflow    (BUF_UNDER),
    .wr_data_count(counter) //書き込まれた数？なら1024 - counterでFIFOの残りサイズがわかるはず
);

//DSP_R
always @(posedge DCLK) begin
    if(DRST==1) begin
        DSP_R <= 0;
    end
    else begin
        if(DISPON) begin
            DSP_R <= dout[23:16];
        end
    end
end //DSP_R

//DSP_G
always @(posedge DCLK) begin
    if(DRST==1) begin
        DSP_G <= 0;
    end
    else begin
        if(DISPON) begin
            DSP_G <= dout[15:8];
        end
    end
end //DSP_G

//DSP_B
always @(posedge DCLK) begin
    if(DRST==1) begin
        DSP_B <= 0;
    end
    else begin
        if(DISPON) begin
            DSP_B <= dout[7:0];
        end
    end
end //DSP_B

endmodule
