//-----------------------------------------------------------------------------
// Title       : FIFO����щ摜�o�́i��u�Ґ݌v�Ώہj
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

/* �\���N���b�N�A���Z�b�g */
input               DCLK,
input               DRST,

/* FIFO�֘A�M�� */
input               DISPON,
input               FIFORST,
input   [63:0]      FIFOIN,
input               FIFOWR,
input               DSP_preDE,
output              BUF_WREADY,
output              BUF_OVER,
output              BUF_UNDER,

/* �摜�o�� */
output  reg [7:0]   DSP_R, DSP_G, DSP_B,
output  reg         DSP_DE
);

//�摜���͂̓�RGB��8bit*4���*2��f=64�������Ă���̂Ń���������48bit���`������
//�摜�o�͂�24bit�����ꂼ��RGB�ɐ؂蕪���Ă������񂷂�

//FIFO�֘A�M��
wire    [9:0] counter;
wire    RST = ARST | DRST | FIFORST;
wire    [23:0] dout;
//wire    [47:0] din = {FIFOIN[55:32], FIFOIN[23:0]};
wire    [47:0] din = {FIFOIN[23:0], FIFOIN[55:32]};
reg     [1:0] dsp_deff;

//wr_data_counter���������܂ꂽ���Ȃ�1024-counter��FIFO�c��T�C�Y���킩��͂�
//1�ŏ������݉\, 0�ŏ������ݕs�\
assign  BUF_WREADY = (12'd1024-counter >= 12'd256) ? 1 : 0;

//FIFO�ɐڑ����邪�g�p���Ȃ�
wire    full;
wire    empty;
wire    valid;

//DSP_DE
always @(posedge DCLK) begin
    dsp_deff <= {dsp_deff[0], DSP_preDE};
end
always @(posedge DCLK) begin
    DSP_DE <= dsp_deff[1];
end //DSP_DE
/* FIFO */
fifo_48in24out_1024depth fifo_48in24out_1024depth(
    .rst          (RST),
    .wr_clk       (ACLK),
    .rd_clk       (DCLK),
    .din          (din),
    .wr_en        (FIFOWR&DISPON),
    .rd_en        (DSP_preDE),
    .dout         (dout),
    .full         (full),
    .overflow     (BUF_OVER),
    .empty        (empty),
    .valid        (valid),
    .underflow    (BUF_UNDER),
    .wr_data_count(counter) //�������܂ꂽ���H�Ȃ�1024 - counter��FIFO�̎c��T�C�Y���킩��͂�
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
        else begin
            DSP_R <= 0;
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
        else begin
            DSP_G <= 0;
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
        else begin
            DSP_B <= 0;
        end
    end
end //DSP_B

endmodule
