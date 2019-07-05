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
    output  reg [31:0]  RDATA,  //�ǂݏo���f�[�^

    /* ���W�X�^�o�� */
    output  reg            DISPON,     //disp_vramctrl, disp_buffer�ցAdisplay��ON�ɂ���
    output  reg    [28:0]  DISPADDR,   //disp_vramctrl�ցA�\���J�n�A�h���X�̉���29bit

    /* ���荞�݁AFIFO�t���O */
    output  reg         DSP_IRQ,    //VBLANK�ɂ�銄���ݐM��
    input               BUF_UNDER,
    input               BUF_OVER
    ); 

/* �ȉ��̋L�q�͏������Ĉꂩ���蒼�� */

// �o�͐M���̌Œ�

//���W�X�^�̒l
reg INTENBL;
reg INTCLR;
reg VBLANK;
reg FIFOOVER;
reg FIFOUNDER;
reg [1:0] arst_vsync;

//ARST��VSYNC�𓯊���
always @(posedge ACLK) begin
    arst_vsync <= {arst_vsync[0], DSP_VSYNC_X};
end

wire VSYNC = arst_vsync[1];

//�������݂Ɋւ���L�q
//�\����H��0�Ȃ̂�WRADDR�̏��4bit��0�Ȃ�1���o�͂���
wire    write_reg  = WREN && WRADDR[15:12]==4'h0;

//DISPADDR���W�X�^
//DISPADDR�ւ̏�������
assign DISPADDR = (write_reg&WRADDR[11:0]==12'h000)? WDATA[27:0]:0;

//ctrl_wr
//write_reg�̏����𖞂����Ă���WRADDR[11:2]�̍ŉ��ʂ̂�1��BYTEEN4bit�̍ŉ��ʃr�b�g��1�Ȃ�control_reg���w�肳�ꂽ���ƂɂȂ�
wire    ctrlreg_wr = (write_reg && WRADDR[11:2]==10'h001 && BYTEEN==2'b00);
// �R���g���[�����W�X�^�iDISPCTRL�j�E�EDISPON
always @( posedge ACLK ) begin
    if ( ARST ) begin
        DISPON <= 1'b0;
    end
    else if ( ctrlreg_wr ) begin
        DISPON <= WDATA[0];
    end
end

// �R���g���[�����W�X�^�iDISPCTRL�j�E�EVBLANK
//�N���b�N�ɍ�������̂�VSYNC��posedge���擾������������
always @(posedge ACLK) begin
    if(ARST) begin
        VBLANK <= 0;
    end
    else if(ctrlreg_wr) begin
        if(WDATA[1]==1) begin
            VBLANK <= 0;
        end
        else if(VSYNC) begin
            VBLANK <= 1;
        end
        else begin
            VBLANK <= 0;
        end
    end
end//VBLANK

//int_wr
wire    int_wr = write_reg && WRADDR[11:2]==10'h002 && BYTEEN==2'b00;

//INTCLR
always @(posedge ACLK) begin
    if(ARST) begin
        INTCLR <= 0;
    end
    else if(int_wr) begin
        if(WDATA[1]) begin
            INTCLR <= 0;    //1�Ȃ�[���N���A
        end
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

//fifo_wr
wire    fifo_wr = write_reg && WRADDR[11:2]==10'h003 && BYTEEN==2'b00;

//FIFOOVER
always @(posedge ACLK) begin
    if(ARST) begin
        FIFOOVER <= 0;
    end
    else if(fifo_wr) begin
        if(WDATA[1]) begin
            FIFOOVER <= 0;  //1�Ȃ�[���N���A
        end
        else if(BUF_OVER) begin
            FIFOOVER <= 1;
        end
    end
end
//FIFOUNDER
always @(posedge ACLK) begin
    if(ARST) begin
        FIFOUNDER <= 0;
    end
    else if(fifo_wr) begin
        if(WDATA[0]) begin
            FIFOUNDER <= 0;  //1�Ȃ�[���N���A
        end
        else if(BUF_OVER) begin
            FIFOUNDER <= 1;
        end
    end
end

//DSP_IRQ
assign DSP_IRQ = (ARST) ? 0 : (VBLANK) ? 1 : (WDATA[1]&int_wr) ? 0 : DSP_IRQ;

//�ȉ��ǂݏo���Ɋւ���L�q
wire    read_reg  = RDEN && RDADDR[15:12]==4'h0;

//RDATA
assign RDATA = (ARST) ? 0 : (!read_reg) ? 0 :
               (RDADDR[11:0]==12'h000) ? {3'h0, DISPADDR} : 
               (RDADDR[11:2]==10'h002) ? {30'h000, VBLANK, DISPON} :
               (RDADDR[11:2]==10'h003) ? {30'h000, FIFOOVER, FIFOUNDER} : 0;

endmodule
