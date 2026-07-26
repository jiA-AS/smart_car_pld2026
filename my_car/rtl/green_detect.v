// ============================================================================
// green_detect.v -- 绿灯识别（像素流水线，零帧存） V2
//
// V2 改动：帧边界检测不再依赖 cmos_frame_vsync 的极性！
//   原因：OV5640 VSYNC 默认极性（消隐期高/帧有效低）与部分例程配置相反，
//         按错误极性使用会导致统计值被持续清零，永远无法触发 found。
//   新方案：检测 frame_valid 的空闲时长 -- 行间消隐仅约 2000 个 pclk，
//           帧间消隐有数万个 pclk，取 IDLE_MAX=20000（约 0.8ms@24MHz），
//           超过即判定一帧结束。任意极性、任意分辨率下均成立。
//
// 原理：RGB565 逐像素阈值判断 -> 帧内累加 sum_x/sum_y/cnt + 包围盒
//       -> 帧结束启动时序除法器求质心 -> 锁存输出
// 输出在相机像素时钟域，每帧更新一次（准静态，跨域直接采样即可）
//
// 阈值调节：TH_G 越大越严格（抗干扰强、暗灯易丢）；
//           TH_RB 越小越严格。 gd_cnt 可作为调参依据（ILA 或调试帧观察）
// ============================================================================
module green_detect #(
    parameter H_ACTIVE = 400,     // 相机行有效像素 = h_disp/2（800x480 LCD 时为 400）
    parameter TH_G     = 6'd25,   // 绿分量下限（0~63）
    parameter TH_RB    = 5'd25,   // 红/蓝分量上限（0~31）
    parameter MIN_AREA = 18'd30, // 判定 found 的最小绿色像素数
    parameter IDLE_MAX = 24'd20000  // 帧结束判据：frame_valid 空闲时钟数
                                    // （须大于行间消隐、小于帧周期；20000 适用 12~30MHz pclk）
)(
    input  wire        clk,           // 相机像素时钟（cam_pclk_1）
    input  wire        rst_n,
    input  wire        frame_vsync,   // cmos_frame_vsync_1（V2 不再使用，保留端口兼容）
    input  wire        frame_valid,   // cmos_frame_valid_1（像素有效选通）
    input  wire [15:0] frame_data,    // wr_data_1（RGB565）
    // ---- 检测结果（帧结束更新，保持到下一帧） ----
    output reg         gd_found,      // 本帧发现绿灯
    output reg  [ 9:0] gd_u,          // 质心横坐标（相机像素）
    output reg  [ 9:0] gd_v,          // 质心纵坐标
    output reg  [ 9:0] gd_min_x,      // 包围盒
    output reg  [ 9:0] gd_max_x,
    output reg  [ 9:0] gd_min_y,
    output reg  [ 9:0] gd_max_y,
    output reg  [17:0] gd_cnt         // 绿色像素总数（调阈值用）
);

