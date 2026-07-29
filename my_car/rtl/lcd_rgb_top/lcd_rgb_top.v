//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2023-2033
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           lcd_rgb_top
// Created by:          正点原子
// Created date:        2025年10月25日10:10:00
// Version:             V1.3
// Descriptions:        LCD顶层模块（PLD2026 赛道三：OSD V3 + 仪表盘 dash_osd）
//
//  [PLD2026 V3] 改动说明：
//   1) osd_overlay 升级 V3：姿态/速度行、TTC预警、调试/夜间模式标签
//   2) osd_overlay 之后串联 dash_osd（右下角俯视图轨迹+姿态仪表），
//      视频链总延迟 2 拍（无感知）
//   3) 端口表新增：姿态/速度/位置/航向/轨迹点/TTC预警/显示模式/调试计数
//   其余原子原有逻辑一字未动
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module lcd_rgb_top(
    input           sys_clk      ,  //系统时钟（50M，dash_osd 轨迹写时钟域）
    input           sys_rst_n,      //复位信号
    input           sys_init_done,
    //lcd接口
    output          lcd_clk,        //LCD驱动时钟
    output          lcd_hs,         //LCD行同步信号
    output          lcd_vs,         //LCD场同步信号
    output          lcd_de,         //LCD数据输入使能
    inout  [23:0]   lcd_rgb,        //LCDRGB颜色数据
    output          lcd_bl,         //LCD背光控制信号
    output          lcd_rst,        //LCD复位信号
    output          lcd_pclk,       //LCD采样时钟
    output  [15:0]  lcd_id,         //LCD屏ID
    output          out_vsync,      //LCD场信号
    output  [10:0]  pixel_xpos,     //像素点横坐标
    output  [10:0]  pixel_ypos,     //像素点纵坐标
    output  [10:0]  h_disp,         //LCD屏水平分辨率
    output  [10:0]  v_disp,         //LCD屏垂直分辨率
    input   [15:0]  data_in,        //数据输入
    output          data_req,       //请求像素点颜色数据输入
    // ---- [PLD2026] 识别框（右屏 = 摄像头1，相机坐标系 0~399） ----
    input           box_found,      //本帧发现绿灯
    input   [ 9:0]  box_min_x,      //包围盒四角
    input   [ 9:0]  box_max_x,
    input   [ 9:0]  box_min_y,
    input   [ 9:0]  box_max_y,
    // ---- [PLD2026 V2] cam1 质心（右屏，相机坐标，cam_pclk_1 域） ----
    input   [ 9:0]  c1_u,
    input   [ 9:0]  c1_v,
    // ---- [PLD2026 V2] cam2 检测（左屏，相机坐标，cam_pclk_2 域） ----
    input           box2_found,
    input   [ 9:0]  box2_min_x,
    input   [ 9:0]  box2_max_x,
    input   [ 9:0]  box2_min_y,
    input   [ 9:0]  box2_max_y,
    input   [ 9:0]  c2_u,
    input   [ 9:0]  c2_v,
    // ---- [PLD2026 V2] 目标距离（50M 域） ----
    input   [15:0]  dist_mm,
    input   [ 1:0]  dist_src,       // 0=无效 1=单目 2=双目
    // ---- [PLD2026 V2] 传感器原始值（50M 域，OSD 数据栏） ----
    input   [31:0]  enc0,
    input   [31:0]  enc1,
    input   [31:0]  enc2,
    input   [31:0]  enc3,
    input   [15:0]  gyro_x,
    input   [15:0]  gyro_y,
    input   [15:0]  gyro_z,
    // ---- [PLD2026 V3] 姿态/速度（50M 域） ----
    input   signed [15:0]  pitch_cdeg,   // 0.01°（attitude_cf）
    input   signed [15:0]  roll_cdeg,
    input   signed [15:0]  fwd_speed,    // mm/s（sensor_calc）
    // ---- [PLD2026 V3] 位置/航向/轨迹点（50M 域，dash_osd 用） ----
    input   signed [31:0]  pos_x,        // mm
    input   signed [31:0]  pos_y,
    input   [ 8:0]  theta_idx,           // 航向 0~359°
    input           trk_wr,              // 轨迹点写脉冲（5Hz）
    input   signed [15:0]  trk_x,        // mm
    input   signed [15:0]  trk_y,
    // ---- [PLD2026 V3] TTC 预警（50M 域） ----
    input   [ 1:0]  warn_level,          // 0=正常 1=黄警 2=红警
    input   [ 7:0]  ttc_ds,              // TTC 0.1s
    // ---- [PLD2026 V3] 显示模式与调试计数 ----
    input   [ 1:0]  disp_mode,           // 0=正常 1=调试 2=夜间
    input   [17:0]  gd_cnt1,             // cam1 绿色像素计数（调试显示）
    input   [17:0]  gd_cnt2
    );

//wire define
wire [15:0]  lcd_rgb_565;           //输出的16位lcd数据
wire [23:0]  lcd_rgb_o ;            //LCD 输出颜色数据
wire [23:0]  lcd_rgb_i ;            //LCD 输入颜色数据
wire [15:0]  disply_data;           //lcd_disply 输出（标题+右屏红框叠加后）
wire [15:0]  osd_data;              //osd_overlay 输出（V3 AR 叠加后）

//*****************************************************
//**                    main code
//*****************************************************

