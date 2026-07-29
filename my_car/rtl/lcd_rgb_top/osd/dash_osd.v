// ============================================================================
// dash_osd.v -- 车辆状态图形化仪表盘（赛道三基础要求4 + 数字孪生扩展）
//
// 串在 osd_overlay 之后（lcd_clk 域）：坐标与 pixel_in 各打 1 拍对齐，
// 叠加判决全组合输出（再引入 1 拍视频延迟，合计 2 拍，无感知）。
//
// 右下角仪表盘窗口（200×136，分辨率自适应锚定右下角）：
//   ┌─────────────────────────┬────────┐
//   │ 轨迹                     │  姿态   │
//   │  俯视轨迹区 128×128      │ P 条   │   姿态条：±45° 满量程，
//   │  ·64 点轨迹 FIFO（绿点） │ R 条   │   中心为零，左负右正
//   │  ·小车图标 + 8方向航向线 │ 48×10  │
//   └─────────────────────────┴────────┘
//   轨迹映射：车上电位置为原点，车固定显示在窗口中心，
//   世界坐标 → 屏幕：sx = (x - cur_x)>>6（64mm/像素，±64px ≈ ±4m），
//   y 轴向上为正（屏幕向下为负）。
//
// 跨时钟说明：轨迹 FIFO 与 pos 在 sys_clk(50M) 域，lcd_clk 域 2 级同步
//   采样 cur_x/cur_y；FIFO 内容为 5Hz 准静态点，直接异步采样（单个像素
//   偶发亚稳无感知，工程可接受）。
// ============================================================================
module dash_osd #(
    parameter [4:0] TRK_SHIFT = 5'd6     // 轨迹比例：mm>>6 = 像素（64mm/px）
)(
    input  wire        lcd_clk,
    input  wire        rst_n,
    input  wire        sys_clk,           // 50M：轨迹 FIFO 写时钟域
    input  wire [10:0] pixel_xpos,
    input  wire [10:0] pixel_ypos,
    input  wire [15:0] pixel_in,
    input  wire [12:0] h_pixel,
    input  wire [12:0] v_pixel,
    // ---- 车辆状态（sys_clk 域，准静态） ----
    input  wire signed [31:0] pos_x,      // mm
    input  wire signed [31:0] pos_y,      // mm
    input  wire        [ 8:0] theta_idx,  // 航向 0~359°（0=上电朝向）
    input  wire signed [15:0] pitch_cdeg, // 0.01°
    input  wire signed [15:0] roll_cdeg,
    // ---- 轨迹点写入口（sys_clk 域，5Hz 单拍脉冲） ----
    input  wire               trk_wr,
    input  wire signed [15:0] trk_x,      // mm，±32767
    input  wire signed [15:0] trk_y,
    output wire        [15:0] pixel_out
);

// ------------------------- 颜色 -------------------------
localparam GREEN  = 16'h07E0;
localparam WHITE  = 16'hFFFF;
localparam CYAN   = 16'h07FF;
localparam YELLOW = 16'hFFE0;
localparam GRAY   = 16'h8410;

// ------------------------- 轨迹 FIFO（sys_clk 域，64 点） -------------------------
reg signed [15:0] fifo_x [0:63];
reg signed [15:0] fifo_y [0:63];
integer k;
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        for (k = 0; k < 64; k = k + 1) begin
            fifo_x[k] <= 16'sd0;  fifo_y[k] <= 16'sd0;
        end
    end
    else if (trk_wr) begin
        fifo_x[0] <= trk_x;  fifo_y[0] <= trk_y;
        for (k = 1; k < 64; k = k + 1) begin
            fifo_x[k] <= fifo_x[k-1];  fifo_y[k] <= fifo_y[k-1];
        end
    end
end

// ------------------------- lcd_clk 域：坐标/数据打 1 拍对齐 -------------------------
reg [10:0] x_d, y_d;
reg [15:0] pin_d;
always @(posedge lcd_clk or negedge rst_n) begin
    if (!rst_n) begin x_d <= 11'd0; y_d <= 11'd0; pin_d <= 16'd0; end
    else begin
        x_d <= pixel_xpos;  y_d <= pixel_ypos;  pin_d <= pixel_in;
    end
end

// ------------------------- 状态量同步进 lcd_clk 域 -------------------------
reg signed [31:0] px_a, px_b, py_a, py_b;
reg [ 8:0] th_a, th_b;
reg signed [15:0] pch_a, pch_b, rol_a, rol_b;
always @(posedge lcd_clk or negedge rst_n) begin
    if (!rst_n) begin
        px_a <= 0; px_b <= 0;  py_a <= 0; py_b <= 0;
        th_a <= 0; th_b <= 0;
        pch_a <= 0; pch_b <= 0;  rol_a <= 0; rol_b <= 0;
    end
    else begin
        px_a <= pos_x; px_b <= px_a;  py_a <= pos_y; py_b <= py_a;
        th_a <= theta_idx; th_b <= th_a;
        pch_a <= pitch_cdeg; pch_b <= pch_a;
        rol_a <= roll_cdeg;  rol_b <= rol_a;
    end
