// ============================================================================
// stereo_dist.v —— 目标测距 V2（clk_50m 域）：双目视差 + 单目尺寸 双模式
//
//   双目模式（两路都识别且视差足够）：
//       dist = F_PIX * BASELINE_MM / |u_cam2 - u_cam1|     → dist_src=2
//   单目模式（仅一路识别，已知光源真实高度 H_LIGHT_MM）：
//       dist = F_PIX * H_LIGHT_MM / 包围盒高度 h            → dist_src=1
//       ★ H_LIGHT_MM 等光源实际尺寸确定后填（当前为占位值，需标定）
//   否则 dist_src=0（无有效距离）
//
// 输入为两个 green_detect 的输出（各自 cam_pclk 域，帧锁存准静态），
// 本模块内 2 级触发器同步；除法器自由运行（约 35 拍刷新一次）。
// ============================================================================
module stereo_dist #(
    parameter [15:0] F_PIX       = 16'd450, // 相机焦距（像素）——需标定
    parameter [15:0] BASELINE_MM = 16'd100, // 双目基线（mm）——实测两镜头中心距
    parameter [ 9:0] MIN_DISP    = 10'd6,   // 最小有效视差（像素）
    parameter [15:0] H_LIGHT_MM  = 16'd100, // 光源真实高度（mm）——★待实测后填★
    parameter [ 9:0] H_MIN_PIX   = 10'd8    // 单目测距最小包围盒高度（像素）
)(
    input  wire        clk,                 // 50MHz
    input  wire        rst_n,
    // cam1（右相机 / 右半屏），cam_pclk_1 域
    input  wire        f1_async,
    input  wire [ 9:0] u1_async,            // 质心横坐标（相机坐标）
    input  wire [ 9:0] h1_async,            // 包围盒高度（像素）
    // cam2（左相机 / 左半屏），cam_pclk_2 域
    input  wire        f2_async,
    input  wire [ 9:0] u2_async,
    input  wire [ 9:0] h2_async,
    // 结果（clk 域，自由运行刷新）
    output reg  [15:0] dist_mm,             // 距离 mm（无效为 0，饱和 9999）
    output reg  [ 1:0] dist_src             // 0=无效 1=单目 2=双目
);

localparam [31:0] K_STEREO = F_PIX * BASELINE_MM;   // 例：450*100=45000
localparam [31:0] K_MONO   = F_PIX * H_LIGHT_MM;    // 例：450*100=45000

// ------------------------- 跨时钟同步 -------------------------
reg f1a, f1b, f2a, f2b;
reg [9:0] u1a, u1b, u2a, u2b, h1a, h1b, h2a, h2b;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        f1a<=0; f1b<=0; f2a<=0; f2b<=0;
        u1a<=0; u1b<=0; u2a<=0; u2b<=0;
        h1a<=0; h1b<=0; h2a<=0; h2b<=0;
    end
    else begin
        f1a<=f1_async; f1b<=f1a;  u1a<=u1_async; u1b<=u1a;  h1a<=h1_async; h1b<=h1a;
        f2a<=f2_async; f2b<=f2a;  u2a<=u2_async; u2b<=u2a;  h2a<=h2_async; h2b<=h2a;
    end
end

// ------------------------- 模式裁决与操作数选择 -------------------------
wire [9:0] disp       = (u2b >= u1b) ? (u2b - u1b) : (u1b - u2b);
wire       stereo_ok  = f1b && f2b && (disp >= MIN_DISP);
// 单目：用能看到目标那一路的包围盒高度
// 单目/尺寸法兜底高度：双目都在取较大者（更可信），单目用可见路
wire [ 9:0] h_sel     = (f1b && f2b) ? ((h1b > h2b) ? h1b : h2b)
                                     : (f1b ? h1b : h2b);
wire       mono_ok    = !stereo_ok && (f1b || f2b) && (h_sel >= H_MIN_PIX);
wire [31:0] sel_dvd   = stereo_ok ? K_STEREO : K_MONO;
wire [31:0] sel_dvs   = stereo_ok ? {22'd0, disp}
                                  : {22'd0, h_sel};
wire [ 1:0] sel_src   = stereo_ok ? 2'd2 : (mono_ok ? 2'd1 : 2'd0);

// ------------------------- 自由运行顺序除法器 -------------------------
localparam D_IDLE = 1'b0, D_RUN = 1'b1;
reg        dstate = D_IDLE;
reg [31:0] dvd = 0;
reg [31:0] dvs = 1;
reg [31:0] quo = 0;
reg [32:0] rem = 0;
reg [ 5:0] dcnt = 0;
reg [ 1:0] src_latched = 0;   // 本题对应的距离来源（与商一起提交）

wire [32:0] rem_shift = {rem[31:0], dvd[31]};
wire        ge        = (rem_shift >= {1'b0, dvs});
wire [31:0] quo_next  = ge ? {quo[30:0], 1'b1} : {quo[30:0], 1'b0};

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dstate <= D_IDLE;
        dvd <= 0; dvs <= 1; quo <= 0; rem <= 0; dcnt <= 0;
        dist_mm <= 16'd0; dist_src <= 2'd0; src_latched <= 2'd0;
    end
    else begin
        case (dstate)
        D_IDLE: begin
            dvd <= sel_dvd;
            dvs <= sel_dvs;
            src_latched <= sel_src;
            quo <= 32'd0;  rem <= 33'd0;  dcnt <= 6'd0;
            dstate <= D_RUN;
        end
        D_RUN: begin
            if (dvs == 32'd0 || src_latched == 2'd0) begin
                // 除数 0 或本题无效：作废
                dist_mm  <= 16'd0;
                dist_src <= 2'd0;
                dstate   <= D_IDLE;
            end
            else begin
                dvd <= {dvd[30:0], 1'b0};
                if (ge) begin
                    rem <= rem_shift - {1'b0, dvs};
                    quo <= {quo[30:0], 1'b1};
                end
                else begin
                    rem <= rem_shift;
                    quo <= {quo[30:0], 1'b0};
                end
                if (dcnt == 6'd31) begin
                    dist_mm  <= (quo_next > 32'd9999) ? 16'd9999 : quo_next[15:0];
                    dist_src <= src_latched;
                    dstate   <= D_IDLE;
                end
                else dcnt <= dcnt + 6'd1;
            end
        end
        endcase
    end
end

endmodule
