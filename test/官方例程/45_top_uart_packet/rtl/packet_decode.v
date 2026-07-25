//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2023-2033
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           packet_decode
// Created by:          正点原子
// Created date:        2025年10月14日14:20:02
// Version:             V1.0
// Descriptions:        数据包解析模块
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module packet_decode(
    input                  clk           ,   //时钟
    input                  rst_n         ,   //复位，低电平有效

    input         [7:0]    uart_rx_data  ,   //UART接收数据完成信号
    input                  uart_rx_done  ,   //UART接收的数据
    input                  packet_tx_done,   //一包数据全部发送完成标志
    
    output  reg   [1:0]    led_data      ,   
    //LED写入数据,两位控制两个LED灯00 01 10 11
    output  reg            beep_data     ,   //蜂鸣器写入数据，1:鸣叫  0:不鸣叫
    output  reg            breath_sw     ,   //呼吸灯开关控制，1:打开  0:关闭
    output  reg   [7:0]    breath_fre    ,   //呼吸灯频率控制
    output  reg            parse_done    ,   //解包完成标志
    output  reg   [7:0]    parse_result  ,   //解包后的结果,8'h00:解析正确 8'hEx:解析错误
    output  reg   [7:0]    parse_cmd         //命令 00：Led 01：Beep 10：Breath_led 11：Key
);

//parameter define
parameter PACKET_HEAD    = 8'h55;      //定义数据包头

parameter LED_CMD        = 8'h00;      //控制LED灯亮灭的命令
parameter BEEP_CMD       = 8'h01;      //控制蜂鸣器发声的命令
parameter BREATH_LED_CMD = 8'h02;      //控制呼吸灯的命令
parameter KEY_CMD        = 8'h03;      //查询按键状态的命令
                                        
parameter ERR_HEAD       = 8'hE0;      //包头检测错误
parameter ERR_CMD        = 8'hE1;      //发送无效命令报错
parameter ERR_DATA_LEN   = 8'hE2;      //有效数据长度发送错误
parameter ERR_CHECKSUM   = 8'hE3;      //校验错误

parameter PARSE_OK       = 8'h00;      //数据包解析正确

//localparam define
localparam  st_head      = 6'b00_0001; //解析包头
localparam  st_cmd       = 6'b00_0010; //解析命令
localparam  st_len       = 6'b00_0100; //解析数据有效长度
localparam  st_data      = 6'b00_1000; //解析数据
localparam  st_check     = 6'b01_0000; //校验
localparam  st_rx_end    = 6'b10_0000; //结束状态

//reg define
reg    [5:0]    cur_state      ; //状态机的现态
reg    [5:0]    next_state     ; //状态机的次态

reg    [2:0]    data_cnt       ; //接收到的数据计数器
reg    [7:0]    data_len       ; //接收的有效数据长度
reg    [7:0]    rec_data       ; //接收到的数据
reg    [7:0]    rec_data_t     ; //接收的数据寄存一拍
reg    [7:0]    checksum       ; //包的累加校验和
reg             skip_en        ; //控制状态跳转使能信号

//*****************************************************
//**                    main code
//*****************************************************

//同步时序模块
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) 
        cur_state <= st_head;
    else
        cur_state <= next_state;
end

//转态转换条件
always@(*)begin
    next_state = st_head;
    case(cur_state)
        st_head:begin
            if(skip_en)
                next_state = st_cmd;
            else if(parse_result == ERR_HEAD)
                next_state = st_rx_end;
            else
                next_state = st_head;
        end
        st_cmd:begin
            if(skip_en)
                next_state = st_len;
            else if(parse_cmd == KEY_CMD)
                next_state = st_check;
            else if(parse_result == ERR_CMD)
                next_state = st_rx_end;
            else
                next_state = st_cmd;
        end
        st_len:begin
            if(skip_en)
                next_state = st_data;
            else if(parse_result == ERR_DATA_LEN) 
                next_state = st_rx_end;
            else
                next_state = st_len;
        end
        st_data:begin
            if(skip_en)
                next_state = st_check;
            else
                next_state = st_data;
        end
        st_check:begin
            if(skip_en)
                next_state = st_rx_end;
            else if( parse_result == ERR_CHECKSUM)
                next_state = st_rx_end;
            else
                next_state = st_check;
        end
        st_rx_end :begin
            if(packet_tx_done)
                next_state = st_head;
            else
                next_state = st_rx_end;
        end
        default:
            next_state = st_head;
    endcase
