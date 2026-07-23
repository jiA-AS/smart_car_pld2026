//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2023-2033
//All rights reserved 
//----------------------------------------------------------------------------------------
// File name:           ov5640_hdmi
// Created by:          正点原子
// Created date:        2025年11月010日14:20:02
// Version:             V1.0
// Descriptions:        OV5640摄像头HDMI显示
//                      
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module ov5640_hdmi(    
    input                 sys_clk      ,  //系统时钟
    input                 sys_rst_n    ,  //系统复位，低电平有效
    //摄像头接口                       
    input                 cam_pclk     ,  //CMOS 数据像素时钟
    input                 cam_vsync    ,  //CMOS 场同步信号
    input                 cam_href     ,  //CMOS 行同步信号
    input   [7:0]         cam_data     ,  //CMOS 数据
    output                cam_rst_n    ,  //CMOS 复位信号，低电平有效
    output                cam_pwdn     ,  //电源休眠模式选择 0：正常模式 1：电源休眠模式
    output                cam_scl      ,  //CMOS SCCB_SCL线
    inout                 cam_sda      ,  //CMOS SCCB_SDA线       
    // DDR3                            
    inout   [31:0]        ddr3_dq      ,  //DDR3 数据
    inout   [3:0]         ddr3_dqs_n   ,  //DDR3 dqs负
    inout   [3:0]         ddr3_dqs_p   ,  //DDR3 dqs正  
    output  [13:0]        ddr3_addr    ,  //DDR3 地址   
    output  [2:0]         ddr3_ba      ,  //DDR3 banck 选择
    output                ddr3_ras_n   ,  //DDR3 行选择
    output                ddr3_cas_n   ,  //DDR3 列选择
    output                ddr3_we_n    ,  //DDR3 读写选择
    output                ddr3_reset_n ,  //DDR3 复位
    output  [0:0]         ddr3_ck_p    ,  //DDR3 时钟正
    output  [0:0]         ddr3_ck_n    ,  //DDR3 时钟负
    output  [0:0]         ddr3_cke     ,  //DDR3 时钟使能
    output  [0:0]         ddr3_cs_n    ,  //DDR3 片选
    output  [3:0]         ddr3_dm      ,  
    output  [0:0]         ddr3_odt     ,                                                                  
    //HDMI接口                           
    output                tmds_clk_p   ,  //TMDS 时钟通道
    output                tmds_clk_n   ,
    output  [2:0]         tmds_data_p  ,  //TMDS 数据通道
    output  [2:0]         tmds_data_n  
    );     

//parameter define                                
parameter  V_CMOS_DISP   = 11'd768;                  //CMOS分辨率--行
parameter  H_CMOS_DISP   = 11'd1024;                 //CMOS分辨率--列   
parameter  TOTAL_H_PIXEL = H_CMOS_DISP + 12'd1216; 
parameter  TOTAL_V_PIXEL = V_CMOS_DISP + 12'd504;                                              
                               
//wire define                          
wire         clk_50m                   ;  //50MHz时钟,提供给LCD驱动时钟
wire         locked                    ;  //时钟锁定信号
wire         rst_n                     ;  //全局复位                                                                       
wire  [15:0] wrdata                    ;  //DDR3控制器模块写数据
wire         rdata_req                 ;  //DDR3控制器模块读使能
wire  [15:0] rddata                    ;  //DDR3控制器模块读数据
wire         rd_vsync                  ;  //输出源更新信号
wire         cmos_frame_valid          ;  //数据有效使能信号
wire         init_calib_complete       ;  //DDR3初始化完成init_calib_complete
wire         sys_init_done             ;  //系统初始化完成(DDR初始化+摄像头初始化)
wire         clk_200m                  ;  //DDR3参考时钟
wire         cmos_frame_vsync          ;  //输出帧有效场同步信号

//*****************************************************
//**                    main code
//*****************************************************

//待时钟锁定后产生复位结束信号
assign  rst_n = sys_rst_n & locked;

//系统初始化完成：DDR3初始化完成
assign  sys_init_done = init_calib_complete;

 //ov5640 驱动
ov5640_dri u_ov5640_dri(
    .clk                 (clk_50m              ),
    .rst_n               (rst_n                ),

    .cam_pclk            (cam_pclk             ),
    .cam_vsync           (cam_vsync            ),
    .cam_href            (cam_href             ),
    .cam_data            (cam_data             ),
    .cam_rst_n           (cam_rst_n            ),
    .cam_pwdn            (cam_pwdn             ),
    .cam_scl             (cam_scl              ),
    .cam_sda             (cam_sda              ),
    
    .capture_start       (init_calib_complete  ),
    .cmos_h_pixel        (H_CMOS_DISP          ),
    .cmos_v_pixel        (V_CMOS_DISP          ),
    .total_h_pixel       (TOTAL_H_PIXEL        ),
    .total_v_pixel       (TOTAL_V_PIXEL        ),
    .cmos_frame_vsync    (cmos_frame_vsync     ),
    .cmos_frame_href     (                     ),
    .cmos_frame_valid    (cmos_frame_valid     ),
    .cmos_frame_data     (wrdata               )
    );   

