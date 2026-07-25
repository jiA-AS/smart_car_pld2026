//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2023-2033
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           top_dual_ov5640_lcd
// Created by:          正点原子
// Created date:        2025年10月25日10:25:00
// Version:             V1.0
// Descriptions:        双目ov5640摄像头lcd显示
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//
module top_dual_ov5640_lcd(    
    input                 sys_clk        ,  //系统时钟
    input                 sys_rst_n      ,  //系统复位，低电平有效
    //摄像头1接口                       
    input                 cam_pclk_1     ,  //cmos数据像素时钟
    input                 cam_vsync_1    ,  //cmos场同步信号
    input                 cam_href_1     ,  //cmos行同步信号
    input   [7:0]         cam_data_1     ,  //cmos数据
    output                cam_rst_n_1    ,  //cmos复位信号，低电平有效
    output                cam_pwdn_1     ,  //电源休眠模式选择 0：正常模式 1：电源休眠模式
    output                cam_scl_1      ,  //cmos SCCB_SCL线
    inout                 cam_sda_1      ,  //cmos SCCB_SDA线
    //摄像头2接口     
    input                 cam_pclk_2     ,  //cmos数据像素时钟
    input                 cam_vsync_2    ,  //cmos场同步信号
    input                 cam_href_2     ,  //cmos行同步信号
    input   [7:0]         cam_data_2     ,  //cmos数据
    output                cam_rst_n_2    ,  //cmos复位信号，低电平有效
    output                cam_pwdn_2     ,  //电源休眠模式选择 0：正常模式 1：电源休眠模式
    output                cam_scl_2      ,  //cmos SCCB_SCL线
    inout                 cam_sda_2      ,  //cmos SCCB_SDA线   
       
    // DDR3                            
    inout   [31:0]        ddr3_dq        ,  //DDR3数据
    inout   [3:0]         ddr3_dqs_n     ,  //DDR3 dqs负
    inout   [3:0]         ddr3_dqs_p     ,  //DDR3 dqs正  
    output  [13:0]        ddr3_addr      ,  //DDR3地址   
    output  [2:0]         ddr3_ba        ,  //DDR3 Bank选择
    output                ddr3_ras_n     ,  //DDR3行选择
    output                ddr3_cas_n     ,  //DDR3列选择
    output                ddr3_we_n      ,  //DDR3读写选择
    output                ddr3_reset_n   ,  //DDR3复位
    output  [0:0]         ddr3_ck_p      ,  //DDR3时钟正
    output  [0:0]         ddr3_ck_n      ,  //DDR3时钟负
    output  [0:0]         ddr3_cke       ,  //DDR3时钟使能
    output  [0:0]         ddr3_cs_n      ,  //DDR3片选
    output  [3:0]         ddr3_dm        ,  //ddr3_dm
    output  [0:0]         ddr3_odt       ,  //ddr3_odt                                     
    //LCD接口                             
    output                lcd_hs         ,  //LCD行同步信号
    output                lcd_vs         ,  //LCD场同步信号
    output                lcd_de         ,  //LCD数据输入使能
    inout       [23:0]    lcd_rgb        ,  //LCD颜色数据
    output                lcd_bl         ,  //LCD背光控制信号
    output                lcd_rst        ,  //LCD复位信号
    output                lcd_pclk       ,   //LCD采样时钟
    //UART接口（传感器链，接ATK-MODULE 插座 J1）
    
    input                 uart_rxd       ,   //ESP32->FPGA   J1:UART2_RXD=E13
    output                uart_txd           //FPGA->ESP32/PC
    );                                 
                                                               
//wire define
                          
