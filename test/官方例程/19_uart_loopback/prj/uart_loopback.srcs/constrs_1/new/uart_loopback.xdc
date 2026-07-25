#时序约束
create_clock -period 20.000 -name sys_clk [get_ports sys_clk]

#IO引脚约束
#----------------------系统时钟---------------------------
set_property -dict {PACKAGE_PIN R4 IOSTANDARD LVCMOS15} [get_ports sys_clk]

#----------------------系统复位---------------------------
set_property -dict {PACKAGE_PIN U7 IOSTANDARD LVCMOS15} [get_ports sys_rst_n]

#----------------------USB UART---------------------------
set_property -dict {PACKAGE_PIN E14 IOSTANDARD LVCMOS33} [get_ports uart_rxd]
set_property -dict {PACKAGE_PIN D17 IOSTANDARD LVCMOS33} [get_ports uart_txd]



