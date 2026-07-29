// ============================================================================
// sensor_calc.v -- 轮式里程计 + 航向积分（赛道三基础要求1/4：速度、位置、航向）
//
// 节拍：parse_done（V1.0 上行帧 100Hz，dt=10ms）
//
// ★ 定点约定：位移内部单位 mm×1024（避免 10ms 小位移被整 mm 截断丢失），
//   位置累加器 40bit signed（±5.4×10^8 mm），输出接口一律换算回 mm。
//
// 轮速/车速：
//   d_i    = enc_i - enc_i_prev                     （10ms 脉冲增量，有符号）
//   mm_i   = d_i × MM_PER_CNT_X1024                 （位移，mm×1024）
//   spd_i  = (mm_i × 25) >>> 8                      （×100/1024 → mm/s）
//   fwd    = (mm0+mm1+mm2+mm3) >>> 2                （四轮平均，mm×1024）
//   fwd_speed = (fwd × 25) >>> 8                    （mm/s）
//
// 航向（陀螺 z 积分，上电 2.56s 静止自校准零偏）：
//   delta_z = (gyro_z - bias) × GYRO_MULT >>> 16    （cdeg/tick，四舍五入）
//   theta_idx：0~359（度），增量式维护，无除法
//   ang_rate = delta_z × 100                        （角速度，0.01°/s）
//
// 位置（航位推算，内部 mm×1024）：
//   pos_x1024 += fwd × cos(theta) >>> 15  （cos/sin 查 sincos_lut，Q15）
//   pos_x = pos_x1024 >>> 10                          （输出 mm，上电原点）
//
// 轨迹抽稀：每 TRK_DECIM(20) 拍输出 trk_wr 单拍 + trk_x/trk_y（mm，饱和）
//
// ★ 标定：MM_PER_CNT_X1024 = 实测毫米数 / 编码器增量 × 1024。
//   方法：直线推车 1000mm，读 enc 增量 D，则参数 = 1000×1024/D。
//   默认 102（≈0.1mm/脉冲）仅为占位，必须实测！
// ============================================================================
module sensor_calc #(
    parameter [15:0] MM_PER_CNT_X1024   = 16'd102,  // mm/脉冲 ×1024 ★标定★
    parameter [15:0] GYRO_LSB_PER_DPS   = 16'd131,  // MPU6050@±250dps=131；LSM6DS3≈114
    parameter [ 5:0] TRK_DECIM          = 6'd20     // 轨迹抽稀（20×10ms=200ms，5Hz）
)(
    input  wire               clk,        // 50MHz（clk_50m）
    input  wire               rst_n,
    input  wire               tick,       // parse_done，100Hz 单拍脉冲
    input  wire signed [31:0] enc0,
    input  wire signed [31:0] enc1,
    input  wire signed [31:0] enc2,
    input  wire signed [31:0] enc3,
    input  wire signed [15:0] gyro_z,
    // ---- 车辆状态（50M 域，准静态，OSD/其他模块直接采样） ----
    output reg  signed [15:0] spd0,       // 四轮轮速 mm/s
    output reg  signed [15:0] spd1,
    output reg  signed [15:0] spd2,
    output reg  signed [15:0] spd3,
    output reg  signed [15:0] fwd_speed,  // 车速 mm/s
    output reg  signed [15:0] ang_rate,   // 角速度 0.01°/s
    output wire signed [31:0] pos_x,      // 位置 mm（上电原点）
    output wire signed [31:0] pos_y,
    output reg        [ 8:0]  theta_idx,  // 航向 0~359（度，0=上电朝向）
    // ---- 轨迹点（5Hz，送 dash_osd，同 50M 域单拍脉冲） ----
    output reg                trk_wr,
    output reg  signed [15:0] trk_x,      // mm，饱和 ±32767
    output reg  signed [15:0] trk_y
);

// round(2^16/LSB)
localparam [15:0] GYRO_MULT = (17'd65536 + {2'b00, GYRO_LSB_PER_DPS[15:1]})
                              / GYRO_LSB_PER_DPS;
