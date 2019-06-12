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

    reg [3:0] state_reg;
    reg [3:0] state_generator;

    reg [15:0] counter;

//�X�e�[�g����`
parameter S_IDLE = 4'b0001, S_SETADDR = 4'b0010, S_READ = 4'b0100, S_WAIT = 4'b1000;

//VGA�̎��̉�f��/8(�P�g�����U�N�V�����ő�����f��)=�K�v�ȃg�����U�N�V������
parameter watch_dogs = 16'h9600; //16'd38400

//�X�e�[�g���W�X�^
always @(posedge ACLK) begin
    if(ARST) begin
        state_reg <= S_IDLE;
    end
    else begin
        state_reg <= state_generator;
    end
end //state_reg

//state_generator
always @* begin
    case(state_reg)
        S_IDLE: if(VRSTART) begin
                    state_generator <= S_SETADDR;
                end
        S_SETADDR: if(ARREADY) begin
                    state_generator <= S_READ;
                   end
        S_READ: if(RLAST&RREADY) begin
                    if(counter==watch_dogs) begin//���ʕ��I��������S_IDLE�ɖ߂�, �J�E���^���K�v
                        state_generator <= S_IDLE;
                    end
                    else if(BUF_WREADY) begin   //�o�b�t�@�ɗ]�T�������S_SETADDR�Ɉړ�
                        state_generator <= S_SETADDR;
                    end
                    else begin  //���ʕ��I�����Ă��炸�C�o�b�t�@�ɗ]�T���Ȃ����S_WAIT�Ɉړ�
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
    else if(state_reg==S_SETADDR&ARREADY) begin
        counter <= counter + 1;
    end
    else if(counter==watch_dogs&RLAST&RREADY) begin
        counter <= 0;
    end
end//counter


//ARADDR
always @(posedge ACLK) begin
    if(ARST==1) begin
        ARADDR <= 10;
    end
    else begin
        if(state_reg==S_SETADDR) begin
            ARADDR <= counter*4'h20 + DISPADDR;    //1�g�����U�N�V������d32bit�Ȃ̂�h20���ړ�������

        end
        else begin
            ARADDR <= 0;
        end
    end
end //ARADDR

//ARVALID
always @(posedge ACLK) begin
    if(ARST==1) begin
        ARVALID <= 0;
    end
    else begin
        if(state_reg==S_SETADDR) begin
            ARVALID <= 1;
        end
        else begin
            ARVALID <= 0;
        end
    end
end //ARVALID
endmodule
