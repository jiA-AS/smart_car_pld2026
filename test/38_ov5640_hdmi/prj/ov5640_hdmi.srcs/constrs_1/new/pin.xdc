create_clock -period 20.000 -name sys_clk [get_ports sys_clk]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets sys_clk]
set_property PACKAGE_PIN R4 [get_ports sys_clk]
set_property IOSTANDARD LVCMOS15 [get_ports sys_clk]
set_property IOSTANDARD LVCMOS15 [get_ports sys_rst_n]
set_property PACKAGE_PIN U7 [get_ports sys_rst_n]

#摄像头接口的时钟
create_clock -period 40.000 -name cmos_pclk [get_ports cam_pclk]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets cam_pclk_IBUF]
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports cam_pclk]
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS33} [get_ports cam_rst_n]
set_property -dict {PACKAGE_PIN AB18 IOSTANDARD LVCMOS33} [get_ports cam_pwdn]
set_property -dict {PACKAGE_PIN P17 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data[0]}]
set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data[1]}]
set_property -dict {PACKAGE_PIN R16 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data[2]}]
set_property -dict {PACKAGE_PIN R17 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data[3]}]
set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data[4]}]
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data[5]}]
set_property -dict {PACKAGE_PIN W17 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data[6]}]
set_property -dict {PACKAGE_PIN U17 IOSTANDARD LVCMOS33 IOB TRUE} [get_ports {cam_data[7]}]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports cam_vsync]
set_property -dict {PACKAGE_PIN N14 IOSTANDARD LVCMOS33} [get_ports cam_href]
set_property -dict {PACKAGE_PIN N13 IOSTANDARD LVCMOS33} [get_ports cam_scl]
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports cam_sda]

set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_ck_n[0]}]



set_property PACKAGE_PIN H20 [get_ports {tmds_data_p[2]}]
set_property PACKAGE_PIN K21 [get_ports {tmds_data_p[1]}]
set_property PACKAGE_PIN J22 [get_ports {tmds_data_p[0]}]
set_property PACKAGE_PIN J20 [get_ports tmds_clk_p]
