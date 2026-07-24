//******************************************************************************
// packet_decode -- V1.0 传感器协议解析（45号例程最小改动版：仅此文件被修改）
// 帧格式（34字节，小端）：
//   AA 55 | type=0x01 | timestamp(2) | enc0~3(4x4) | gyro xyz(3x2) | acc xyz(3x2) | CRC8
// CRC8/SMBUS：多项式0x07、初值0x00，覆盖 type~acc_z 共31字节
// 解析成功：led_data=2'b01（LED0亮）；CRC错误：led_data=2'b10（LED1亮）
// parse_done 为单拍脉冲（不等 packet_tx_done，原厂 packet_code 照常回包）
//******************************************************************************
module packet_decode #(
    parameter PACKET_HEAD    = 8'h55,   //帧头第二字节
    parameter LED_CMD        = 8'h00,   //控制LED灯亮灭的命令
    parameter BEEP_CMD       = 8'h01,   //控制蜂鸣器发声的命令
    parameter BREATH_LED_CMD = 8'h02,   //控制呼吸灯的命令
    parameter KEY_CMD        = 8'h03,   //查询按键状态的命令
    parameter ERR_HEAD       = 8'hE0,   //包头检测错误
    parameter ERR_CMD        = 8'hE1,   //发送无效命令报错
    parameter ERR_DATA_LEN   = 8'hE2,   //有效数据长度发送错误
    parameter ERR_CHECKSUM   = 8'hE3,   //校验错误
    parameter PARSE_OK       = 8'h00    //数据包解析正确
)(
    input                  clk           ,   //时钟
    input                  rst_n         ,   //复位，低电平有效

    input         [7:0]    uart_rx_data  ,   //UART接收的数据
    input                  uart_rx_done  ,   //UART接收数据完成信号
    input                  packet_tx_done,   //（本版不使用，保留端口兼容顶层）

    output  reg   [1:0]    led_data      ,   //两位控制两个LED灯
    output  reg            beep_data     ,   //蜂鸣器写入数据
    output  reg            breath_sw     ,   //呼吸灯开关控制
    output  reg   [7:0]    breath_fre    ,   //呼吸灯频率控制
    output  reg            parse_done    ,   //解包完成标志（单拍脉冲）
    output  reg   [7:0]    parse_result  ,   //8'h00:解析正确 8'hEx:解析错误
    output  reg   [7:0]    parse_cmd         //命令
);

//localparam define
localparam  S_H1   = 2'd0;             //等帧头第一字节 0xAA
localparam  S_H2   = 2'd1;             //等帧头第二字节 PACKET_HEAD
localparam  S_DATA = 2'd2;             //收 31 字节载荷
localparam  S_CRC  = 2'd3;             //收 CRC 并校验

//reg define
reg    [1:0]    cur_state;
reg    [4:0]    data_cnt;              //载荷字节计数 0~30
reg    [7:0]    rx_buf [0:30];         //载荷缓存
reg    [7:0]    crc;                   //滚动CRC8

//解包结果寄存器（里程碑2接运算模块时使用，本里程碑暂不接出）
reg  [15:0]        timestamp;
reg  signed [31:0] enc0, enc1, enc2, enc3;
reg  signed [15:0] gyro_x, gyro_y, gyro_z;
reg  signed [15:0] acc_x, acc_y, acc_z;

//*****************************************************
//**                    main code
//*****************************************************

//CRC8/SMBUS：与 STM32 端 crc8() 完全等价
function [7:0] crc8_next;
    input [7:0] crc_in;
    input [7:0] din;
    integer i;
    reg [7:0] c;
    begin
        c = crc_in ^ din;
        for (i = 0; i < 8; i = i + 1)
            c = c[7] ? ({c[6:0],1'b0} ^ 8'h07) : {c[6:0],1'b0};
        crc8_next = c;
    end
endfunction

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cur_state    <= S_H1;
        data_cnt     <= 5'd0;
        crc          <= 8'd0;
        led_data     <= 2'b0;
        beep_data    <= 1'b0;
        breath_sw    <= 1'b0;
        breath_fre   <= 8'b0;
        parse_done   <= 1'b0;
        parse_result <= 8'b0;
        parse_cmd    <= 8'b0;
    end
    else begin
        parse_done <= 1'b0;              //默认：单拍脉冲
        case(cur_state)
            //------ 等帧头 0xAA（静默搜索）------
            S_H1: begin
                if(uart_rx_done && uart_rx_data == 8'hAA)
                    cur_state <= S_H2;
            end
            //------ 等帧头第二字节（容忍 AA AA 55）------
            S_H2: begin
                if(uart_rx_done) begin
                    if(uart_rx_data == PACKET_HEAD) begin
                        cur_state <= S_DATA;
                        data_cnt  <= 5'd0;
                        crc       <= 8'd0;
                    end
                    else if(uart_rx_data != 8'hAA)
                        cur_state <= S_H1;
                end
            end
            //------ 收 31 字节载荷，边收边算 CRC ------
            S_DATA: begin
                if(uart_rx_done) begin
                    rx_buf[data_cnt] <= uart_rx_data;
                    crc              <= crc8_next(crc, uart_rx_data);
                    if(data_cnt == 5'd30)
                        cur_state <= S_CRC;
                    else
                        data_cnt <= data_cnt + 1'b1;
                end
            end
            //------ 校验 + 小端解包，打一拍 parse_done 就回帧头 ------
            S_CRC: begin
                if(uart_rx_done) begin
                    cur_state  <= S_H1;
                    parse_done <= 1'b1;          //脉冲触发 packet_code 回包
                    parse_cmd  <= LED_CMD;
                    if(uart_rx_data == crc && rx_buf[0] == 8'h01) begin
                        parse_result <= PARSE_OK;
                        led_data     <= 2'b01;   //LED0亮 = 收到合规帧
                        timestamp <= {rx_buf[2],  rx_buf[1]};
                        enc0      <= {rx_buf[6],  rx_buf[5],  rx_buf[4],  rx_buf[3]};
                        enc1      <= {rx_buf[10], rx_buf[9],  rx_buf[8],  rx_buf[7]};
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
                        parse_result <= ERR_CHECKSUM;
                        led_data     <= 2'b10;   //LED1亮 = CRC错误
                    end
                end
            end
            default: cur_state <= S_H1;
        endcase
    end
end

endmodule