// ============================================================================
// osd_overlay.v —— AR 叠加层 V2（PLD2026）
//
// 串在 lcd_disply 之后（lcd_clk 域）：坐标打 1 拍与 pixel_in 对齐，
// 叠加判决→字体查表→颜色选择全组合，零额外延迟。
//
// 显示内容（全部带单位、十进制人性化）：
//   中央偏上：编码器行 "编码器 E0:+12345678 ... E3:+00000042 cnt"（带符号十进制）
//             陀螺仪行 "陀螺仪 GX:-250 GY:+003 GZ:+000 dps"（LSB→dps 换算）
//   识别框  ：cam2(左屏)绿框 + 双质心红十字 + 框旁 "uuu,vvvpx"（相机内坐标）
//   中央偏下：模式+距离 "双目对接:1234mm" / "单目跟踪:1234mm"（无效显示 ----）
//   目标丢失：双目都未识别时屏幕正中央红色 "目标丢失"
//
// 检测/距离/传感器输入均为外域准静态信号，本模块内 2 级触发器同步。
// ============================================================================
module osd_overlay #(
    parameter [15:0] GYRO_LSB_PER_DPS = 16'd131  // 陀螺仪灵敏度：LSB/(°/s)
                                                 // MPU6050 @±250dps=131；LSM6DS3 @±250dps≈114
)(
    input  wire        lcd_clk,
    input  wire        rst_n,
    input  wire [10:0] pixel_xpos,
    input  wire [10:0] pixel_ypos,
    input  wire [15:0] pixel_in,
    input  wire [12:0] h_pixel,
    input  wire [12:0] v_pixel,
    // ---- cam1（右相机/右半屏），相机坐标，cam_pclk_1 域 ----
    input  wire        f1_async,
    input  wire [ 9:0] c1u_async,
    input  wire [ 9:0] c1v_async,
    // ---- cam2（左相机/左半屏），相机坐标，cam_pclk_2 域 ----
    input  wire        f2_async,
    input  wire [ 9:0] c2u_async,
    input  wire [ 9:0] c2v_async,
    input  wire [ 9:0] b2_minx_async,
    input  wire [ 9:0] b2_maxx_async,
    input  wire [ 9:0] b2_miny_async,
    input  wire [ 9:0] b2_maxy_async,
    // ---- 距离（50M 域） ----
    input  wire [15:0] dist_mm_async,
    input  wire [ 1:0] dist_src_async,  // 0=无效 1=单目 2=双目
    // ---- 传感器原始值（50M 域） ----
    input  wire [31:0] enc0,
    input  wire [31:0] enc1,
    input  wire [31:0] enc2,
    input  wire [31:0] enc3,
    input  wire [15:0] gyro_x,
    input  wire [15:0] gyro_y,
    input  wire [15:0] gyro_z,
    output wire [15:0] pixel_out
);

// ------------------------- 颜色 -------------------------
localparam GREEN  = 16'h07E0;
localparam RED    = 16'hF800;
localparam YELLOW = 16'hFFE0;
localparam WHITE  = 16'hFFFF;
localparam CYAN   = 16'h07FF;

// ------------------------- 坐标打 1 拍，与 pixel_in 对齐 -------------------------
reg [10:0] x_d1, y_d1;
always @(posedge lcd_clk or negedge rst_n) begin
    if (!rst_n) begin x_d1 <= 0; y_d1 <= 0; end
    else begin x_d1 <= pixel_xpos; y_d1 <= pixel_ypos; end
end