// ------------------------- 帧结束检测：valid 空闲超时 -------------------------
reg [23:0] idle_cnt = 24'd0;
reg        frame_end = 1'b0;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        idle_cnt  <= 24'd0;
        frame_end <= 1'b0;
    end
    else begin
        frame_end <= 1'b0;                      // 默认每拍清零（单拍脉冲）
        if (frame_valid)
            idle_cnt <= 24'd0;
        else if (idle_cnt < IDLE_MAX + 24'd1)
            idle_cnt <= idle_cnt + 24'd1;
        if (idle_cnt == IDLE_MAX)               // 到达阈值：一帧结束（仅一拍）
            frame_end <= 1'b1;
    end
end

// ------------------------- 像素坐标计数（仅按有效像素计） -------------------------
reg [9:0] x, y;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        x <= 10'd0;  y <= 10'd0;
    end
    else if (frame_end) begin                   // 帧结束归零，准备下一帧
        x <= 10'd0;  y <= 10'd0;
    end
    else if (frame_valid) begin
        if (x == H_ACTIVE-1) begin
            x <= 10'd0;  y <= y + 10'd1;
        end
        else x <= x + 10'd1;
    end
end

// ------------------------- 绿色阈值判断 -------------------------
wire [4:0] pix_r = frame_data[15:11];
wire [5:0] pix_g = frame_data[10: 5];
wire [4:0] pix_b = frame_data[ 4: 0];
wire is_green = (pix_g >= TH_G) && (pix_r <= TH_RB) && (pix_b <= TH_RB);

// ------------------------- 帧内统计 -------------------------
reg [31:0] sum_x = 0, sum_y = 0;
reg [17:0] cnt   = 0;
reg [ 9:0] min_x = 10'd1023, max_x = 0, min_y = 10'd1023, max_y = 0;

wire stat_en = frame_valid && is_green;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sum_x <= 0;  sum_y <= 0;  cnt <= 0;
        min_x <= 10'd1023;  max_x <= 0;
        min_y <= 10'd1023;  max_y <= 0;
    end
    else if (frame_end) begin                   // 帧结束清零，准备下一帧
        sum_x <= 0;  sum_y <= 0;  cnt <= 0;
        min_x <= 10'd1023;  max_x <= 0;
        min_y <= 10'd1023;  max_y <= 0;
    end
    else if (stat_en) begin
        sum_x <= sum_x + x;
        sum_y <= sum_y + y;
        cnt   <= cnt + 18'd1;
        if (x < min_x) min_x <= x;
        if (x > max_x) max_x <= x;
        if (y < min_y) min_y <= y;
        if (y > max_y) max_y <= y;
    end
end

// ------------------------- 时序除法器（32拍移位-减法，u/v 共用） -------------------------
// 注意：frame_end 当拍统计值尚未清零（非阻塞赋值），此处采样到的是完整帧统计
localparam D_IDLE = 0, D_RUN_U = 1, D_RUN_V = 2, D_LATCH = 3;
reg [ 1:0] dstate = D_IDLE;
reg [31:0] dividend = 0;
reg [31:0] divisor  = 0;
reg [31:0] quotient = 0;
reg [31:0] rem      = 0;
reg [ 5:0] dcnt     = 0;
reg [ 9:0] quo_u = 0, quo_v = 0;
// 帧结束时刻的统计快照（除法期间原统计已清零，必须快照）
reg [17:0] c_cnt   = 0;
reg [ 9:0] c_min_x = 0, c_max_x = 0, c_min_y = 0, c_max_y = 0;

wire [32:0] rem_shift = {rem[30:0], dividend[31]};
wire        ge        = (rem_shift >= {1'b0, divisor});

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dstate <= D_IDLE;
        dividend <= 0;  divisor <= 0;  quotient <= 0;  rem <= 0;  dcnt <= 0;
        quo_u <= 0;     quo_v <= 0;
        gd_found <= 1'b0;
        gd_u <= 0;  gd_v <= 0;
        gd_min_x <= 0;  gd_max_x <= 0;  gd_min_y <= 0;  gd_max_y <= 0;
        gd_cnt <= 0;
    end
    else begin
        case (dstate)
            // ---- 等帧结束 ----
            D_IDLE: begin
                if (frame_end) begin
                    if (cnt >= MIN_AREA) begin
                        dividend <= sum_x;
                        divisor  <= {14'd0, cnt};
                        quotient <= 0;  rem <= 0;  dcnt <= 0;
                        // 快照本帧统计，供 D_LATCH 锁存
                        c_cnt   <= cnt;
                        c_min_x <= min_x;  c_max_x <= max_x;
                        c_min_y <= min_y;  c_max_y <= max_y;
                        dstate   <= D_RUN_U;
                    end
                    else begin
                        // 没找到：直接锁存"未发现"，不除（防除零）
                        gd_found <= 1'b0;
                        gd_cnt   <= cnt;
                        gd_min_x <= 0;  gd_max_x <= 0;
                        gd_min_y <= 0;  gd_max_y <= 0;
                    end
                end
            end
            // ---- 求 u = sum_x / cnt ----
            D_RUN_U: begin
                dividend <= {dividend[30:0], 1'b0};
                if (ge) begin
                    rem      <= rem_shift[31:0] - divisor;
                    quotient <= {quotient[30:0], 1'b1};
                end
                else begin
                    rem      <= rem_shift[31:0];
                    quotient <= {quotient[30:0], 1'b0};
                end
                if (dcnt == 6'd31) begin
                    quo_u    <= ge ? {quotient[8:0], 1'b1} : quotient[9:0];
                    dividend <= sum_y;                 // 准备求 v
                    quotient <= 0;  rem <= 0;  dcnt <= 0;
                    dstate   <= D_RUN_V;
                end
                else dcnt <= dcnt + 6'd1;
            end
            // ---- 求 v = sum_y / cnt ----
            D_RUN_V: begin
                dividend <= {dividend[30:0], 1'b0};
                if (ge) begin
                    rem      <= rem_shift[31:0] - divisor;
                    quotient <= {quotient[30:0], 1'b1};
                end
                else begin
                    rem      <= rem_shift[31:0];
                    quotient <= {quotient[30:0], 1'b0};
                end
                if (dcnt == 6'd31) begin
                    quo_v  <= ge ? {quotient[8:0], 1'b1} : quotient[9:0];
                    dstate <= D_LATCH;
                end
                else dcnt <= dcnt + 6'd1;
            end
            // ---- 锁存本帧结果 ----
            D_LATCH: begin
                gd_found <= 1'b1;
                gd_u     <= quo_u;
                gd_v     <= quo_v;
                gd_min_x <= c_min_x;
                gd_max_x <= c_max_x;
                gd_min_y <= c_min_y;
                gd_max_y <= c_max_y;
                gd_cnt   <= c_cnt;
                dstate   <= D_IDLE;
            end
            default: dstate <= D_IDLE;
        endcase
    end
end

endmodule
