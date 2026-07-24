//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2023-2033
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           packet_code
// Created by:          正点原子
// Created date:        2025年10月14日14:20:02
// Version:             V1.0
// Descriptions:        根据包解析的内容返回对应信息
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module packet_code(
    //input
    input                clk           ,   //外部50MHz时钟
    input                rst_n         ,   //系外部复位信号，低有效
    input         [1:0]  key           ,   //按键输入
    input                uart_tx_busy  ,   //发送忙状态信号
                                       
    input                parse_done    ,   //包解析完成信号
    input         [7:0]  parse_result  ,   //解包后的结果,8'h00:解析正确 8'hEx:解析错误
    input         [7:0]  parse_cmd     ,
     //output
    output    reg        packet_tx_done,   //数据全部发送完成标志
    output    reg        uart_tx_en    ,   //串口发送使能
    output    reg [7:0]  uart_tx_data      //串口发送数据
    );

//parameter define
parameter PACKET_HEAD    = 8'h55;    //定义数据包头
parameter KEY_CMD        = 8'h03;    //查询按键状态的命令
parameter PARSE_OK       = 8'h00;    //数据包解析正确

//reg define
reg         tx_busy_d0       ; //采沿,寄存两拍数据
reg         tx_busy_d1       ; 
reg         tx_en            ; //发送使能信号
            
reg [7:0]   data_cnt         ; //发送数据计数器
reg [7:0]   packet_len       ; //发送一包数据的长度
reg [39:0]  uart_packet_data ; //定义发送包数据长度

//wire define
wire        neg_tx_busy      ; //uart发送忙信号的下降沿

//*****************************************************
//**                    main code
//*****************************************************

//检测到发送忙信号的下降沿，表示一个字节数据发送完成
assign neg_tx_busy = tx_busy_d1 & (~tx_busy_d0) ;

//采下降沿,寄存两拍数据
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        tx_busy_d0 <= 1'b0;
        tx_busy_d1 <= 1'b0;
    end
    else begin
        tx_busy_d0 <= uart_tx_busy;
        tx_busy_d1 <= tx_busy_d0;
    end
end

//统计发送一包数据的长度
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        packet_len <= 8'b0;
    else if(parse_cmd == KEY_CMD && parse_result == PARSE_OK)
        packet_len <= 8'd5;
    else
        packet_len <= 8'd3;
end

//发送数据计数器
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        data_cnt <= 8'b0;  
    else if(neg_tx_busy) begin                //一个字节数据发送完成，neg_tx_busy信号拉高  
        if (data_cnt == (packet_len - 8'd1))  //计数到最后一个数据，计数器清零
            data_cnt <= 8'b0;
        else 
            data_cnt <= data_cnt + 8'b1;
    end
end

//数据全部发送完成的过程
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        packet_tx_done <= 1'b0;
    else if(data_cnt == (packet_len - 8'd1) && neg_tx_busy ) 
    //数据计数到最后一位并且发送完成
        packet_tx_done <= 1'b1;    // 数据全部发送完成，packet_tx_done拉高
    else
        packet_tx_done <= 1'b0;
end

//字节数据发送完成拉高发送使能信号
always@(posedge clk or negedge rst_n )begin
    if(!rst_n)
      tx_en <= 1'b0 ;
   else if(neg_tx_busy && (data_cnt < (packet_len - 8'd1)))
   //字节数据发送完成
        tx_en <= 1'b1;
    else
        tx_en <= 1'b0;
end

//判断向上位机发送数据信号，并在串口发送模块空闲时给出串口发送使能信号
always@(posedge clk or negedge rst_n )begin
    if(!rst_n)
        uart_tx_en <= 1'b0 ;
   else if(parse_done || tx_en)
   //接收数据完成开始发送或者数据发送使能信号
        uart_tx_en <= 1'b1;
    else
        uart_tx_en <= 1'b0;
end

//打包发送给上位机的数据包
always @(posedge clk or negedge rst_n ) begin
    if(!rst_n)
        uart_packet_data <= {32'd0,PACKET_HEAD};
    else if(parse_done)begin
        if(packet_len == 8'd3) begin
            if(parse_result == PARSE_OK) begin                       //发送解析正确数据包
                uart_packet_data[15:8] <= parse_cmd;
                uart_packet_data[23:16] <= PACKET_HEAD + parse_cmd;  //计算发送数据包校验和
            end   
            else begin
                uart_packet_data[15:8] <= parse_result;              //发送解析错误数据包
                uart_packet_data[23:16] <= PACKET_HEAD + parse_result;  
            end
        end
        else begin
            uart_packet_data[15:8] <= parse_cmd;
            uart_packet_data[23:16] <= 8'h01;                       //发送查询结果数据包
            uart_packet_data[31:24] <= {3'b0,key[1],3'b0,key[0]};
            uart_packet_data[39:32] <= PACKET_HEAD + parse_cmd + 8'h01 + {3'b0,key[1],3'b0,key[0]}; 
        end
    end
end

//发送数据
always @(posedge clk or negedge rst_n ) begin
    if(!rst_n)
        uart_tx_data <= 8'b0;
    else begin
        case(data_cnt)
            8'd0 : uart_tx_data <= uart_packet_data[7:0];
            8'd1 : uart_tx_data <= uart_packet_data[15:8];
            8'd2 : uart_tx_data <= uart_packet_data[23:16];
            8'd3 : uart_tx_data <= uart_packet_data[31:24];
            8'd4 : uart_tx_data <= uart_packet_data[39:32];
            default : uart_tx_data <= 8'b0;
        endcase    
    end
end

endmodule