end

//时序电路描述状态输出
always @(posedge clk or negedge rst_n) begin  
    if(!rst_n)begin
        data_cnt     <= 3'b0;
        parse_result <= 8'b0;
        parse_cmd    <= 8'b0;
        data_len     <= 8'b0;
        parse_done   <= 1'b0;
        skip_en      <= 1'b0;
        rec_data     <= 8'b0;
        rec_data_t   <= 8'b0;
        checksum     <= 8'b0;
    end
    else begin
        skip_en <= 1'b0;
        parse_done <= 1'b0;
        case(cur_state)
           st_head: begin  //检测包头
               if(uart_rx_done)
                   if(uart_rx_data == PACKET_HEAD)begin
                       skip_en <= 1'b1;
                       checksum <= PACKET_HEAD;
                   end
                   else begin
                       parse_result <= ERR_HEAD;        //包头检测错误
                       parse_done    <= 1'b1;
                   end
           end
           st_cmd: begin  //接收命令
                if(uart_rx_done)begin 
                    if(uart_rx_data == LED_CMD || uart_rx_data == BEEP_CMD
                    || uart_rx_data == BREATH_LED_CMD) begin
                        parse_cmd <= uart_rx_data;
                        checksum  <= checksum + uart_rx_data;
                        skip_en   <= 1'b1;
                    end
                    else if(uart_rx_data == KEY_CMD)begin
                        parse_cmd <= uart_rx_data;
                        checksum  <= checksum + uart_rx_data;
                    end
                    else begin
                        parse_done <= 1'b1;
                        parse_result <= ERR_CMD;        //检测到未定义命令
                    end
                 end
            end
           st_len: begin  //接收有效数据位
               if(uart_rx_done)begin
                   if(uart_rx_data== 8'd0) begin
                       parse_result <= ERR_DATA_LEN;    //没有发送有效数据
                       parse_done    <= 1'b1;
                   end
                   else begin
                       data_len <= uart_rx_data;
                       skip_en  <= 1'b1;
                       checksum <= checksum + uart_rx_data;
                   end
               end
           end
            st_data: begin  //接收有效数据与累加
                if(uart_rx_done)begin
                    rec_data <= uart_rx_data;
                    rec_data_t <= rec_data;
                    data_cnt <= data_cnt + 3'd1;
                    if(data_cnt < data_len)begin
                        data_cnt <= data_cnt + 3'd1;
                        checksum <= uart_rx_data + checksum ;
                    end
                    else
                        checksum <= checksum;
                    if(data_cnt == data_len - 8'd1)begin
                        data_cnt <= 3'd0;
                        skip_en  <= 1'b1;
                    end
                end
            end
            st_check:begin  //校验
                if(uart_rx_done)begin
                    if(checksum == uart_rx_data)begin
                        skip_en      <= 1'b1;
                        parse_done   <= 1'b1;             //接收完成
                    end
                    else begin 
                        parse_result <= ERR_CHECKSUM;     //校验错误
                        parse_done    <= 1'b1;
                    end
                end
            end
            st_rx_end:begin
                if(packet_tx_done)begin
                    skip_en       <= 1'b0 ;
                    parse_done    <= 1'b0 ;
                    parse_result  <= 8'b0 ;
                    parse_cmd     <= 8'd0 ;
                    checksum      <= 8'd0;
                    data_len      <= 8'd0 ;
                end
            end
           default: ;
        endcase
    end    
end

//接收完成后处理数据
always @(posedge clk or negedge rst_n) begin  
    if(!rst_n)begin
        led_data   <= 2'b0;
        beep_data  <= 1'b0;
        breath_sw  <= 1'b0;
        breath_fre <= 8'b0;
    end
    else if((parse_result == PARSE_OK) && (parse_done == 1'b1))begin
        if(parse_cmd == LED_CMD)
            led_data <= {rec_data[4],rec_data[0]};
        else if(parse_cmd == BEEP_CMD)
            beep_data <= rec_data[0];
        else if(parse_cmd == BREATH_LED_CMD) begin
            breath_sw <= rec_data_t[0];
            breath_fre <= rec_data;
        end
    end
end    

endmodule 