wire         clk_50m                   ;  //50MHz时钟,提供给LCD驱动时钟
wire         locked                    ;  //时钟锁定信号
wire         rst_n                     ;  //全局复位                                    
wire         i2c_exec                  ;  //I2C触发执行信号
wire  [23:0] i2c_data                  ;  //I2C要配置的地址与数据(高8位地址,低8位数据)          
wire         cam_init_done             ;  //摄像头初始化完成
wire         i2c_done                  ;  //I2C寄存器配置完成信号
wire         i2c_dri_clk               ;  //I2C操作时钟                                 
wire         wr_en                     ;  //DDR3控制器模块写使能
wire         rdata_req                 ;  //DDR3控制器模块读使能
wire  [15:0] rddata                    ;  //DDR3控制器模块读数据
wire         cmos_frame_valid_1        ;  //数据1有效使能信号
wire  [15:0] wr_data_1                 ;  //DDR3控制器模块写数据1
wire         cmos_frame_valid_2        ;  //数据2有效使能信号
wire  [15:0] wr_data_2                 ;  //DDR3控制器模块写数据2
wire         init_calib_complete       ;  //DDR3初始化完成init_calib_complete
wire         sys_init_done             ;  //系统初始化完成(DDR初始化+摄像头初始化)
wire         clk_200m                  ;  //DDR3参考时钟
wire         cmos_frame_vsync_1        ;  //输出帧1有效场同步信号
wire         cmos_frame_vsync_2        ;  //输出帧2有效场同步信号
wire         lcd_de                    ;  //LCD数据输入使能
wire         cmos_frame_href           ;  //输出帧有效行同步信号 
wire  [27:0] app_addr_rd_min           ;  //读DDR3的起始地址
wire  [27:0] app_addr_rd_max           ;  //读DDR3的结束地址
wire  [7:0]  rd_bust_len               ;  //从DDR3中读数据时的突发长度
wire  [27:0] app_addr_wr_min           ;  //写DDR3的起始地址
wire  [27:0] app_addr_wr_max           ;  //写DDR3的结束地址
wire  [7:0]  wr_bust_len               ;  //从DDR3中写数据时的突发长度
wire  [9:0]  pixel_xpos_w              ;  //像素点横坐标
wire  [9:0]  pixel_ypos_w              ;  //像素点纵坐标   
wire         lcd_clk                   ;  //分频产生的LCD采样时钟
wire  [12:0] h_disp                    ;  //LCD屏水平分辨率
wire  [12:0] v_disp                    ;  //LCD屏垂直分辨率     
wire  [10:0] h_pixel                   ;  //存入DDR3的水平分辨率        
wire  [10:0] v_pixel                   ;  //存入DDR3的屏垂直分辨率 
wire  [12:0] y_addr_st                 ;  //开窗垂直方向起始地址
wire  [12:0] y_addr_end                ;  //开窗垂直方向截至地址
wire  [15:0] lcd_id                    ;  //LCD屏的ID号
wire  [27:0] ddr3_addr_max             ;  //存入DDR3的最大读写地址 
wire         i2c_rh_wl                 ;  //I2C读写控制信号             
wire  [7:0]  i2c_data_r                ;  //I2C读数据 
wire  [12:0] total_h_pixel             ;  //水平总像素大小 
wire  [12:0] total_v_pixel             ;  //垂直总像素大小

//*****************************************************
//**                    main code
//*****************************************************

//待时钟锁定后产生复位结束信号
assign  rst_n = sys_rst_n & locked;

//系统初始化完成：DDR3初始化完成
assign  sys_init_done = init_calib_complete;

//摄像头图像分辨率设置模块
picture_size u_picture_size (
    .rst_n              (rst_n),
    .clk                (clk_50m  ),    
    .lcd_id             (lcd_id),           //LCD的器件ID
                        
    .cmos_h_pixel       (h_disp  ),         //摄像头水平分辨率
    .cmos_v_pixel       (v_disp  ),         //摄像头垂直分辨率  
    .total_h_pixel      (total_h_pixel ),   //水平总像素大小
    .total_v_pixel      (total_v_pixel ),   //垂直总像素大小
    .y_addr_st          (y_addr_st ), 
    .y_addr_end         (y_addr_end),
    .ddr3_max_addr      (ddr3_addr_max)     //DDR3最大读写地址
    );
   
