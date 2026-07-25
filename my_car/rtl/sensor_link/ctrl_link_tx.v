// ============================================================================
// ctrl_link_tx.v —— V1.1 下行指令帧组帧 + 发送（FPGA -> ESP32）
// 帧格式（9 字节）：
//   55 AA | 02 | mode(1) | left(2小端) | right(2小端) | CRC8(覆盖前8字节)
//   mode: 0=停车 1=速度控制 2=搜索(原地转)
// 以 SEND_HZ 固定频率发送；发送间隙输入变化不影响在发帧
// ============================================================================
module ctrl_link_tx #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD     = 115200,
    parameter SEND_HZ  = 50
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [ 7:0] mode,
    input  wire [15:0] left,        // int16，按字节原样发送（符号由 ESP32 端解释）
    input  wire [15:0] right,
    output wire        txd
);

localparam SEND_DIV = CLK_FREQ / SEND_HZ;

// ------------------------- CRC8/SMBUS -------------------------
function [7:0] crc8_next(input [7:0] crc, input [7:0] data);
integer i;
reg [7:0] c;
begin
    c = crc ^ data;
    for (i = 0; i < 8; i = i + 1)
        c = c[7] ? ((c << 1) ^ 8'h07) : (c << 1);
    crc8_next = c;
end
endfunction

// ------------------------- 发送定时 -------------------------
reg [31:0] send_cnt = 0;
wire send_tick = (send_cnt == SEND_DIV - 1);
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) send_cnt <= 0;
    else if (send_tick) send_cnt <= 0;
    else send_cnt <= send_cnt + 1;
end

// ------------------------- 组帧 + 逐字节发送 -------------------------
reg [3:0] idx = 0;          // 0~8：当前发送第几字节
reg       sending = 1'b0;
reg       tx_en = 1'b0;
reg [7:0] tx_data = 8'd0;
wire      tx_busy;

reg [7:0] frame [0:8];

sl_uart_tx #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD)) u_tx (
    .clk(clk), .rst_n(rst_n),
    .tx_en(tx_en), .tx_data(tx_data),
    .txd(txd), .busy(tx_busy)
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sending <= 1'b0;  idx <= 0;
        tx_en <= 1'b0;    tx_data <= 8'd0;
    end
    else begin
        tx_en <= 1'b0;
        if (!sending) begin
            if (send_tick) begin
                // 锁存并组帧
                frame[0] <= 8'h55;  frame[1] <= 8'hAA;  frame[2] <= 8'h02;
                frame[3] <= mode;
                frame[4] <= left[7:0];   frame[5] <= left[15:8];
                frame[6] <= right[7:0];  frame[7] <= right[15:8];
                frame[8] <= crc8_next(
                              crc8_next(
                                crc8_next(
                                  crc8_next(
                                    crc8_next(
                                      crc8_next(
                                        crc8_next(crc8_next(8'd0, 8'h55), 8'hAA),
                                      8'h02),
                                    mode),
                                  left[7:0]),
                                left[15:8]),
                              right[7:0]),
                            right[15:8]);
                sending <= 1'b1;
                idx     <= 4'd0;
            end
        end
        else if (!tx_busy && !tx_en) begin
            if (idx <= 4'd8) begin
                tx_data <= frame[idx];
                tx_en   <= 1'b1;             // 启动本字节发送
                idx     <= idx + 4'd1;
            end
            else begin
                sending <= 1'b0;             // 9 字节全部发出
            end
        end
    end
end

endmodule
