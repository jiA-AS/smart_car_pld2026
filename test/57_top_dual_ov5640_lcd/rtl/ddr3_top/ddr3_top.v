//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2023-2033
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           ddr3_top
// Created by:          正点原子
// Created date:        2025年10月25日13:37:00
// Version:             V1.0
// Descriptions:        ddr3控制器顶层
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module ddr3_top(
    input              sys_clk_i           ,   //DDR3参考时钟
    input              clk_ref_i           ,   //MIG IP核输入时钟
    input              rst_n               ,   //复位,低有效            
    //DDR3接口信号                           
    input   [27:0]     app_addr_rd_min     ,   //读DDR3的起始地址
    input   [27:0]     app_addr_rd_max     ,   //读DDR3的结束地址
    input   [7:0]      rd_bust_len         ,   //从DDR3中读数据时的突发长度
    input   [27:0]     app_addr_wr_min     ,   //写DDR3的起始地址
    input   [27:0]     app_addr_wr_max     ,   //写DDR3的结束地址
    input   [7:0]      wr_bust_len         ,   //从DDR3中写数据时的突发长度
    // DDR3 IO接口 
    inout   [31:0]     ddr3_dq             ,   //DDR3数据
    inout   [3:0]      ddr3_dqs_n          ,   //DDR3 dqs负
    inout   [3:0]      ddr3_dqs_p          ,   //DDR3 dqs正  
    output  [13:0]     ddr3_addr           ,   //DDR3地址   
    output  [2:0]      ddr3_ba             ,   //DDR3 Bank选择
    output             ddr3_ras_n          ,   //DDR3行选择
    output             ddr3_cas_n          ,   //DDR3列选择
    output             ddr3_we_n           ,   //DDR3读写选择
    output             ddr3_reset_n        ,   //DDR3复位
    output  [0:0]      ddr3_ck_p           ,   //DDR3时钟正
    output  [0:0]      ddr3_ck_n           ,   //DDR3时钟负
    output  [0:0]      ddr3_cke            ,   //DDR3时钟使能
    output  [0:0]      ddr3_cs_n           ,   //DDR3片选
    output  [3:0]      ddr3_dm             ,   //ddr3_dm
    output  [0:0]      ddr3_odt            ,   //ddr3_odt      
    //用户接口
    input              ddr3_read_valid     ,   //DDR3读使能   
    input              ddr3_pingpang_en    ,   //DDR3乒乓操作使能 
    input              wr_clk_1            ,   //wfifo时钟1
    input              wr_en_1             ,   //数据有效使能信号
    input   [15:0]     wrdata_1            ,   //有效数据 
    input              wr_load_1           ,   //输入源场信号    
    input              wr_clk_2            ,   //wfifo时钟2
    input              wr_en_2             ,   //数据有效使能信号
    input   [15:0]     wrdata_2            ,   //有效数据 
    input              wr_load_2           ,   //输入源场信号
    
    input   [12:0]     h_disp              ,   //摄像头水平分辨率 
    input              rd_clk              ,   //rfifo的读时钟      
    input              rdata_req           ,   //请求像素点颜色数据输入  
    input              rd_load             ,   //输出源场信号
    output  [15:0]     rddata              ,   //rfifo输出数据
    output             init_calib_complete     //DDR3初始化完成信号
    );                
                      
 //wire define  
wire                  ui_clk               ;   //用户时钟
wire [27:0]           app_addr             ;   //DDR3地址
wire [2:0]            app_cmd              ;   //用户读写命令
wire                  app_en               ;   //MIG IP核使能
wire                  app_rdy              ;   //MIG IP核空闲
wire [255:0]          app_rd_data          ;   //用户读数据
wire                  app_rd_data_end      ;   //突发读当前时钟最后一个数据 
wire                  app_rd_data_valid    ;   //读数据有效
wire [255:0]          app_wdf_data         ;   //用户写数据 
wire                  app_wdf_end          ;   //突发写当前时钟最后一个数据 
wire [31:0]           app_wdf_mask         ;   //写数据屏蔽                           
wire                  app_wdf_rdy          ;   //写空闲                               
wire                  app_sr_active        ;   //保留                                 
wire                  app_ref_ack          ;   //刷新请求                             
wire                  app_zq_ack           ;   //ZQ校准请求                          
wire                  app_wdf_wren         ;   //DDR3写使能      
wire                  ui_clk_sync_rst      ;   //用户复位信号                         
wire [20:0]           rd_cnt               ;   //实际读地址计数                       
wire [3 :0]           state_cnt            ;   //状态计数器                           
wire [23:0]           rd_addr_cnt          ;   //用户读地址计数器                     
wire [23:0]           wr_addr_cnt          ;   //用户写地址计数器                     
wire                  rfifo_wren           ;   //从DDR3读出数据的有效使能              
wire [255:0]          rfifo_wdata_1        ;   //rfifo1输入数据  
wire [255:0]          rfifo_wdata_2        ;   //rfifo2输入数据   
wire [10:0]           wfifo_rcount_1       ;   //wfifo1剩余数据计数 
wire [10:0]           wfifo_rcount_2       ;   //wfifo2剩余数据计数 
wire [10:0]           rfifo_wcount_1       ;   //rfifo1写进数据计数
wire [10:0]           rfifo_wcount_2       ;   //rfifo2写进数据计数  
                                                                                  