//将摄像头16bit数据转换为24bit的lcd数据
assign lcd_rgb_o = {lcd_rgb_565[15:11],3'b000,lcd_rgb_565[10:5],2'b00,
                    lcd_rgb_565[4:0],3'b000};

//像素数据方向切换
assign lcd_rgb = lcd_de ? lcd_rgb_o : {24{1'bz}};
assign lcd_rgb_i = lcd_rgb;

//*****************************************************
//**                    main code
//*****************************************************

//时钟分频模块
clk_div u_clk_div(
    .clk                    (sys_clk  ),
    .rst_n                  (sys_rst_n),
    .lcd_id                 (lcd_id   ),
    .lcd_pclk               (lcd_clk  )
    );

//读LCD ID模块
rd_id u_rd_id(
    .clk                    (sys_clk  ),
    .rst_n                  (sys_rst_n),
    .lcd_rgb                (lcd_rgb_i),
    .lcd_id                 (lcd_id   )
    );

//lcd驱动模块
lcd_driver u_lcd_driver(
    .lcd_clk        (lcd_clk),
    .rst_n          (sys_rst_n & sys_init_done),
    .lcd_id         (lcd_id),

    .lcd_hs         (lcd_hs),
    .lcd_vs         (lcd_vs),
    .lcd_de         (lcd_de),
    .lcd_rgb        (),
    .lcd_bl         (lcd_bl),
    .lcd_rst        (lcd_rst),
    .lcd_pclk       (lcd_pclk),

    .pixel_data     (data_in),
    .data_req       (data_req),
    .out_vsync      (out_vsync),
    .h_disp         (h_disp),
    .v_disp         (v_disp),
    .pixel_xpos     (pixel_xpos),
    .pixel_ypos     (pixel_ypos)
    );

 lcd_disply u_lcd_disply(

    .lcd_clk          (lcd_clk),                   //lcd模块驱动时钟
    .sys_rst_n        (sys_rst_n & sys_init_done), //复位信号
    //RGB LCD接口
    .pixel_xpos       (pixel_xpos),                //像素点横坐标
    .pixel_ypos       (pixel_ypos),                //像素点纵坐标
    .rd_data          (data_in),                   //图像数据
    .rd_h_pixel       (h_disp),                    //图像水平像素大小
    .pixel_data       (disply_data),               //像素点数据
    // ---- [PLD2026] 识别框透传 ----
    .box_found        (box_found),
    .box_min_x        (box_min_x),
    .box_max_x        (box_max_x),
    .box_min_y        (box_min_y),
    .box_max_y        (box_max_y)
);

//*****************************************************
//**  [PLD2026 V3] AR 叠加层（osd_overlay V3）：cam2框(预警变色)/双质心十字/
//**  位置标注/模式+距离/编码器陀螺仪/姿态/速度/TTC预警行/目标丢失/模式标签
//*****************************************************
osd_overlay u_osd_overlay(
    .lcd_clk          (lcd_clk),
    .rst_n            (sys_rst_n & sys_init_done),
    .pixel_xpos       (pixel_xpos),
    .pixel_ypos       (pixel_ypos),
    .pixel_in         (disply_data),
    .h_pixel          ({2'b00, h_disp}),
    .v_pixel          ({2'b00, v_disp}),
    .f1_async         (box_found),
    .c1u_async        (c1_u),
    .c1v_async        (c1_v),
    .f2_async         (box2_found),
    .c2u_async        (c2_u),
    .c2v_async        (c2_v),
    .b2_minx_async    (box2_min_x),
    .b2_maxx_async    (box2_max_x),
    .b2_miny_async    (box2_min_y),
    .b2_maxy_async    (box2_max_y),
    .dist_mm_async    (dist_mm),
    .dist_src_async   (dist_src),
    .enc0             (enc0),
    .enc1             (enc1),
    .enc2             (enc2),
    .enc3             (enc3),
    .gyro_x           (gyro_x),
    .gyro_y           (gyro_y),
    .gyro_z           (gyro_z),
    // ---- [V3] ----
    .pitch_cdeg       (pitch_cdeg),
    .roll_cdeg        (roll_cdeg),
    .fwd_speed        (fwd_speed),
    .warn_level       (warn_level),
    .ttc_ds           (ttc_ds),
    .disp_mode        (disp_mode),
    .gd_cnt1          (gd_cnt1),
    .gd_cnt2          (gd_cnt2),
    .pixel_out        (osd_data)
);

//*****************************************************
//**  [PLD2026 V3] 车辆状态仪表盘（dash_osd）：右下角俯视图轨迹
//**  （64点 FIFO + 小车图标 + 8方向航向线）+ pitch/roll 姿态条
//*****************************************************
dash_osd u_dash_osd(
    .lcd_clk          (lcd_clk),
    .rst_n            (sys_rst_n & sys_init_done),
    .sys_clk          (sys_clk),
    .pixel_xpos       (pixel_xpos),
    .pixel_ypos       (pixel_ypos),
    .pixel_in         (osd_data),
    .h_pixel          ({2'b00, h_disp}),
    .v_pixel          ({2'b00, v_disp}),
    .pos_x            (pos_x),
    .pos_y            (pos_y),
    .theta_idx        (theta_idx),
    .pitch_cdeg       (pitch_cdeg),
    .roll_cdeg        (roll_cdeg),
    .trk_wr           (trk_wr),
    .trk_x            (trk_x),
    .trk_y            (trk_y),
    .disp_mode        (disp_mode),   // [V3.2] 轨迹档窗外压暗+窗框高亮
    .pixel_out        (lcd_rgb_565)
);

endmodule
