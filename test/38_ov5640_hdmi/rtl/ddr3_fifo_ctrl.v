//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2023-2033
//All rights reserved 
//----------------------------------------------------------------------------------------
// File name:           ddr3_fifo_ctrl
// Created by:          正点原子
// Created date:        2025年11月010日14:20:02
// Version:             V1.0
// Descriptions:        ddr3控制器fifo控制模块
//                      
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module ddr3_fifo_ctrl(
    input               rst_n            ,  //复位信号
    input               wr_clk           ,  //wfifo时钟
    input               rd_clk           ,  //rfifo时钟
    input               ui_clk           ,  //用户时钟
    input               wr_en            ,  //数据有效使能信号
    input      [15:0]   wrdata           ,  //有效数据
    input      [255:0]  rfifo_din        ,  //用户读数据
    input               rdata_req        ,  //请求像素点颜色数据输入 
    input               rfifo_wren       ,  //从DDR3读出数据的有效使能
    input               wfifo_rden       ,  //wfifo读使能
    input               rd_load          ,  //输出源场信号
    input               wr_load          ,  //输入源场信号          

    output     [255:0]  wfifo_dout       ,  //用户写数据
    output     [10:0]   rfifo_wcount     ,  //rfifo剩余数据计数
    output     [10:0]   wfifo_rcount     ,  //wfifo写进数据计数
    output reg [15:0]   rddata              //读有效数据     	
    );
           
//reg define
reg  [255:0] wrdata_t          ;  //由16bit输入源数据移位拼接得到
reg  [3:0]   byte_cnt          ;  //写数据移位计数器
reg  [3:0]   i                 ;  //读数据移位计数器       
reg          wfifo_wren        ;  //wfifo写使能信号
reg          rd_load_d0        ;
reg          rdfifo_rst_h      ;  //rfifo复位信号，高有效
reg          wr_load_d0        ;
reg          wr_load_d1        ;
reg          wfifo_rst_h       ;  //wfifo复位信号，高有效
reg  [15:0]  wr_load_d         ;  //由输入源场信号移位拼接得到
reg  [15:0]  rd_load_d         ;  //由输出源场信号移位拼接得到    
 
//wire define 
wire [255:0] rfifo_dout        ;  //rfifo输出数据    
wire [255:0] wfifo_din         ;  //wfifo写数据
wire [15:0]  dataout[0:15]     ;  //定义输出数据的二维数组
wire         rfifo_rden        ;  //rfifo的读使能

//*****************************************************
//**                    main code
//*****************************************************  

//rfifo输出的数据存到二维数组
assign dataout [0] = rfifo_dout[255:240];
assign dataout [1] = rfifo_dout[239:224];
assign dataout [2] = rfifo_dout[223:208];
assign dataout [3] = rfifo_dout[207:192];
assign dataout [4] = rfifo_dout[191:176];
assign dataout [5] = rfifo_dout[175:160];
assign dataout [6] = rfifo_dout[159:144];
assign dataout [7] = rfifo_dout[143:128];
assign dataout [8] = rfifo_dout[127:112];
assign dataout [9] = rfifo_dout[111:96];
assign dataout[10] = rfifo_dout[95:80];
assign dataout[11] = rfifo_dout[79:64];
assign dataout[12] = rfifo_dout[63:48];
assign dataout[13] = rfifo_dout[47:32];
assign dataout[14] = rfifo_dout[31:16];
assign dataout[15] = rfifo_dout[15:0];

assign wfifo_din = wrdata_t ;

