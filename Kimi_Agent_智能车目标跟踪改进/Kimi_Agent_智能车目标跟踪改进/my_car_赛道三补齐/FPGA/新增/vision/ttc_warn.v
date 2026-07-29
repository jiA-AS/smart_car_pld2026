// ============================================================================
// ttc_warn.v —— 碰撞时间（TTC）三级预警（赛道三扩展：安全预警）
//
// 原理：TTC = 当前距离 / 接近速度
//   接近速度：100ms 窗口距离差分  cs = (dist[t-10] - dist[t]) × 10  mm/s
//   中值 3 滤波抑制单帧测距跳变；cs ≤ MIN_CS（非接近）时 TTC 视为无穷大
//   TTC 由顺序除法器计算（17 拍），单位 0.1s，饱和 25.5s
//
// 三级预警（阈值参数可调，带降级迟滞防抖）：
//   TTC < TTC_RED_DS(1.5s) → level=2 红（OSD 框变红闪烁 + "注意"红字；
//                              tracker_ctrl 收到 level=2 会切断 MATCH 速度）
//   TTC < TTC_YEL_DS(3.0s) → level=1 黄（框变黄 + "注意"黄字；MATCH 半速）
//   其余                   → level=0 绿（正常）
//   升级立即生效，降级需连续 HOLD_TICKS(5) 个节拍满足，防止闪烁跳变
//
// 节拍：parse_done（100Hz）。dist 无效（dist_src=0）时 level=0。
// ============================================================================
module ttc_warn #(
    parameter [ 7:0] TTC_YEL_DS = 8'd30,   // 黄警阈值 0.1s（3.0s）
    parameter [ 7:0] TTC_RED_DS = 8'd15,   // 红警阈值 0.1s（1.5s）
    parameter [15:0] MIN_CS     = 16'd20,  // 最小接近速度 mm/s（低于不算接近）
    parameter [ 2:0] HOLD_TICKS = 3'd5     // 降级迟滞节拍数
)(
    input  wire        clk,         // 50MHz（clk_50m）
    input  wire        rst_n,
    input  wire        tick,        // parse_done，100Hz
    input  wire [15:0] dist_mm,     // stereo_dist 输出
    input  wire [ 1:0] dist_src,    // 0=无效 1=单目 2=双目
    output reg  [ 1:0] warn_level,  // 0=正常 1=黄警 2=红警
    output reg  [ 7:0] ttc_ds       // TTC，0.1s（255=≥25.5s/不接近）
);

// ------------------------- 距离历史（100ms 窗口） -------------------------
reg [15:0] dh [0:9];
integer i;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 10; i = i + 1) dh[i] <= 16'd0;
    end
    else if (tick && (dist_src != 2'd0)) begin
        dh[0] <= dist_mm;
        for (i = 1; i < 10; i = i + 1) dh[i] <= dh[i-1];
    end
end

// ------------------------- 接近速度 + 中值 3 滤波 -------------------------
wire [15:0] cs_now = (dh[9] > dist_mm) ? ((dh[9] - dist_mm) << 3)
                                        + ((dh[9] - dist_mm) << 1)   // ×10
                                       : 16'd0;
reg [15:0] cs_d1, cs_d2;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin cs_d1 <= 16'd0; cs_d2 <= 16'd0; end
    else if (tick) begin cs_d1 <= cs_now; cs_d2 <= cs_d1; end
end
wire [15:0] cs_med = ((cs_now >= cs_d1 && cs_d1 >= cs_d2) ||
                      (cs_d2 >= cs_d1 && cs_d1 >= cs_now)) ? cs_d1 :
                     ((cs_d1 >= cs_now && cs_now >= cs_d2) ||
                      (cs_d2 >= cs_now && cs_now >= cs_d1)) ? cs_now : cs_d2;

// ------------------------- TTC 顺序除法器（17 拍） -------------------------
// ttc_ds = dist×10 / cs_med（仅 tick 且接近时启动）
localparam D_IDLE = 1'b0, D_RUN = 1'b1;
reg        dstate;
reg [16:0] dvd;
reg [15:0] dvs, rem;
reg [ 7:0] quo;
reg [ 4:0] dcnt;

wire [16:0] rem_shift = {rem[14:0], dvd[16]};
wire        ge        = (rem_shift >= {1'b0, dvs});

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dstate <= D_IDLE;
        dvd <= 17'd0;  dvs <= 16'd0;  rem <= 16'd0;  quo <= 8'd0;  dcnt <= 5'd0;
        ttc_ds <= 8'd255;
    end
    else begin
        case (dstate)
        D_IDLE: begin
            if (tick) begin
                if (dist_src == 2'd0 || cs_med <= MIN_CS)
                    ttc_ds <= 8'd255;            // 无效/不接近：TTC 无穷大
                else begin
                    dvd    <= {1'b0, dist_mm} * 17'd10;
                    dvs    <= cs_med;
                    rem    <= 16'd0;  quo <= 8'd0;  dcnt <= 5'd0;
                    dstate <= D_RUN;
                end
            end
        end
        D_RUN: begin
            dvd <= {dvd[15:0], 1'b0};
            if (ge) begin
                rem <= rem_shift[15:0] - dvs;
                quo <= {quo[6:0], 1'b1};
            end
            else begin
                rem <= rem_shift[15:0];
                quo <= {quo[6:0], 1'b0};
            end
            if (dcnt == 5'd16) begin
                ttc_ds <= (&quo) ? 8'd255 : {quo[6:0], ge};  // 饱和 255
                dstate <= D_IDLE;
            end
            else dcnt <= dcnt + 5'd1;
        end
        endcase
    end
end

// ------------------------- 三级裁决 + 降级迟滞 -------------------------
wire [1:0] level_now = (ttc_ds < TTC_RED_DS) ? 2'd2 :
                       (ttc_ds < TTC_YEL_DS) ? 2'd1 : 2'd0;
reg [2:0] hold_cnt;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        warn_level <= 2'd0;  hold_cnt <= 3'd0;
    end
    else if (tick) begin
        if (level_now >= warn_level) begin       // 升级（含同级）：立即
            warn_level <= level_now;
            hold_cnt   <= 3'd0;
        end
        else begin                               // 降级：需连续 HOLD_TICKS 拍
            if (hold_cnt >= HOLD_TICKS - 3'd1) begin
                warn_level <= level_now;
                hold_cnt   <= 3'd0;
            end
            else hold_cnt <= hold_cnt + 3'd1;
        end
    end
end

endmodule
