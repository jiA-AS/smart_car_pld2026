// ============================================================================
// sensor_link.v —— 传感器链集成核（57 工程移植版）
// 一条线进（uart_rxd）、一条线出（uart_txd）、解包数据全导出
//
// 内部：
//   sl_uart_rx   → v1_decode（V1.0 上行：编码器/IMU，100Hz）
//   ctrl_link_tx → sl_uart_tx（V1.1 下行：速度指令，50Hz）
//
// 现阶段（阶段1冒烟测试）：下行帧 mode=0(停车)，left=enc0低16位，right=timestamp
//   —— 串口助手能看到结构化数据证明"收+解+发"全链工作；
//   —— ESP32 端收到 mode=0 也不会动车，绝对安全。
// 阶段3接入追踪控制时：把 mode/left/right 改接 tracker_ctrl 输出即可（只改三行）。
// ============================================================================
module sensor_link #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD     = 115200
)(
    input  wire               clk,            // 50MHz（顶层接 clk_50m）
    input  wire               rst_n,          // 顶层接 rst_n
    input  wire               uart_rxd,       // E13：ESP32 -> FPGA
    output wire               uart_txd,       // D16/D17：FPGA -> ESP32/PC
    // 解包导出（阶段2/3 用：OSD 数据栏、pose_core；当前顶层可悬空）
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
    output wire       [ 7:0]  parse_result    // 0x00 好 / 0xE3 CRC错
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

// ------------------------- 下行：V1.1 指令帧 -------------------------
// 阶段1冒烟：mode=0 停车；left/right 借道传 enc0/timestamp 供观察
// 阶段3追踪：改接 tracker_ctrl 的 mode/target_left/target_right
ctrl_link_tx #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD), .SEND_HZ(50)) u_ctrl_tx (
    .clk(clk), .rst_n(rst_n),
    .mode (8'd0),
    .left (enc0[15:0]),
    .right(timestamp),
    .txd  (uart_txd)
);

endmodule
