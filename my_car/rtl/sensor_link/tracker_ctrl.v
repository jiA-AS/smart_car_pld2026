// ============================================================================
// tracker_ctrl.v -- 绿灯追踪控制器 V3（三模式）
//
// 识别情况 → 控制模式（V1.1 下行 mode 字段）：
//   1) 未识别（双目都无）      → S_STOP   : mode=0 静止停车（不转圈）
//   2) 单目识别（仅一路看到）  → S_MONO   : mode=1 单目跟随
//        方位-only 追踪 + 单目方位偏移补偿（仅右路看到→目标实际更偏右，
//        err 加 +MONO_OFFS；仅左路看到→加 -MONO_OFFS）；低速前进 MONO_V
//   3) 双目识别               → S_MATCH  : mode=2 双目自动对接（自动化模式）
//        距离环优先用双目测距 dist_mm：base = (dist-DIST_ARRIVE)*KD_NUM/1024；
//        距离无效时退化为包围盒高度保持；dist<=DIST_ARRIVE_MM 判定到达停车
//
// 转向（追踪/对接通用）：err = u - U_CENTER（右为正）；turn = err/4；
//   left = base + turn，right = base - turn（目标偏右 → 左轮快 → 右转）
//   ★ 单位约定：left/right ∈ [-100,+100]，百分比（%），见通信协议 V1.2
//
// 输入为准静态跨域信号，20ms 一拍（与 V1.1 50Hz 发送节拍对齐）。
// ============================================================================
module tracker_ctrl #(
    parameter [ 9:0] U_CENTER   = 10'd200,  // 画面中线（H_ACTIVE/2）
    parameter [ 9:0] DEADZONE   = 10'd8,    // 转向死区（像素）
    parameter [ 7:0] V_MAX      = 8'd45,    // 基础速度上限（%）
    parameter [ 7:0] MONO_V     = 8'd25,    // 单目跟随前进速度（%，低速谨慎）
    parameter [ 9:0] MONO_OFFS  = 10'd60,   // 单目方位偏移补偿（像素，实测标定）
    parameter [15:0] DIST_ARRIVE= 16'd300,  // 对接到达距离（mm）
    parameter [ 9:0] KD_NUM     = 10'd102,  // 距离环增益 ×1024（≈0.1 %/mm）
    parameter [ 9:0] H_REF      = 10'd120,  // [退化路径] 距离保持的包围盒高度
    parameter [ 9:0] H_ARRIVE   = 10'd150   // [退化路径] 到达判定高度
)(
    input  wire        clk,         // 50MHz
    input  wire        rst_n,
    // ---- 各路识别标志（模式判定） ----
    input  wire        f1,          // cam1（右）识别到
    input  wire        f2,          // cam2（左）识别到
    // ---- 融合后的追踪量（顶层融合，准静态） ----
    input  wire        gd_found,
    input  wire [ 9:0] gd_u,
    input  wire [ 9:0] gd_min_y,
    input  wire [ 9:0] gd_max_y,
    // ---- 距离（stereo_dist，50M 域） ----
    input  wire [15:0] dist_mm,
    input  wire [ 1:0] dist_src,    // 0=无效 1=单目 2=双目
    // ---- V1.1 指令输出（%） ----
    output reg  [ 7:0] mode,        // 0=停车 1=单目跟随 2=双目对接
    output reg  [15:0] left,
    output reg  [15:0] right
);

// ------------------------- 20ms 节拍 -------------------------
localparam TICK_MAX = 32'd1_000_000;    // 50MHz / 50Hz
reg [31:0] tick_cnt = 0;
reg        tick     = 1'b0;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tick_cnt <= 0;  tick <= 1'b0;
    end
    else if (tick_cnt >= TICK_MAX-1) begin
        tick_cnt <= 0;  tick <= 1'b1;
    end
    else begin
        tick_cnt <= tick_cnt + 32'd1;  tick <= 1'b0;
    end
end

// ------------------------- 状态定义 -------------------------
localparam S_STOP   = 2'd0,   // 未识别：静止停车（不转圈）
           S_MONO   = 2'd1,   // 单目跟随
           S_MATCH  = 2'd2,   // 双目自动对接
           S_ARRIVE = 2'd3;   // 对接到达停车
reg [1:0] state = S_STOP;

wire both = f1 && f2;
wire mono = f1 ^  f2;

