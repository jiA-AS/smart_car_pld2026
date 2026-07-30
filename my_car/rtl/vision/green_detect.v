// ============================================================================
// green_detect.v -- 绿灯识别（像素流水线，零帧存） V4.2
//
// 目标靶标：手持 8×8 绿色 LED 点阵灯（正方形主动光源），小车跟随用。
//
// V4.2 改动：密度阈值默认 DEN_SHIFT 3→4（填充率 12.5%→6.25%）。
//   ★ 关键认识：8×8 点阵是 64 个分离亮点 + 暗 PCB 间隙的【稀疏结构】，
//     填充率仅 ~10~16%（距离越远每个 LED 像素越少、填充率越低），
//     12.5% 的密度阈值会连真点阵一起拦掉 → "完全识别不了"。
//     误识别的零星小光点（cnt 小、bbox 远大于光源、密度 <5%）
//     在 6.25% 阈值下依然被拦，方形度/多帧闸兜底。
//   若放宽后稀疏误识别回潮：DEN_SHIFT 回 3 并把 MIN_AREA 同步上调
//   （点阵 cnt≈64×每灯像素数，零星点 cnt 通常 <50，用 cnt 规模区分）。
//
// V4.1 改动：在第 3 道闸后新增第 5 道 方形度判决——
//   8×8 点阵为正方形，手持旋转/透视投影下包围盒长宽比仍接近 1:1；
//   长条绿物（竹竿/绿边线/反光条/门缝光）长宽比悬殊，直接排除。
//   判据：w ≤ h×2 且 h ≤ w×2（长宽比 0.5~2.0 冗余），纯移位比较。
//
// V4 改动（白天抗误识别五道闸）：
//   1) 颜色判决由"G≥th_g 且 R/B≤th_rb"改为 差分判决：
//        is_green = (G ≥ th_g) && (G-R ≥ th_diff) && (G-B ≥ th_diff)
//      白天绿植/草地在自动白平衡下 R/B 可低至 12 以下，旧判决会整片通过；
//      8×8 点阵是主动发光饱和绿，G-R、G-B 差 ≥20，绿植差通常 <12。
//      差分对曝光/白平衡漂移天然鲁棒（整体亮度变，差值不变）。
//      th_rb 端口废弃，改为 th_diff 运行时端口（mode_switch 驱动）。
//   2) 面积窗：cnt 须同时满足 MIN_AREA ≤ cnt ≤ MAX_AREA。
//      白天大片绿植 cnt 数千~数万，被 MAX_AREA 直接排除。
//   3) 密度判决：cnt × 2^DEN_SHIFT ≥ bbox_w × bbox_h（填充率 ≥ 1/2^DEN_SHIFT）。
//      实心发光点阵填充率 50%+；绿植是稀疏纹理，过阈值后填充率常 <10%。
//   4) 多帧确认：raw_ok 连续 CONFIRM_FRAMES 帧才置 gd_found，丢 1 帧即清。
//      白天瞬态反光（玻璃/水面/金属）单帧闪现被滤除，30fps 下确认延迟仅 ~67ms。
//      ★ 若手持灯为扫描式驱动（MAX7219 类）且实测 found 闪烁，
//        说明相机曝光与灯扫描拍频：CONFIRM 改 1，或提高灯的扫描频率。
//   5) [V4.1] 方形度判决：见上。
//
// 原理：RGB565 逐像素阈值判断 -> 帧内累加 sum_x/sum_y/cnt + 包围盒
//       -> 帧结束启动时序除法器求质心 -> 锁存输出
// 输出在相机像素时钟域，每帧更新一次（准静态，跨域直接采样即可）
//
// 阈值调节：TH_G 越大越严格（抗干扰强、暗灯易丢）；
//           TH_DIFF 越大越严格（白天建议 ≥16，夜间/调试可放宽到 10）；
//           gd_cnt 可作为调参依据（OSD 调试行 G1/G2 实时显示）
// ============================================================================
module green_detect #(
    parameter H_ACTIVE = 400,         // 相机行有效像素 = h_disp/2（800x480 LCD 时为 400）
    parameter TH_G     = 6'd40,      // 绿分量下限（0~63，默认白天档参考值）
    parameter TH_DIFF  = 6'd16,      // G-R / G-B 差分下限（0~63，默认白天档参考值）
    parameter MIN_AREA = 18'd30,    // 判定 found 的最小绿色像素数
    parameter MAX_AREA = 18'd6000,  // [V4] 最大绿色像素数（大片绿植排除；400x240 画面的 ~6%）
    // [V4.2] 默认 3→4（密度≥6.25%）：8×8 点阵是 64 个分离亮点+暗间隙的稀疏结构，
    //   填充率仅 ~10~16%（远距更低），12.5% 阈值会把真点阵也拦掉导致完全识别不了。
    //   零星小光点误识别（cnt 小、bbox 大、密度常 <5%）在 6.25% 下仍被拦。
    parameter DEN_SHIFT= 4'd4,      // [V4.2] 密度判决：cnt×2^4 ≥ bbox 面积（填充率≥6.25%）
    parameter CONFIRM  = 2'd2,      // [V4] 多帧确认帧数（1=不启用确认）
    parameter SQUARE_EN= 1'b1,      // [V4.1] 方形度判决使能（0=关闭，靶标非方形时关）
    parameter IDLE_MAX = 24'd20000  // 帧结束判据：frame_valid 空闲时钟数
                                    // （须大于行间消隐、小于帧周期；20000 适用 12~30MHz pclk）
)(
    input  wire        clk,          // 相机像素时钟（cam_pclk_1）
    input  wire        rst_n,
    input  wire        frame_vsync,
    input  wire        frame_valid,
    input  wire [15:0] frame_data,
    // ---- mode_switch 输出的运行时阈值 ----
    input  wire [ 5:0] th_g,         // 绿分量下限（0~63）
    input  wire [ 5:0] th_diff,      // [V4] G-R / G-B 差分下限（0~63）
    // ---- 检测结果（帧结束更新，保持到下一帧）  ----
    output reg         gd_found,     // 本帧发现绿灯（已过多帧确认）
    output reg  [ 9:0] gd_u,         // 质心横坐标（相机像素）
    output reg  [ 9:0] gd_v,         // 质心纵坐标
    output reg  [ 9:0] gd_min_x,     // 包围盒
    output reg  [ 9:0] gd_max_x,
    output reg  [ 9:0] gd_min_y,
    output reg  [ 9:0] gd_max_y,
    output reg  [17:0] gd_cnt        // 绿色像素总数（调阈值用）
);

