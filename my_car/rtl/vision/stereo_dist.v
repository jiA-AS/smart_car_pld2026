// ============================================================================
// stereo_dist.v —— 双目视差测距（clk_50m 域）
//
//   视差 disp = |u_cam2 - u_cam1|（两相机各自坐标系下的质心横坐标差）
//   距离 dist_mm = F_PIX * BASELINE_MM / disp
//
// 输入为两个 green_detect 的输出（各自 cam_pclk 域，帧锁存准静态），
// 本模块内做 2 级触发器同步；除法器自由运行（约 35 拍≈0.7us 刷新一次），
// 输入变化后很快反映到输出，无需与帧同步。
//
// 标定：F_PIX/BASELINE_MM 见说明文档；若双目装反，取绝对值已自适应。
// ============================================================================
module stereo_dist #(
    parameter [15:0] F_PIX       = 16'd450, // 相机焦距（像素）——需标定
    parameter [15:0] BASELINE_MM = 16'd100, // 双目基线（mm）——实测两镜头中心距
    parameter [ 9:0] MIN_DISP    = 10'd6    // 最小有效视差（小于则距离不可信）
)(
    input  wire        clk,                 // 50MHz
    input  wire        rst_n,
    // cam1（右相机 / 右半屏），cam_pclk_1 域
    input  wire        f1_async,
    input  wire [ 9:0] u1_async,
    // cam2（左相机 / 左半屏），cam_pclk_2 域
    input  wire        f2_async,
    input  wire [ 9:0] u2_async,
    // 结果（clk 域，自由运行刷新）
    output reg  [15:0] dist_mm,             // 距离 mm（无效时为 0）
    output reg         dist_valid           // 距离有效
);

localparam [31:0] K_DIST = F_PIX * BASELINE_MM;   // 例：450*100=45000

// ------------------------- 跨时钟同步 -------------------------
reg f1a, f1b, f2a, f2b;
reg [9:0] u1a, u1b, u2a, u2b;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        f1a<=0; f1b<=0; f2a<=0; f2b<=0;
        u1a<=0; u1b<=0; u2a<=0; u2b<=0;
    end
    else begin
        f1a<=f1_async; f1b<=f1a;  u1a<=u1_async; u1b<=u1a;
        f2a<=f2_async; f2b<=f2a;  u2a<=u2_async; u2b<=u2a;
    end
end

// 视差（绝对值，双目左右装反也自适应）
wire [9:0] disp    = (u2b >= u1b) ? (u2b - u1b) : (u1b - u2b);
wire       inputs_ok = f1b && f2b && (disp >= MIN_DISP);

// ------------------------- 自由运行顺序除法器 -------------------------
localparam D_IDLE = 1'b0, D_RUN = 1'b1;
reg        dstate = D_IDLE;
reg [31:0] dvd = 0;
reg [31:0] dvs = 1;
reg [31:0] quo = 0;
reg [32:0] rem = 0;
reg [ 5:0] dcnt = 0;

wire [32:0] rem_shift = {rem[31:0], dvd[31]};
// 本拍移位后的完整商（含当前 bit），完成拍提交必须用它而非 quo
wire        ge       = (rem_shift >= {1'b0, dvs});
wire [31:0] quo_next = ge ? {quo[30:0], 1'b1} : {quo[30:0], 1'b0};

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dstate <= D_IDLE;
        dvd <= 0; dvs <= 1; quo <= 0; rem <= 0; dcnt <= 0;
        dist_mm <= 16'd0; dist_valid <= 1'b0;
    end
    else begin
        case (dstate)
        // ---- 装载新一轮除法 ----
        D_IDLE: begin
            dvd <= K_DIST;
            dvs <= {22'd0, disp};
            quo <= 32'd0;  rem <= 33'd0;  dcnt <= 6'd0;
            dstate <= D_RUN;
        end
        // ---- 32 拍移位-减法 ----
        D_RUN: begin
            if (dvs == 32'd0) begin
                // 除数 0：本题作废
                dist_valid <= 1'b0;
                dist_mm    <= 16'd0;
                dstate     <= D_IDLE;
            end
            else begin
                dvd <= {dvd[30:0], 1'b0};
                if (rem_shift >= {1'b0, dvs}) begin
                    rem <= rem_shift - {1'b0, dvs};
                    quo <= {quo[30:0], 1'b1};
                end
                else begin
                    rem <= rem_shift;
                    quo <= {quo[30:0], 1'b0};
                end
                if (dcnt == 6'd31) begin
                    // 本题完成：提交（用含最后一拍的完整商 quo_next）
                    dist_valid <= inputs_ok;
                    dist_mm    <= inputs_ok
                                  ? ((quo_next > 32'd9999) ? 16'd9999 : quo_next[15:0])
                                  : 16'd0;
                    dstate <= D_IDLE;
                end
                else dcnt <= dcnt + 6'd1;
            end
        end
        endcase
    end
end

endmodule
