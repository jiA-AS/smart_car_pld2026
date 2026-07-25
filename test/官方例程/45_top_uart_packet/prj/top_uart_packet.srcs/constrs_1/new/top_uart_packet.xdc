#时序约束
create_clock -period 20.000 -name sys_clk [get_ports sys_clk]

#IO管脚约束
set_property -dict {PACKAGE_PIN R4 IOSTANDARD LVCMOS15} [get_ports sys_clk]
set_property -dict {PACKAGE_PIN U7 IOSTANDARD LVCMOS15} [get_ports sys_rst_n]

set_property -dict {PACKAGE_PIN V9 IOSTANDARD LVCMOS15} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN Y8 IOSTANDARD LVCMOS15} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN V7 IOSTANDARD LVCMOS15} [get_ports beep]
set_property -dict {PACKAGE_PIN Y7 IOSTANDARD LVCMOS15} [get_ports breath_led]
set_property -dict {PACKAGE_PIN T4 IOSTANDARD LVCMOS15} [get_ports {key[0]}]
set_property -dict {PACKAGE_PIN T3 IOSTANDARD LVCMOS15} [get_ports {key[1]}]

#----------------------USB UART---------------------------
set_property -dict {PACKAGE_PIN E14 IOSTANDARD LVCMOS33} [get_ports uart_rxd]
set_property -dict {PACKAGE_PIN D17 IOSTANDARD LVCMOS33} [get_ports uart_txd]


