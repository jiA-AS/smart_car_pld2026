//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//----------------------------------------------------------------------------------------
// File name:           packet_code
// Descriptions:        根据包解析的内容返回对应信息（原厂代码，原样恢复）
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module packet_code(
    input                clk           ,   //外部50MHz时钟
    input                rst_n         ,   //系外部复位信号，低有效
    input         [1:0]  key           ,   //按键输入
    input                uart_tx_busy  ,   //发送忙状态信号
    input                parse_done    ,   //包解析完成信号
    input         [7:0]  parse_result  ,   //解包后的结果,8'h00:解析正确 8'hEx:解析错误
    input         [7:0]  parse_cmd     ,
    output    reg        packet_tx_done,   //数据全部发送完成标志
    output    reg        uart_tx_en    ,   //串口发送使能
    output    reg [7:0]  uart_tx_data      //串口发送数据
    );

parameter PACKET_HEAD    = 8'h55;    //定义数据包头
parameter KEY_CMD        = 8'h03;    //查询按键状态的命令
parameter PARSE_OK       = 8'h00;    //数据包解析正确

reg         tx_busy_d0       ;
reg         tx_busy_d1       ;
reg         tx_en            ;
reg [7:0]   data_cnt         ;
reg [7:0]   packet_len       ;
reg [39:0]  uart_packet_data ;

wire        neg_tx_busy      ;

assign neg_tx_busy = tx_busy_d1 & (~tx_busy_d0) ;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        tx_busy_d0 <= 1'b0;
        tx_busy_d1 <= 1'b0;
    end
    else begin
        tx_busy_d0 <= uart_tx_busy;
        tx_busy_d1 <= tx_busy_d0;
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        packet_len <= 8'b0;
    else if(parse_cmd == KEY_CMD && parse_result == PARSE_OK)
        packet_len <= 8'd5;
    else
        packet_len <= 8'd3;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        data_cnt <= 8'b0;
    else if(neg_tx_busy) begin
        if (data_cnt == (packet_len - 8'd1))
            data_cnt <= 8'b0;
        else
            data_cnt <= data_cnt + 8'b1;
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        packet_tx_done <= 1'b0;
    else if(data_cnt == (packet_len - 8'd1) && neg_tx_busy )
        packet_tx_done <= 1'b1;
    else
        packet_tx_done <= 1'b0;
end

always@(posedge clk or negedge rst_n )begin
    if(!rst_n)
      tx_en <= 1'b0 ;
   else if(neg_tx_busy && (data_cnt < (packet_len - 8'd1)))
        tx_en <= 1'b1;
    else
        tx_en <= 1'b0;
end

always@(posedge clk or negedge rst_n )begin
    if(!rst_n)
        uart_tx_en <= 1'b0 ;
   else if(parse_done || tx_en)
        uart_tx_en <= 1'b1;
    else
        uart_tx_en <= 1'b0;
end

always @(posedge clk or negedge rst_n ) begin
    if(!rst_n)
        uart_packet_data <= {32'd0,PACKET_HEAD};
    else if(parse_done)begin
        if(packet_len == 8'd3) begin
            if(parse_result == PARSE_OK) begin
                uart_packet_data[15:8] <= parse_cmd;
                uart_packet_data[23:16] <= PACKET_HEAD + parse_cmd;
            end
            else begin
                uart_packet_data[15:8] <= parse_result;
                uart_packet_data[23:16] <= PACKET_HEAD + parse_result;
            end
        end
        else begin
            uart_packet_data[15:8] <= parse_cmd;
            uart_packet_data[23:16] <= 8'h01;
            uart_packet_data[31:24] <= {3'b0,key[1],3'b0,key[0]};
            uart_packet_data[39:32] <= PACKET_HEAD + parse_cmd + 8'h01 + {3'b0,key[1],3'b0,key[0]};
        end
    end
end

always @(posedge clk or negedge rst_n ) begin
    if(!rst_n)
        uart_tx_data <= 8'b0;
    else begin
        case(data_cnt)
            8'd0 : uart_tx_data <= uart_packet_data[7:0];
            8'd1 : uart_tx_data <= uart_packet_data[15:8];
            8'd2 : uart_tx_data <= uart_packet_data[23:16];
            8'd3 : uart_tx_data <= uart_packet_data[31:24];
            8'd4 : uart_tx_data <= uart_packet_data[39:32];
            default : uart_tx_data <= 8'b0;
        endcase
    end
end

endmodule