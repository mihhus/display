//-----------------------------------------------------------------------------
// Title       : VRAM����i��u�Ґ݌v�Ώہj
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

    // Read Address, �A�h���X�n��
    output  [31:0]  ARADDR,
    output          ARVALID,
    input           ARREADY,
    // Read Data, �f�[�^�n��������RREADY�ɂȂ��Ă��FIFO�Ƀf�[�^���������܂��
    input           RLAST,
    input           RVALID,
    output          RREADY,

    /* �𑜓x�؂�ւ� */
    input   [1:0]   RESOL,

    /* ���u���b�N����̐M�� */
    input           VRSTART,   //syncgen��� VRAM�ǂݏo���J�n�M��
    input           DISPON,    //disp_regctrl, disp_buffer���\��ON
    input   [28:0]  DISPADDR,  //disp_regctrl���\���J�n�̃A�h���X�̉��ʂQ�X�r�b�g
    input           BUF_WREADY //disp_buffer���@FIFO�ւ̏������݉\
);

//AXI�Ŋe��M��������肷�� Master�Ƃ���
//FIFO�֏�������

    reg [3:0] CUR;
    reg [3:0] NXT;

    reg [15:0] COUNT;

//1��ʂ��I������܂ł̃g�����U�N�V������
//�e�𑜓x�̎��̉�f��/8(�P�g�����U�N�V�����ő�����f��)=�K�v�ȃg�����U�N�V������+1���Ă�
//�X�e�[�g���W�X�^�̔�r����ʂ�̌��ˍ�����WATCH_DOGS���P�����Ă���K�v������
//RESOL==0 VGA, RESOL==1 XGA, RESOL==2 SXGA
    wire    [15:0] WATCH_DOGS = (RESOL==2'b00)? 16'h12C1:(RESOL==2'b01)?16'h3001:16'h5001; //16'd4800, 786432, 1310720
//1�g�����U�N�V�������̃A�h���X�̐i�ݕ�
    wire    [8:0] STEP = 9'h100;
//�X�e�[�g����`
parameter S_IDLE = 4'b0001, S_SETADDR = 4'b0010, S_READ = 4'b0100, S_WAIT = 4'b1000;

//AR�`���l���̑��M��
//ARADDR 8*32=256��1�g�����U�N�V�����Ȃ̂�
assign ARADDR = COUNT*STEP+DISPADDR;

//ARVALID
assign ARVALID = (CUR==S_SETADDR) ? 1 : 0;

//�X�e�[�g���W�X�^
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
        S_IDLE: if(VRSTART) begin   //�ҋ@
                    NXT <= S_SETADDR;
                end
                else begin
                    NXT <= S_IDLE;
                end
        S_SETADDR: if(ARREADY) begin    //AR�`���l���ɃA�h���X�𔭍s
                        NXT <= S_READ;
                    end
                    else begin
                        NXT <= S_SETADDR;
                    end
        S_READ: if(RLAST&RVALID) begin  //VRAM��ǂݏo���AFIFO�ɂ�
                    if(COUNT==WATCH_DOGS-1) begin//���ʕ��I��������S_IDLE�ɖ߂�, �J�E���^���K�v
                        NXT <= S_IDLE;
                    end
                    else if(BUF_WREADY) begin   //�o�b�t�@�ɗ]�T�������S_SETADDR�Ɉړ�
                        NXT <= S_SETADDR;
                    end
                    else begin  //���ʕ��I�����Ă��炸�C�o�b�t�@�ɗ]�T���Ȃ����S_WAIT�Ɉړ�
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
