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

endmodule
