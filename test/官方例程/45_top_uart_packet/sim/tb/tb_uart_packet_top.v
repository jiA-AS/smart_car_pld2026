`timescale 1ns / 1ps
//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2023-2033
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           tb_top_uart_packet
// Created by:          正点原子
// Created date:        2023/4/6 10:55:56
// Version:             V1.0
// Descriptions:        串口通信仿真模块
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module tb_top_uart_packet();

//parameter define
parameter CLK_PERIOD = 20                   ;//时钟周期为20ns
parameter CLK_FREQ   = 50000000             ;  //系统时钟周期
parameter UART_BPS   = 115200               ;  //该接收端口的波特率
parameter BPS_CNT    = CLK_FREQ/UART_BPS    ;  //接收一个字节的周期

// reg define
reg        sys_clk     ;
reg        sys_rst_n   ;
reg  [7:0] uart_rx_data;
reg        uart_rx_done;
reg  [1:0] key         ;
//wire define
wire [1:0] led         ;
wire       beep        ;
wire       breath_led  ;
wire       uart_txd    ;

//初始化设置
initial begin
    sys_clk      <= 1'b0 ;
    sys_rst_n    <= 1'b0 ;
    uart_rx_data <= 8'h00;
    uart_rx_done <= 1'b0 ;
    key          <= 2'b00;
    #20
    sys_rst_n <= 1'b1 ;
    #40
    key          <= 2'b10;
    
    //点亮LED0灯
    #150000
    uart_rx_data <= 8'h55;
    uart_rx_done <= 1'b1 ;
    #20
    uart_rx_done  <= 1'b0;
    
    #150000
    uart_rx_data <= 8'h00; //控制LED
    uart_rx_done <= 1'b1 ;
    #20
    uart_rx_done <= 1'b0 ;
    
    #150000
    uart_rx_data <= 8'h01;
    uart_rx_done <= 1'b1 ;
    #20
    uart_rx_done <= 1'b0 ;
    
    #150000
    uart_rx_data <= 8'h01;  //打开LED_0灯
    uart_rx_done <= 1'b1 ;
    #20
    uart_rx_done <= 1'b0 ;
    
    #150000
    uart_rx_data <= 8'h57;
    uart_rx_done <= 1'b1 ;
    #20
    uart_rx_done <= 1'b0 ;
    
    #1500000
    uart_rx_data <= 8'h00;
    
    //按键查询
    //#150000
    //uart_rx_data <= 8'h55;
    //uart_rx_done <= 1'b1 ;
    //#20
    //uart_rx_done  <= 1'b0;
    //
    //#150000
    //uart_rx_data <= 8'h03; //查询按键
    //uart_rx_done <= 1'b1 ;
    //#20
    //uart_rx_done <= 1'b0 ;
    //
    //#150000
    //uart_rx_data <= 8'h58;
    //uart_rx_done <= 1'b1 ;
    //#20
    //uart_rx_done <= 1'b0 ;
    //
    //#1500000
    //uart_rx_data <= 8'h00;
    
    //打开呼吸灯
    //#150000
    //uart_rx_data <= 8'h55;
    //uart_rx_done <= 1'b1 ;
    //#20
    //uart_rx_done  <= 1'b0;
    //
    //#150000
    //uart_rx_data <= 8'h02; //控制呼吸灯
    //uart_rx_done <= 1'b1 ;
    //#20
    //uart_rx_done <= 1'b0 ;
    //
    //#150000
    //uart_rx_data <= 8'h02;
    //uart_rx_done <= 1'b1 ;
    //#20
    //uart_rx_done <= 1'b0 ;
    //
    //#150000
    //uart_rx_data <= 8'h01;  //打开呼吸灯
    //uart_rx_done <= 1'b1 ;  
    //#20
    //uart_rx_done <= 1'b0 ;
    //
    //#150000
    //uart_rx_data <= 8'h01;//仅用于仿真
    //uart_rx_done <= 1'b1 ;
    //#20
    //uart_rx_done <= 1'b0 ;
    //
    //#150000
    //uart_rx_data <= 8'h5B;
    //uart_rx_done <= 1'b1 ;
    //#20
    //uart_rx_done <= 1'b0 ;
    //
    //#1500000
    //uart_rx_data <= 8'h00;
    
    //误码测试
    //#150000
    //uart_rx_data <= 8'h55; 
    //uart_rx_done <= 1'b1 ;
    //#20
    //uart_rx_done  <= 1'b0;
    //
    //#150000
    //uart_rx_data <= 8'h00; //控制LED
    //uart_rx_done <= 1'b1 ;
    //#20
    //uart_rx_done <= 1'b0 ;
    //
    //#150000
    //uart_rx_data <= 8'h01;
    //uart_rx_done <= 1'b1 ;
    //#20
    //uart_rx_done <= 1'b0 ;
    //
    //#150000
    //uart_rx_data <= 8'h01;  //打开LED_0灯
    //uart_rx_done <= 1'b1 ;
    //#20
    //uart_rx_done <= 1'b0 ;
    //
    //#150000
    //uart_rx_data <= 8'h58;//校验错误"E3"
    //uart_rx_done <= 1'b1 ;
    //#20
    //uart_rx_done <= 1'b0 ;
    //
    //#1500000
    //uart_rx_data <= 8'h00;
end

//50Mhz的时钟，周期则为1/50Mhz=20ns,所以每10ns，电平取反一次
always #(CLK_PERIOD/2) sys_clk = ~sys_clk;

top_uart_packet u_top_uart_packet(
    //input
    .sys_clk    (sys_clk   ),      //外部50Mhn时钟
    .sys_rst_n  (sys_rst_n ),      //外部复位信号，低有效
    .uart_rxd   (uart_txd  ),      //UART接收端口
    .key        (key       ),      //按键输入
    //output
    .led        (led       ),
    .beep       (beep      ),
    .breath_led (breath_led),
    .uart_txd   ()                 //UART发送端口
        );

//例化发送模块
uart_tx #(
    .CLK_FREQ (CLK_FREQ),          //设置系统时钟频率
    .UART_BPS (UART_BPS))          //设置串口发送波特率
    u_uart_tx(
    //input
    .clk            (sys_clk     ),
    .rst_n          (sys_rst_n   ),
    .uart_tx_en     (uart_rx_done),
    .uart_tx_data   (uart_rx_data),
    //output
    .uart_tx_busy   (),
    .uart_txd       (uart_txd    )
); 

endmodule