// ------------------------- 输入跨时钟同步 -------------------------
reg        f1a, f1b, f2a, f2b;
reg [ 1:0] dsa, dsb;
reg [ 9:0] c1ua, c1ub, c1va, c1vb, c2ua, c2ub, c2va, c2vb;
reg [ 9:0] b2xa, b2xb, b2Xa, b2Xb, b2ya, b2yb, b2Ya, b2Yb;
reg [15:0] dmm_a, dmm_b;
reg [31:0] e0a, e0b, e1a, e1b, e2a, e2b, e3a, e3b;
reg [15:0] gxa, gxb, gya, gyb, gza, gzb;
always @(posedge lcd_clk or negedge rst_n) begin
    if (!rst_n) begin
        f1a<=0; f1b<=0; f2a<=0; f2b<=0; dsa<=0; dsb<=0;
        c1ua<=0; c1ub<=0; c1va<=0; c1vb<=0;
        c2ua<=0; c2ub<=0; c2va<=0; c2vb<=0;
        b2xa<=0; b2xb<=0; b2Xa<=0; b2Xb<=0;
        b2ya<=0; b2yb<=0; b2Ya<=0; b2Yb<=0;
        dmm_a<=0; dmm_b<=0;
        e0a<=0; e0b<=0; e1a<=0; e1b<=0; e2a<=0; e2b<=0; e3a<=0; e3b<=0;
        gxa<=0; gxb<=0; gya<=0; gyb<=0; gza<=0; gzb<=0;
    end
    else begin
        f1a<=f1_async; f1b<=f1a;  f2a<=f2_async; f2b<=f2a;
        dsa<=dist_src_async; dsb<=dsa;  dmm_a<=dist_mm_async; dmm_b<=dmm_a;
        c1ua<=c1u_async; c1ub<=c1ua;  c1va<=c1v_async; c1vb<=c1va;
        c2ua<=c2u_async; c2ub<=c2ua;  c2va<=c2v_async; c2vb<=c2va;
        b2xa<=b2_minx_async; b2xb<=b2xa;  b2Xa<=b2_maxx_async; b2Xb<=b2Xa;
        b2ya<=b2_miny_async; b2yb<=b2ya;  b2Ya<=b2_maxy_async; b2Yb<=b2Ya;
        e0a<=enc0; e0b<=e0a;  e1a<=enc1; e1b<=e1a;
        e2a<=enc2; e2b<=e2a;  e3a<=enc3; e3b<=e3a;
        gxa<=gyro_x; gxb<=gxa;  gya<=gyro_y; gyb<=gya;  gza<=gyro_z; gzb<=gza;
    end
end