//OV5640 驱动
ov5640_dri u_ov5640_dri_1(
    .clk               (clk_50m),
    .rst_n             (rst_n),

    .cam_pclk          (cam_pclk_1),
    .cam_vsync         (cam_vsync_1),
    .cam_href          (cam_href_1 ),
    .cam_data          (cam_data_1 ),
    .cam_rst_n         (cam_rst_n_1),
    .cam_pwdn          (cam_pwdn_1),
    .cam_scl           (cam_scl_1  ),
    .cam_sda           (cam_sda_1  ),
    
    .capture_start     (init_calib_complete),
    .cmos_h_pixel      (h_disp[12:1]),
    .cmos_v_pixel      (v_disp),
    .total_h_pixel     (total_h_pixel),
    .total_v_pixel     (total_v_pixel),
    .y_addr_st         (y_addr_st ), 
    .y_addr_end        (y_addr_end),
    .cmos_frame_vsync  (cmos_frame_vsync_1),
    .cmos_frame_href   (),
    .cmos_frame_valid  (cmos_frame_valid_1),
    .cmos_frame_data   (wr_data_1)
    );   

//OV5640 驱动
ov5640_dri u_ov5640_dri_2(
    .clk               (clk_50m),
    .rst_n             (rst_n),

    .cam_pclk          (cam_pclk_2 ),
    .cam_vsync         (cam_vsync_2),
    .cam_href          (cam_href_2 ),
    .cam_data          (cam_data_2),
    .cam_rst_n         (cam_rst_n_2),
    .cam_pwdn          (cam_pwdn_2 ),
    .cam_scl           (cam_scl_2  ),
    .cam_sda           (cam_sda_2 ),
    
    .capture_start     (init_calib_complete),
    .cmos_h_pixel      (h_disp[12:1]),
    .cmos_v_pixel      (v_disp),
    .total_h_pixel     (total_h_pixel),
    .total_v_pixel     (total_v_pixel),
    .y_addr_st         (y_addr_st ), 
    .y_addr_end        (y_addr_end),
    .cmos_frame_vsync  (cmos_frame_vsync_2),
    .cmos_frame_href   (),
    .cmos_frame_valid  (cmos_frame_valid_2),
    .cmos_frame_data   (wr_data_2)
    );    

