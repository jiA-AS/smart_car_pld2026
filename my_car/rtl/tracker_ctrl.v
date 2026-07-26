// ============================================================================
// tracker_ctrl.v -- 绿灯追踪控制器（比例导引 + 距离保持 + 丢灯搜索）
//
// 输入：green_detect 的检测结果（cam_pclk 域，准静态，本模块 50MHz 直接采样）
// 输出：V1.1 下行指令 mode/left/right（速度 -100~+100，接 ctrl_link_tx）
//
// 控制律：
//   转向：err_u = gd_u - U_CENTER；turn = err_u/4（比例，右偏正）
//         left = base + turn，right = base - turn（灯偏右 -> 右轮慢 -> 车头右摆）
//   距离：h = 包围盒高度（距离代理，越近越大）
//         base = (H_REF - h)/2，限幅 [0, V_MAX]；h >= H_ARRIVE 判定到达停车
//   状态：S_TRACK 追踪 / S_LOST 短时保持 / S_SEARCH 原地搜索 / S_ARRIVE 到达
//
// 所有计算 20ms 一拍（与 V1.1 50Hz 发送节拍对齐），输出寄存器即存储。
// ============================================================================
module tracker_ctrl #(
    parameter U_CENTER  = 10'd200,  // 画面中线（H_ACTIVE/2）
    parameter DEADZONE  = 10'd8,    // 转向死区（像素），防抖动
    parameter V_MAX     = 8'd45,    // 基准速度上限（0~100）
    parameter H_REF     = 10'd120,  // 目标距离对应的包围盒高度（实测标定！）
    parameter H_ARRIVE  = 10'd150,  // 到达判定高度（大于此值停车）
    parameter SEARCH_SPD= 8'd22,    // 搜索转速（原地旋转）
    parameter LOST_LIM  = 8'd25     // 丢灯容忍拍数（25 x 20ms = 0.5s）
)(
    input  wire        clk,         // 50MHz
    input  wire        rst_n,
    // ---- 检测结果（green_detect，准静态跨域采样） ----
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
           S_LOST   = 2'd1,   // 短时丢失，保持最后方向
           S_SEARCH = 2'd2,   // 原地旋转搜索
           S_ARRIVE = 2'd3;   // 到达停车
reg [1:0] state = S_SEARCH;   // 上电先搜索

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
reg [7:0] lost_cnt = 0;
reg       last_dir = 1'b0;    // 最后看到灯的方位：0=左 1=右（决定搜索转向）

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state    <= S_SEARCH;
        lost_cnt <= 0;
        last_dir <= 1'b0;
        mode  <= 8'd0;
        left  <= 16'd0;
        right <= 16'd0;
    end
    else if (tick) begin
        // 记录最后方位（用于搜索转向）
        if (gd_found && err_u > 12'sd0)       last_dir <= 1'b1;
        else if (gd_found && err_u < 12'sd0)  last_dir <= 1'b0;

        case (state)
            // ---------------- 追踪 ----------------
            S_TRACK: begin
                if (!gd_found) begin
                    state    <= S_LOST;
                    lost_cnt <= 8'd1;
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
            // ---------------- 短时丢失：保持最后指令 ----------------
            S_LOST: begin
                if (gd_found) begin
                    state    <= S_TRACK;
                    lost_cnt <= 0;
                end
                else if (lost_cnt >= LOST_LIM) begin
                    state <= S_SEARCH;      // 超时进搜索
                end
                else lost_cnt <= lost_cnt + 8'd1;
                // left/right 保持上一拍不动（惯性通过遮挡）
            end
            // ---------------- 搜索：原地慢转 ----------------
            S_SEARCH: begin
                if (gd_found) begin
                    state <= S_TRACK;
                end
                else begin
                    mode <= 8'd1;
                    if (last_dir) begin             // 灯最后在右边 -> 向右转
                        left  <=  $signed({8'd0, SEARCH_SPD});
                        right <= -$signed({8'd0, SEARCH_SPD});
                    end
                    else begin                      // 向左转
                        left  <= -$signed({8'd0, SEARCH_SPD});
                        right <=  $signed({8'd0, SEARCH_SPD});
                    end
                end
            end
            // ---------------- 到达：停车，灯移开则重新追踪 ----------------
            S_ARRIVE: begin
                mode  <= 8'd0;
                left  <= 16'd0;
                right <= 16'd0;
                if (!gd_found) state <= S_LOST;
                else if (box_h < H_REF - 10'd10) state <= S_TRACK; // 灯远了，继续跟
            end
            default: state <= S_SEARCH;
        endcase
    end
end

endmodule
