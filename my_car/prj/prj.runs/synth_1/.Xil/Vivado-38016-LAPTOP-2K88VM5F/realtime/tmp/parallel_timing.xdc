#
# Created by 
#   realTimeFpga.exe  on Wed Jul 29 09:41:30 2026
# (c) Xilinx, Inc.
#
# define clock sys_clk
create_clock -period 20.000000 -waveform {0.000000 10.000000} -name sys_clk [get_ports sys_clk]
# define clock u_clk_wiz_0/clk_out1
create_generated_clock -source [get_ports sys_clk] -edges {1 2 3} -edge_shift {0.000000 -7.500000 -15.000000} -name u_clk_wiz_0\/clk_out1 [get_pins u_clk_wiz_0/bbstub_clk_out1/O]
# define clock u_clk_wiz_0/clk_out2
create_generated_clock -source [get_ports sys_clk] -edges {1 2 3} -edge_shift {0.000000 0.000000 0.000000} -name u_clk_wiz_0\/clk_out2 [get_pins u_clk_wiz_0/bbstub_clk_out2/O]
# define clock u_ddr3_top/u_mig_7series_0/ui_clk
create_clock -period 10.000000 -waveform {0.000000 5.000000} -name u_ddr3_top\/u_mig_7series_0\/ui_clk [get_pins u_ddr3_top/u_mig_7series_0/bbstub_ui_clk/O]
# define clock cmos_pclk
create_clock -period 40.000000 -waveform {0.000000 20.000000} -name cmos_pclk [get_ports cam_pclk_2]
# define clock constraints sys_clk
# define clock constraints u_clk_wiz_0/clk_out1
# define clock constraints u_clk_wiz_0/clk_out2
# define clock constraints u_ddr3_top/u_mig_7series_0/ui_clk
# define clock constraints cmos_pclk
