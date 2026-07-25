// ============================================================================
// v1_decode.v —— V1.0 传感器协议解码器（自包含，替代 45 工程的 packet_decode）
// 帧格式（34 字节，小端）：
//   AA 55 | 01 | ts(2) | enc0~3(4×4) | gyro x/y/z(3×2) | acc x/y/z(3×2) | CRC8
//   CRC8/SMBUS(0x07) 覆盖第 2~32 字节（版本字节起共 31 字节，不含帧头）
// 输出：解包寄存器（保持到下一好帧覆盖）+ parse_done 脉冲（仅好帧产生）
// ============================================================================
module v1_decode (
    input  wire               clk,
    input  wire               rst_n,
    input  wire       [ 7:0]  rx_data,      // 接 sl_uart_rx
    input  wire               rx_done,
    output reg        [15:0]  timestamp,
    output reg  signed [31:0] enc0,
    output reg  signed [31:0] enc1,
    output reg  signed [31:0] enc2,
    output reg  signed [31:0] enc3,
    output reg  signed [15:0] gyro_x,
    output reg  signed [15:0] gyro_y,
    output reg  signed [15:0] gyro_z,
    output reg  signed [15:0] acc_x,
    output reg  signed [15:0] acc_y,
    output reg  signed [15:0] acc_z,
    output reg                parse_done,    // 好帧单拍脉冲（下游 frame_valid 用这个）
    output reg        [ 7:0]  parse_result   // 0x00=好帧 0xE3=CRC错
);

// ------------------------- CRC8/SMBUS 滚动计算 -------------------------
function [7:0] crc8_next;
input [7:0] crc;
input [7:0] data;
integer i;
reg [7:0] c;
begin
    c = crc ^ data;
    for (i = 0; i < 8; i = i + 1)
        c = c[7] ? ((c << 1) ^ 8'h07) : (c << 1);
    crc8_next = c;
end
endfunction

// ------------------------- 状态机 -------------------------
localparam S_H1 = 0, S_H2 = 1, S_DATA = 2, S_CRC = 3;
reg [ 1:0] state = S_H1;
reg [ 5:0] byte_cnt = 0;        // 0~30：共 31 个数据字节
reg [ 7:0] crc = 0;
reg [ 7:0] rx_rx_buf [0:30];          // rx_buf[0]=版本 rx_buf[1..2]=ts rx_buf[3..18]=enc rx_buf[19..24]=gyro rx_buf[25..30]=acc

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= S_H1;  byte_cnt <= 0;  crc <= 0;
        parse_done <= 1'b0;  parse_result <= 8'h00;
        timestamp <= 16'd0;
        enc0 <= 0; enc1 <= 0; enc2 <= 0; enc3 <= 0;
        gyro_x <= 0; gyro_y <= 0; gyro_z <= 0;
        acc_x <= 0;  acc_y <= 0;  acc_z <= 0;
    end
    else begin
        parse_done <= 1'b0;                       // 默认低，单拍脉冲
        if (rx_done) begin
            case (state)
                // ---- 等帧头 0xAA ----
                S_H1: if (rx_data == 8'hAA) state <= S_H2;
                // ---- 等帧头 0x55（容忍 AA AA 55） ----
                S_H2: begin
                    if (rx_data == 8'h55) begin
                        state <= S_DATA;  byte_cnt <= 0;  crc <= 0;
                    end
                    else if (rx_data != 8'hAA) state <= S_H1;
                end
                // ---- 收 31 个数据字节 + 滚动 CRC ----
                S_DATA: begin
                    rx_buf[byte_cnt] <= rx_data;
                    crc <= crc8_next(crc, rx_data);
                    if (byte_cnt == 6'd30) state <= S_CRC;
                    else byte_cnt <= byte_cnt + 1;
                end
                // ---- 第 34 字节：校验 + 解包 ----
                S_CRC: begin
                    state <= S_H1;
                    if (rx_data == crc && rx_buf[0] == 8'h01) begin
                        parse_result <= 8'h00;
                        parse_done   <= 1'b1;
                        timestamp <= {rx_buf[ 2], rx_buf[ 1]};
                        enc0      <= {rx_buf[ 6], rx_buf[ 5], rx_buf[ 4], rx_buf[ 3]};
                        enc1      <= {rx_buf[10], rx_buf[ 9], rx_buf[ 8], rx_buf[ 7]};
                        enc2      <= {rx_buf[14], rx_buf[13], rx_buf[12], rx_buf[11]};
                        enc3      <= {rx_buf[18], rx_buf[17], rx_buf[16], rx_buf[15]};
                        gyro_x    <= {rx_buf[20], rx_buf[19]};
                        gyro_y    <= {rx_buf[22], rx_buf[21]};
                        gyro_z    <= {rx_buf[24], rx_buf[23]};
                        acc_x     <= {rx_buf[26], rx_buf[25]};
                        acc_y     <= {rx_buf[28], rx_buf[27]};
                        acc_z     <= {rx_buf[30], rx_buf[29]};
                    end
                    else begin
                        parse_result <= 8'hE3;
                    end
                end
                default: state <= S_H1;
            endcase
        end
    end
end

endmodule
