// ============================================================================
// mode_switch.v —— 按键显示/识别模式切换（赛道三：人机交互）
//
// 功能：板载按键（低有效）短按循环切换三种模式：
//   0 = 正常模式：标准识别阈值 + 标准 OSD
//   1 = 调试模式：OSD 左上角增显两路绿色像素计数 G1/G2（调阈值依据）
//   2 = 夜间模式：绿色阈值降档（弱光/夜间演示），OSD 右上角显示"夜间"
//
// 消抖：20ms 双向消抖（50MHz × 1_000_000），确认后的下降沿计一次按键。
//
// 输出阈值直接驱动 green_detect 的 th_g/th_rb 运行时端口（V3 起阈值
// 不再是编译期 parameter，可在线切换）。
// ============================================================================
module mode_switch #(
    parameter [19:0] DEB_CNT      = 20'd1_000_000, // 消抖计数（20ms@50M）
    parameter [ 5:0] NORM_TH_G    = 6'd40,         // 正常/调试档：绿下限
    parameter [ 4:0] NORM_TH_RB   = 5'd12,         //           红蓝上限
    parameter [ 5:0] NIGHT_TH_G   = 6'd28,         // 夜间档：放宽绿下限
    parameter [ 4:0] NIGHT_TH_RB  = 5'd18          //          放宽红蓝上限
)(
    input  wire       clk,        // 50MHz（clk_50m）
    input  wire       rst_n,
    input  wire       key_n,      // 按键输入，低有效（需上拉，见 XDC 说明）
    output reg  [1:0] disp_mode,  // 0=正常 1=调试 2=夜间
    output reg  [5:0] th_g,       // 当前绿分量下限（送 green_detect）
    output reg  [4:0] th_rb       // 当前红/蓝分量上限（送 green_detect）
);

// ------------------------- 同步 + 消抖 -------------------------
reg key_m, key_s;                      // 2 级同步（按键异步输入）
reg [19:0] deb_cnt;
reg        key_stable;                 // 消抖后稳定电平

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        key_m <= 1'b1;  key_s <= 1'b1;
        deb_cnt <= 20'd0;  key_stable <= 1'b1;
    end
    else begin
        key_m <= key_n;  key_s <= key_m;
        if (key_s != key_stable) begin
            if (deb_cnt >= DEB_CNT - 20'd1) begin
                key_stable <= key_s;   // 稳定 20ms 才确认
                deb_cnt    <= 20'd0;
            end
            else deb_cnt <= deb_cnt + 20'd1;
        end
        else deb_cnt <= 20'd0;
    end
end

// ------------------------- 下降沿检测 → 模式循环 -------------------------
reg key_d1;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        key_d1    <= 1'b1;
        disp_mode <= 2'd0;
    end
    else begin
        key_d1 <= key_stable;
        if (key_d1 && !key_stable)     // 确认按下
            disp_mode <= (disp_mode == 2'd2) ? 2'd0 : disp_mode + 2'd1;
    end
end

// ------------------------- 模式 → 阈值 -------------------------
always @(*) begin
    case (disp_mode)
        2'd2:    begin th_g = NIGHT_TH_G;  th_rb = NIGHT_TH_RB;  end
        default: begin th_g = NORM_TH_G;   th_rb = NORM_TH_RB;   end
    endcase
end

endmodule
