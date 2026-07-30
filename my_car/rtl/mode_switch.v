// ============================================================================
// mode_switch.v -- 显示/识别模式切换 V3（遥控优先 + KEY0 兜底，差分阈值）
//
// 模式语义（与 ESP 端 V1.2 协议、OLED 页同步）：
//   0 = 视角档：白天识别阈值（差分严格）+ 全 HUD（双目画面为主）
//   1 = 轨迹档：白天阈值 + 轨迹仪表盘突出（dash_osd 窗外压暗）
//   2 = 调试档：夜间阈值降档（弱光放宽差分）+ OSD 调试行 G1/G2 + "夜间"标签
//
// V2 改动：模式源从"仅 KEY0"改为双源仲裁--
//   遥控优先：rc_tick（sl_parse_done，100Hz）驱动的 0.5s 看门狗，期间
//             disp_mode 直接取 rc_mode（遥控器左拨杆 s1，ESP 上行帧解析）；
//   KEY0 兜底：超过 0.5s 无好帧（未接 ESP/调台时）自动退回板载按键循环。
//   遥控恢复在线时立刻切回遥控档位（无需按键）。
//
// 消抖：20ms 双向消抖（50MHz × 1_000_000），确认后的下降沿计一次按键。
// 输出阈值直接驱动 green_detect 的 th_g/th_diff 运行时端口。
// V3 改动：配合 green_detect V4 差分判决，th_rb（红蓝上限）废弃，
//   改为 th_diff（G-R/G-B 差分下限）。白天靠差分区分饱和绿光与绿植，
//   白天档 TH_DIFF=16，调试/夜间档放宽到 10。
// ============================================================================
module mode_switch #(
    parameter [19:0] DEB_CNT      = 20'd1_000_000, // 消抖计数（20ms@50M）
    parameter [24:0] RC_TIMEOUT   = 25'd25_000_000,// 遥控模式超时（0.5s@50M）
    parameter [ 5:0] NORM_TH_G    = 6'd40,         // 视角/轨迹档：绿下限
    parameter [ 5:0] NORM_TH_DIFF = 6'd16,         //        [V3] G-R/G-B 差分下限（白天）
    parameter [ 5:0] NIGHT_TH_G   = 6'd28,         // 调试档：放宽绿下限
    parameter [ 5:0] NIGHT_TH_DIFF= 6'd10          //        [V3] 放宽差分下限（夜间/调试）
)(
    input  wire       clk,        // 50MHz（clk_50m）
    input  wire       rst_n,
    input  wire       key_n,      // 板载按键 KEY0，低有效（需上拉，见 XDC 说明）
    input  wire       rc_tick,    // 上行好帧脉冲（sl_parse_done，100Hz）
    input  wire [1:0] rc_mode,    // 遥控显示模式（v1_decode V1.2 解出）
    output reg  [1:0] disp_mode,  // 0=视角 1=轨迹 2=调试
    output wire       rc_active,  // 1=当前模式来自遥控（调试用，可悬空）
    output reg  [5:0] th_g,       // 当前绿分量下限（送 green_detect）
    output reg  [5:0] th_diff     // [V3] 当前 G-R/G-B 差分下限（送 green_detect）
);

// ------------------------- 按键：同步 + 消抖 -------------------------
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

// ------------------------- KEY0 本地模式（兜底用） -------------------------
reg       key_d1;
reg [1:0] key_mode;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        key_d1   <= 1'b1;
        key_mode <= 2'd0;
    end
    else begin
        key_d1 <= key_stable;
        if (key_d1 && !key_stable)     // 确认按下
            key_mode <= (key_mode == 2'd2) ? 2'd0 : key_mode + 2'd1;
    end
end

// ------------------------- 遥控看门狗：0.5s 无好帧 → 退回 KEY0 -------------------------
reg [24:0] rc_cnt;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)        rc_cnt <= RC_TIMEOUT;      // 上电默认"遥控不在线"→ KEY0
    else if (rc_tick)  rc_cnt <= 25'd0;
    else if (rc_cnt < RC_TIMEOUT) rc_cnt <= rc_cnt + 25'd1;
end

assign rc_active = (rc_cnt < RC_TIMEOUT);

// ------------------------- 模式仲裁：遥控优先 -------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) disp_mode <= 2'd0;
    else        disp_mode <= rc_active ? rc_mode : key_mode;
end

// ------------------------- 模式 → 阈值 -------------------------
always @(*) begin
    case (disp_mode)
        2'd2:    begin th_g = NIGHT_TH_G;  th_diff = NIGHT_TH_DIFF;  end
        default: begin th_g = NORM_TH_G;   th_diff = NORM_TH_DIFF;   end
    endcase
end

endmodule
