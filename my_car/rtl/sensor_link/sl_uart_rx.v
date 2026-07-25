// ============================================================================
// sl_uart_rx.v —— UART 接收器（传感器链专用，50MHz / 参数化波特率）
// 8N1，中点采样，rxd 双触发同步；每收完一字节 rx_done 拉高一个时钟
// ============================================================================
module sl_uart_rx #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD     = 115200
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rxd,
    output reg  [7:0] rx_data,
    output reg        rx_done
);

localparam BAUD_DIV = CLK_FREQ / BAUD;

reg [1:0] sync = 2'b11;
always @(posedge clk) sync <= {sync[0], rxd};
wire rxd_s = sync[1];

reg [3:0]  state = S_IDLE;
reg [15:0] cnt = 0;
reg [2:0]  bit_idx = 0;
localparam S_IDLE = 0, S_START = 1, S_DATA = 2, S_STOP = 3;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= S_IDLE;  cnt <= 0;  bit_idx <= 0;
        rx_data <= 8'd0;  rx_done <= 1'b0;
    end
    else begin
        rx_done <= 1'b0;
        case (state)
            S_IDLE: begin
                cnt <= 0;
                if (!rxd_s) state <= S_START;        // 检测到起始位下降
            end
            S_START: begin                            // 到起始位中点确认
                if (cnt == BAUD_DIV/2 - 1) begin
                    cnt <= 0;
                    if (!rxd_s) state <= S_DATA;      // 确认是真起始位
                    else        state <= S_IDLE;      // 毛刺，放弃
                end
                else cnt <= cnt + 1;
            end
            S_DATA: begin
                if (cnt == BAUD_DIV - 1) begin
                    cnt <= 0;
                    rx_data[bit_idx] <= rxd_s;        // 中点采样，LSB 先收
                    if (bit_idx == 3'd7) begin
                        bit_idx <= 0;
                        state   <= S_STOP;
                    end
                    else bit_idx <= bit_idx + 1;
                end
                else cnt <= cnt + 1;
            end
            S_STOP: begin
                if (cnt == BAUD_DIV - 1) begin
                    cnt     <= 0;
                    state   <= S_IDLE;
                    rx_done <= 1'b1;                  // 收完一字节
                end
                else cnt <= cnt + 1;
            end
            default: state <= S_IDLE;
        endcase
    end
end

endmodule