//*****************************************************                               
//**                    main code                                                     
//*****************************************************                               
                                                                                      
//DDR3读写模块                                                                            
 ddr3_rw u_ddr3_rw(                                                                   
    .ui_clk               (ui_clk)              ,                                     
    .ui_clk_sync_rst      (ui_clk_sync_rst)     ,                                      
    //MIG 接口                                                                        
    .init_calib_complete  (init_calib_complete) ,   //DDR3初始化完成信号    
    .app_rdy              (app_rdy)             ,   //MIG IP核空闲    
    .app_wdf_rdy          (app_wdf_rdy)         ,   //写空闲                                   
    .app_rd_data_valid    (app_rd_data_valid)   ,   //读数据有效 
    .app_rd_data          (app_rd_data)         ,   //读数据           
    .app_addr             (app_addr)            ,   //DDR3地址                                   
    .app_en               (app_en)              ,   //MIG IP核使能                                   
    .app_wdf_wren         (app_wdf_wren)        ,   //DDR3写使能                                    
    .app_wdf_end          (app_wdf_end)         ,   //突发写当前时钟最后一个数据 
    .app_cmd              (app_cmd)             ,   //用户读写命令                    
    //DDR3 地址参数                                                                   
    .app_addr_rd_min      (app_addr_rd_min)     ,   //读DDR3的起始地址                                  
    .app_addr_rd_max      (app_addr_rd_max)     ,   //读DDR3的结束地址                                  
    .rd_bust_len          (rd_bust_len)         ,   //从DDR3中读数据时的突发长度 
    .app_addr_wr_min      (app_addr_wr_min)     ,   //写DDR3的起始地址
    .app_addr_wr_max      (app_addr_wr_max)     ,   //写DDR3的结束地址
    .wr_bust_len          (wr_bust_len)         ,   //从DDR3中写数据时的突发长度
    //用户接口                     
    .rfifo_wren_1         (rfifo_wren_1)        ,   //rfifo写使能 
    .rfifo_wdata_1        (rfifo_wdata_1)       ,   //rfifo写数据 
    .rfifo_wren_2         (rfifo_wren_2)        ,   //rfifo写使能  
    .rfifo_wdata_2        (rfifo_wdata_2)       ,   //rfifo写数据
    .wfifo_rden_1         (wfifo_rden_1)        ,   //写端口FIFO1中的读使能
    .wfifo_rden_2         (wfifo_rden_2)        ,   //写端口FIFO2中的读使能  
    .rd_load              (rd_load)             ,   //输出源场信号
    .wr_load_1            (wr_load_1)           ,   //输入源场信号
    .wr_load_2            (wr_load_2)           ,   //输入源场信号    
    .ddr3_read_valid      (ddr3_read_valid)     ,   //DDR3读使能
    .ddr3_pingpang_en     (ddr3_pingpang_en)    ,   //DDR3乒乓操作使能 
    .wfifo_rcount_1       (wfifo_rcount_1)      ,   //wfifo剩余数据计数                  
    .rfifo_wcount_1       (rfifo_wcount_1)      ,   //rfifo写进数据计数
    .wfifo_rcount_2       (wfifo_rcount_2)      ,   //wfifo剩余数据计数                  
    .rfifo_wcount_2       (rfifo_wcount_2)      ,   //rfifo写进数据计数   
    .wr_clk_2             (wr_clk_2)            ,   //wfifo时钟 
    .wr_clk_1             (wr_clk_1)                //wfifo时钟          
    );
    
