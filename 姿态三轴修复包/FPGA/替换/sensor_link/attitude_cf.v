// ============================================================================
// attitude_cf.v -- 互补滤波姿态解算 V4（pitch/roll/yaw 三轴，赛道三基础要求2）
//
// 原理：陀螺仪积分（高频响应好）+ 加速度计重力分量解算（低频无漂移），
//       一阶互补滤波融合：  θ = (θ + ω·dt)·α + θ_acc·(1-α)
//       yaw 无重力基准（6 轴 MPU6050/LSM6DS3 无磁力计），只能 gyro_z 开环
//       积分，靠 ZUPT 零偏跟踪压制漂移（见下）。
//
// V4 改动（治"姿态一直飘"）：
//   1) 零偏 Q10 定点（1/1024 LSB 分辨率），上电 512 tick（5.12s）校准，
//      校准期间 pitch/roll/yaw 一律锁 0（V3 校准期也在用 bias=0 积分，白积 2.56s）；
//   2) ZUPT 零偏自适应：cal_done 后，三轴角速度全 <4 LSB（≈0.03°/s，判静止）
//      时 bias 以 τ≈2048 tick（约 20s）时间常数慢速跟踪——MPU6050 零偏随温度
//      漂移是"越放越飘"的主因，固定零偏几分钟后即失效，必须在线跟踪；
//   3) 新增 yaw_cdeg 输出：gyro_z 开环积分，Q16 亚 LSB 累加（残余零偏 <1 LSB
//      时不会像整数 cdeg 累加那样被四舍五入成 ±1°/s 的恒速漂移），±180° 回绕。
//
// 节拍：parse_done（V1.2 上行帧 100Hz，dt=10ms）
// 上电自校准：前 512 个节拍（5.12s）累加 gyro_x/y/z 求零偏，
//             ★ 上电后约 5 秒内小车必须保持静止且电机停转 ★
//
// 轴向约定（ROS 四驱标准安装：主板水平，x 前 / y 左 / z 上，与鱼香官方
//   MPU6050_light 库一致）：pitch 绕 y（gyro_y）、roll 绕 x（gyro_x）、
//   yaw 绕 z（gyro_z，左转为正）；实车方向反了改 INV_P/INV_R/INV_Y。
//
// 输出：pitch/roll/yaw_cdeg，单位 0.01°，yaw 范围 ±180°（±18000）回绕
// ============================================================================
module attitude_cf #(
    parameter [15:0] GYRO_LSB_PER_DPS = 16'd131,  // MPU6050@±250dps=131；LSM6DS3≈114
    parameter [10:0] ALPHA_N          = 11'd1004, // 互补系数 α×1024（0.98→τ≈0.5s@100Hz）
    parameter        INV_P            = 1'b0,     // 1 = pitch 取反（安装方向反了用）
    parameter        INV_R            = 1'b0,     // 1 = roll 取反
    parameter        INV_Y            = 1'b0      // 1 = yaw 取反
)(
    input  wire               clk,         // 50MHz（clk_50m）
    input  wire               rst_n,
    input  wire               tick,        // parse_done，100Hz 单拍脉冲
    input  wire signed [15:0] gyro_x,
    input  wire signed [15:0] gyro_y,
    input  wire signed [15:0] gyro_z,
    input  wire signed [15:0] acc_x,
    input  wire signed [15:0] acc_y,
    input  wire signed [15:0] acc_z,
    output reg  signed [15:0] pitch_cdeg,  // 俯仰角，0.01°
    output reg  signed [15:0] roll_cdeg,   // 横滚角，0.01°
    output reg  signed [15:0] yaw_cdeg,    // [V4] 航向角，0.01°，±180° 回绕
    output reg                cal_done     // 零偏校准完成（上电约 5.12s 后置 1）
);
// round(2^16/LSB)：LSB=131→500，LSB=114→575；数值上 ≈ gyro/LSB [cdeg/tick]
localparam [15:0] GYRO_MULT = (17'd65536 + {2'b00, GYRO_LSB_PER_DPS[15:1]})
                              / GYRO_LSB_PER_DPS;
localparam [9:0]  CAL_TICKS = 10'd512;              // 5.12s @100Hz
localparam signed [16:0] STILL_TH = 17'sd4;         // 静止阈值 4 LSB ≈ 0.03°/s

// ------------------------- 三轴零偏（Q10 = LSB×1024）+ 校准 + ZUPT -------------------------
reg [9:0]         cal_cnt;
reg signed [31:0] sum_gx, sum_gy, sum_gz;
reg signed [31:0] bias_qx, bias_qy, bias_qz;      // Q10 定点零偏

wire signed [31:0] gx_q10 = {{16{gyro_x[15]}}, gyro_x} <<< 10;
wire signed [31:0] gy_q10 = {{16{gyro_y[15]}}, gyro_y} <<< 10;
wire signed [31:0] gz_q10 = {{16{gyro_z[15]}}, gyro_z} <<< 10;

