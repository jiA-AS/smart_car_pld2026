//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2023-2033
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           cmd_exe
// Created by:          正点原子
// Created date:        2025年10月14日09:40:02
// Version:             V1.0
// Descriptions:        命令执行模块
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module cmd_exe(
    //input
    input              clk       ,     //系统时钟，50MHZ
    input              rst_n     ,     //系统复位，低电平有效
    input     [1:0]    led_data  ,     //LED灯信号
    input              beep_data ,     //蜂鸣器信号
    input              breath_sw ,     //呼吸灯控制信号 0：关闭  1：打开
    input     [7:0]    breath_fre,     //呼吸灯频率控制信号 
    //output
    output             breath_led,     //呼吸灯信号
    output    [1:0]    led       ,     //LED灯
    output             beep            //蜂鸣器
);

//*****************************************************
//**                    main code
//*****************************************************
assign  led = led_data  ;    //输出LED灯信号
assign  beep = beep_data;    //输出蜂鸣器信号

//例化呼吸灯模块
breath_led u_breath_led(
    .sys_clk     (clk       ),
    .sys_rst_n   (rst_n     ),
    .breath_fre  (breath_fre),
    .breath_sw   (breath_sw ),
    .breath_led  (breath_led)
);

endmodule