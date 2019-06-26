//-----------------------------------------------------------------------------
// Title       : 同期信号生成（受講者設計対象）
// Project     : pattern
// Filename    : syncgen.v
//-----------------------------------------------------------------------------
// Description :
// 
//-----------------------------------------------------------------------------
// Revisions   :
// Date        Version  Author        Description
// 201?/??/??  1.00     ???????????   Created
//-----------------------------------------------------------------------------


module syncgen(
    input               DCLK,           //ドットクロック
    input               DRST,           //リセット
    input       [1:0]   RESOL,          //解像度設定信号
    output              VRSTART,        //表示開始
    output  reg         DSP_HSYNC_X ,    //水平同期信号
    output  reg         DSP_VSYNC_X,    //垂直同期信号
    output  reg         DSP_preDE      //DSP_DEの１つ前の信号(1で画像データが有効)
);

`include "syncgen_param.vh"
//内部信号
reg [10:0]  HCNT;           //水平カウンタ
reg [10:0]  VCNT;            //垂直カウンタ

//VRSTART
 assign VRSTART = (VCNT==VFP+VPW+VBP-1) ? 1 : 0;

//DSP_HSYNC_X
always@(posedge DCLK) begin
    if(DRST==1'b1) begin
        DSP_HSYNC_X <= 11'h1;
    end
    else begin
        if(HCNT == HFP-1) begin
            DSP_HSYNC_X <= 11'h0;
        end
        else if(HCNT == HFP+HPW-1) begin
            DSP_HSYNC_X <= 11'h1;
        end
    end
end //DSP_HSYNC_X

//DSP_VSYNC_X
always@(posedge DCLK) begin
    if(DRST==1'b1) begin
        DSP_VSYNC_X <= 11'h1;
    end
    else begin
        if(VCNT == VFP & HCNT == HFP-1) begin
        //立下りをHSYNCと合わせる
            DSP_VSYNC_X <= 1'b0;
        end
        else if(VCNT == VFP+VPW & HCNT == HFP-1) begin
        //立ち上がりをHSYNCと合わせる
            DSP_VSYNC_X <= 1'b1;
        end
    end
end //DSP_VSYNC_X

//DSP_preDE
always@(posedge DCLK) begin
    if(DRST==1'b1) begin
        DSP_preDE <= 1'b0;
    end
    else begin
        if((VCNT==VFP+VPW+VBP+VDO)|(HCNT==HFP+HPW+HBP+HDO-2)) begin
            DSP_preDE <= 1'b0;
        end
        else if((VCNT>=VFP+VPW+VBP)&(VCNT<=VFP+VPW+VBP+VDO)&(HCNT==HFP+HPW+HBP-2)) begin
            DSP_preDE <= 1'b1;
        end
    end
end //DSP_preDE

//HCNT
always@(posedge DCLK) begin
    if(DRST==1'b1) begin
        HCNT <= 1'b0;
    end
    else begin
        if(HCNT == HSC-1) begin
            HCNT <= 1'b0;
        end
        else begin
            HCNT <= HCNT + 1'b1;
        end
    end

end //HCNT

//VCNT
always@(posedge DCLK) begin
    if(DRST==1'b1) begin
        VCNT <= 1'b0;
    end
    else begin
        if(HCNT == HSC-1'b1) begin
            if(VCNT == VSC-1'b1) begin
                VCNT <= 1'b0;
            end
            else begin
                VCNT <= VCNT + 1;
            end
        end
    end
end //VCNT


endmodule //syncgen