//移位寄存器计满时，从rfifo读出一个数据
assign rfifo_rden = (rdata_req && (i == 4'd15)) ? 1'b1  :  1'b0; 

//16位数据转256位RGB565数据        
always @(posedge wr_clk or negedge rst_n) begin
    if(!rst_n) begin
        wrdata_t <= 256'd0;
        byte_cnt <= 4'd0;
    end
    else if(wr_en) begin
        if(byte_cnt == 4'd15)begin
            byte_cnt <= 4'd0;
            wrdata_t <= {wrdata_t[239:0],wrdata};
        end
        else begin
            byte_cnt <= byte_cnt + 4'd1;
            wrdata_t <= {wrdata_t[239:0],wrdata};
        end
    end
    else begin
        byte_cnt <= byte_cnt;
        wrdata_t <= wrdata_t;
    end    
end 

//wfifo写使能产生
always @(posedge wr_clk or negedge rst_n) begin
    if(!rst_n) 
        wfifo_wren <= 1'd0;
    else if(wfifo_wren == 1'd1)
        wfifo_wren <= 1'd0;
    else if(byte_cnt == 4'd15 && wr_en)  //输入源数据传输8次，写使能拉高一次
        wfifo_wren <= 1'd1;
    else 
        wfifo_wren <= 1'd0;
 end   

//对rfifo出来的256bit数据拆解成16个16bit数据
always @(posedge rd_clk or negedge rst_n) begin
    if(!rst_n) begin
        rddata <= 16'b0;
        i      <= 4'd0;
    end
    else if(rdata_req) begin
        if(i == 15)begin
            rddata <= dataout[i];
            i      <= 4'd0;
        end
        else begin
            rddata <= dataout[i];
            i      <= i + 4'd1;
        end
    end 
    else begin
        rddata <= rddata;
        i      <= 4'd0;
    end
end  

always @(posedge ui_clk or negedge rst_n) begin
    if(!rst_n)
        rd_load_d0 <= 1'b0;
    else
        rd_load_d0 <= rd_load;      
end 

//对输出源场信号进行移位寄存
always @(posedge ui_clk or negedge rst_n) begin
    if(!rst_n)
        rd_load_d <= 1'b0;
    else
        rd_load_d <= {rd_load_d[14:0],rd_load_d0};       
end 

//产生一段复位电平，满足fifo复位时序  
always @(posedge ui_clk or negedge rst_n) begin
    if(!rst_n)
        rdfifo_rst_h <= 1'b0;
    else if(rd_load_d[0] && !rd_load_d[14])
        rdfifo_rst_h <= 1'b1;   
    else
        rdfifo_rst_h <= 1'b0;              
end  

//对输入源场信号进行移位寄存
 always @(posedge wr_clk or negedge rst_n) begin
    if(!rst_n)begin
        wr_load_d0 <= 1'b0;
        wr_load_d  <= 16'b0;        
    end     
    else begin
        wr_load_d0 <= wr_load;
        wr_load_d  <= {wr_load_d[14:0],wr_load_d0};      
    end                 
end  

//产生一段复位电平，满足fifo复位时序 
 always @(posedge wr_clk or negedge rst_n) begin
    if(!rst_n)
        wfifo_rst_h <= 1'b0;          
    else if(wr_load_d[0] && !wr_load_d[15])
        wfifo_rst_h <= 1'b1;       
    else
        wfifo_rst_h <= 1'b0;                      
end   

rd_fifo u_rd_fifo (
  .rst               (~rst_n|rdfifo_rst_h),                    
  .wr_clk            (ui_clk             ),   
  .rd_clk            (rd_clk             ),    
  .din               (rfifo_din          ), 
  .wr_en             (rfifo_wren         ),
  .rd_en             (rfifo_rden         ),
  .dout              (rfifo_dout         ),
  .full              (                   ),          
  .empty             (                   ),          
  .rd_data_count     (                   ),  
  .wr_data_count     (rfifo_wcount       ),  
  .wr_rst_busy       (                   ),      
  .rd_rst_busy       (                   )      
);

wr_fifo u_wr_fifo (
  .rst               (~rst_n|wfifo_rst_h ),
  .wr_clk            (wr_clk             ),            
  .rd_clk            (ui_clk             ),           
  .din               (wfifo_din          ),         
  .wr_en             (wfifo_wren         ),        
  .rd_en             (wfifo_rden         ),        
  .dout              (wfifo_dout         ),       
  .full              (                   ),                  
  .empty             (                   ),                  
  .rd_data_count     (wfifo_rcount       ),  
  .wr_data_count     (                   ),  
  .wr_rst_busy       (                   ),      
  .rd_rst_busy       (                   )    
);

endmodule 

