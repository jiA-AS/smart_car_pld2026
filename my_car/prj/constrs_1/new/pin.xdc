set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets sys_clk]
create_clock -period 20.000 -name sys_clk [get_ports sys_clk]
set_property PACKAGE_PIN R4 [get_ports sys_clk]
set_property IOSTANDARD LVCMOS15 [get_ports sys_clk]
set_property IOSTANDARD LVCMOS15 [get_ports sys_rst_n]
set_property PACKAGE_PIN U7 [get_ports sys_rst_n]

#RGB LCD
set_property -dict {PACKAGE_PIN M16 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[7]}]
set_property -dict {PACKAGE_PIN L16 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[6]}]
set_property -dict {PACKAGE_PIN K16 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[5]}]
set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[4]}]
set_property -dict {PACKAGE_PIN K19 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[3]}]
set_property -dict {PACKAGE_PIN M13 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[2]}]
set_property -dict {PACKAGE_PIN L13 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[1]}]
set_property -dict {PACKAGE_PIN L14 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[0]}]

set_property -dict {PACKAGE_PIN L15 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[15]}]
set_property -dict {PACKAGE_PIN K13 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[14]}]
set_property -dict {PACKAGE_PIN K14 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[13]}]
set_property -dict {PACKAGE_PIN J16 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[12]}]
set_property -dict {PACKAGE_PIN J15 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[11]}]
set_property -dict {PACKAGE_PIN H15 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[10]}]
set_property -dict {PACKAGE_PIN J14 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[9]}]
set_property -dict {PACKAGE_PIN H14 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[8]}]

set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[16]}]
set_property -dict {PACKAGE_PIN G18 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[17]}]
set_property -dict {PACKAGE_PIN G15 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[18]}]
set_property -dict {PACKAGE_PIN G16 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[19]}]
set_property -dict {PACKAGE_PIN H19 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[20]}]
set_property -dict {PACKAGE_PIN J19 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[21]}]
set_property -dict {PACKAGE_PIN G13 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[22]}]
set_property -dict {PACKAGE_PIN H13 IOSTANDARD LVCMOS33} [get_ports {lcd_rgb[23]}]

set_property -dict {PACKAGE_PIN H18 IOSTANDARD LVCMOS33} [get_ports lcd_hs]
set_property -dict {PACKAGE_PIN J17 IOSTANDARD LVCMOS33} [get_ports lcd_vs]
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33} [get_ports lcd_de]
set_property -dict {PACKAGE_PIN W9  IOSTANDARD LVCMOS15} [get_ports lcd_bl]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33} [get_ports lcd_pclk]
set_property -dict {PACKAGE_PIN Y9 IOSTANDARD LVCMOS15} [get_ports lcd_rst]

#CAMERA
################ J3 ###########################
set_property -dict {PACKAGE_PIN C19 IOSTANDARD LVCMOS33} [get_ports cam_scl_1]
set_property -dict {PACKAGE_PIN A20 IOSTANDARD LVCMOS33} [get_ports cam_sda_1]
set_property -dict {PACKAGE_PIN C20 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data_1[0]}]
set_property -dict {PACKAGE_PIN C22 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data_1[2]}]
set_property -dict {PACKAGE_PIN A21 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data_1[4]}]
set_property -dict {PACKAGE_PIN D15 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data_1[6]}]
set_property -dict {PACKAGE_PIN D16 IOSTANDARD LVCMOS33} [get_ports cam_pclk_1]
create_clock -period 40.000 -name cmos_pclk [get_ports cam_pclk_1]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets cam_pclk_1_IBUF]
set_property -dict {PACKAGE_PIN C18 IOSTANDARD LVCMOS33} [get_ports cam_vsync_1]
set_property -dict {PACKAGE_PIN B20 IOSTANDARD LVCMOS33} [get_ports cam_href_1]
set_property -dict {PACKAGE_PIN D20 IOSTANDARD LVCMOS33} [get_ports cam_rst_n_1]
set_property -dict {PACKAGE_PIN B22 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data_1[1]}]
set_property -dict {PACKAGE_PIN B21 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data_1[3]}]
set_property -dict {PACKAGE_PIN D14 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data_1[5]}]
set_property -dict {PACKAGE_PIN E16 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data_1[7]}]
set_property -dict {PACKAGE_PIN B16 IOSTANDARD LVCMOS33} [get_ports cam_pwdn_1]

#摄像头2接口的时钟
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets cam_pclk_IBUF]
set_property -dict {PACKAGE_PIN B15 IOSTANDARD LVCMOS33} [get_ports cam_pwdn_2]
set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33} [get_ports cam_scl_2]
set_property -dict {PACKAGE_PIN R17 IOSTANDARD LVCMOS33} [get_ports cam_sda_2]
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data_2[0]}]
set_property -dict {PACKAGE_PIN U17 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data_2[2]}]
set_property -dict {PACKAGE_PIN AA18 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data_2[4]}]
set_property -dict {PACKAGE_PIN B13 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data_2[6]}]
set_property -dict {PACKAGE_PIN C15 IOSTANDARD LVCMOS33} [get_ports cam_pclk_2]
create_clock -period 40.000 -name cmos_pclk [get_ports cam_pclk_2]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets cam_pclk_2_IBUF]

set_property -dict {PACKAGE_PIN R16 IOSTANDARD LVCMOS33} [get_ports cam_vsync_2]
set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS33} [get_ports cam_href_2]
set_property -dict {PACKAGE_PIN W17 IOSTANDARD LVCMOS33} [get_ports cam_rst_n_2]
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data_2[1]}]
set_property -dict {PACKAGE_PIN AB18 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data_2[3]}]
set_property -dict {PACKAGE_PIN C13 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data_2[5]}]
set_property -dict {PACKAGE_PIN C14 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data_2[7]}]


set_property -dict {PACKAGE_PIN E13 IOSTANDARD LVCMOS33} [get_ports uart_rxd]
set_property -dict {PACKAGE_PIN F14 IOSTANDARD LVCMOS33} [get_ports uart_txd]

set_property -dict {PACKAGE_PIN T6 IOSTANDARD LVCMOS15} [get_ports key_mode]

set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP [current_design]