//DDR3顶层模块
ddr3_top u_ddr3_top (
    .rst_n                 (rst_n),                 //复位,低有效
    .init_calib_complete   (init_calib_complete),   //DDR3初始化完成信号    
    //DDR3接口信号         
    .app_addr_rd_min       (28'd0),                 //读DDR3的起始地址
    .app_addr_rd_max       (ddr3_addr_max[27:2]),   //读DDR3的结束地址
    .rd_bust_len           (h_disp[10:4]),          //从DDR3中读数据时的突发长度
    .app_addr_wr_min       (28'd0),                 //写DDR3的起始地址
    .app_addr_wr_max       (ddr3_addr_max[27:2]),   //写DDR3的结束地址
    .wr_bust_len           (h_disp[10:4]),          //从DDR3中写数据时的突发长度
    //DDR3 IO接口                
    .ddr3_dq               (ddr3_dq),               //DDR3数据
    .ddr3_dqs_n            (ddr3_dqs_n),            //DDR3 dqs负
    .ddr3_dqs_p            (ddr3_dqs_p),            //DDR3 dqs正  
    .ddr3_addr             (ddr3_addr),             //DDR3地址   
    .ddr3_ba               (ddr3_ba),               //DDR3 Bank选择
    .ddr3_ras_n            (ddr3_ras_n),            //DDR3行选择
    .ddr3_cas_n            (ddr3_cas_n),            //DDR3列选择
    .ddr3_we_n             (ddr3_we_n),             //DDR3读写选择
    .ddr3_reset_n          (ddr3_reset_n),          //DDR3复位
    .ddr3_ck_p             (ddr3_ck_p),             //DDR3时钟正
    .ddr3_ck_n             (ddr3_ck_n),             //DDR3时钟负  
    .ddr3_cke              (ddr3_cke),              //DDR3时钟使能
    .ddr3_cs_n             (ddr3_cs_n),             //DDR3片选
    .ddr3_dm               (ddr3_dm),               //ddr3_dm
    .ddr3_odt              (ddr3_odt),              //ddr3_odt
    //System Clock Ports                            
    .sys_clk_i             (clk_200m),   
    //Reference Clock Ports                         
    .clk_ref_i             (clk_200m), 
    //用户接口
    .ddr3_read_valid       (1'b1),                  //DDR3读使能
    .ddr3_pingpang_en      (1'b1),                  //DDR3乒乓操作使能
    .wr_clk_1              (cam_pclk_1),            //摄像头1时钟
    .wr_load_1             (cmos_frame_vsync_1),    //摄像头1场信号    
    .wr_en_1               (cmos_frame_valid_1),    //数据1有效使能信号
    .wrdata_1              (wr_data_1),             //有效数据1 
    .wr_clk_2              (cam_pclk_2),            //摄像头2时钟
    .wr_load_2             (cmos_frame_vsync_2),    //摄像头2场信号    
    .wr_en_2               (cmos_frame_valid_2),    //数据有效使能信号
    .wrdata_2              (wr_data_2),             //有效数据    

    .h_disp                (h_disp),    
    .rd_clk                (lcd_clk),               //rfifo的读时钟 
    .rd_load               (rd_vsync),              //LCD场信号    
    .rddata                (rddata),                //rfifo输出数据
    .rdata_req             (rdata_req)              //请求数据输入   
     );                

 clk_wiz_0 u_clk_wiz_0
   (
    // Clock out ports
    .clk_out1              (clk_200m),     
    .clk_out2              (clk_50m),
    // Status and control signals
    .reset                 (1'b0), 
    .locked                (locked),       
   // Clock in ports
    .clk_in1               (sys_clk)
    );     

//LCD驱动显示模块
lcd_rgb_top  u_lcd_rgb_top(
    .sys_clk               (clk_50m  ),
    .sys_rst_n             (rst_n ),
    .sys_init_done         (sys_init_done),     
                           
    //lcd接口                            
    .lcd_id                (lcd_id),                //LCD屏的ID号 
    .lcd_hs                (lcd_hs),                //LCD行同步信号
    .lcd_vs                (lcd_vs),                //LCD场同步信号
    .lcd_de                (lcd_de),                //LCD数据输入使能
    .lcd_rgb               (lcd_rgb),               //LCD颜色数据
    .lcd_bl                (lcd_bl),                //LCD背光控制信号
    .lcd_rst               (lcd_rst),               //LCD复位信号
    .lcd_pclk              (lcd_pclk),              //LCD采样时钟
    .lcd_clk               (lcd_clk),               //LCD驱动时钟
    //用户接口                     
    .out_vsync             (rd_vsync),              //LCD场信号
    .h_disp                (),                      //行分辨率  
    .v_disp                (),                      //场分辨率   
    .pixel_xpos            (),
    .pixel_ypos            (),  
    .data_in               (rddata),                //rfifo输出数据
    .data_req              (rdata_req)              //请求数据输入
    );   
    
//*****************************************************
//**  PLD2026：传感器链（UART 收发 + V1.0 解包 + V1.1 下行）
//**  解码输出阶段2/3 接 OSD 数据栏与 pose_core，当前悬空（综合器自动修剪，仅警告）
//*****************************************************
sensor_link#(
     .CLK_FREQ (50_000_000),
     .BAUD     (115200)
)u_sensor_link (
    .clk          (clk_50m),
    .rst_n        (rst_n),
    .uart_rxd     (uart_rxd),
    .uart_txd     (uart_txd),
    .timestamp    (),
    .enc0         (),
    .enc1         (),
    .enc2         (),
    .enc3         (),
    .gyro_x       (),
    .gyro_y       (),
    .gyro_z       (),
    .acc_x        (),
    .acc_y        (),
    .acc_z        (),
    .parse_done   (),
    .parse_result ()
);
endmodule