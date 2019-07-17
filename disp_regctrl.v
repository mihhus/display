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
    output  reg         DISPON,     //disp_vramctrl, disp_buffer�ցAdisplay��ON�ɂ���
    output  reg [28:0]  DISPADDR,   //disp_vramctrl�ցA�\���J�n�A�h���X�̉���29bit

    /* ���荞�݁AFIFO�t���O */
    output   reg        DSP_IRQ,    //VBLANK�ɂ�銄���ݐM��
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

//VBLANK�p
reg preVSYNC;

//ARST��VSYNC�𓯊���
reg [1:0] arst_vsync;
always @(posedge ACLK) begin
    arst_vsync <= {arst_vsync[0], DSP_VSYNC_X};
end

wire VSYNC = arst_vsync[1];

//�������݂Ɋւ���L�q
//�\����H��0�Ȃ̂�WRADDR�̏��4bit��0�Ȃ�1���o�͂���
wire    write_reg  = WREN && WRADDR[15:12]==4'h0;

//DISPADDR���W�X�^
//DISPADDR�ւ̏�������
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
//write_reg�̏����𖞂����Ă���WRADDR[11:2]�̍ŉ��ʂ̂�1��BYTEEN4bit�̍ŉ��ʃr�b�g��1�Ȃ�control_reg���w�肳�ꂽ���ƂɂȂ�
wire    ctrlreg_wr = write_reg && WRADDR[11:2]==10'h001 && BYTEEN[0];
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
            FIFOOVER <= 0;  //1�Ȃ�[���N���A
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
            FIFOUNDER <= 0;  //1�Ȃ�[���N���A
        end
        else if(BUF_OVER) begin
            FIFOUNDER <= 1;
        end
    end
end


//�ȉ��ǂݏo���Ɋւ���L�q
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
