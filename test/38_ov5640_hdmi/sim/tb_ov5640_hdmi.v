`timescale 1ns/1ns

module tb_ov5640_hdmi;

//***************************************************************************
// The following parameters refer to width of various ports
//***************************************************************************

parameter CS_WIDTH  = 1;  // # of unique CS outputs to memory.
parameter DM_WIDTH  = 2;  // # of DM (data mask)
parameter DQ_WIDTH  = 16; // # of DQ (data)
parameter DQS_WIDTH = 2;  // # of DQ per DQS
parameter ODT_WIDTH = 1;  // # of ODT outputs to memory.
parameter ROW_WIDTH = 14; // # of memory Row Address bits.

//**************************************************************************//
// Local parameters Declarations
//**************************************************************************//

localparam real TPROP_DQS = 0.00; // Delay for DQS signal during Write Operatio
localparam real TPROP_DQS_RD = 0.00;  // Delay for DQS signal during Read Operation
localparam real TPROP_PCB_CTRL = 0.00;  // Delay for Address and Ctrl signals
localparam real TPROP_PCB_DATA = 0.00;  // Delay for data signal during Write operation
localparam real TPROP_PCB_DATA_RD = 0.00; // Delay for data signal during Read operation
localparam MEMORY_WIDTH = 16;
localparam NUM_COMP     = DQ_WIDTH / MEMORY_WIDTH;

//**************************************************************************//
// Wire Declarations
//**************************************************************************//
reg                           sys_clk;
reg                           sys_rst_n;
//ddr3 interface
wire                          ddr3_reset_n;
wire [DQ_WIDTH-1:0]           ddr3_dq_fpga;
wire [DQS_WIDTH-1:0]          ddr3_dqs_p_fpga;
wire [DQS_WIDTH-1:0]          ddr3_dqs_n_fpga;
wire [ROW_WIDTH-1:0]          ddr3_addr_fpga;
wire [3-1:0]                  ddr3_ba_fpga;
wire                          ddr3_ras_n_fpga;
wire                          ddr3_cas_n_fpga;
wire                          ddr3_we_n_fpga;
wire [1-1:0]                  ddr3_cke_fpga;
wire [1-1:0]                  ddr3_ck_p_fpga;
wire [1-1:0]                  ddr3_ck_n_fpga;
wire                          init_calib_complete;
wire [(CS_WIDTH*1)-1:0]       ddr3_cs_n_fpga;
wire [DM_WIDTH-1:0]           ddr3_dm_fpga;
wire [ODT_WIDTH-1:0]          ddr3_odt_fpga; 
reg  [(CS_WIDTH*1)-1:0]       ddr3_cs_n_sdram_tmp;
reg  [DM_WIDTH-1:0]           ddr3_dm_sdram_tmp;     
reg  [ODT_WIDTH-1:0]          ddr3_odt_sdram_tmp;
wire [DQ_WIDTH-1:0]           ddr3_dq_sdram;
reg  [ROW_WIDTH-1:0]          ddr3_addr_sdram [0:1];
reg  [3-1:0]                  ddr3_ba_sdram [0:1];
reg                           ddr3_ras_n_sdram;
reg                           ddr3_cas_n_sdram;
reg                           ddr3_we_n_sdram;
wire [(CS_WIDTH*1)-1:0]       ddr3_cs_n_sdram;
wire [ODT_WIDTH-1:0]          ddr3_odt_sdram;
reg  [1-1:0]                  ddr3_cke_sdram;
wire [DM_WIDTH-1:0]           ddr3_dm_sdram;
wire [DQS_WIDTH-1:0]          ddr3_dqs_p_sdram;
wire [DQS_WIDTH-1:0]          ddr3_dqs_n_sdram;
reg  [1-1:0]                  ddr3_ck_p_sdram;
reg  [1-1:0]                  ddr3_ck_n_sdram;

//hdmi interface
reg                           hpdin        ;
wire                          tmds_clk_p   ;
wire                          tmds_clk_n   ;
wire [2:0]                    tmds_data_p  ;
wire [2:0]                    tmds_data_n  ;
wire                          tmds_oen     ;
wire                          hpdout       ;

//CMOS Camera interface and data output simulation
wire			              cmos_pclk;				//24MHz CMOS Pixel clock input
wire			              cmos_vsync;				//L: vaild, H: invalid
wire			              cmos_href;				//H: vaild, L: invalid
wire	[7:0]	              cmos_data;				//8 bits cmos data input
wire                          cam_rst_n;
wire                          cam_pwdn ;
wire                          cam_scl  ;
wire                          cam_sda  ;

//**************************************************************************//
// Reset Generation
//**************************************************************************//
initial begin
  sys_rst_n = 1'b0;
  hpdin = 1'b0;
  #200
  sys_rst_n = 1'b1;
  hpdin = 1'b1;
end

//**************************************************************************//
// Clock Generation
//**************************************************************************//
initial
    sys_clk = 1'b0;
always
    sys_clk = #10 ~sys_clk;

//Generate 48MHz driver clock
reg    clk; 
wire    clk_cmos = clk;        //48MHz
initial    
    clk = 1'b0;
always       
    clk = #11 ~clk;
  
always @( * ) begin
  ddr3_ck_p_sdram     <=  ddr3_ck_p_fpga;
  ddr3_ck_n_sdram     <=  ddr3_ck_n_fpga;
  ddr3_addr_sdram[0]  <=  ddr3_addr_fpga;
  ddr3_addr_sdram[1]  <=  ddr3_addr_fpga;
  ddr3_ba_sdram[0]    <=  ddr3_ba_fpga;
  ddr3_ba_sdram[1]    <=  ddr3_ba_fpga;
  ddr3_ras_n_sdram    <=  ddr3_ras_n_fpga;
  ddr3_cas_n_sdram    <=  ddr3_cas_n_fpga;
  ddr3_we_n_sdram     <=  ddr3_we_n_fpga;
  ddr3_cke_sdram      <=  ddr3_cke_fpga;
end

always @( * )
  ddr3_cs_n_sdram_tmp <=  ddr3_cs_n_fpga;

assign ddr3_cs_n_sdram =  ddr3_cs_n_sdram_tmp;

always @( * )
  ddr3_dm_sdram_tmp <=  ddr3_dm_fpga;//DM signal generation

assign ddr3_dm_sdram = ddr3_dm_sdram_tmp;     

always @( * )
  ddr3_odt_sdram_tmp <=   ddr3_odt_fpga;

assign ddr3_odt_sdram =  ddr3_odt_sdram_tmp;

// Controlling the bi-directional BUS
genvar dqwd;
generate
  for (dqwd = 1;dqwd < DQ_WIDTH;dqwd = dqwd+1) begin : dq_delay
    WireDelay #
    (
      .Delay_g     (TPROP_PCB_DATA),
      .Delay_rd    (TPROP_PCB_DATA_RD),
      .ERR_INSERT ("OFF")
    )
    u_delay_dq
    (
      .A                 (ddr3_dq_fpga[dqwd]),
      .B                 (ddr3_dq_sdram[dqwd]),
      .reset            (sys_rst_n),
      .phy_init_done (u_ov5640_hdmi.u_ddr3_top.init_calib_complete)
    );
  end

  WireDelay #
  (
    .Delay_g     (TPROP_PCB_DATA),
    .Delay_rd    (TPROP_PCB_DATA_RD),
    .ERR_INSERT ("OFF")
  )
  u_delay_dq_0
  (
    .A                 (ddr3_dq_fpga[0]),
    .B                 (ddr3_dq_sdram[0]),
    .reset            (sys_rst_n),
    .phy_init_done (u_ov5640_hdmi.u_ddr3_top.init_calib_complete)
  );
endgenerate

genvar dqswd;
generate
  for (dqswd = 0;dqswd < DQS_WIDTH;dqswd = dqswd+1) begin : dqs_delay
    WireDelay #
    (
      .Delay_g     (TPROP_DQS),
      .Delay_rd    (TPROP_DQS_RD),
      .ERR_INSERT ("OFF")
    )
    u_delay_dqs_p
    (
      .A                 (ddr3_dqs_p_fpga[dqswd]),
      .B                 (ddr3_dqs_p_sdram[dqswd]),
      .reset            (sys_rst_n),
      .phy_init_done (u_ov5640_hdmi.u_ddr3_top.init_calib_complete)
    );

    WireDelay #
    (
      .Delay_g     (TPROP_DQS),
      .Delay_rd    (TPROP_DQS_RD),
      .ERR_INSERT ("OFF")
    )
    u_delay_dqs_n
    (
      .A                 (ddr3_dqs_n_fpga[dqswd]),
      .B                 (ddr3_dqs_n_sdram[dqswd]),
      .reset            (sys_rst_n),
      .phy_init_done (u_ov5640_hdmi.u_ddr3_top.init_calib_complete)
    );
  end
endgenerate

//===========================================================================
//                                 FPGA Memory Controller
//===========================================================================

ov5640_hdmi  u_ov5640_hdmi(
  .cam_pclk                 (cmos_pclk ),
  .cam_vsync                (cmos_vsync),
  .cam_href                 (cmos_href ),
  .cam_data                 (cmos_data ),
  .cam_rst_n                (cam_rst_n),
  .cam_pwdn                 (cam_pwdn ),
  .cam_scl                  (cam_scl  ),
  .cam_sda                  (cam_sda  ),
  .ddr3_dq                  (ddr3_dq_fpga),
  .ddr3_dqs_n               (ddr3_dqs_n_fpga),
  .ddr3_dqs_p               (ddr3_dqs_p_fpga),
  .ddr3_addr                (ddr3_addr_fpga),
  .ddr3_ba                  (ddr3_ba_fpga),
  .ddr3_ras_n               (ddr3_ras_n_fpga),
  .ddr3_cas_n               (ddr3_cas_n_fpga),
  .ddr3_we_n                (ddr3_we_n_fpga),
  .ddr3_reset_n             (ddr3_reset_n),
  .ddr3_ck_p                (ddr3_ck_p_fpga),
  .ddr3_ck_n                (ddr3_ck_n_fpga),
  .ddr3_cke                 (ddr3_cke_fpga),
  .ddr3_cs_n                (ddr3_cs_n_fpga),     
  .ddr3_dm                  (ddr3_dm_fpga),  
  .ddr3_odt                 (ddr3_odt_fpga), 
  .hpdin                    (hpdin        ),
  .tmds_clk_p               (tmds_clk_p   ),
  .tmds_clk_n               (tmds_clk_n   ),
  .tmds_data_p              (tmds_data_p  ),
  .tmds_data_n              (tmds_data_n  ),
  .tmds_oen                 (tmds_oen     ),
  .hpdout                   (hpdout       ),      
  .sys_clk                  (sys_clk),
  .sys_rst_n                (sys_rst_n)
);

//**************************************************************************//
//  Models instantiations
//**************************************************************************//

genvar r,i;
generate
  for (r = 0; r < CS_WIDTH; r = r + 1) begin: mem_rnk
      for (i = 0; i < NUM_COMP; i = i + 1) begin: gen_mem
        ddr3_model u_comp_ddr3
        (
          .rst_n    (ddr3_reset_n),
          .ck       (ddr3_ck_p_sdram),
          .ck_n     (ddr3_ck_n_sdram),
          .cke      (ddr3_cke_sdram[r]),
          .cs_n     (ddr3_cs_n_sdram[r]),
          .ras_n    (ddr3_ras_n_sdram),
          .cas_n    (ddr3_cas_n_sdram),
          .we_n     (ddr3_we_n_sdram),
          .dm_tdqs  (ddr3_dm_sdram[(2*(i+1)-1):(2*i)]),
          .ba       (ddr3_ba_sdram[r]),
          .addr     (ddr3_addr_sdram[r]),
          .dq       (ddr3_dq_sdram[16*(i+1)-1:16*(i)]),
          .dqs      (ddr3_dqs_p_sdram[(2*(i+1)-1):(2*i)]),
          .dqs_n    (ddr3_dqs_n_sdram[(2*(i+1)-1):(2*i)]),
          .tdqs_n   (),
          .odt      (ddr3_odt_sdram[r])
        );
      end
    end
endgenerate

Video_Image_Simulate_CMOS  
#(
    .CMOS_VSYNC_VALID    (1'b1),     //VSYNC = 1
    .IMG_HDISP           (10'd32),    //(10'd640),    //640*480
    .IMG_VDISP           (10'd4)        //(10'd480)
)
u_Video_Image_Simulate_CMOS
(
    //global reset
    .rst_n                (sys_rst_n),    
    
    //CMOS Camera interface and data output simulation
    .cmos_xclk            (clk_cmos),          //48MHz cmos clock
    .cmos_pclk            (cmos_pclk ),        //48MHz when rgb output
    .cmos_vsync           (cmos_vsync),        //L: vaild, H: invalid
    .cmos_href            (cmos_href ),        //H: vaild, L: invalid
    .cmos_data            (cmos_data )         //8 bits cmos data input
);

endmodule