// -------------------------  帧结束检测：valid 空闲超时 -------------------------
reg [23:0] idle_cnt = 24'd0;
reg        frame_end = 1'b0;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        idle_cnt  <= 24'd0;
        frame_end <= 1'b0;
    end
    else begin
        frame_end <= 1'b0;                      // 默认每拍清零（单拍脉冲）
        if (frame_valid)
            idle_cnt <= 24'd0;
        else if (idle_cnt < IDLE_MAX + 24'd1)
            idle_cnt <= idle_cnt + 24'd1;
        if (idle_cnt == IDLE_MAX)               // 到达阈值：一帧结束（仅一拍）
            frame_end <= 1'b1;
    end
end

// ------------------------- 像素坐标计数 -------------------------
reg [9:0] x, y;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        x <= 10'd0;  y <= 10'd0;
    end
    else if (frame_end) begin
        x <= 10'd0;  y <= 10'd0;
    end
    else if (frame_valid) begin
        if (x == H_ACTIVE-1) begin
            x <= 10'd0;  y <= y + 10'd1;
        end
        else x <= x + 10'd1;
    end
end

// ------------------------- [V4] 绿色差分判决 -------------------------
// g ≥ th_g 且 g-r ≥ th_diff 且 g-b ≥ th_diff（全部无符号，无下溢）
wire [4:0] pix_r = frame_data[15:11];
wire [5:0] pix_g = frame_data[10: 5];
wire [4:0] pix_b = frame_data[ 4: 0];
wire is_green = ({1'b0, pix_g} >= {1'b0, th_g})
             && ({1'b0, pix_g} >= ({2'b00, pix_r} + {1'b0, th_diff}))
             && ({1'b0, pix_g} >= ({2'b00, pix_b} + {1'b0, th_diff}));

// ------------------------- 帧内统计 -------------------------
reg [31:0] sum_x = 0;
reg [31:0] sum_y = 0;
reg [17:0] cnt   = 0;
reg [ 9:0] min_x = 10'd1023;
reg [ 9:0] max_x = 0;
reg [ 9:0] min_y = 10'd1023;
reg [ 9:0] max_y = 0;

wire stat_en = frame_valid && is_green;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sum_x <= 0;  sum_y <= 0;  cnt <= 0;
        min_x <= 10'd1023;  max_x <= 0;
        min_y <= 10'd1023;  max_y <= 0;
    end
    else if (frame_end) begin                   // 帧结束清零，准备下一帧
        sum_x <= 0;  sum_y <= 0;  cnt <= 0;
        min_x <= 10'd1023;  max_x <= 0;
        min_y <= 10'd1023;  max_y <= 0;
    end
    else if (stat_en) begin
        sum_x <= sum_x + x;
        sum_y <= sum_y + y;
        cnt   <= cnt + 18'd1;
        if (x < min_x) min_x <= x;
        if (x > max_x) max_x <= x;
        if (y < min_y) min_y <= y;
        if (y > max_y) max_y <= y;
    end
end

// --------------- [V4/V4.1] 面积窗 + 密度 + 方形度判决（组合，帧结束时刻有效） ---------------
wire [9:0]  bbox_w    = max_x - min_x + 10'd1;      // cnt≥MIN_AREA 时 min≤max 成立
wire [9:0]  bbox_h    = max_y - min_y + 10'd1;
wire [19:0] bbox_area = bbox_w * bbox_h;            // ≤400×240=96000（17bit）
wire [21:0] cnt_den   = {4'd0, cnt} << DEN_SHIFT;   // cnt × 2^DEN_SHIFT
wire        area_ok   = (cnt >= MIN_AREA) && (cnt <= MAX_AREA);
wire        dens_ok   = (cnt_den >= {2'b00, bbox_area});
// [V4.1] 方形度：w≤2h 且 h≤2w（8×8 点阵≈1:1，手持旋转/透视冗余到 2:1）
wire        squ_ok    = !SQUARE_EN
                     || (({1'b0, bbox_w} <= {bbox_h, 1'b0})
                      && ({1'b0, bbox_h} <= {bbox_w, 1'b0}));
wire        raw_ok    = area_ok && dens_ok && squ_ok;  // 本帧原始判决（未多帧确认）

// ------------------------- 时序除法器（32拍移位-减法，u/v 共用） -------------------------
// 注意：frame_end 当拍统计值尚未清零（非阻塞赋值），此处采样到的是完整帧统计
localparam D_IDLE = 0, D_RUN_U = 1, D_RUN_V = 2, D_LATCH = 3;
reg [ 1:0] dstate = D_IDLE;
reg [31:0] dividend = 0;
reg [31:0] divisor  = 0;
reg [31:0] quotient = 0;
reg [31:0] rem      = 0;
reg [ 5:0] dcnt     = 0;
reg [ 9:0] quo_u = 0;
reg [ 9:0] quo_v = 0;
// 帧结束时刻的统计快照（除法期间原统计已清零，必须快照）
reg [17:0] c_cnt   = 0;
reg [ 9:0] c_min_x = 0;
reg [ 9:0] c_max_x = 0;
reg [ 9:0] c_min_y = 0;
reg [ 9:0] c_max_y = 0;
// [V4] 多帧确认：raw_ok 连续命中计数（≥CONFIRM 封顶）
reg [ 1:0] ok_streak = 2'd0;

wire [32:0] rem_shift = {rem[30:0], dividend[31]};
wire        ge        = (rem_shift >= {1'b0, divisor});

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dstate <= D_IDLE;
        dividend <= 0;  divisor <= 0;  quotient <= 0;  rem <= 0;  dcnt <= 0;
        quo_u <= 0;     quo_v <= 0;
        gd_found <= 1'b0;
        gd_u <= 0;  gd_v <= 0;
        gd_min_x <= 0;  gd_max_x <= 0;  gd_min_y <= 0;  gd_max_y <= 0;
        gd_cnt <= 0;
        ok_streak <= 2'd0;
    end
    else begin
        case (dstate)
            //  ---- 等帧结束 ----
            D_IDLE: begin
                if (frame_end) begin
                    if (raw_ok) begin
                        // [V4] 多帧确认：连续 CONFIRM 帧 raw_ok 才输出 found
                        if (ok_streak < CONFIRM)
                            ok_streak <= ok_streak + 2'd1;
                        if (ok_streak >= CONFIRM - 2'd1) begin
                            dividend <= sum_x;
                            divisor  <= {14'd0, cnt};
                            quotient <= 0;  rem <= 0;  dcnt <= 0;
                            // 快照本帧统计，供 D_LATCH 锁存
                            c_cnt   <= cnt;
                            c_min_x <= min_x;  c_max_x <= max_x;
                            c_min_y <= min_y;  c_max_y <= max_y;
                            dstate   <= D_RUN_U;
                        end
                        else begin
                            // 确认中：暂不出 found，但保留 cnt 供调参观察
                            gd_found <= 1'b0;
                            gd_cnt   <= cnt;
                        end
                    end
                    else begin
                        // 本帧不过：确认计数清零，锁存"未发现"，不除（防除零）
                        ok_streak <= 2'd0;
                        gd_found  <= 1'b0;
                        gd_cnt    <= cnt;
                        gd_min_x <= 0;  gd_max_x <= 0;
                        gd_min_y <= 0;  gd_max_y <= 0;
                    end
                end
            end
            // ---- 求 u = sum_x / cnt ----
            D_RUN_U: begin
                dividend <= {dividend[30:0], 1'b0};
                if (ge) begin
                    rem      <= rem_shift[31:0] - divisor;
                    quotient <= {quotient[30:0], 1'b1};
                end
                else begin
                    rem      <= rem_shift[31:0];
                    quotient <= {quotient[30:0], 1'b0};
                end
                if (dcnt == 6'd31) begin
                    quo_u    <= ge ? {quotient[8:0], 1'b1} : quotient[9:0];
                    dividend <= sum_y;
                    quotient <= 0;  rem <= 0;  dcnt <= 0;
                    dstate   <= D_RUN_V;
                end
                else dcnt <= dcnt + 6'd1;
            end

            D_RUN_V: begin
                dividend <= {dividend[30:0], 1'b0};
                if (ge) begin
                    rem      <= rem_shift[31:0] - divisor;
                    quotient <= {quotient[30:0], 1'b1};
                end
                else begin
                    rem      <= rem_shift[31:0];
                    quotient <= {quotient[30:0], 1'b0};
                end
                if (dcnt == 6'd31) begin
                    quo_v  <= ge ? {quotient[8:0], 1'b1} : quotient[9:0];
                    dstate <= D_LATCH;
                end
                else dcnt <= dcnt + 6'd1;
            end

            D_LATCH: begin
                gd_found <= 1'b1;
                gd_u     <= quo_u;
                gd_v     <= quo_v;
                gd_min_x <= c_min_x;
                gd_max_x <= c_max_x;
                gd_min_y <= c_min_y;
                gd_max_y <= c_max_y;
                gd_cnt   <= c_cnt;
                dstate   <= D_IDLE;
            end
            default: dstate <= D_IDLE;
        endcase
    end
end

endmodule
