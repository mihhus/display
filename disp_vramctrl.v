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

    // Read Address
    output  [31:0]  ARADDR,
    output          ARVALID,
    input           ARREADY,
    // Read Data 
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

    reg [15:0] counter;

//�X�e�[�g����`
parameter S_IDLE = 4'b0001, S_SETADDR = 4'b0010, S_READ = 4'b0100, S_WAIT = 4'b1000;

//VGA�̎��̉�f��/8(�P�g�����U�N�V�����ő�����f��)=�K�v�ȃg�����U�N�V������
parameter watch_dogs = 16'h9600; //16'd38400

//AR�`���l���̑��M��
//ARADDR
assign ARADDR = (!ARST&CUR==S_SETADDR) ? counter*4'h20+DISPADDR : 0;

//ARVALID
assign ARVALID = (!ARST&NXT==S_SETADDR) ? 1 : 0;

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
        S_IDLE: if(VRSTART) begin
                    NXT <= S_SETADDR;
                end
        S_SETADDR: if(ARREADY) begin
                    NXT <= S_READ;
                   end
        S_READ: if(RLAST&RREADY) begin
                    if(counter==watch_dogs) begin//���ʕ��I��������S_IDLE�ɖ߂�, �J�E���^���K�v
                        NXT <= S_IDLE;
                    end
                    else if(BUF_WREADY) begin   //�o�b�t�@�ɗ]�T�������S_SETADDR�Ɉړ�
                        NXT <= S_SETADDR;
                    end
                    else begin  //���ʕ��I�����Ă��炸�C�o�b�t�@�ɗ]�T���Ȃ����S_WAIT�Ɉړ�
                        NXT <= S_WAIT;
                    end
                end
        S_WAIT: if(BUF_WREADY) begin
                    NXT <= S_SETADDR;
                end
        default:
            NXT <= S_IDLE;
    endcase
end //NXT;

//RREADY
assign RREADY = (CUR==S_READ&!ARST) ? 1 : 0;

//counter
always @(posedge ACLK) begin
    if(ARST) begin
        counter <= 0;
    end
    else if(CUR==S_SETADDR&ARREADY) begin
        counter <= counter + 1;
    end
    else if(counter==watch_dogs&RLAST&RREADY) begin
        counter <= 0;
    end
end//counter
endmodule