// 使用值：Q10 四舍五入回 LSB
wire signed [15:0] bias_x = (bias_qx + 32'sd512) >>> 10;
wire signed [15:0] bias_y = (bias_qy + 32'sd512) >>> 10;
wire signed [15:0] bias_z = (bias_qz + 32'sd512) >>> 10;

wire signed [16:0] gx_d = {gyro_x[15], gyro_x} - {bias_x[15], bias_x};
wire signed [16:0] gy_d = {gyro_y[15], gyro_y} - {bias_y[15], bias_y};
wire signed [16:0] gz_d = {gyro_z[15], gyro_z} - {bias_z[15], bias_z};

// 静止判据：三轴角速度全小于阈值（电机振动会自然超过阈值，自动停止跟踪）
wire still = (gx_d > -STILL_TH) && (gx_d < STILL_TH)
          && (gy_d > -STILL_TH) && (gy_d < STILL_TH)
          && (gz_d > -STILL_TH) && (gz_d < STILL_TH);

// ZUPT 步进（带符号舍入补偿，消除定点死区：|diff|>1 LSB 即能动）
wire signed [31:0] zx_diff = gx_q10 - bias_qx;
wire signed [31:0] zy_diff = gy_q10 - bias_qy;
wire signed [31:0] zz_diff = gz_q10 - bias_qz;
wire signed [31:0] zx_step = (zx_diff >= 32'sd0) ? ((zx_diff + 32'sd1024) >>> 11)
                                                 : -((32'sd1024 - zx_diff) >>> 11);
wire signed [31:0] zy_step = (zy_diff >= 32'sd0) ? ((zy_diff + 32'sd1024) >>> 11)
                                                 : -((32'sd1024 - zy_diff) >>> 11);
wire signed [31:0] zz_step = (zz_diff >= 32'sd0) ? ((zz_diff + 32'sd1024) >>> 11)
                                                 : -((32'sd1024 - zz_diff) >>> 11);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cal_cnt  <= 10'd0;
        sum_gx   <= 32'sd0;  sum_gy <= 32'sd0;  sum_gz <= 32'sd0;
        bias_qx  <= 32'sd0;  bias_qy <= 32'sd0; bias_qz <= 32'sd0;
        cal_done <= 1'b0;
    end
    else if (tick) begin
        if (!cal_done) begin
            if (cal_cnt == CAL_TICKS - 10'd1) begin
                // (sum/512)×1024 = sum×2 → Q10，零偏分辨率 1/512 LSB
                bias_qx  <= sum_gx <<< 1;
                bias_qy  <= sum_gy <<< 1;
                bias_qz  <= sum_gz <<< 1;
                cal_done <= 1'b1;
            end
            else begin
                sum_gx <= sum_gx + {{16{gyro_x[15]}}, gyro_x};
                sum_gy <= sum_gy + {{16{gyro_y[15]}}, gyro_y};
                sum_gz <= sum_gz + {{16{gyro_z[15]}}, gyro_z};
            end
            cal_cnt <= cal_cnt + 10'd1;
        end
        else if (still) begin
            // ZUPT：bias 以 1/2048 per tick 向实测值靠近（τ≈20s），跟踪温漂
            bias_qx <= bias_qx + zx_step;
            bias_qy <= bias_qy + zy_step;
            bias_qz <= bias_qz + zz_step;
        end
    end
end

// ------------------------- 除法器输入准备 -------------------------
wire [15:0] az_abs = acc_z[15] ? (~acc_z + 16'd1) : acc_z;
wire [15:0] ax_abs = acc_x[15] ? (~acc_x + 16'd1) : acc_x;
wire [15:0] ay_abs = acc_y[15] ? (~acc_y + 16'd1) : acc_y;
wire [14:0] den    = (az_abs < 16'd256) ? 15'd256 : az_abs[14:0];

// ------------------------- 陀螺增量（pitch/roll，cdeg/tick 四舍五入） -------------------------
wire signed [33:0] gx_m = gx_d * $signed({1'b0, GYRO_MULT});
wire signed [33:0] gy_m = gy_d * $signed({1'b0, GYRO_MULT});
wire signed [15:0] dth_x = (gx_m + 34'sd32768) >>> 16;   // roll 增量
wire signed [15:0] dth_y = (gy_m + 34'sd32768) >>> 16;   // pitch 增量

// ------------------------- [V4] yaw：Q16 亚 LSB 积分 + ±180° 回绕 -------------------------
wire signed [33:0] gz_m = gz_d * $signed({1'b0, GYRO_MULT});   // Q16 cdeg/tick
reg  signed [39:0] yaw_q;                                      // Q16 cdeg 累加器
localparam signed [39:0] YAW_LIM  = 40'sd1179648000;           //  18000<<16
localparam signed [39:0] YAW_SPAN = 40'sd2359296000;           //  36000<<16
wire signed [39:0] yaw_sum  = yaw_q + {{6{gz_m[33]}}, gz_m};
wire signed [39:0] yaw_next = (yaw_sum >  YAW_LIM) ? yaw_sum - YAW_SPAN :
                              (yaw_sum < -YAW_LIM) ? yaw_sum + YAW_SPAN :
                                                      yaw_sum;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        yaw_q    <= 40'sd0;
        yaw_cdeg <= 16'sd0;
    end
    else if (tick && cal_done) begin
        yaw_q    <= yaw_next;
        yaw_cdeg <= INV_Y ? -yaw_next[31:16] : yaw_next[31:16];
    end
end

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
wire signed [16:0]  roll_int  = {roll_cdeg[15],  roll_cdeg}  + {dth_x[15], dth_x};
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
        // ---- 等 100Hz 节拍（校准完成后才开始解算，校准期姿态锁 0） ----
        S_IDLE: begin
            if (tick && cal_done) begin
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
                                         : {quo[9:0], ge};   // >1024 饱和；末拍商位=ge
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
