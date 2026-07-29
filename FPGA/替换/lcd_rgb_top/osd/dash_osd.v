// ============================================================================
// dash_osd.v —— 车辆状态图形化仪表盘 V3.1（赛道三基础要求4 + 数字孪生扩展）
//
// V3.1 瘦身（应对 Vivado 2018.3 技术映射 TclStackFree 崩溃）：
//   1) 轨迹 FIFO 64→32 点（并行比较器减半，显示 6.4s 历史）
//   2) 移除 osd_font 例化（2080 项巨型 case）——"轨迹/姿态"4 字直接
//      内嵌 64 项小 ROM
//   3) 饱和函数 sat12 由 2 个 32bit 比较改为 20bit 高位检测
// 功能与接口和 V3 完全一致，直接替换即可。
//
// 串在 osd_overlay 之后（lcd_clk 域）：坐标与 pixel_in 各打 1 拍对齐，
// 叠加判决全组合输出（视频链合计 2 拍延迟，无感知）。
//
// 右下角仪表盘窗口（200×136）：左 128×128 俯视轨迹区（32 点 FIFO 绿点
// + 小车图标 + 8 方向航向线），右 56 宽姿态条区（pitch/roll 各 ±45°
// 满量程 ±24px，中心为零）。世界→屏幕：sx=(x-cur_x)>>6（64mm/px）。
//
// 跨时钟说明：轨迹 FIFO 与 pos 在 sys_clk(50M) 域，lcd_clk 域 2 级同步
//   采样 cur_x/cur_y；FIFO 为 5Hz 准静态点，直接异步采样（单像素偶发
//   亚稳无感知，工程可接受）。
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
    // ---- [V3.2] 显示模式（sys_clk 域准静态，内部同步到 lcd_clk） ----
    input  wire        [ 1:0] disp_mode,  // 0=视角 1=轨迹 2=调试
    output wire        [15:0] pixel_out
);

// [V3.2] 新增 disp_mode 端口：轨迹档（==1）时窗外画面压暗一半、窗框青色高亮，
//        配合遥控左拨杆 s1 中档实现"轨迹视角分屏"。
// ------------------------- 颜色 -------------------------
localparam GREEN  = 16'h07E0;
localparam WHITE  = 16'hFFFF;
localparam CYAN   = 16'h07FF;
localparam YELLOW = 16'hFFE0;
localparam GRAY   = 16'h8410;

// ------------------------- 轨迹 FIFO（sys_clk 域，32 点） -------------------------
reg signed [15:0] fifo_x [0:31];
reg signed [15:0] fifo_y [0:31];
integer k;
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        for (k = 0; k < 32; k = k + 1) begin
            fifo_x[k] <= 16'sd0;  fifo_y[k] <= 16'sd0;
        end
    end
    else if (trk_wr) begin
        fifo_x[0] <= trk_x;  fifo_y[0] <= trk_y;
        for (k = 1; k < 32; k = k + 1) begin
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

