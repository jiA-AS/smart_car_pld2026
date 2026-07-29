// ============================================================================
// attitude_cf.v —— 互补滤波姿态解算（pitch/roll，赛道三基础要求2）
//
// 原理：陀螺仪积分（高频响应好）+ 加速度计重力分量解算（低频无漂移），
//       一阶互补滤波融合：  θ = (θ + ω·dt)·α + θ_acc·(1-α)
//
// 节拍：parse_done（V1.0 上行帧 100Hz，dt=10ms）
// 上电自校准：前 256 个节拍（2.56s）累加 gyro_x/gyro_y 求零偏，
//             ★ 上电后约 2.6 秒内小车必须保持静止 ★
//
// 加速度角度：pitch_acc = atan2(-acc_x, acc_z)，roll_acc = atan2(acc_y, acc_z)
//   比值 |num|×256/den 由时分复用顺序除法器计算（各 24 拍），atan 查 atan_lut
//   （比值饱和到 4.0，对应 ±75.96°；分母 az<256 时钳位 256 防除零）
//
// 陀螺积分：Δθ(0.01°)/tick = (gyro - bias) × GYRO_MULT >>> 16（四舍五入）
//   GYRO_MULT = round(2^16 / GYRO_LSB_PER_DPS)，数值上 ≈ gyro/LSB [cdeg/tick]
//   （因为 1 dps × 10ms = 0.01° = 1 cdeg）
//
// 轴向约定（MPU 水平安装，x 前 / y 左 / z 上）：
//   pitch 绕 y 轴（gyro_y），roll 绕 x 轴（gyro_x）；
//   实车若方向相反，改 INV_P / INV_R 参数即可，不用改代码。
//
// 时序：tick → S_P（24拍除法）→ S_R（24拍）→ S_F1（查pitch的atan）
//       → S_F2（查roll的atan并锁存滤波结果）→ S_IDLE，全程 <1.1us@50M
//
// 输出：pitch_cdeg / roll_cdeg，单位 0.01°，有符号（±7596 = ±75.96° 饱和）
// ============================================================================
module attitude_cf #(
    parameter [15:0] GYRO_LSB_PER_DPS = 16'd131,  // MPU6050@±250dps=131；LSM6DS3≈114
    parameter [10:0] ALPHA_N          = 11'd1004, // 互补系数 α×1024（0.98→τ≈0.5s@100Hz）
    parameter        INV_P            = 1'b0,     // 1 = pitch 取反（安装方向反了用）
    parameter        INV_R            = 1'b0      // 1 = roll 取反
)(
    input  wire               clk,         // 50MHz（clk_50m）
    input  wire               rst_n,
    input  wire               tick,        // parse_done，100Hz 单拍脉冲
    input  wire signed [15:0] gyro_x,
    input  wire signed [15:0] gyro_y,
    input  wire signed [15:0] acc_x,
    input  wire signed [15:0] acc_y,
    input  wire signed [15:0] acc_z,
    output reg  signed [15:0] pitch_cdeg,  // 俯仰角，0.01°
    output reg  signed [15:0] roll_cdeg,   // 横滚角，0.01°
    output reg                cal_done     // 零偏校准完成（上电约 2.56s 后置 1）
);

// round(2^16/LSB) = (2^16 + LSB/2)/LSB：LSB=131→500，LSB=114→575
localparam [15:0] GYRO_MULT = (17'd65536 + {2'b00, GYRO_LSB_PER_DPS[15:1]})
                              / GYRO_LSB_PER_DPS;
localparam [8:0]  CAL_TICKS = 9'd256;               // 2.56s @100Hz

