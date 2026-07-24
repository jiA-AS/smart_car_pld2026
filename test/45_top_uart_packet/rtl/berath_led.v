//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2023-2033
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           breath_led
// Created by:          正点原子
// Created date:        2025年10月1日09:40:02
// Version:             V1.0
// Descriptions:        呼吸灯实验
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module breath_led(
    input         sys_clk   ,    //系统时钟 50MHz
    input         sys_rst_n ,    //系统复位，低电平有效
    input  [7:0]  breath_fre,    //呼吸灯频率信号
    input         breath_sw ,    //呼吸灯控制信号 0：关闭  1：打开
    output reg    breath_led     //呼吸灯信号
);

//parameter define
parameter CNT_MS_MAX = 10'd1000;
parameter CNT_S_MAX  = 10'd1000;
//parameter CNT_MS_MAX = 10'd10; //用于仿真
//parameter CNT_S_MAX  = 10'd10; //用于仿真

//reg define
reg [6:0] cnt_us;
reg [9:0] cnt_ms;
reg [9:0] cnt_s ;
reg       inc_dec_flag; //亮度递增/递减 0:递增 1:递减

//wire define
wire [7:0] cnt_us_max; //每个亮度阶梯的时长
wire       rst_n     ; //呼吸灯复位信号
//*****************************************************
//**                  main code
//*****************************************************
assign rst_n   = sys_rst_n & breath_sw;
assign cnt_us_max = breath_fre * 25;

//cnt_us:计数us
always@(posedge sys_clk or negedge rst_n) begin
    if(!rst_n)
        cnt_us <= 7'b0;
    else if(cnt_us == (cnt_us_max - 7'b1 ))
        cnt_us <= 7'b0;
    else
        cnt_us <= cnt_us + 7'b1;
end

//cnt_ms:计数ms
always@(posedge sys_clk or negedge rst_n) begin
    if(!rst_n)
        cnt_ms <= 10'b0;
    else if(cnt_ms == (CNT_MS_MAX - 10'b1) && cnt_us == (cnt_us_max - 7'b1))
        cnt_ms <= 10'b0;
    else if(cnt_us == cnt_us_max - 7'b1)
        cnt_ms <= cnt_ms + 10'b1;
    else
        cnt_ms <= cnt_ms;
end

//cnt_s:计数s
always@(posedge sys_clk or negedge rst_n) begin
    if(!rst_n)
        cnt_s <= 10'b0;
    else if(cnt_s == (CNT_S_MAX - 10'b1) && cnt_ms == (CNT_MS_MAX - 10'b1) && cnt_us == (cnt_us_max - 7'b1))
        cnt_s <= 10'b0;
    else if(cnt_ms == (CNT_MS_MAX - 10'b1) && cnt_us == (cnt_us_max - 7'b1))
        cnt_s <= cnt_s + 10'b1;
    else
        cnt_s <= cnt_s;         
end

//inc_dec_flag为低电平，lLED灯由暗变亮，inc_dec_flag为高电平，LED灯由亮变暗
always@(posedge sys_clk or negedge rst_n) begin
    if(!rst_n)
        inc_dec_flag <= 1'b0;
    else if(cnt_s == (CNT_S_MAX - 10'b1) && cnt_ms ==( CNT_MS_MAX - 10'b1) && cnt_us == (cnt_us_max - 7'b1))
        inc_dec_flag <= ~inc_dec_flag;
    else
        inc_dec_flag <= inc_dec_flag;
end

//breath_led:输出信号连接到外部的LED灯
always@(posedge sys_clk or negedge rst_n) begin
    if(!rst_n)
        breath_led <= 1'b0;
    else if((inc_dec_flag == 1'b1 && cnt_ms >= cnt_s) || (inc_dec_flag == 1'b0 && cnt_ms <= cnt_s))
        breath_led <= 1'b1;
    else
        breath_led <= 1'b0;
end

endmodule