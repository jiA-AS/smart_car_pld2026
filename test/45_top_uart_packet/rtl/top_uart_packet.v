//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2023-2033
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           top_uart_packet
// Created by:          正点原子
// Created date:        2025/10/6 10:55:56
// Version:             V1.0
// Descriptions:        串口通信数据包解析顶层模块
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module top_uart_packet( 
    input               sys_clk   ,    //系统时钟，50MHZ
    input               sys_rst_n ,    //系统复位，低电平有效

    input               uart_rxd  ,    //串口接收的数据
    input   [1:0]       key       ,    //按键输入,2个按键

    output  [1:0]       led       ,     //LED输出,2个LED灯
    output              beep      ,     //蜂鸣器输出
    output              breath_led,     //呼吸灯输出
    output              uart_txd        //串口发送的数据
);

//parameter define
parameter PACKET_HEAD    = 8'h55;    //定义数据包头

parameter LED_CMD        = 8'h00;    //控制LED灯亮灭的命令
parameter BEEP_CMD       = 8'h01;    //控制蜂鸣器发声的命令
parameter BREATH_LED_CMD = 8'h02;    //控制呼吸灯的命令
parameter KEY_CMD        = 8'h03;    //查询按键状态的命令

parameter ERR_HEAD       = 8'hE0;    //包头检测错误
parameter ERR_CMD        = 8'hE1;    //发送无效命令报错
parameter ERR_DATA_LEN   = 8'hE2;    //有效数据长度发送错误
parameter ERR_CHECKSUM   = 8'hE3;    //校验错误

parameter PARSE_OK       = 8'h00;    //数据包解析正确

//wire define
wire    [7:0]    uart_rx_data   ;    //UART接收端接收的数据
wire             uart_rx_done   ;    //UART接收一字节数据完成标志
wire    [1:0]    led_data       ;    //LED写入数据,两位控制两个LED灯00 01 10 11
wire             beep_data      ;    //蜂鸣器写入数据，1发声，0不发声
wire             parse_done     ;    //解包完成标志
wire    [7:0]    parse_result   ;    //解包后的结果,8'h00:解析正确 8'hEx:解析错误
wire    [7:0]    parse_cmd      ;    //命令 00：Led 01：Beep 10：Breath_led 11：Key
wire             breath_sw      ;    //呼吸灯开关控制，一位，0：关  1：开
wire    [7:0]    breath_fre     ;    //呼吸灯频率控制
wire             uart_tx_en     ;    //UART发送端使能信号
wire    [7:0]    uart_tx_data   ;    //UART发送端的数据
wire             uart_tx_busy   ;    //UART发送端忙状态信号
wire             packet_tx_done ;    //一包数据全部发送完成标志
//*****************************************************
//**                   main code
//*****************************************************

//例化串口通信接收模块uart_rx
uart_rx    u_uart_rx(
    .clk                 (sys_clk       ),
    .rst_n               (sys_rst_n     ),
    .uart_rxd            (uart_rxd      ),
    .uart_rx_done        (uart_rx_done  ),
    .uart_rx_data        (uart_rx_data  ) 
);

//例化数据包解析模块
packet_decode #(
    .PACKET_HEAD         (PACKET_HEAD   ),
    .LED_CMD             (LED_CMD       ),
    .BEEP_CMD            (BEEP_CMD      ),
    .BREATH_LED_CMD      (BREATH_LED_CMD),
    .KEY_CMD             (KEY_CMD       ),
    .ERR_HEAD            (ERR_HEAD      ),
    .ERR_CMD             (ERR_CMD       ),
    .ERR_DATA_LEN        (ERR_DATA_LEN  ),
    .ERR_CHECKSUM        (ERR_CHECKSUM  ),
    .PARSE_OK            (PARSE_OK      ))
    u_packet_decode(
    .clk                 (sys_clk       ),
    .rst_n               (sys_rst_n     ),
    .uart_rx_data        (uart_rx_data  ),
    .uart_rx_done        (uart_rx_done  ),
    .packet_tx_done      (packet_tx_done),
    .led_data            (led_data      ),
    .beep_data           (beep_data     ),
    .breath_sw           (breath_sw     ),
    .breath_fre          (breath_fre    ),
    .parse_done          (parse_done    ),
    .parse_result        (parse_result  ),
    .parse_cmd           (parse_cmd     )
);

//例化命令执行模块
cmd_exe    u_cmd_exe(
    .clk                 (sys_clk       ),
    .rst_n               (sys_rst_n     ),
    .led_data            (led_data      ),
    .beep_data           (beep_data     ),
    .breath_sw           (breath_sw     ),
    .breath_fre          (breath_fre    ),
    .led                 (led           ),
    .beep                (beep          ),
    .breath_led          (breath_led    )
);

//例化数据包封装模块
packet_code #(
    .PACKET_HEAD         (PACKET_HEAD   ),
    .KEY_CMD             (KEY_CMD       ),
    .PARSE_OK            (PARSE_OK      ))
    u_packet_code(
    .clk                 (sys_clk       ),
    .rst_n               (sys_rst_n     ),
    .key                 (key           ),
    .uart_tx_busy        (uart_tx_busy  ),
    .parse_done          (parse_done    ),
    .parse_result        (parse_result  ),
    .parse_cmd           (parse_cmd     ),
    .packet_tx_done      (packet_tx_done),
    .uart_tx_en          (uart_tx_en    ),
    .uart_tx_data        (uart_tx_data  )
);

//例化串口通信发送模块uart_tx
uart_tx    u_uart_tx(
    .clk                (sys_clk        ),
    .rst_n              (sys_rst_n      ),
    .uart_tx_data       (uart_tx_data   ),
    .uart_tx_en         (uart_tx_en     ),
    .uart_tx_busy       (uart_tx_busy   ),
    .uart_txd           (uart_txd       )
);

endmodule