// ------------------------- 轨迹命中（32 点并行比较） -------------------------
wire signed [11:0] px_rel = $signed({1'b0, x_d}) - $signed({1'b0, TRK_CX});
wire signed [11:0] py_rel = $signed({1'b0, y_d}) - $signed({1'b0, TRK_CY});
wire        in_trk = (x_rel < 11'd128) && (y_rel >= 11'd4) && (y_rel < 11'd132);

// [V3.1] 轻量饱和：高 20 位全零（非负小值）或全一（负小值）判界
function [11:0] sat12;
    input signed [31:0] v;
    begin
        if (v[31:12] == 20'h00000)      sat12 = v[11:0];        // 0 ~ +2047
        else if (&v[31:12])             sat12 = v[11:0];        // -2048 ~ -1
        else                            sat12 = v[31] ? 12'h800 : 12'h7FF;
    end
endfunction

wire [31:0] trk_hit;
genvar gi;
generate
    for (gi = 0; gi < 32; gi = gi + 1) begin : G_HIT
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
wire signed [11:0] p_len = (p_len32 > 32'sd24) ? 12'sd24 :
                           ((p_len32 < -32'sd24) ? -12'sd24 : p_len32[11:0]);
wire signed [11:0] r_len = (r_len32 > 32'sd24) ? 12'sd24 :
                           ((r_len32 < -32'sd24) ? -12'sd24 : r_len32[11:0]);

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

// ------------------------- [V3.1] 内嵌标签字库（仅 轨迹/姿态 4 字） -------------------------
// "轨迹" @(X0+4, Y0+4)；"姿态" @(ATT_X+12, Y0+8)
wire [10:0] l1x = x_d - (X0 + 11'd4);    // "轨迹" 标签区相对坐标
wire [10:0] l1y = y_d - (Y0 + 11'd4);
wire [10:0] l2x = x_d - (ATT_X + 11'd12);// "姿态" 标签区相对坐标
wire [10:0] l2y = y_d - (Y0 + 11'd8);
wire        in_lab1 = (l1x < 11'd32) && (l1y < 11'd16);
wire        in_lab2 = (l2x < 11'd32) && (l2y < 11'd16);

wire        lab_en  = in_lab1 || in_lab2;
wire [ 1:0] lab_idx = in_lab1 ? ((l1x < 11'd16) ? 2'd0 : 2'd1)   // 轨 迹
                              : ((l2x < 11'd16) ? 2'd2 : 2'd3);  // 姿 态
wire [ 3:0] lab_row = in_lab1 ? l1y[3:0] : l2y[3:0];
wire [10:0] lab_lx  = in_lab1 ? l1x : l2x;
wire [ 3:0] lab_col = (lab_lx < 11'd16) ? lab_lx[3:0] : (lab_lx - 11'd16);

// 4 字 × 16 行点阵（unifont，与 osd_font.v 同图源）
reg [15:0] gbits;
always @(*) begin
    case (lab_idx)
    2'd0: begin  // 轨
        case (lab_row)
            4'd0: gbits = 16'h2080;  4'd1: gbits = 16'h2080;
            4'd2: gbits = 16'h2080;  4'd3: gbits = 16'hFC80;
            4'd4: gbits = 16'h43F0;  4'd5: gbits = 16'h5090;
            4'd6: gbits = 16'h9090;  4'd7: gbits = 16'hFC90;
            4'd8: gbits = 16'h1090;  4'd9: gbits = 16'h1090;
            4'd10: gbits = 16'h1C90; 4'd11: gbits = 16'hF092;
            4'd12: gbits = 16'h5112; 4'd13: gbits = 16'h1112;
            4'd14: gbits = 16'h120E; 4'd15: gbits = 16'h1400;
        endcase
    end
    2'd1: begin  // 迹
        case (lab_row)
            4'd0: gbits = 16'h0040;  4'd1: gbits = 16'h2020;
            4'd2: gbits = 16'h1020;  4'd3: gbits = 16'h17FE;
            4'd4: gbits = 16'h0090;  4'd5: gbits = 16'h0090;
            4'd6: gbits = 16'hF294;  4'd7: gbits = 16'h1292;
            4'd8: gbits = 16'h1492;  4'd9: gbits = 16'h1110;
            4'd10: gbits = 16'h1110; 4'd11: gbits = 16'h1250;
            4'd12: gbits = 16'h1420; 4'd13: gbits = 16'h2800;
            4'd14: gbits = 16'h47FE; 4'd15: gbits = 16'h0000;
        endcase
    end
    2'd2: begin  // 姿
        case (lab_row)
            4'd0: gbits = 16'h4080;  4'd1: gbits = 16'h2080;
            4'd2: gbits = 16'h09FC;  4'd3: gbits = 16'h1204;
            4'd4: gbits = 16'h2448;  4'd5: gbits = 16'hE040;
            4'd6: gbits = 16'h20A0;  4'd7: gbits = 16'h2318;
            4'd8: gbits = 16'h2C06;  4'd9: gbits = 16'h0400;
            4'd10: gbits = 16'hFFFE; 4'd11: gbits = 16'h0820;
            4'd12: gbits = 16'h1C40; 4'd13: gbits = 16'h0380;
            4'd14: gbits = 16'h0C70; 4'd15: gbits = 16'h7008;
        endcase
    end
    default: begin  // 态
        case (lab_row)
            4'd0: gbits = 16'h0100;  4'd1: gbits = 16'h0100;
            4'd2: gbits = 16'h7FFC;  4'd3: gbits = 16'h0100;
            4'd4: gbits = 16'h0280;  4'd5: gbits = 16'h0440;
            4'd6: gbits = 16'h0A20;  4'd7: gbits = 16'h3118;
            4'd8: gbits = 16'hC006;  4'd9: gbits = 16'h0100;
            4'd10: gbits = 16'h0888; 4'd11: gbits = 16'h4884;
            4'd12: gbits = 16'h4812; 4'd13: gbits = 16'h4812;
            4'd14: gbits = 16'h87F0; 4'd15: gbits = 16'h0000;
        endcase
    end
    endcase
end
wire lab_pix = lab_en && gbits[4'd15 - lab_col];

// ------------------------- 边框与分隔线 -------------------------
wire on_frame = in_win && ((x_d == X0) || (x_d == X0 + WIN_W - 11'd1)
                        || (y_d == Y0) || (y_d == Y0 + WIN_H - 11'd1));
wire on_sep   = in_win && (x_d == X0 + 11'd132);

// ------------------------- [V3.2] 轨迹档突出：模式同步 + 窗外压暗 -------------------------
// disp_mode 来自 sys_clk 域（准静态），2 级同步到 lcd_clk 域
reg [1:0] dm_a, dm_b;
always @(posedge lcd_clk or negedge rst_n) begin
    if (!rst_n) begin dm_a <= 2'd0; dm_b <= 2'd0; end
    else        begin dm_a <= disp_mode; dm_b <= dm_a; end
end
wire track_mode = (dm_b == 2'd1);
// RGB565 各通道 >>1 压暗（R[15:11] G[10:5] B[4:0]）
wire [15:0] pin_dim = {1'b0, pin_d[15:12], 1'b0, pin_d[10:6], 1'b0, pin_d[4:1]};
wire [15:0] pin_sel = (track_mode && !in_win) ? pin_dim : pin_d;
wire [15:0] frame_color = track_mode ? CYAN : WHITE;

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
       on_frame  ? frame_color :
                   pin_sel;

endmodule
