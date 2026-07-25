//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2023-2033
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           picture_size
// Created by:          正点原子
// Created date:        2025年10月25日10:13:00
// Version:             V1.0
// Descriptions:        摄像头输出图像尺寸及帧率配置
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module picture_size (
    input              rst_n         ,//复位信号
    input              clk           ,//时钟信号         
    input       [15:0] lcd_id        ,//LCD的器件ID
             
    output reg  [12:0] cmos_h_pixel  ,//摄像头水平分辨率
    output reg  [12:0] cmos_v_pixel  ,//摄像头垂直分辨率   
    output reg  [12:0] total_h_pixel ,//水平总像素大小
    output reg  [12:0] total_v_pixel ,//垂直总像素大小
    output reg  [12:0] y_addr_st     ,//开窗垂直方向起始地址
    output reg  [12:0] y_addr_end    ,//开窗垂直方向截至地址
    output reg  [27:0] ddr3_max_addr  //ddr最大读写地址
);

//*****************************************************
//**                    main code                      
//*****************************************************

//配置摄像头输出尺寸的大小
always @(posedge clk or negedge rst_n) begin 
    if(!rst_n) begin
        cmos_h_pixel <= 13'b0;
        cmos_v_pixel <= 13'd0;
        ddr3_max_addr <= 28'd0;        
    end 
    else begin    
        case(lcd_id ) 
            16'h4342 : begin
                cmos_h_pixel   <= 13'd480;    
                cmos_v_pixel   <= 13'd272;
                ddr3_max_addr  <= 28'd130560;
            end 
            16'h7084 : begin
                cmos_h_pixel   <= 13'd800;    
                cmos_v_pixel   <= 13'd480;           
                ddr3_max_addr  <= 28'd384000;
            end 
            16'h7016 : begin
                cmos_h_pixel   <= 13'd1024;    
                cmos_v_pixel   <= 13'd600;           
                ddr3_max_addr  <= 28'd614400;
            end    
            16'h1018 : begin
                cmos_h_pixel   <= 13'd1280;    
                cmos_v_pixel   <= 13'd800;           
                ddr3_max_addr  <= 28'd1024000;
            end 
            16'h4384 : begin
                cmos_h_pixel   <= 13'd800;    
                cmos_v_pixel   <= 13'd480;           
                ddr3_max_addr  <= 28'd384000;
            end
            default : begin
                cmos_h_pixel   <= 13'd480;    
                cmos_v_pixel   <= 13'd272;           
                ddr3_max_addr  <= 28'd384000;
            end
        endcase
    end    
end 

//对HTS及VTS的配置会影响摄像头输出图像的帧率
always @(*) begin
    case(lcd_id)
        16'h4342 : begin 
            total_h_pixel = 13'd1800;
            total_v_pixel = 13'd1000;
        end 
        16'h7084 : begin  
            total_h_pixel = 13'd1800;
            total_v_pixel = 13'd1000;
        end 
        16'h7016 : begin  
            total_h_pixel = 13'd2200;
            total_v_pixel = 13'd1000;
        end 
        16'h1018 : begin 
            total_h_pixel = 13'd2570;
            total_v_pixel = 13'd980;
        end 
        16'h4384 : begin  
            total_h_pixel = 13'd1800;
            total_v_pixel = 13'd1000;
        end
        default : begin
            total_h_pixel = 13'd1800;
            total_v_pixel = 13'd1000;
        end 
    endcase
end 

//按照LCD屏幕的分辨率比例，输出OV5640预缩放窗口大小，避免画面拉伸
always @(*) begin
    case(lcd_id)
        16'h4342 : begin 
            y_addr_st  = 13'd228;
            y_addr_end = 13'd1723;
        end 
        16'h7084 : begin  
            y_addr_st  = 13'd187;
            y_addr_end = 13'd1763;
        end 
        16'h7016 : begin  
            y_addr_st  = 13'd201;
            y_addr_end = 13'd1749;
        end 
        16'h1018 : begin 
            y_addr_st  = 13'd153;
            y_addr_end = 13'd1798;
        end 
        16'h4384 : begin  
            y_addr_st  = 13'd187;
            y_addr_end = 13'd1763;
        end 
        default : begin
            y_addr_st  = 13'd228;
            y_addr_end = 13'd1723;
        end 
    endcase
end 

endmodule 