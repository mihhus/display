//-----------------------------------------------------------------------------
// Title       : ���W�X�^����i��u�Ґ݌v�Ώہj
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
    input               DSP_VSYNC_X, //syncgen���V������Sync

    /* ���W�X�^�o�X */
    input       [15:0]  WRADDR, //���4bit�Ŏ��u���b�N�ɑ΂��鏑�����݉��𔻒f���A����12bit�Ń��W�X�^��I������
    input       [3:0]   BYTEEN, //�o�C�g�P�ʂł̏������݃C�l�[�u��
    input               WREN,   //�������݃C�l�[�u��
    input       [31:0]  WDATA,  //�������݃f�[�^
    input       [15:0]  RDADDR, //4bit�Ŏ��u���b�N�ɑ΂���ǂݏo�����ۂ��𔻒f���A����12bit�Ń��W�X�^��I������
    input               RDEN,   //�ǂݏo���C�l�[�u��
    output      [31:0]  RDATA,  //�ǂݏo���f�[�^

    /* ���W�X�^�o�� */
    output  reg         DISPON,     //disp_vramctrl, disp_buffer�ցAdisplay��ON�ɂ���
    output      [28:0]  DISPADDR,   //disp_vramctrl�ցA�\���J�n�A�h���X�̉���29bit

    /* ���荞�݁AFIFO�t���O */
    output              DSP_IRQ,    //VBLANK�ɂ�銄���ݐM��
    input               BUF_UNDER,
    input               BUF_OVER
    ); 

/* �ȉ��̋L�q�͏������Ĉꂩ���蒼�� */

// �o�͐M���̌Œ�
assign RDATA    = 32'b0;
assign DISPADDR = 29'h0;
assign DSP_IRQ  = 1'b0;

wire    write_reg  = WREN && WRADDR[15:12]==4'h0;
wire    ctrlreg_wr = (write_reg && WRADDR[11:2]==10'h001 && BYTEEN[0]);

// �R���g���[�����W�X�^�iDISPCTRL�j�E�EDISPON
always @( posedge ACLK ) begin
    if ( ARST )
        DISPON <= 1'b0;
    else if ( ctrlreg_wr )
        DISPON <= WDATA[0];
end

endmodule