end

// ------------------------- 窗口几何（右下角锚定） -------------------------
// 总宽 200 = 128(轨迹) + 8(间隔) + 56(姿态条) + 8(右边距)
wire [10:0] WIN_W  = 11'd200;
wire [10:0] WIN_H  = 11'd136;
wire [10:0] X0     = h_pixel[10:0] - WIN_W - 11'd8;
wire [10:0] Y0     = v_pixel[10:0] - WIN_H - 11'd8;
wire [10:0] TRK_CX = X0 + 11'd64;         // 轨迹区中心（小车位置）
wire [10:0] TRK_CY = Y0 + 11'd68;
wire [10:0] ATT_X  = X0 + 11'd140;        // 姿态条区左缘（56 宽）
wire [10:0] x_rel  = x_d - X0;
wire [10:0] y_rel  = y_d - Y0;
wire        in_win = (x_d >= X0) && (x_d < X0 + WIN_W)
                  && (y_d >= Y0) && (y_d < Y0 + WIN_H);

// ------------------------- 轨迹命中（64 点并行比较） -------------------------
wire signed [11:0] px_rel = $signed({1'b0, x_d}) - $signed({1'b0, TRK_CX});
wire signed [11:0] py_rel = $signed({1'b0, y_d}) - $signed({1'b0, TRK_CY});
wire        in_trk = (x_rel < 11'd128) && (y_rel >= 11'd4) && (y_rel < 11'd132);

// 每点屏幕坐标（饱和 ±2047，防截断假命中）
// 饱和函数：返回 12bit 补码（赋给 signed 信号使用，bit pattern 一致）
function [11:0] sat12;
    input signed [31:0] v;
    begin
        if (v > 32'sd2047)       sat12 = 12'h7FF;
        else if (v < -32'sd2048) sat12 = 12'h800;
        else                     sat12 = v[11:0];
    end
endfunction

wire [63:0] trk_hit;
genvar gi;
generate
    for (gi = 0; gi < 64; gi = gi + 1) begin : G_HIT
        wire signed [31:0] dwx = {{16{fifo_x[gi][15]}}, fifo_x[gi]} - px_b;
        wire signed [31:0] dwy = {{16{fifo_y[gi][15]}}, fifo_y[gi]} - py_b;
        wire signed [11:0] sx  = sat12(dwx >>> TRK_SHIFT);
        wire signed [11:0] sy  = sat12(-(dwy >>> TRK_SHIFT));   // y 向上为正
        assign trk_hit[gi] = in_trk && (px_rel == sx) && (py_rel == sy);
    end
endgenerate
wire on_track = |trk_hit;

// ------------------------- 小车图标 + 8 方向航向线 -------------------------
wire signed [11:0] dx = px_rel;
wire signed [11:0] dy = py_rel;
// 车体：中心 ±4 空心方块
wire on_body = (dx >= -12'sd4) && (dx <= 12'sd4)
            && (dy >= -12'sd4) && (dy <= 12'sd4)
            && ((dx == -12'sd4) || (dx == 12'sd4)
             || (dy == -12'sd4) || (dy == 12'sd4));
// 航向方向：0=右 1=右上 2=上 3=左上 4=左 5=左下 6=下 7=右下
wire [2:0] dir = ((({3'b000, th_b} + 12'd22) / 12'd45)) & 3'b111;
wire in_head = (dx >= -12'sd12) && (dx <= 12'sd12)
            && (dy >= -12'sd12) && (dy <= 12'sd12);
wire on_head = in_head && (
       ((dir == 3'd0) && (dy == 12'sd0)  && (dx >= 12'sd0))
    || ((dir == 3'd1) && (dx == -dy)     && (dx >= 12'sd0))
    || ((dir == 3'd2) && (dx == 12'sd0)  && (dy <= 12'sd0))
    || ((dir == 3'd3) && (dx == dy)      && (dx <= 12'sd0))
    || ((dir == 3'd4) && (dy == 12'sd0)  && (dx <= 12'sd0))
    || ((dir == 3'd5) && (dx == -dy)     && (dx <= 12'sd0))
    || ((dir == 3'd6) && (dx == 12'sd0)  && (dy >= 12'sd0))
    || ((dir == 3'd7) && (dx == dy)      && (dx >= 12'sd0)));

// ------------------------- 姿态条（±45° 满量程 ±24px） -------------------------
// len_px = cdeg × 24 / 4500 ≈ (cdeg × 349) >> 16，饱和 ±24
wire signed [31:0] p_len32 = ({{16{pch_b[15]}}, pch_b} * 32'sd349) >>> 16;
wire signed [31:0] r_len32 = ({{16{rol_b[15]}}, rol_b} * 32'sd349) >>> 16;
wire signed [11:0] p_len = sat12(p_len32 > 32'sd24 ? 32'sd24 :
                                 (p_len32 < -32'sd24 ? -32'sd24 : p_len32));
wire signed [11:0] r_len = sat12(r_len32 > 32'sd24 ? 32'sd24 :
                                 (r_len32 < -32'sd24 ? -32'sd24 : r_len32));

// 条几何：中心 x = ATT_X+28，pitch 条 y ∈ [Y0+40, Y0+50)，roll 条 y ∈ [Y0+80, Y0+90)
wire [10:0] BAR_CX  = ATT_X + 11'd28;
wire        in_pbar = (x_d >= BAR_CX - 11'd25) && (x_d <= BAR_CX + 11'd25)
                   && (y_d >= Y0 + 11'd40) && (y_d < Y0 + 11'd50);
wire        in_rbar = (x_d >= BAR_CX - 11'd25) && (x_d <= BAR_CX + 11'd25)
                   && (y_d >= Y0 + 11'd80) && (y_d < Y0 + 11'd90);
wire signed [11:0] bx = $signed({1'b0, x_d}) - $signed({1'b0, BAR_CX});
// 边框（上下沿 + 左右端）
wire on_pfrm = in_pbar && ((y_d == Y0 + 11'd40) || (y_d == Y0 + 11'd49)
                        || (bx == -12'sd25) || (bx == 12'sd25));
wire on_rfrm = in_rbar && ((y_d == Y0 + 11'd80) || (y_d == Y0 + 11'd89)
                        || (bx == -12'sd25) || (bx == 12'sd25));
// 中心零刻度线
wire on_pzero = in_pbar && (bx == 12'sd0);
wire on_rzero = in_rbar && (bx == 12'sd0);
// 填充（中心 → 值方向）
wire on_pfill = in_pbar && !on_pfrm
             && ((p_len > 12'sd0) && (bx > 12'sd0) && (bx <= p_len)
              || (p_len < 12'sd0) && (bx < 12'sd0) && (bx >= p_len));
wire on_rfill = in_rbar && !on_rfrm
             && ((r_len > 12'sd0) && (bx > 12'sd0) && (bx <= r_len)
              || (r_len < 12'sd0) && (bx < 12'sd0) && (bx >= r_len));

// ------------------------- 中文标签（osd_font 组合查表） -------------------------
// "轨迹" @(X0+4, Y0+4)；"姿态" @(ATT_X+12, Y0+8)
wire [10:0] l1x = x_d - (X0 + 11'd4);    // "轨迹" 标签区相对坐标
wire [10:0] l1y = y_d - (Y0 + 11'd4);
wire [10:0] l2x = x_d - (ATT_X + 11'd12);// "姿态" 标签区相对坐标
wire [10:0] l2y = y_d - (Y0 + 11'd8);
wire        in_lab1 = (l1x < 11'd32) && (l1y < 11'd16);
wire        in_lab2 = (l2x < 11'd32) && (l2y < 11'd16);

reg        lab_en;
reg [ 7:0] lab_ch;
reg [ 3:0] lab_row, lab_col;
always @(*) begin
    lab_en = 1'b0;  lab_ch = 8'h20;  lab_row = 4'd0;  lab_col = 4'd0;
    if (in_lab1) begin                              // 轨 迹
        lab_en  = 1'b1;
        lab_ch  = (l1x < 11'd16) ? 8'h9B : 8'h9C;
        lab_row = l1y[3:0];
        lab_col = (l1x < 11'd16) ? l1x[3:0] : (l1x - 11'd16);
    end
    else if (in_lab2) begin                         // 姿 态
        lab_en  = 1'b1;
        lab_ch  = (l2x < 11'd16) ? 8'h99 : 8'h9A;
        lab_row = l2y[3:0];
        lab_col = (l2x < 11'd16) ? l2x[3:0] : (l2x - 11'd16);
    end
end
wire [15:0] lab_bits;
osd_font u_dash_font(.ch(lab_ch), .row(lab_row), .bits(lab_bits));
wire lab_pix = lab_en && lab_bits[4'd15 - lab_col[3:0]];

// ------------------------- 边框与分隔线 -------------------------
wire on_frame = in_win && ((x_d == X0) || (x_d == X0 + WIN_W - 11'd1)
                        || (y_d == Y0) || (y_d == Y0 + WIN_H - 11'd1));
wire on_sep   = in_win && (x_d == X0 + 11'd132);

// ------------------------- 叠加输出（组合） -------------------------
assign pixel_out =
       lab_pix   ? WHITE  :
       on_track  ? GREEN  :
       on_head   ? CYAN   :
       on_body   ? WHITE  :
       on_pfill  ? YELLOW :
       on_rfill  ? CYAN   :
       on_pzero  ? GRAY   :
       on_rzero  ? GRAY   :
       on_pfrm   ? WHITE  :
       on_rfrm   ? WHITE  :
       on_sep    ? GRAY   :
       on_frame  ? WHITE  :
                   pin_d;

endmodule