// ------------------------- 相机坐标 → 屏幕坐标 -------------------------
wire [10:0] half11 = h_pixel[12:1];
wire [10:0] cx1s = {1'b0, c1ub} + half11;   // cam1 右半屏
wire [10:0] cy1s = {1'b0, c1vb};
wire [10:0] cx2s = {1'b0, c2ub};            // cam2 左半屏
wire [10:0] cy2s = {1'b0, c2vb};
wire [10:0] b2x0 = {1'b0, b2xb};
wire [10:0] b2x1 = {1'b0, b2Xb};
wire [10:0] b2y0 = {1'b0, b2yb};
wire [10:0] b2y1 = {1'b0, b2Yb};

// ------------------------- 编码器：带符号十进制（8 位饱和） -------------------------
wire [31:0] m0 = e0b[31] ? (~e0b + 32'd1) : e0b;
wire [31:0] m1 = e1b[31] ? (~e1b + 32'd1) : e1b;
wire [31:0] m2 = e2b[31] ? (~e2b + 32'd1) : e2b;
wire [31:0] m3 = e3b[31] ? (~e3b + 32'd1) : e3b;
wire [31:0] m0c = (m0 > 32'd99999999) ? 32'd99999999 : m0;
wire [31:0] m1c = (m1 > 32'd99999999) ? 32'd99999999 : m1;
wire [31:0] m2c = (m2 > 32'd99999999) ? 32'd99999999 : m2;
wire [31:0] m3c = (m3 > 32'd99999999) ? 32'd99999999 : m3;

// ------------------------- 陀螺仪：LSB → dps -------------------------
wire [15:0] gxm = gxb[15] ? (~gxb + 16'd1) : gxb;
wire [15:0] gym = gyb[15] ? (~gyb + 16'd1) : gyb;
wire [15:0] gzm = gzb[15] ? (~gzb + 16'd1) : gzb;
wire [15:0] gxd = gxm / GYRO_LSB_PER_DPS;   // 0~250
wire [15:0] gyd = gym / GYRO_LSB_PER_DPS;
wire [15:0] gzd = gzm / GYRO_LSB_PER_DPS;

// ------------------------- 十进制位提取 -------------------------
// 距离（0~9999mm）
wire [3:0] d_th = dmm_b / 1000;
wire [3:0] d_hu = (dmm_b / 100) % 10;
wire [3:0] d_te = (dmm_b / 10) % 10;
wire [3:0] d_on = dmm_b % 10;
// 相机内质心坐标（3 位）
wire [3:0] u1_h = c1ub / 100;  wire [3:0] u1_t = (c1ub / 10) % 10;  wire [3:0] u1_o = c1ub % 10;
wire [3:0] v1_h = c1vb / 100;  wire [3:0] v1_t = (c1vb / 10) % 10;  wire [3:0] v1_o = c1vb % 10;
wire [3:0] u2_h = c2ub / 100;  wire [3:0] u2_t = (c2ub / 10) % 10;  wire [3:0] u2_o = c2ub % 10;
wire [3:0] v2_h = c2vb / 100;  wire [3:0] v2_t = (c2vb / 10) % 10;  wire [3:0] v2_o = c2vb % 10;
// 陀螺仪 dps（3 位）
wire [3:0] gx_h = gxd / 100;  wire [3:0] gx_t = (gxd / 10) % 10;  wire [3:0] gx_o = gxd % 10;
wire [3:0] gy_h = gyd / 100;  wire [3:0] gy_t = (gyd / 10) % 10;  wire [3:0] gy_o = gyd % 10;
wire [3:0] gz_h = gzd / 100;  wire [3:0] gz_t = (gzd / 10) % 10;  wire [3:0] gz_o = gzd % 10;

// ------------------------- 字符工具函数 -------------------------
function [7:0] dec2ch;
    input [3:0] d;
    dec2ch = 8'h30 + d;
endfunction

// ------------------------- 布局 -------------------------
// 编码器行：48 + 8 + 55*8(440) = 496px
localparam [12:0] L0_W = 13'd496;
wire [10:0] L0_X = (h_pixel - L0_W) >> 1;
wire [10:0] L0_Y = v_pixel >> 3;                          // 中央偏上
// 陀螺仪行：48 + 8 + 27*8(216) = 272px
localparam [12:0] L1_W = 13'd272;
wire [10:0] L1_X = (h_pixel - L1_W) >> 1;
wire [10:0] L1_Y = L0_Y + 11'd24;
// 模式+距离行：4中文字(64) + 8 + 7*8(56) = 128px，中央偏下
localparam [12:0] LD_W = 13'd128;
wire [10:0] LD_X = (h_pixel - LD_W) >> 1;
wire [10:0] LD_Y = (v_pixel >> 1) + (v_pixel >> 2);
// 目标丢失：4*16 + 3*8 = 88px，屏幕正中央
localparam [12:0] LOST_W = 13'd88;
wire [10:0] LOST_X = (h_pixel - LOST_W) >> 1;
wire [10:0] LOST_Y = (v_pixel >> 1) - 11'd8;

// 框旁标签 "uuu,vvvpx"（9字符 72px）
wire [10:0] lab1_x = (cx1s > h_pixel[10:0] - 11'd84) ? (h_pixel[10:0] - 11'd84)
                                                     : (cx1s + 11'd12);
wire [10:0] lab1_y = (cy1s > v_pixel[10:0] - 11'd28) ? (v_pixel[10:0] - 11'd28)
                                                     : (cy1s + 11'd12);
wire [10:0] lab2_x = (b2x0 > h_pixel[10:0] - 11'd80) ? (h_pixel[10:0] - 11'd80) : b2x0;
wire [10:0] lab2_y = (b2y0 >= 11'd20) ? (b2y0 - 11'd20)
                                      : ((b2y1 > v_pixel[10:0] - 11'd20)
                                         ? (v_pixel[10:0] - 11'd20) : (b2y1 + 11'd4));

// ------------------------- 行内相对坐标 -------------------------
wire [10:0] x_rel0  = x_d1 - L0_X;    wire [10:0] y_rel0  = y_d1 - L0_Y;
wire [10:0] x_rel1  = x_d1 - L1_X;    wire [10:0] y_rel1  = y_d1 - L1_Y;
wire [10:0] x_reld  = x_d1 - LD_X;    wire [10:0] y_reld  = y_d1 - LD_Y;
wire [10:0] x_rell  = x_d1 - LOST_X;  wire [10:0] y_rell  = y_d1 - LOST_Y;
wire [10:0] x_relb1 = x_d1 - lab1_x;  wire [10:0] y_relb1 = y_d1 - lab1_y;
wire [10:0] x_relb2 = x_d1 - lab2_x;  wire [10:0] y_relb2 = y_d1 - lab2_y;

wire [5:0] col0  = (x_rel0 - 11'd56) >> 3;
wire [5:0] col1  = (x_rel1 - 11'd56) >> 3;
wire [5:0] cold  = (x_reld - 11'd72) >> 3;   // 距离 ASCII 区（中文占0~63，间隔64~71）
wire [5:0] colb1 = x_relb1 >> 3;
wire [5:0] colb2 = x_relb2 >> 3;

wire [1:0]  lost_idx = (x_rell < 11'd24) ? 2'd0 :
                       (x_rell < 11'd48) ? 2'd1 :
                       (x_rell < 11'd72) ? 2'd2 : 2'd3;
wire [10:0] lost_cell_x = x_rell - {5'd0, lost_idx, 4'b0000} - {6'd0, lost_idx, 3'b000};

wire lost = !f1b && !f2b;

// 距离行中文模式标签字索引（4 字）：双目对接=92 88 93 94 / 单目跟踪=8F 88 90 91
wire [1:0]  md_idx = x_reld[5:4];           // 0~3（每字 16px）

// ------------------------- 文本区域译码（组合） -------------------------
reg        text_en;
reg        cjk;
reg [ 7:0] ch;
reg [ 3:0] crow;
reg [ 3:0] ccol;
reg [15:0] tcolor;

always @(*) begin
    text_en = 1'b0; cjk = 1'b0; ch = 8'h20; crow = 4'd0; ccol = 4'd0; tcolor = WHITE;

    // ---------- 目标丢失（屏幕正中央，最高优先级） ----------
    if (lost && y_rell < 11'd16 && x_rell < LOST_W[10:0]) begin
        if (lost_cell_x < 11'd16) begin
            text_en = 1'b1; cjk = 1'b1; tcolor = RED;
            ch    = 8'h88 + {6'd0, lost_idx};                 // 目(0x88) 标 丢 失
            crow  = y_rell[3:0];
            ccol  = lost_cell_x[3:0];
        end
    end
    // ---------- 编码器行（十进制带符号 + cnt） ----------
    else if (y_rel0 < 11'd16 && x_rel0 < L0_W[10:0]) begin
        if (x_rel0 < 11'd48) begin
            text_en = 1'b1; cjk = 1'b1; tcolor = WHITE;
            ch    = 8'h80 + {6'd0, x_rel0[5:4]};              // 编(0x80) 码 器
            crow  = y_rel0[3:0];
            ccol  = x_rel0[3:0];
        end
        else if (x_rel0 >= 11'd56) begin
            text_en = 1'b1; tcolor = WHITE;
            crow  = y_rel0[3:0];
            ccol  = (x_rel0 - 11'd56) & 11'd7;
            // 每路 12 字符："E0:" + 符号 + 8 位数字；4 路 + 3 空格 + " cnt"
            case (col0)
                6'd0 : ch = 8'h45;  6'd1 : ch = 8'h30;  6'd2 : ch = 8'h3A;   // E0:
                6'd3 : ch = e0b[31] ? 8'h2D : 8'h2B;                         // +/-
                6'd4 : ch = dec2ch(m0c / 10000000 % 10);
                6'd5 : ch = dec2ch(m0c / 1000000 % 10);
                6'd6 : ch = dec2ch(m0c / 100000 % 10);
                6'd7 : ch = dec2ch(m0c / 10000 % 10);
                6'd8 : ch = dec2ch(m0c / 1000 % 10);
                6'd9 : ch = dec2ch(m0c / 100 % 10);
                6'd10: ch = dec2ch(m0c / 10 % 10);
                6'd11: ch = dec2ch(m0c % 10);
                6'd12: ch = 8'h20;
                6'd13: ch = 8'h45;  6'd14: ch = 8'h31;  6'd15: ch = 8'h3A;   // E1:
                6'd16: ch = e1b[31] ? 8'h2D : 8'h2B;
                6'd17: ch = dec2ch(m1c / 10000000 % 10);
                6'd18: ch = dec2ch(m1c / 1000000 % 10);
                6'd19: ch = dec2ch(m1c / 100000 % 10);
                6'd20: ch = dec2ch(m1c / 10000 % 10);
                6'd21: ch = dec2ch(m1c / 1000 % 10);
                6'd22: ch = dec2ch(m1c / 100 % 10);
                6'd23: ch = dec2ch(m1c / 10 % 10);
                6'd24: ch = dec2ch(m1c % 10);
                6'd25: ch = 8'h20;
                6'd26: ch = 8'h45;  6'd27: ch = 8'h32;  6'd28: ch = 8'h3A;   // E2:
                6'd29: ch = e2b[31] ? 8'h2D : 8'h2B;
                6'd30: ch = dec2ch(m2c / 10000000 % 10);
                6'd31: ch = dec2ch(m2c / 1000000 % 10);
                6'd32: ch = dec2ch(m2c / 100000 % 10);
                6'd33: ch = dec2ch(m2c / 10000 % 10);
                6'd34: ch = dec2ch(m2c / 1000 % 10);
                6'd35: ch = dec2ch(m2c / 100 % 10);
                6'd36: ch = dec2ch(m2c / 10 % 10);
                6'd37: ch = dec2ch(m2c % 10);
                6'd38: ch = 8'h20;
                6'd39: ch = 8'h45;  6'd40: ch = 8'h33;  6'd41: ch = 8'h3A;   // E3:
                6'd42: ch = e3b[31] ? 8'h2D : 8'h2B;
                6'd43: ch = dec2ch(m3c / 10000000 % 10);
                6'd44: ch = dec2ch(m3c / 1000000 % 10);
                6'd45: ch = dec2ch(m3c / 100000 % 10);
                6'd46: ch = dec2ch(m3c / 10000 % 10);
                6'd47: ch = dec2ch(m3c / 1000 % 10);
                6'd48: ch = dec2ch(m3c / 100 % 10);
                6'd49: ch = dec2ch(m3c / 10 % 10);
                6'd50: ch = dec2ch(m3c % 10);
                6'd51: ch = 8'h20;
                6'd52: ch = 8'h63;  6'd53: ch = 8'h6E;  6'd54: ch = 8'h74;   // cnt
                default: ch = 8'h20;
            endcase
        end
    end
    // ---------- 陀螺仪行（dps 带符号） ----------
    else if (y_rel1 < 11'd16 && x_rel1 < L1_W[10:0]) begin
        if (x_rel1 < 11'd48) begin
            text_en = 1'b1; cjk = 1'b1; tcolor = CYAN;
            ch    = 8'h83 + {6'd0, x_rel1[5:4]};              // 陀(0x83) 螺 仪
            crow  = y_rel1[3:0];
            ccol  = x_rel1[3:0];
        end
        else if (x_rel1 >= 11'd56) begin
            text_en = 1'b1; tcolor = CYAN;
            crow  = y_rel1[3:0];
            ccol  = (x_rel1 - 11'd56) & 11'd7;
            case (col1)
                6'd0 : ch = 8'h47;  6'd1 : ch = 8'h58;  6'd2 : ch = 8'h3A;   // GX:
                6'd3 : ch = gxb[15] ? 8'h2D : 8'h2B;
                6'd4 : ch = dec2ch(gx_h);  6'd5 : ch = dec2ch(gx_t);  6'd6 : ch = dec2ch(gx_o);
                6'd7 : ch = 8'h20;
                6'd8 : ch = 8'h47;  6'd9 : ch = 8'h59;  6'd10: ch = 8'h3A;   // GY:
                6'd11: ch = gyb[15] ? 8'h2D : 8'h2B;
                6'd12: ch = dec2ch(gy_h);  6'd13: ch = dec2ch(gy_t);  6'd14: ch = dec2ch(gy_o);
                6'd15: ch = 8'h20;
                6'd16: ch = 8'h47;  6'd17: ch = 8'h5A;  6'd18: ch = 8'h3A;   // GZ:
                6'd19: ch = gzb[15] ? 8'h2D : 8'h2B;
                6'd20: ch = dec2ch(gz_h);  6'd21: ch = dec2ch(gz_t);  6'd22: ch = dec2ch(gz_o);
                6'd23: ch = 8'h20;
                6'd24: ch = 8'h64;  6'd25: ch = 8'h70;  6'd26: ch = 8'h73;   // dps
                default: ch = 8'h20;
            endcase
        end
    end
    // ---------- 模式+距离行（中央偏下） ----------
    else if (!lost && y_reld < 11'd16 && x_reld < LD_W[10:0]) begin
        if (x_reld < 11'd64) begin
            // 中文模式标签 4 字：双目对接=92 88 93 94 / 单目跟踪=8F 88 90 91
            text_en = 1'b1; cjk = 1'b1;
            tcolor  = (f1b && f2b) ? GREEN : YELLOW;
            case (md_idx)
                2'd0:    ch = (f1b && f2b) ? 8'h92 : 8'h8F;   // 双 / 单
                2'd1:    ch = 8'h88;                          // 目
                2'd2:    ch = (f1b && f2b) ? 8'h93 : 8'h90;   // 对 / 跟
                default: ch = (f1b && f2b) ? 8'h94 : 8'h91;   // 接 / 踪
            endcase
            crow  = y_reld[3:0];
            ccol  = x_reld[3:0];
        end
        else if (x_reld >= 11'd72) begin                    // ":1234mm"
            text_en = 1'b1; tcolor = (f1b && f2b) ? GREEN : YELLOW;
            crow  = y_reld[3:0];
            ccol  = (x_reld - 11'd72) & 11'd7;
            case (cold)
                6'd0 : ch = 8'h3A;                          // :
                6'd1 : ch = (dsb != 2'd0) ? dec2ch(d_th) : 8'h2D;
                6'd2 : ch = (dsb != 2'd0) ? dec2ch(d_hu) : 8'h2D;
                6'd3 : ch = (dsb != 2'd0) ? dec2ch(d_te) : 8'h2D;
                6'd4 : ch = (dsb != 2'd0) ? dec2ch(d_on) : 8'h2D;
                6'd5 : ch = 8'h6D;                          // m
                6'd6 : ch = 8'h6D;                          // m
                default: ch = 8'h20;
            endcase
        end
    end
    // ---------- cam1（右屏）质心旁标签 "uuu,vvvpx" ----------
    else if (f1b && y_relb1 < 11'd16 && x_relb1 < 11'd72) begin
        text_en = 1'b1; tcolor = YELLOW;
        crow  = y_relb1[3:0];
        ccol  = x_relb1 & 11'd7;
        case (colb1)
            6'd0 : ch = dec2ch(u1_h);
            6'd1 : ch = dec2ch(u1_t);
            6'd2 : ch = dec2ch(u1_o);
            6'd3 : ch = 8'h2C;                              // ,
            6'd4 : ch = dec2ch(v1_h);
            6'd5 : ch = dec2ch(v1_t);
            6'd6 : ch = dec2ch(v1_o);
            6'd7 : ch = 8'h70;                              // p
            6'd8 : ch = 8'h78;                              // x
            default: ch = 8'h20;
        endcase
    end
    // ---------- cam2（左屏）框旁标签 "uuu,vvvpx" ----------
    else if (f2b && y_relb2 < 11'd16 && x_relb2 < 11'd72) begin
        text_en = 1'b1; tcolor = YELLOW;
        crow  = y_relb2[3:0];
        ccol  = x_relb2 & 11'd7;
        case (colb2)
            6'd0 : ch = dec2ch(u2_h);
            6'd1 : ch = dec2ch(u2_t);
            6'd2 : ch = dec2ch(u2_o);
            6'd3 : ch = 8'h2C;
            6'd4 : ch = dec2ch(v2_h);
            6'd5 : ch = dec2ch(v2_t);
            6'd6 : ch = dec2ch(v2_o);
            6'd7 : ch = 8'h70;
            6'd8 : ch = 8'h78;
            default: ch = 8'h20;
        endcase
    end
end

// ------------------------- 字体 ROM 查表 -------------------------
wire [15:0] font_bits;
osd_font u_osd_font(
    .ch   (ch),
    .row  (crow),
    .bits (font_bits)
);
wire text_pix = text_en && (cjk ? font_bits[4'd15 - ccol]
                                 : font_bits[3'd7 - ccol[2:0]]);

// ------------------------- 图形：cam2 识别框 + 双质心十字 -------------------------
wire on_b2 = f2b
    && (x_d1 >= b2x0) && (x_d1 <= b2x1)
    && (y_d1 >= b2y0) && (y_d1 <= b2y1)
    && ((x_d1 < b2x0 + 11'd2) || (x_d1 > b2x1 - 11'd2)
     || (y_d1 < b2y0 + 11'd2) || (y_d1 > b2y1 - 11'd2));

wire [10:0] dx1 = (x_d1 > cx1s) ? (x_d1 - cx1s) : (cx1s - x_d1);
wire [10:0] dy1 = (y_d1 > cy1s) ? (y_d1 - cy1s) : (cy1s - y_d1);
wire [10:0] dx2 = (x_d1 > cx2s) ? (x_d1 - cx2s) : (cx2s - x_d1);
wire [10:0] dy2 = (y_d1 > cy2s) ? (y_d1 - cy2s) : (cy2s - y_d1);
wire on_c1 = f1b && ((dx1 <= 11'd8 && y_d1 == cy1s)
                  || (dy1 <= 11'd8 && x_d1 == cx1s));
wire on_c2 = f2b && ((dx2 <= 11'd8 && y_d1 == cy2s)
                  || (dy2 <= 11'd8 && x_d1 == cx2s));

wire        gfx_on  = on_b2 || on_c1 || on_c2;
wire [15:0] gfx_col = (on_c1 || on_c2) ? RED : GREEN;

// ------------------------- 叠加输出（组合，与 pixel_in 同拍） -------------------------
assign pixel_out = text_pix ? tcolor
                 : gfx_on   ? gfx_col
                 :            pixel_in;

endmodule
