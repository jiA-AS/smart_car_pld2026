// ============================================================================
// tracker_ctrl.v -- 绿灯追踪控制器（比例导引 + 距离保持 + 丢失停车） V2
//
// 输入：green_detect 的检测结果（经顶层双目融合，准静态，本模块 50MHz 采样）
// 输出：V1.1 下行指令 mode/left/right（速度 -100~+100，接 ctrl_link_tx）
//
// V2 改动（按需求）：识别不到目标时不再原地转圈搜索，而是立即静止停车，
//   并在 LCD 上显示"目标丢失"（显示由 osd_overlay 完成）。
//   - S_LOST / S_SEARCH（转圈）状态删除，丢失当拍即 mode=0、left=right=0
//   - 上电默认 S_STOP（无目标不动），看到目标才进 S_TRACK
//   - SEARCH_SPD / LOST_LIM 参数保留声明以兼容 sensor_link 例化，不再使用
//
// 控制律（追踪中，不变）：
//   转向：err_u = gd_u - U_CENTER；turn = err_u/4（比例，右偏正）
//         left = base + turn，right = base - turn（灯偏右 -> 右轮慢 -> 车头右摆）
//   距离：h = 包围盒高度（距离代理，越近越大）
//         base = (H_REF - h)/2，限幅 [0, V_MAX]；h >= H_ARRIVE 判定到达停车
//
// 所有计算 20ms 一拍（与 V1.1 50Hz 发送节拍对齐），输出寄存器即存储。
// ============================================================================
module tracker_ctrl #(
parameter U_CENTER  = 10'd200,  // 画面中线（H_ACTIVE/2）
parameter DEADZONE  = 10'd8,    // 转向死区（像素），防抖动
parameter V_MAX     = 8'd45,    // 基准速度上限（0~100）
parameter H_REF     = 10'd120,  // 目标距离对应的包围盒高度（实测标定！）
parameter H_ARRIVE  = 10'd150,  // 到达判定高度（大于此值停车）
parameter SEARCH_SPD= 8'd22,    // [V2 弃用] 原为搜索转速，保留兼容
parameter LOST_LIM  = 8'd25     // [V2 弃用] 原为丢灯容忍拍数，保留兼容
)(
input  wire        clk,         // 50MHz
input  wire        rst_n,
// ---- 检测结果（双目融合后，准静态跨域采样） ----
input  wire        gd_found,
input  wire [ 9:0] gd_u,
input  wire [ 9:0] gd_min_y,
input  wire [ 9:0] gd_max_y,
// ---- V1.1 指令输出（接 ctrl_link_tx） ----
output reg  [ 7:0] mode,        // 0=停车 1=速度控制
output reg  [15:0] left,        // 低 8 位有效：有符号速度 -100~+100
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
localparam S_TRACK  = 2'd0,   // 正常追踪
S_STOP   = 2'd1,   // 目标丢失：静止停车（V2：替代原转圈搜索）
S_ARRIVE = 2'd2;   // 到达停车
reg [1:0] state = S_STOP;   // 上电无目标，静止等待
// ------------------------- 中间量 -------------------------
wire [9:0] box_h  = gd_max_y - gd_min_y;              // 包围盒高度
// 有符号偏差与速度量（12 位足够）
wire signed [11:0] err_u  = $signed({2'b00, gd_u}) - $signed({2'b00, U_CENTER});
wire signed [11:0] turn   = err_u >>> 2;              // 比例转向 Kp=1/4
wire signed [11:0] d_err  = $signed({2'b00, H_REF}) - $signed({2'b00, box_h});
wire signed [11:0] base_r = d_err >>> 1;              // 比例前进 Kd=1/2
// 限幅到 [0, V_MAX]
wire signed [11:0] base   = (base_r < 12'sd0) ? 12'sd0 :
(base_r > $signed({4'd0, V_MAX})) ? $signed({4'd0, V_MAX}) : base_r;
// 死区处理后的转向量
wire signed [11:0] turn_d = (err_u > $signed({2'b00, DEADZONE}) ||
err_u < -$signed({2'b00, DEADZONE})) ? turn : 12'sd0;
// 左右轮合成 + 限幅到 [-100, +100]
wire signed [11:0] left_r  = base + turn_d;
wire signed [11:0] right_r = base - turn_d;
function signed [11:0] clamp100;
input signed [11:0] v;
begin
if (v > 12'sd100)       clamp100 = 12'sd100;
else if (v < -12'sd100) clamp100 = -12'sd100;
else                    clamp100 = v;
end
endfunction
// 限幅后的左右轮速度（有符号 12 位）
wire signed [11:0] left_c  = clamp100(left_r);
wire signed [11:0] right_c = clamp100(right_r);
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
// ---------------- 追踪 ----------------
S_TRACK: begin
if (!gd_found) begin
// 目标丢失：立即静止停车（V2：不再转圈搜索）
state <= S_STOP;
mode  <= 8'd0;
left  <= 16'd0;
right <= 16'd0;
end
else if (box_h >= H_ARRIVE) begin
state <= S_ARRIVE;      // 到达：停车
mode  <= 8'd0;
left  <= 16'd0;
right <= 16'd0;
end
else begin
mode  <= 8'd1;
left  <= {{4{left_c[11]}}, left_c};
right <= {{4{right_c[11]}}, right_c};
end
end
// ---------------- 丢失停车：静止等待目标重现 ----------------
S_STOP: begin
mode  <= 8'd0;
left  <= 16'd0;
right <= 16'd0;
if (gd_found) state <= S_TRACK;
end
// ---------------- 到达：停车，灯移开则重新追踪 ----------------
S_ARRIVE: begin
mode  <= 8'd0;
left  <= 16'd0;
right <= 16'd0;
if (!gd_found) state <= S_STOP;
else if (box_h < H_REF - 10'd10) state <= S_TRACK; // 灯远了，继续跟
end
default: state <= S_STOP;
endcase
end
end
endmodule