ddr3_top u_ddr3_top (
    .sys_clk_i           (clk_200m             ),   //MIG IP核输入时钟 
    .clk_ref_i           (clk_200m             ),   //DDR3参考时钟    
    .rst_n               (rst_n                ),   //复位,低有效
    .init_calib_complete (init_calib_complete  ),   //DDR3初始化完成信号    
    //ddr3接口信号       
    .app_addr_rd_min     (28'd0                ),   //读DDR3的起始地址
    .app_addr_rd_max     (24'd393216           ),   //读DDR3的结束地址
    .rd_bust_len         (H_CMOS_DISP[10:4]    ),   //从DDR3中读数据时的突发长度
    .app_addr_wr_min     (28'd0                ),   //写DDR3的起始地址
    .app_addr_wr_max     (24'd393216           ),   //写DDR3的结束地址
    .wr_bust_len         (H_CMOS_DISP[10:4]    ),   //从DDR3中写数据时的突发长度   
    // DDR3 IO接口              
    .ddr3_dq             (ddr3_dq              ),   //DDR3 数据
    .ddr3_dqs_n          (ddr3_dqs_n           ),   //DDR3 dqs负
    .ddr3_dqs_p          (ddr3_dqs_p           ),   //DDR3 dqs正  
    .ddr3_addr           (ddr3_addr            ),   //DDR3 地址   
    .ddr3_ba             (ddr3_ba              ),   //DDR3 banck 选择
    .ddr3_ras_n          (ddr3_ras_n           ),   //DDR3 行选择
    .ddr3_cas_n          (ddr3_cas_n           ),   //DDR3 列选择
    .ddr3_we_n           (ddr3_we_n            ),   //DDR3 读写选择
    .ddr3_reset_n        (ddr3_reset_n         ),   //DDR3 复位
    .ddr3_ck_p           (ddr3_ck_p            ),   //DDR3 时钟正
    .ddr3_ck_n           (ddr3_ck_n            ),   //DDR3 时钟负  
    .ddr3_cke            (ddr3_cke             ),   //DDR3 时钟使能
    .ddr3_cs_n           (ddr3_cs_n            ),   //DDR3 片选
    .ddr3_dm             (ddr3_dm              ),   
    .ddr3_odt            (ddr3_odt             ),   
    //用户                                            
    .ddr3_read_valid     (1'b1                 ),   //DDR3 读使能
    .ddr3_pingpang_en    (1'b1                 ),   //DDR3 乒乓操作使能
    .wr_clk              (cam_pclk             ),   //写时钟
    .wr_load             (cmos_frame_vsync     ),   //输入源更新信号   
    .wr_en               (cmos_frame_valid     ),   //数据有效使能信号
    .wrdata              (wrdata               ),   //有效数据 
    .rd_clk              (pixel_clk            ),   //读时钟 
    .rd_load             (rd_vsync             ),   //输出源更新信号    
    .rddata              (rddata               ),   //rfifo输出数据
    .rdata_req           (rdata_req            )    //请求数据输入   
     );                    

 clk_wiz_0 u_clk_wiz_0
   (
    // Clock out ports
    .clk_out1            (clk_200m             ),     
    .clk_out2            (clk_50m              ),
    .clk_out3            (pixel_clk_5x         ),
    .clk_out4            (pixel_clk            ),
    // Status and control signals
    .reset               (~sys_rst_n           ), 
    .locked              (locked               ),       
   // Clock in ports
    .clk_in1             (sys_clk              )
    );     
 
//HDMI驱动显示模块    
hdmi_top u_hdmi_top(
    .pixel_clk           (pixel_clk            ),
    .pixel_clk_5x        (pixel_clk_5x         ),    
    .sys_rst_n           (sys_init_done & rst_n),
    //hdmi接口                   
    .tmds_clk_p          (tmds_clk_p           ),   // TMDS 时钟通道
    .tmds_clk_n          (tmds_clk_n           ),
    .tmds_data_p         (tmds_data_p          ),   // TMDS 数据通道
    .tmds_data_n         (tmds_data_n          ),
    //用户接口 
    .video_vs            (rd_vsync             ),   //HDMI场信号  
    .pixel_xpos          (                     ),
    .pixel_ypos          (                     ),      
    .data_in             (rddata               ),   //数据输入 
    .data_req            (rdata_req            )    //请求数据输入   
);   

endmodule