// ------------------------- 控制律中间量 -------------------------
wire [9:0] box_h = gd_max_y - gd_min_y;
// 方位偏差（右为正）+ 单目偏移补偿
wire signed [12:0] err_raw = $signed({3'b000, gd_u}) - $signed({3'b000, U_CENTER});
wire signed [12:0] err_adj = (state == S_MONO)
                             ? (f1 ? (err_raw + $signed({3'b000, MONO_OFFS}))
                                   : (err_raw - $signed({3'b000, MONO_OFFS})))
                             : err_raw;
wire signed [12:0] turn    = err_adj >>> 2;                    // Kp = 1/4
wire signed [12:0] turn_d  = (err_adj >  $signed({3'b000, DEADZONE}) ||
                              err_adj < -$signed({3'b000, DEADZONE}))
                             ? turn : 13'sd0;
// 距离环（MATCH 模式，优先双目测距）
wire signed [17:0] d_err   = $signed({2'b00, dist_mm}) - $signed({2'b00, DIST_ARRIVE});
wire signed [27:0] base_d  = (d_err * $signed({1'b0, KD_NUM})) >>> 10;
// 退化路径：包围盒高度保持
wire signed [12:0] h_err   = $signed({3'b000, H_REF}) - $signed({3'b000, box_h});
wire signed [12:0] base_h  = h_err >>> 1;
// MATCH 基础速度选择 + 限幅 [0, V_MAX]
wire signed [17:0] base_m_raw = (dist_src == 2'd2) ? base_d : {{5{base_h[12]}}, base_h};
wire signed [17:0] base_m  = (base_m_raw < 18'sd0) ? 18'sd0 :
                             (base_m_raw > $signed({10'd0, V_MAX}))
                             ? $signed({10'd0, V_MAX}) : base_m_raw;
// 左右轮合成 + 限幅 [-100, +100]（%）
function signed [15:0] clamp100;
    input signed [15:0] v;
    begin
        if (v > 16'sd100)       clamp100 = 16'sd100;
        else if (v < -16'sd100) clamp100 = -16'sd100;
        else                    clamp100 = v;
    end
endfunction
wire signed [15:0] mono_l = clamp100($signed({8'd0, MONO_V}) + turn_d);
wire signed [15:0] mono_r = clamp100($signed({8'd0, MONO_V}) - turn_d);
wire signed [15:0] mtch_l = clamp100(base_m[15:0] + {{3{turn_d[12]}}, turn_d});
wire signed [15:0] mtch_r = clamp100(base_m[15:0] - {{3{turn_d[12]}}, turn_d});

// 到达判定：双目距离有效用距离，否则用包围盒高度
wire arrived = (dist_src == 2'd2) ? (dist_mm <= DIST_ARRIVE)
                                  : (box_h >= H_ARRIVE);

// ------------------------- 主状态机（每 20ms 一拍） -------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= S_STOP;
        mode  <= 8'd0;
        left  <= 16'd0;
        right <= 16'd0;
    end
    else if (tick) begin
        case (state)
        // ---------------- 未识别：静止停车 ----------------
        S_STOP: begin
            mode  <= 8'd0;  left <= 16'd0;  right <= 16'd0;
            if (both)      state <= S_MATCH;
            else if (mono) state <= S_MONO;
        end
        // ---------------- 单目跟随 ----------------
        S_MONO: begin
            if (!gd_found) begin
                state <= S_STOP;
                mode  <= 8'd0;  left <= 16'd0;  right <= 16'd0;
            end
            else if (both) state <= S_MATCH;
            else begin
                mode  <= 8'd1;
                left  <= mono_l;
                right <= mono_r;
            end
        end
        // ---------------- 双目自动对接 ----------------
        S_MATCH: begin
            if (!gd_found) begin
                state <= S_STOP;
                mode  <= 8'd0;  left <= 16'd0;  right <= 16'd0;
            end
            else if (mono) state <= S_MONO;
            else if (arrived) begin
                state <= S_ARRIVE;
                mode  <= 8'd0;  left <= 16'd0;  right <= 16'd0;
            end
            else begin
                mode  <= 8'd2;
                left  <= mtch_l;
                right <= mtch_r;
            end
        end
        // ---------------- 到达停车：目标移远或丢失则退出 ----------------
        S_ARRIVE: begin
            mode  <= 8'd0;  left <= 16'd0;  right <= 16'd0;
            if (!gd_found)      state <= S_STOP;
            else if (!arrived)  state <= both ? S_MATCH : S_MONO;
        end
        default: state <= S_STOP;
        endcase
    end
end

endmodule
