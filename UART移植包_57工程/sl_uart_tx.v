// ============================================================================
// sl_uart_tx.v —— UART 发送器（传感器链专用，50MHz / 参数化波特率）
// 8N1；tx_en 拉高一个时钟启动发送，busy 指示发送中
// ============================================================================
module sl_uart_tx #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD     = 115200
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tx_en,
    input  wire [7:0] tx_data,
    output reg        txd,
    output reg        busy
);

localparam BAUD_DIV = CLK_FREQ / BAUD;

reg [7:0]  shift = 0;
reg [3:0]  bit_idx = 0;    // 0=起始位 1~8=数据 9=停止位
reg [15:0] cnt = 0;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        txd <= 1'b1;  busy <= 1'b0;
        shift <= 8'd0;  bit_idx <= 4'd0;  cnt <= 16'd0;
    end
    else if (!busy) begin
        txd <= 1'b1;
        if (tx_en) begin
            busy    <= 1'b1;
            shift   <= tx_data;
            bit_idx <= 4'd0;
            cnt     <= 16'd0;
            txd     <= 1'b0;              // 起始位
        end
    end
    else begin
        if (cnt == BAUD_DIV - 1) begin
            cnt <= 16'd0;
            if (bit_idx == 4'd9) begin    // 停止位发完
                busy <= 1'b0;
                txd  <= 1'b1;
            end
            else begin
                bit_idx <= bit_idx + 4'd1;
                case (bit_idx)            // 下一位
                    4'd0: txd <= shift[0];
                    4'd1: txd <= shift[1];
                    4'd2: txd <= shift[2];
                    4'd3: txd <= shift[3];
                    4'd4: txd <= shift[4];
                    4'd5: txd <= shift[5];
                    4'd6: txd <= shift[6];
                    4'd7: txd <= shift[7];
                    default: txd <= 1'b1; // 停止位
                endcase
            end
        end
        else cnt <= cnt + 16'd1;
    end
end

endmodule