// ------------------------- 上电零偏校准 -------------------------
reg [8:0]         cal_cnt;
reg signed [31:0] sum_gx, sum_gy;
reg signed [15:0] bias_x, bias_y;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cal_cnt  <= 9'd0;
        sum_gx   <= 32'sd0;  sum_gy <= 32'sd0;
        bias_x   <= 16'sd0;  bias_y <= 16'sd0;
        cal_done <= 1'b0;
    end
    else if (tick && !cal_done) begin
        if (cal_cnt == CAL_TICKS - 9'd1) begin
            bias_x   <= sum_gx >>> 9;               // sum/256（算术右移）
            bias_y   <= sum_gy >>> 9;
            cal_done <= 1'b1;
        end
        else begin
            sum_gx  <= sum_gx + {{16{gyro_x[15]}}, gyro_x};
            sum_gy  <= sum_gy + {{16{gyro_y[15]}}, gyro_y};
        end
        cal_cnt <= cal_cnt + 9'd1;
    end
end

// ------------------------- 除法器输入准备 -------------------------
wire [15:0] az_abs = acc_z[15] ? (~acc_z + 16'd1) : acc_z;
wire [15:0] ax_abs = acc_x[15] ? (~acc_x + 16'd1) : acc_x;
wire [15:0] ay_abs = acc_y[15] ? (~acc_y + 16'd1) : acc_y;
wire [14:0] den    = (az_abs < 16'd256) ? 15'd256 : az_abs[14:0];

// ------------------------- 陀螺增量（cdeg/tick，四舍五入） -------------------------
wire signed [16:0] gx_d = {gyro_x[15], gyro_x} - {bias_x[15], bias_x};
wire signed [16:0] gy_d = {gyro_y[15], gyro_y} - {bias_y[15], bias_y};
wire signed [33:0] gx_m = gx_d * $signed({1'b0, GYRO_MULT});
wire signed [33:0] gy_m = gy_d * $signed({1'b0, GYRO_MULT});
wire signed [15:0] dth_x = (gx_m + 34'sd32768) >>> 16;   // roll 增量
wire signed [15:0] dth_y = (gy_m + 34'sd32768) >>> 16;   // pitch 增量

// ------------------------- 时分复用顺序除法器 + atan 查表 -------------------------
localparam S_IDLE = 3'd0, S_P = 3'd1, S_R = 3'd2, S_F1 = 3'd3, S_F2 = 3'd4;
reg [ 2:0]  state;
reg [23:0]  dvd;                    // 被除数（|num|×256，≤2^23）
reg [14:0]  dvs, quo;
reg [15:0]  rem;
reg [ 4:0]  dcnt;
reg [10:0]  ratio_p, ratio_r;       // 比值×256，饱和 1024
reg         sign_p,  sign_r;        // 角度符号

wire [16:0] rem_shift = {rem[14:0], dvd[23]};
wire        ge        = (rem_shift >= {2'b00, dvs});

// atan LUT（组合 ROM）：S_F1 查 pitch，S_F2 查 roll
wire [10:0] lut_idx = (state == S_F2) ? ratio_r : ratio_p;
wire [12:0] lut_val;
atan_lut u_atan_lut(.idx(lut_idx), .val(lut_val));

reg  signed [15:0] acc_p_cdeg;      // S_F1 锁存的 pitch 加速度角
wire signed [15:0] acc_r_cdeg = sign_r ? -$signed({3'b000, lut_val})
                                       :  $signed({3'b000, lut_val});

// ------------------------- 互补滤波乘加（组合，S_F2 拍锁存） -------------------------
wire signed [16:0]  pitch_int = {pitch_cdeg[15], pitch_cdeg} + {dth_y[15], dth_y};
wire signed [16:0]  roll_int  = {roll_cdeg[15],  roll_cdeg} + {dth_x[15], dth_x};
wire signed [10:0]  alpha_s   = $signed({1'b0, ALPHA_N});          // +1004
wire signed [11:0]  beta_s    = 12'sd1024 - {1'b0, ALPHA_N};       // +20
wire signed [31:0]  pitch_f   = (pitch_int * alpha_s
                               + {{5{acc_p_cdeg[15]}}, acc_p_cdeg} * beta_s) >>> 10;
wire signed [31:0]  roll_f    = (roll_int  * alpha_s
                               + {{5{acc_r_cdeg[15]}}, acc_r_cdeg} * beta_s) >>> 10;

// ------------------------- 主状态机 -------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state   <= S_IDLE;
        dvd     <= 24'd0;  dvs <= 15'd0;  quo <= 15'd0;  rem <= 16'd0;  dcnt <= 5'd0;
        ratio_p <= 11'd0;  ratio_r <= 11'd0;
        sign_p  <= 1'b0;   sign_r  <= 1'b0;
        acc_p_cdeg <= 16'sd0;
        pitch_cdeg <= 16'sd0;  roll_cdeg <= 16'sd0;
    end
    else begin
        case (state)
        // ---- 等 100Hz 节拍，启动 pitch 比值除法 ----
        S_IDLE: begin
            if (tick) begin
                dvd    <= {ax_abs[14:0], 8'd0};   // |acc_x|×256
                dvs    <= den;
                quo    <= 15'd0;  rem <= 16'd0;  dcnt <= 5'd0;
                sign_p <= acc_x[15];              // atan2(-ax,az)：ax>0 → pitch 为负
                state  <= S_P;
            end
        end
        // ---- pitch 比值：24 拍移位除法 ----
        S_P: begin
            dvd <= {dvd[22:0], 1'b0};
            if (ge) begin
                rem <= rem_shift[15:0] - {1'b0, dvs};
                quo <= {quo[13:0], 1'b1};
            end
            else begin
                rem <= rem_shift[15:0];
                quo <= {quo[13:0], 1'b0};
            end
            if (dcnt == 5'd23) begin
                ratio_p <= (|quo[14:10]) ? 11'd1024
                           : {quo[9:0], ge};        // >1024 饱和；末拍商位=ge
                dvd     <= {ay_abs[14:0], 8'd0};   // 接着算 roll
                quo     <= 15'd0;  rem <= 16'd0;  dcnt <= 5'd0;
                sign_r  <= acc_y[15];              // atan2(ay,az)：ay>0 → roll 为正
                state   <= S_R;
            end
            else dcnt <= dcnt + 5'd1;
        end
        // ---- roll 比值 ----
        S_R: begin
            dvd <= {dvd[22:0], 1'b0};
            if (ge) begin
                rem <= rem_shift[15:0] - {1'b0, dvs};
                quo <= {quo[13:0], 1'b1};
            end
            else begin
                rem <= rem_shift[15:0];
                quo <= {quo[13:0], 1'b0};
            end
            if (dcnt == 5'd23) begin
                ratio_r <= (|quo[14:10]) ? 11'd1024 : {quo[9:0], ge};
                state   <= S_F1;
            end
            else dcnt <= dcnt + 5'd1;
        end
        // ---- S_F1：查 pitch 的 atan 并锁存（lut_idx=ratio_p） ----
        S_F1: begin
            acc_p_cdeg <= sign_p ? -$signed({3'b000, lut_val})
                                 :  $signed({3'b000, lut_val});
            state      <= S_F2;
        end
        // ---- S_F2：查 roll 的 atan（lut_idx=ratio_r），锁存滤波结果 ----
        S_F2: begin
            pitch_cdeg <= INV_P ? -pitch_f[15:0] : pitch_f[15:0];
            roll_cdeg  <= INV_R ? -roll_f[15:0]  : roll_f[15:0];
            state      <= S_IDLE;
        end
        default: state <= S_IDLE;
        endcase
    end
end

endmodule