//MIG IP核模块
mig_7series_0 u_mig_7series_0 (
    // Memory interface ports
    .ddr3_addr           (ddr3_addr)            ,         
    .ddr3_ba             (ddr3_ba)              ,            
    .ddr3_cas_n          (ddr3_cas_n)           ,         
    .ddr3_ck_n           (ddr3_ck_n)            ,        
    .ddr3_ck_p           (ddr3_ck_p)            ,          
    .ddr3_cke            (ddr3_cke)             ,            
    .ddr3_ras_n          (ddr3_ras_n)           ,         
    .ddr3_reset_n        (ddr3_reset_n)         ,      
    .ddr3_we_n           (ddr3_we_n)            ,        
    .ddr3_dq             (ddr3_dq)              ,            
    .ddr3_dqs_n          (ddr3_dqs_n)           ,        
    .ddr3_dqs_p          (ddr3_dqs_p)           ,      
    .ddr3_cs_n           (ddr3_cs_n)            , 
    .ddr3_dm             (ddr3_dm)              ,    
    .ddr3_odt            (ddr3_odt)             ,          
    // Application interface ports 
    .app_addr            (app_addr)             ,         
    .app_cmd             (app_cmd)              ,          
    .app_en              (app_en)               ,        
    .app_wdf_data        (app_wdf_data)         ,      
    .app_wdf_end         (app_wdf_end)          ,       
    .app_wdf_wren        (app_wdf_wren)         ,           
    .app_rd_data         (app_rd_data)          ,       
    .app_rd_data_end     (app_rd_data_end)      ,       
    .app_rd_data_valid   (app_rd_data_valid)    ,     
    .init_calib_complete (init_calib_complete)  ,            
                                                     
    .app_rdy             (app_rdy)              ,      
    .app_wdf_rdy         (app_wdf_rdy)          ,          
    .app_sr_req          (0)                    ,                    
    .app_ref_req         (0)                    ,              
    .app_zq_req          (0)                    ,             
    .app_sr_active       (app_sr_active)        ,        
    .app_ref_ack         (app_ref_ack)          ,         
    .app_zq_ack          (app_zq_ack)           ,             
    .ui_clk              (ui_clk)               ,                
    .ui_clk_sync_rst     (ui_clk_sync_rst)      ,    
    .app_wdf_mask        (32'b0)                ,    
    // System Clock Ports                            
    .sys_clk_i           (sys_clk_i)            ,    
    // Reference Clock Ports                         
    .clk_ref_i           (clk_ref_i)            ,    
    .sys_rst             (rst_n)                 
    );                                               

//FIFO调度顶层模块
ddr3_fifo_ctrl_top u_ddr3_fifo_ctrl_top(
    .rst_n             (rst_n &&init_calib_complete),  //复位信号    
    .rd_clk            (rd_clk)                     ,  //rfifo时钟
    .ui_clk            (ui_clk)                     ,  //用户时钟
    //fifo1接口信号                                 
    .wr_clk_1          (wr_clk_1)                   ,  //wfifo时钟    
    .wr_en_1           (wr_en_1)                    ,  //数据有效使能信号
    .wrdata_1          (wrdata_1)                   ,  //有效数据
    .wr_load_1         (wr_load_1)                  ,  //输入源场信号    
    .rfifo_din_1       (rfifo_wdata_1)              ,  //rfifo写数据
    .rfifo_wren_1      (rfifo_wren_1)               ,  //rfifo写使能
    .wfifo_rden_1      (wfifo_rden_1)               ,  //wfifo读使能
    .wfifo_rcount_1    (wfifo_rcount_1)             ,  //wfifo剩余数据计数
    .rfifo_wcount_1    (rfifo_wcount_1)             ,  //rfifo写进数据计数    
    //fifo2接口信号                                 
    .wr_clk_2          (wr_clk_2)                   ,  //wfifo时钟    
    .wr_en_2           (wr_en_2)                    ,  //数据有效使能信号
    .wrdata_2          (wrdata_2)                   ,  //有效数据    
    .wr_load_2         (wr_load_2)                  ,  //输入源场信号
    .rfifo_din_2       (rfifo_wdata_2)              ,  //rfifo写数据
    .rfifo_wren_2      (rfifo_wren_2)               ,  //rfifo写使能
    .wfifo_rden_2      (wfifo_rden_2)               ,  //wfifo读使能    
    .wfifo_rcount_2    (wfifo_rcount_2)             ,  //wfifo剩余数据计数
    .rfifo_wcount_2    (rfifo_wcount_2)             ,  //rfifo写进数据计数
                                                    
    .h_disp            (h_disp)                     ,  //摄像头水平分辨率
    .rd_load           (rd_load)                    ,  //输出源场信号
    .rdata_req         (rdata_req)                  ,  //请求像素点颜色数据输入     
    .rddata            (rddata)                     ,  //有效数据 
    .wfifo_dout        (app_wdf_data)                  //用户写数据    
    );
      
endmodule