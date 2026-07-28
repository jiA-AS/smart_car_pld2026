// ============================================================================
// sensor_link.v -- 传感器链集成核（三模式追踪版 V2）
// 一条线进（uart_rxd）、一条线出（uart_txd）、解包数据全导出
//
// 内部：
//   sl_uart_rx   → v1_decode（V1.0 上行：编码器/IMU，100Hz）
//   tracker_ctrl → ctrl_link_tx → sl_uart_tx（V1.1 下行：追踪速度指令，50Hz）
//
// V2 变化：tracker_ctrl 升级为三模式（未识别停车/单目跟随/双目对接），
//   本模块新增端口透传双目识别标志（f1/f2）与距离（dist_mm/dist_src）。
//   ★ 单位约定：trk_left/trk_right ∈ [-100,+100]，百分比（%），见协议 V1.2
// ============================================================================
module sensor_link #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD     = 115200
)(
    input  wire               clk,            // 50MHz（顶层接 clk_50m）
    input  wire               rst_n,          // 顶层接 rst_n
    input  wire               uart_rxd,       // E13：ESP32 -> FPGA
    output wire               uart_txd,       // F14：FPGA -> ESP32/PC
    // ---- 双目识别标志（模式判定，cam_pclk 域准静态） ----
    input  wire               f1,             // cam1（右）识别到
    input  wire               f2,             // cam2（左）识别到
    // ---- 融合后的绿灯检测结果（顶层融合，准静态） ----
    input  wire               gd_found,
    input  wire       [ 9:0]  gd_u,
    input  wire       [ 9:0]  gd_min_y,
    input  wire       [ 9:0]  gd_max_y,
    // ---- 距离（stereo_dist，50M 域） ----
    input  wire       [15:0]  dist_mm,
    input  wire       [ 1:0]  dist_src,       // 0=无效 1=单目 2=双目
    // 解包导出（OSD 数据栏用）
    output wire       [15:0]  timestamp,
    output wire signed [31:0] enc0,
    output wire signed [31:0] enc1,
    output wire signed [31:0] enc2,
    output wire signed [31:0] enc3,
    output wire signed [15:0] gyro_x,
    output wire signed [15:0] gyro_y,
    output wire signed [15:0] gyro_z,
    output wire signed [15:0] acc_x,
    output wire signed [15:0] acc_y,
    output wire signed [15:0] acc_z,
    output wire               parse_done,     // 好帧单拍脉冲
    output wire       [ 7:0]  parse_result,   // 0x00 好 / 0xE3 CRC错
    // ---- 追踪指令监视（ILA 调试用，顶层可悬空） ----
    output wire       [ 7:0]  trk_mode,       // 0=停车 1=单目跟随 2=双目对接
    output wire       [15:0]  trk_left,       // %（-100~+100）
    output wire       [15:0]  trk_right
);

// ------------------------- 上行：接收 + 解包 -------------------------
wire [7:0] rx_data;
wire       rx_done;

sl_uart_rx #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD)) u_rx (
    .clk(clk), .rst_n(rst_n),
    .rxd(uart_rxd),
    .rx_data(rx_data), .rx_done(rx_done)
);

v1_decode u_decode (
    .clk(clk), .rst_n(rst_n),
    .rx_data(rx_data), .rx_done(rx_done),
    .timestamp(timestamp),
    .enc0(enc0), .enc1(enc1), .enc2(enc2), .enc3(enc3),
    .gyro_x(gyro_x), .gyro_y(gyro_y), .gyro_z(gyro_z),
    .acc_x(acc_x), .acc_y(acc_y), .acc_z(acc_z),
    .parse_done(parse_done),
    .parse_result(parse_result)
);

// ------------------------- 追踪控制：视觉 -> 速度指令（三模式） -------------------------
tracker_ctrl #(
    .U_CENTER    (10'd200),
    .DEADZONE    (10'd8),
    .V_MAX       (8'd45),
    .MONO_V      (8'd25),      // 单目跟随速度（%，低速谨慎）
    .MONO_OFFS   (10'd60),     // 单目方位偏移补偿（像素，实测标定）
    .DIST_ARRIVE (16'd300),    // 对接到达距离（mm）
    .KD_NUM      (10'd102),    // 距离环增益 ×1024
    .H_REF       (10'd120),    // [退化路径] 距离保持灯高
    .H_ARRIVE    (10'd150)     // [退化路径] 到达判定灯高
) u_tracker (
    .clk      (clk),
    .rst_n    (rst_n),
    .f1       (f1),
    .f2       (f2),
    .gd_found (gd_found),
    .gd_u     (gd_u),
    .gd_min_y (gd_min_y),
    .gd_max_y (gd_max_y),
    .dist_mm  (dist_mm),
    .dist_src (dist_src),
    .mode     (trk_mode),
    .left     (trk_left),
    .right    (trk_right)
);

// ------------------------- 下行：V1.1 指令帧 -------------------------
ctrl_link_tx #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD), .SEND_HZ(50)) u_ctrl_tx (
    .clk(clk), .rst_n(rst_n),
    .mode (trk_mode),
    .left (trk_left),
    .right(trk_right),
    .txd  (uart_txd)
);

endmodule