localparam [9:0]  CAL_TICKS = 10'd512;   // [V2] 5.12s @100Hz

// ------------------------- 编码器差分 -------------------------
reg signed [31:0] enc0_p, enc1_p, enc2_p, enc3_p;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        enc0_p <= 32'sd0;  enc1_p <= 32'sd0;
        enc2_p <= 32'sd0;  enc3_p <= 32'sd0;
    end
    else if (tick) begin
        enc0_p <= enc0;  enc1_p <= enc1;  enc2_p <= enc2;  enc3_p <= enc3;
    end
end
wire signed [31:0] d0 = enc0 - enc0_p;
wire signed [31:0] d1 = enc1 - enc1_p;
wire signed [31:0] d2 = enc2 - enc2_p;
wire signed [31:0] d3 = enc3 - enc3_p;

// ------------------------- 位移（mm×1024）与速度（mm/s） -------------------------
wire signed [31:0] mm0 = d0 * $signed({1'b0, MM_PER_CNT_X1024});
wire signed [31:0] mm1 = d1 * $signed({1'b0, MM_PER_CNT_X1024});
wire signed [31:0] mm2 = d2 * $signed({1'b0, MM_PER_CNT_X1024});
wire signed [31:0] mm3 = d3 * $signed({1'b0, MM_PER_CNT_X1024});
wire signed [31:0] fwd = (mm0 + mm1 + mm2 + mm3) >>> 2;   // mm×1024

// 饱和函数：返回 16bit 补码（赋给 signed 信号使用，bit pattern 一致）
function [15:0] sat16;
    input signed [31:0] v;
    begin
        if (v > 32'sd32767)       sat16 = 16'h7FFF;
        else if (v < -32'sd32768) sat16 = 16'h8000;
        else                      sat16 = v[15:0];
    end
endfunction

// ------------------------- 陀螺 z 零偏校准 -------------------------
// [V2] 零偏 Q10 定点（LSB×1024，分辨率 1/512 LSB）+ ZUPT 温漂跟踪
reg [9:0]         cal_cnt;
reg               cal_done;
reg signed [31:0] sum_gz;
reg signed [31:0] bias_qz;      // Q10

wire signed [31:0] gz_q10 = {{16{gyro_z[15]}}, gyro_z} <<< 10;
wire signed [15:0] bias_z = (bias_qz + 32'sd512) >>> 10;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cal_cnt <= 10'd0;  cal_done <= 1'b0;
        sum_gz  <= 32'sd0;  bias_qz <= 32'sd0;
    end
    else if (tick) begin
        if (!cal_done) begin
            if (cal_cnt == CAL_TICKS - 10'd1) begin
                bias_qz  <= sum_gz <<< 1;      // (sum/512)×1024 = sum×2
                cal_done <= 1'b1;
            end
            else sum_gz <= sum_gz + {{16{gyro_z[15]}}, gyro_z};
            cal_cnt <= cal_cnt + 10'd1;
        end
        else if (still)
            // ZUPT：静止时 bias 以 1/2048 per tick 慢速跟踪（τ≈20s，舍入补偿消死区）
            bias_qz <= bias_qz + (((gz_q10 - bias_qz) >= 32'sd0)
                                  ? (((gz_q10 - bias_qz) + 32'sd1024) >>> 11)
                                  : -((32'sd1024 - (gz_q10 - bias_qz)) >>> 11));
    end
end

// ------------------------- 航向增量（cdeg/tick） -------------------------
wire signed [16:0] gz_d    = {gyro_z[15], gyro_z} - {bias_z[15], bias_z};
wire signed [33:0] gz_m    = gz_d * $signed({1'b0, GYRO_MULT});   // Q16 cdeg/tick
wire signed [31:0] gz_m32  = gz_m[31:0];
wire signed [15:0] delta_z = (gz_m + 34'sd32768) >>> 16;          // 仅供角速度显示
// [V2] 静止判据：角速度小 且 四轮编码器均无增量（真静止才跟踪零偏）
wire still = (gz_d > -17'sd4) && (gz_d < 17'sd4)
          && (d0 == 32'sd0) && (d1 == 32'sd0)
          && (d2 == 32'sd0) && (d3 == 32'sd0);

// ------------------------- sin/cos 查表（组合） -------------------------
wire signed [15:0] sin_q15, cos_q15;
sincos_lut u_sincos_lut(.idx(theta_idx), .sin_q15(sin_q15), .cos_q15(cos_q15));

// ------------------------- 位置增量（mm×1024）与累加器 -------------------------
wire signed [47:0] dx1024 = (fwd * cos_q15) >>> 15;
wire signed [47:0] dy1024 = (fwd * sin_q15) >>> 15;
reg  signed [39:0] pos_x1024, pos_y1024;

assign pos_x = pos_x1024 >>> 10;          // 输出 mm
assign pos_y = pos_y1024 >>> 10;

// ------------------------- 主时序 -------------------------
reg signed [31:0] frac_q;      // [V2] 航向小数累加（Q16 cdeg，亚 LSB 精度）
wire signed [31:0] ang_sum = frac_q + gz_m32;
reg [5:0]         decim_cnt;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        spd0 <= 16'sd0;  spd1 <= 16'sd0;  spd2 <= 16'sd0;  spd3 <= 16'sd0;
        fwd_speed <= 16'sd0;  ang_rate <= 16'sd0;
        pos_x1024 <= 40'sd0;  pos_y1024 <= 40'sd0;
        theta_idx <= 9'd0;  frac_q <= 32'sd0;
        decim_cnt <= 6'd0;
        trk_wr <= 1'b0;  trk_x <= 16'sd0;  trk_y <= 16'sd0;
    end
    else begin
        trk_wr <= 1'b0;                          // 默认清零（单拍脉冲）
        if (tick) begin
            // ---- 轮速/车速/角速度（×25>>>8 = ×100/1024） ----
            spd0      <= sat16((mm0 * 32'sd25) >>> 8);
            spd1      <= sat16((mm1 * 32'sd25) >>> 8);
            spd2      <= sat16((mm2 * 32'sd25) >>> 8);
            spd3      <= sat16((mm3 * 32'sd25) >>> 8);
            fwd_speed <= sat16((fwd * 32'sd25) >>> 8);
            ang_rate  <= sat16({{16{delta_z[15]}}, delta_z} * 32'sd100);
            // ---- 位置（mm×1024 累加） ----
            pos_x1024 <= pos_x1024 + dx1024[39:0];
            pos_y1024 <= pos_y1024 + dy1024[39:0];
            // ---- [V2] 航向：Q16 亚 LSB 累加，每满 ±100cdeg 调整 1° ----
            // （整数 cdeg 累加会把 <1LSB 的残余零偏四舍五入成 ±1°/s 恒速漂移）
            if (cal_done) begin                      // 校准完成后才积分
                if (ang_sum >= 32'sd6553600) begin   // +100<<16
                    frac_q    <= ang_sum - 32'sd6553600;
                    theta_idx <= (theta_idx == 9'd359) ? 9'd0 : theta_idx + 9'd1;
                end
                else if (ang_sum <= -32'sd6553600) begin
                    frac_q    <= ang_sum + 32'sd6553600;
                    theta_idx <= (theta_idx == 9'd0) ? 9'd359 : theta_idx - 9'd1;
                end
                else
                    frac_q <= ang_sum;
            end
            // ---- 轨迹抽稀（5Hz） ----
            if (decim_cnt == TRK_DECIM - 6'd1) begin
                decim_cnt <= 6'd0;
                trk_wr    <= 1'b1;
                trk_x     <= sat16((pos_x1024 + dx1024[39:0]) >>> 10);
                trk_y     <= sat16((pos_y1024 + dy1024[39:0]) >>> 10);
            end
            else decim_cnt <= decim_cnt + 6'd1;
        end
    end
end

endmodule
