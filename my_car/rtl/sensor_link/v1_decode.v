// ============================================================================
// v1_decode.v -- V1.2 传感器协议解码器（自包含）
// 帧格式（35 字节，小端）：
//   AA 55 | 03 | ts(2) | enc0~3(4×4) | gyro x/y/z(3×2) | acc x/y/z(3×2) | disp_mode | CRC8
//   CRC8/SMBUS(0x07) 覆盖第 2~33 字节（版本字节起共 32 字节，不含帧头）
//   ★ V1.2 新增 disp_mode 字节（rx_buf[31]）：遥控器左拨杆 s1 映射的显示模式
//     0=视角 1=轨迹 2=调试；版本字节 0x01→0x03，旧固件帧一律拒绝（CRC/版本不符）
// 输出：解包寄存器（保持到下一好帧覆盖）+ parse_done 脉冲（仅好帧产生）
// ============================================================================
module v1_decode (
    input  wire               clk,
    input  wire               rst_n,
    input  wire       [ 7:0]  rx_data,      // 来自 sl_uart_rx
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
    output reg        [ 1:0]  disp_mode,     // [V1.2] 0=视角 1=轨迹 2=调试
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
reg [ 5:0] byte_cnt = 0;        // 0~31：共 32 个数据字节
reg [ 7:0] crc = 0;
reg [ 7:0] rx_buf [0:31];       // [0]=版本 [1..2]=ts [3..18]=enc [19..24]=gyro [25..30]=acc [31]=disp_mode
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= S_H1;  byte_cnt <= 0;  crc <= 0;
        parse_done <= 1'b0;  parse_result <= 8'h00;
        timestamp <= 16'd0;
        enc0 <= 0; enc1 <= 0; enc2 <= 0; enc3 <= 0;
        gyro_x <= 0; gyro_y <= 0; gyro_z <= 0;
        acc_x <= 0;  acc_y <= 0;  acc_z <= 0;
        disp_mode <= 2'd0;
    end
    else begin
        parse_done <= 1'b0;                     // 默认低，单拍脉冲
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
                // ---- 收 32 个数据字节 + 滚动 CRC ----
                S_DATA: begin
                    rx_buf[byte_cnt] <= rx_data;
                    crc <= crc8_next(crc, rx_data);
                    if (byte_cnt == 6'd31) state <= S_CRC;
                    else byte_cnt <= byte_cnt + 1;
                end
                // ---- 第 35 字节：校验 + 解包 ----
                S_CRC: begin
                    state <= S_H1;
                    if (rx_data == crc && rx_buf[0] == 8'h03) begin
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
                        // [V1.2] 显示模式：只取低 2 位，>2 钳到 0（视角档，最安全）
                        disp_mode <= (rx_buf[31] <= 8'd2) ? rx_buf[31][1:0] : 2'd0;
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
