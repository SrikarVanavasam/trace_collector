// (C) 2001-2024 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


// (C) 2001-2021 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


`timescale 1 ns / 1 ps
`include "include_h.sv"

module pioperf_user_app_top
#(
  parameter PLD_CLK_FREQ = 500,
  parameter LANE_MODE ="PCIE_X16",
  parameter DEVICE_FAMILY = "Agilex 7",
  parameter NUM_SEG = 4,
  parameter BITS_PER_SEG	= 'd256,
  parameter TRACE_RECORDS = 4)
 (
  input logic                              clk,
  input logic                              srstn,

  input logic                              slow_clk,
  input logic                              slow_srstn,                   
      // RX Interface to Hard IP
  input logic  [NUM_SEG              -1:0] rx_st_sop_i,
  input logic  [NUM_SEG              -1:0] rx_st_eop_i,
  input logic  [BITS_PER_SEG * NUM_SEG        -1:0] rx_st_data_i,
  input logic  [128 * NUM_SEG        -1:0] rx_st_header_i,
  input logic  [NUM_SEG              -1:0] rx_st_dvalid_i,
  input logic  [3 * NUM_SEG          -1:0] rx_st_bar_range_i,
  input logic  [32 * NUM_SEG         -1:0] rx_st_prefix_i,
  input logic  [NUM_SEG     			   -1:0] rx_st_hvalid_i,
  input logic  [NUM_SEG     			   -1:0] rx_st_pvalid_i,
  output logic                             rx_st_ready_o,
      // TX Interface to Hard IP
  output logic  [NUM_SEG             -1:0] tx_st_sop_o,
  output logic  [NUM_SEG             -1:0] tx_st_eop_o,
  output logic  [BITS_PER_SEG * NUM_SEG       -1:0] tx_st_data_o,
  output logic  [128 * NUM_SEG       -1:0] tx_st_header_o,
  output logic  [NUM_SEG             -1:0] tx_st_valid_o,
  output logic  [32 * NUM_SEG        -1:0] tx_st_prefix_o ,           //   input,   width = 128,      new                 .tx_st0_prefix
  output logic  [NUM_SEG          	 -1:0] tx_st_hvalid_o ,           //   input,    width = 4,      new                 .tx_st0_hvalid
  output logic  [NUM_SEG      			 -1:0] tx_st_pvalid_o ,          //   input,    width = 4,        new               .tx_st0_pvalid
  input  logic                             tx_st_ready_i,

  output credit_info               my_credit_info,
  output dma_cfg                   dma_wr_cfg_o,


  input   logic   [7:0]           hip_reconfig_readdata_i,
  input   logic                   hip_reconfig_readdatavalid_i,
  input   logic                   hip_reconfig_waitrequest_i, 
  output  logic   [31:0]          hip_reconfig_address_o,
  output  logic                   hip_reconfig_write_o,
  output  logic   [7:0]           hip_reconfig_writedata_o,
  output  logic                   hip_reconfig_read_o,

  
  input logic				              np_cdts_ready_i,
  input logic				              p_cdts_ready_i,

  // Between CXL and PCIe
  input logic                         trace_valid,
  input logic [511:0]                 trace_data,
  input logic [63:0]                  trace_buffer_base_addr,
  input logic [63:0]                  trace_buffer_size,
  input logic [63:0]                  control_register,
  output  logic [63:0]                  dropped_traces,
  output  logic [63:0]                  written_traces
);
	 
  link_info my_link_info;



if (LANE_MODE !="PCIE_X16_BP") begin 

  assign my_link_info.maxpayload               = 'b0;
	assign my_link_info.maxrdreq                 = 'b0;
	assign my_link_info.e_tag                    = 'b0;             
  assign my_link_info.bdf                      = 'b0; 
	assign my_link_info.busmasterenable          = 'b0;
  assign my_link_info.link_width               = 'b0;
  assign my_link_info.link_speed               = 'b0;
end

  logic [9:0] tx_st_hdr_len;
  logic tx_st_hdr_valid;
  logic [1:0] tx_st_hdr_type;	 

  assign my_credit_info.bam_rx_signal_ready_i = rx_st_ready_o;   //pio_rx_ready
  assign my_credit_info.pio_tx_st_ready_i     = tx_st_ready_i;       //pio_tx_st_ready_i
  assign my_credit_info.tx_hdr_i              = tx_st_hdr_len;   				  //pio_txc_header[9:0]
  assign my_credit_info.tx_hdr_valid_i        = tx_st_hdr_valid;          //pio_txc_valid
  assign my_credit_info.tx_hdr_type_i         = tx_st_hdr_type;

  logic [BITS_PER_SEG * NUM_SEG -1:0] rx_data;
  logic [3                      -1:0] rx_barnum;
  logic [128                    -1:0] rx_hdr;
  logic                            rx_sop; 
  logic                            rx_eop; 
  logic                            rx_valid;
  logic                            rx_ready; 
  logic                            tx_valid;
  logic                            tx_sop;
  logic                            tx_eop;
  logic [BITS_PER_SEG * NUM_SEG -1:0] tx_data;
  logic [128                    -1:0] tx_hdr;
  logic                            tx_rdy;
  completion_info                  cpl_info;
  dma_cmd_tx_intf                  dma_rd_cmd_tx_intf;
  dma_cmd_tx_intf                  dma_wr_cmd_tx_intf;
  logic                            tx_rdy_dma_wr;
  logic                            tx_rdy_dma_rd;
  logic                            tx_rdy_rx;
  logic [16                  -1:0] m_avmm_write_byteenable;
  logic [1                   -1:0] m_avmm_write_barnum;
  logic [7                   -1:0] m_avmm_write_address;
  logic [7                   -1:0] m_avmm_read_address;
  logic [7                   -1:0] m_avmm_read_address_r;
  
  logic [512                 -1:0] m_avmm_write_data;
  logic [512                 -1:0] m_avmm_read_data_0;
  logic [512                 -1:0] m_avmm_read_data_1;  
  logic [64                  -1:0] byteena;
  logic                            wren;
  logic [                     2:0] maxpayload;
  logic [                     2:0] maxrdreq;
  logic                            e_tag;
  logic [                    15:0] bdf;
  logic                            busmasterenable;
  logic [                     5:0] link_width;
  logic [                     3:0] link_speed;

  // TX Interface to Hard IP
  logic [NUM_SEG                -1:0]  tx_st_sop_r;
  logic [NUM_SEG                -1:0]  tx_st_eop_r;
  logic [BITS_PER_SEG * NUM_SEG -1:0]  tx_st_data_r;
  logic [128 * NUM_SEG          -1:0]  tx_st_header_r;
  logic [NUM_SEG                -1:0]  tx_st_valid_r;  
  logic [NUM_SEG                -1:0]  tx_st_hvalid_r;
  logic [2                      -1:0]  credit;  
  logic cpl_timeout;

  (*noprune*)  logic        srstn_0 /*synthesis preserve*/ ;
  (*noprune*) logic        srstn_1 /*synthesis preserve*/ ;
  (*noprune*) logic        srstn_2 /*synthesis preserve*/ ;
  (*noprune*) logic        srstn_3 /*synthesis preserve*/ ;
  (*noprune*) logic        srstn_4 /*synthesis preserve*/ ;
  (*noprune*)  logic        srstn_5 /*synthesis preserve*/ ;
  (*noprune*) logic [5:0] rst_duplicated_n /*synthesis preserve*/ ;

assign srstn_0 = ~rst_duplicated_n[0];
assign srstn_1 = ~rst_duplicated_n[1];
assign srstn_2 = ~rst_duplicated_n[2];
assign srstn_3 = ~rst_duplicated_n[3];
assign srstn_4 = ~rst_duplicated_n[4];
assign srstn_5 = ~rst_duplicated_n[5];

    logic  [15:0]                  tx_cdts_limit_r;          
    logic  [2:0]                   tx_cdts_limit_tdm_idx_r;
    logic tx_rdy_timeout  /* synthesis preserve */;
    logic[11:0] tx_rdy_timer  /* synthesis preserve */;
    
    logic [3:0] rx_st_valid_or;
  logic [1:0] hdr_is_mesgx_wr;
  logic [1:0] hdr_is_wr;

  wire [BITS_PER_SEG * NUM_SEG -1:0]         rx0_data_w;         
  wire [127:0]         rx0_hdr_w;   
  wire [2:0]           rx0_bar_range_w;  

  wire                 rx0_sop_w;          
  wire                 rx0_eop_w;          
  wire                 rx0_data_valid_w;   
  wire                 rx_data_ready_w;    
  wire [BITS_PER_SEG * NUM_SEG -1:0]         rx1_data_w;
  wire [127:0]         rx1_hdr_w;
  wire [2:0]           rx1_bar_range_w;

  wire                 rx1_sop_w;
  wire                 rx1_eop_w;
  wire                 rx1_data_valid_w;

rnr_pcie_reset_tree p0_rst_status  (.coreclkout_hip(clk), .din(1'b1), .src_alive_r(srstn), .reset_status_tree(rst_duplicated_n));
  wire [127:0] rx0_header;
  wire         rx0_header_v;
  wire [127:0] rx1_header;
  wire         rx1_header_v;

  wire [NUM_SEG-1:0]        tx_st_sop_w;
  wire [NUM_SEG-1:0]       tx_st_eop_w;
  wire [BITS_PER_SEG*NUM_SEG-1:0] tx_st_data_w;
  wire [128*NUM_SEG-1:0] tx_st_header_w;
  wire [NUM_SEG-1:0]       tx_st_valid_w;

  //tied off output of unused signal
  assign tx_st_err_o = 3'h0;
  assign tx_st_tlp_prfx_o = 64'h0;

  assign tx_st_sop_o = tx_st_sop_r;
  assign tx_st_eop_o = tx_st_eop_r;
  assign tx_st_data_o = tx_st_data_r;
  assign tx_st_header_o = tx_st_header_r;
  assign tx_st_valid_o = tx_st_valid_r;
  
  assign tx_st_prefix_o = 128'h0;
  assign tx_st_pvalid_o = 3'h0;

  assign tx_st_hvalid_o = tx_st_hvalid_r; 
 
  always_ff @ (posedge clk) begin
    if (srstn == 1'b0) begin
      tx_st_valid_r <= 1'b0;
      tx_st_hdr_type <= 2'b00 ; 
    end else begin
      tx_st_sop_r <= tx_st_sop_w;
      tx_st_eop_r <= tx_st_eop_w;
      tx_st_data_r <= tx_st_data_w;
      tx_st_header_r <= tx_st_header_w;
      tx_st_valid_r <= tx_st_valid_w;
      tx_st_hvalid_r <= tx_st_sop_w;	// generate header valid	
    
      tx_st_hdr_len <= tx_st_header_w[105:96];  // for credit interface
      tx_st_hdr_valid <= tx_st_sop_w[0]; // for credit interface
      
      if (tx_st_header_w[127:120] == 8'h60) begin
        tx_st_hdr_type <= 2'b00 ;                  // for credit interface - posted TLP
      end else if (tx_st_header_w[127:120] == 8'h20) begin
        tx_st_hdr_type <= 2'b01 ;                  // for credit interface - non-posted TLP
      end else if (tx_st_header_w[127:120] == 8'h4a) begin
        tx_st_hdr_type <= 2'b11 ;                  // for credit interface - Cpld TLP
      end
    end
  end
	
  assign credit = 2'b11;
  
 
 always_ff @(posedge clk)
    begin
    if (srstn_0 == 1'b0) begin
      tx_rdy_timeout <= 1'b0;
      tx_rdy_timer   <= 'b0;
    end else begin
      if (tx_st_ready_i == 1'b0)
        tx_rdy_timer <= tx_rdy_timer + 1'b1;
      else
        tx_rdy_timer <= 'b0;

      if (tx_rdy_timer == 12'h200)
        tx_rdy_timeout <= 1'b1;
    end  
  end       

assign rx_st_valid_or = rx_st_dvalid_i | rx_st_hvalid_i;


logic   [127:0]         cfg_tlp_hdr_rx0_hdr;   
logic                   cfg_tlp_hdr_rx0_data_valid;
logic   [255:0]         cfg_tlp_data;


logic                   cfg_cpl_valid;   		   
logic                   cfg_cpl_sop;  		   
logic                   cfg_cpl_eop;  		   
logic   [127	: 0]      cfg_cpl_hdr;     
logic	  [511	: 0]      cfg_cpl_data;    
logic                   cfg_cpl_ready;

generate 
if (LANE_MODE =="PCIE_X16_BP")
begin


pioperf_cfg_space_ctrl cfg_space_ctrl(
  .clk                          (clk),
  .srst_n                       (srstn_0),
  .slow_clk                     (slow_clk),
	.slow_srstn                   (slow_srstn),

  // Stream 0 for CfgRd or CfgWr coming from Host
  .cfg_tlp_hdr_rx0_hdr_i        (cfg_tlp_hdr_rx0_hdr),   
  .cfg_tlp_hdr_rx0_data_valid_i (cfg_tlp_hdr_rx0_data_valid),
  .cfg_tlp_data_i               (cfg_tlp_data),

  // HIP reconfig interface
  .hip_reconfig_readdata_i      (hip_reconfig_readdata_i),
	.hip_reconfig_readdatavalid_i (hip_reconfig_readdatavalid_i),
	.hip_reconfig_waitrequest_i   (hip_reconfig_waitrequest_i), 
	.hip_reconfig_address_o       (hip_reconfig_address_o),
  .hip_reconfig_write_o         (hip_reconfig_write_o),
	.hip_reconfig_writedata_o     (hip_reconfig_writedata_o),
	.hip_reconfig_read_o          (hip_reconfig_read_o),

  // Config Cpl going back to the Host
  .cfg_cpl_valid_o              (cfg_cpl_valid),   		   
  .cfg_cpl_sop_o                (cfg_cpl_sop),  		   
  .cfg_cpl_eop_o                (cfg_cpl_eop),  		   
  .cfg_cpl_hdr_o                (cfg_cpl_hdr),     
  .cfg_cpl_data_o               (cfg_cpl_data),    
  .cfg_cpl_ready_i              (cfg_cpl_ready),
  .link_info_o                  (my_link_info)
);
end
endgenerate

// This module simplify RX to always output 1 segment
pioperf_multitlp_adapter_v2  
     #( .NUM_SEG  (NUM_SEG),
      .BITS_PER_SEG (BITS_PER_SEG)) adapter (
    .clk              (clk),
    .srst_n           (srstn_0),

    .rx_st_ready_o    (rx_st_ready_o),
    .rx_st_valid_i    (rx_st_valid_or),
    .rx_st_sop      (rx_st_sop_i),
    .rx_st_eop      (rx_st_eop_i),
    .rx_st_hdr      (rx_st_header_i),
    .rx_st_data     (rx_st_data_i),
    .rx_st_bar_range(rx_st_bar_range_i),
    .rx_data_ready_i  (1'b1),
				  
    .rx0_data_o       (rx0_data_w),
    .rx0_hdr_o        (rx0_hdr_w),
    .rx0_bar_range_o  (rx0_bar_range_w),
    .rx0_sop_o        (rx0_sop_w),
    .rx0_eop_o        (rx0_eop_w),
    .rx0_data_valid_o (rx0_data_valid_w),
				  
    .rx1_data_o       (rx1_data_w),
    .rx1_hdr_o        (rx1_hdr_w),
    .rx1_bar_range_o  (rx1_bar_range_w),
    .rx1_sop_o        (rx1_sop_w),
    .rx1_eop_o        (rx1_eop_w),
    .rx1_data_valid_o (rx1_data_valid_w)     
   );

	// extract data for credit interface		
generate 

if (LANE_MODE =="PCIE_X16_BP")
begin
  logic rx1_is_cfg;
  logic rx0_is_cfg;
  
  assign my_credit_info.hdr_is_cfg_i = {rx1_is_cfg, rx0_is_cfg};

always_comb begin
  if ((rx1_hdr_w[127:120] == `CFGRD0) || (rx1_hdr_w[127:120] == `CFGWR0) || (rx1_hdr_w[127:120] == `CFGRD1) || (rx1_hdr_w[127:120] == `CFGWR1)) begin
    rx1_is_cfg = 1;
  end else begin
    rx1_is_cfg = 0;
  end
  if ((rx0_hdr_w[127:120] == `CFGRD0) || (rx0_hdr_w[127:120] == `CFGWR0) || (rx0_hdr_w[127:120] == `CFGRD1) || (rx0_hdr_w[127:120] == `CFGWR1)) begin
    rx0_is_cfg = 1;
  end else begin
    rx0_is_cfg = 0;
  end
end

end

endgenerate


  assign my_credit_info.hdr_len_i     = {rx1_hdr_w[105:96],rx0_hdr_w[105:96]};
  assign my_credit_info.hdr_valid_i   = {rx1_sop_w, rx0_sop_w};
  assign my_credit_info.hdr_is_wr_i   = {hdr_is_mesgx_wr | hdr_is_wr};   					
  assign my_credit_info.hdr_is_rd_i   = {~rx1_hdr_w[126] & (rx1_hdr_w[124:122]==3'b0), ~rx0_hdr_w[126] & (rx0_hdr_w[124:122]==3'b0)};   	
  assign my_credit_info.hdr_is_cpl_i  = {(rx1_hdr_w[123:121]==3'b101), (rx0_hdr_w[123:121]==3'b101)};   
  assign hdr_is_mesgx_wr              = {(rx1_hdr_w[126:123]==4'b1110), (rx0_hdr_w[126:123]==4'b1110)};			// decode for mesg 
  assign hdr_is_wr                    = {rx1_hdr_w[126] & (rx1_hdr_w[124:120]==5'b0), rx0_hdr_w[126] & (rx0_hdr_w[124:120]==5'b0)};

		

  pioperf_rx_diverter_v4  
  #(  .NUM_SEG      (NUM_SEG),
        .BITS_PER_SEG (BITS_PER_SEG)) diverter
   (
    .clk                      (clk),
    .srst_n                   (srstn_1),

    .rx0_data_i               (rx0_data_w),         
    .rx0_hdr_i                (rx0_hdr_w),   
    .rx0_bar_range_i          (rx0_bar_range_w),      
    .rx0_sop_i                (rx0_sop_w),          
    .rx0_eop_i                (rx0_eop_w),          
    .rx0_data_valid_i         (rx0_data_valid_w),   
    .rx_data_ready_o          (rx_data_ready_w),    
    
    .rx1_data_i               (rx1_data_w),
    .rx1_hdr_i                (rx1_hdr_w),
    .rx1_bar_range_i          (rx1_bar_range_w),
    .rx1_sop_i                (rx1_sop_w),
    .rx1_eop_i                (rx1_eop_w),
    .rx1_data_valid_i         (rx1_data_valid_w),
    
    .cpl_hdr_rx0_hdr_o        (rx0_header),   
    .cpl_hdr_rx0_data_valid_o (rx0_header_v),   
    .cpl_hdr_rx1_hdr_o        (rx1_header),
    .cpl_hdr_rx1_data_valid_o (rx1_header_v),
    
   
    // Stream 0 for CfgRd or CfgWr coming from Host
    .cfg_tlp_hdr_rx0_hdr_o(cfg_tlp_hdr_rx0_hdr),   
    .cfg_tlp_hdr_rx0_data_valid_o(cfg_tlp_hdr_rx0_data_valid),
    .cfg_tlp_data_o(cfg_tlp_data),   
     

    .dma_rx_data_o            (rx_data),
    .dma_rx_hdr_o             (rx_hdr),
    .dma_rx_bar_range_o       (rx_barnum),
    .dma_rx_sop_o             (rx_sop),
    .dma_rx_eop_o             (rx_eop),
    .dma_rx_data_valid_o      (rx_valid),
    .dma_rx_data_ready_i      (rx_ready)    
  );

  pioperf_rx_intf_v2 
   #(  .NUM_SEG      (NUM_SEG),
        .BITS_PER_SEG (BITS_PER_SEG)) rx
  (
    .clk                      (clk),
    .srstn                    (srstn_2),

    .rx_sop                   (rx_sop),
    .rx_eop                   (rx_eop),
    .rx_header                (rx_hdr),
    .rx_data                  (rx_data),
    .rx_valid                 (rx_valid),
    .rx_barnum                (rx_barnum),
    .rx_ready                 (rx_ready),

    .cpl_ready_i              (cpl_ready),
    .cpl_info_o               (cpl_info),

    .m_avmm_read_address      (m_avmm_read_address),  
    .m_avmm_write_byteenable  (m_avmm_write_byteenable),
    .m_avmm_write_barnum      (m_avmm_write_barnum),
    .m_avmm_write_address     (m_avmm_write_address), 
    .m_avmm_write_data        (m_avmm_write_data) 
  );

  //------------------------------------------
  // BAR registers
  //------------------------------------------
  logic cpld_valid	;    		   
  logic cpld_sop  	;   		   
  logic cpld_eop    ;  		   
  logic [128 - 1 : 0] cpld_hdr   ;    
  logic [512 - 1 : 0] cpld_data  ;  
  logic cpld_ready	;

  logic [NUM_SEG -1	: 0]	mwr_valid	;    		   
  logic [NUM_SEG -1	: 0] 	mwr_sop  	;   		   
  logic [NUM_SEG -1	: 0] 	mwr_eop    ;  		   
  logic [128*NUM_SEG -1	: 0] mwr_hdr   ;    
  logic [BITS_PER_SEG*NUM_SEG -1	: 0] mwr_data  ;  
  logic mwr_ready	;

  logic [NUM_SEG -1	: 0]	mrd_valid	;    		   
  logic [NUM_SEG -1	: 0] 	mrd_sop  	;   		   
  logic [NUM_SEG -1	: 0] 	mrd_eop    ;  		   
  logic [128*NUM_SEG -1	: 0] mrd_hdr   ;    
  logic [BITS_PER_SEG*NUM_SEG -1	: 0] mrd_data  ;  
  logic mrd_ready	;	 

  dma_cfg dma_wr_cfg;
  dma_cfg dma_rd_cfg;
  dma_info dma_wr_info;
  dma_info dma_rd_info;

  assign dma_wr_cfg_o = dma_wr_cfg;
	 
  pioperf_bar_v2 bar0 (
    .clk                      (clk),
    .srstn                    (srstn_3),

    .s_avmm_write_byteenable  (m_avmm_write_byteenable),
    .s_avmm_write_barnum      (m_avmm_write_barnum),
    .s_avmm_write_address     (m_avmm_write_address[6:1]),
    .s_avmm_write_data        (m_avmm_write_data),

    .dma_rd_cfg_o             (dma_rd_cfg), 
    .dma_rd_info_i            (dma_rd_info),
    .dma_wr_cfg_o             (dma_wr_cfg),	
    .dma_wr_info_i            (dma_wr_info),

    .bdf								      (bdf),		

    .cpl_ready_o					    (cpl_ready),
    .cpl_info_i						    (cpl_info),
    .cpld_valid_o             (cpld_valid),
    .cpld_sop_o               (cpld_sop),    		   
    .cpld_eop_o               (cpld_eop),    		   
    .cpld_hdr_o               (cpld_hdr[127:0]),    
    .cpld_data_o              (cpld_data[511:0]),  
    .cpld_ready_i             (cpld_ready) 
  );
	 
  trace_recorder 
    #(  .NUM_SEG      (NUM_SEG),
        .BITS_PER_SEG (BITS_PER_SEG),
        .TRACE_RECORDS (TRACE_RECORDS)
      ) trace_gen (
    .clk            (clk),
    .srstn          (srstn_1),

    .cpl_info_i			(cpl_info),
    .dma_wr_cfg_i		(dma_wr_cfg),	
    .dma_wr_info_o	(dma_wr_info),
    
    .tlp_dvalid_o 	(mwr_valid),    		   
    .tlp_sop_o   		(mwr_sop),   		   
    .tlp_eop_o   		(mwr_eop),  		   
    .tlp_hdr_o   		(mwr_hdr),    
    .tlp_data_o  		(mwr_data),  
    .tlp_ready_i		(mwr_ready),

    .p_cdts_ready_i	(p_cdts_ready_i),

    // CSR <-> Trace Recorder
    .trace_valid                       ( trace_valid ), // Output from CSR Top
    .trace_data                        ( trace_data ), // Output from CSR Top
    .trace_buffer_base_addr            ( trace_buffer_base_addr ), // Output from CSR Top
    .trace_buffer_size                 ( trace_buffer_size      ), // Output from CSR Top
    .control_register                  ( control_register       ), // Output from CSR Top
    .dropped_traces                    ( dropped_traces         ), // Input to CSR Top
    .written_traces                    ( written_traces         )  // Input to CSR Top
  ); 

  pioperf_rd_traffic_gen 
    #( .NUM_SEG  (NUM_SEG),
    .BITS_PER_SEG (BITS_PER_SEG)) rd_gen (
    .clk              (clk),
    .srstn            (srstn_4),
    
    .rx0_header_v     (rx0_header_v),
    .rx0_header       (rx0_header),
    .rx1_header_v     (rx1_header_v),
    .rx1_header       (rx1_header),
    
    .dma_rd_info_o	  (dma_rd_info),	// output
    .dma_rd_cfg_i		  (dma_rd_cfg),	// input
    
    .tlp_dvalid_o     (mrd_valid),    		   
    .tlp_sop_o   	    (mrd_sop),   		   
    .tlp_eop_o   	    (mrd_eop),  		   
    .tlp_hdr_o   	    (mrd_hdr),    
    .tlp_data_o  	    (mrd_data),  
    .tlp_ready_i			(mrd_ready),
    
    .np_cdts_ready_i	(np_cdts_ready_i),
    .link_info_i      (my_link_info)
); 

  
generate 

    wire  [NUM_SEG-1	: 0]  cfg_cpl_valid_i_w ;   		   
    wire  [NUM_SEG-1	: 0]  cfg_cpl_sop_i_w    ; 		   
    wire  [NUM_SEG-1	: 0]  cfg_cpl_eop_i_w     ; 		   
    wire	[128*NUM_SEG-1	: 0]  cfg_cpl_hdr_i_w  ;     
    wire	[256*NUM_SEG-1	: 0]  cfg_cpl_data_i_w ;    
    wire 	cfg_cpl_ready_w;

if (LANE_MODE =="PCIE_X16_BP") begin
  	assign cfg_cpl_valid_i_w = {3'b0, cfg_cpl_valid};
	assign cfg_cpl_sop_i_w   = {3'b0, cfg_cpl_sop};
	assign cfg_cpl_eop_i_w   = {3'b0, cfg_cpl_eop};
	assign cfg_cpl_hdr_i_w   = {384'b0, cfg_cpl_hdr};
	assign cfg_cpl_data_i_w  = {512'b0, cfg_cpl_data};
	assign cfg_cpl_ready = cfg_cpl_ready_w;  
	end
else begin	
	assign cfg_cpl_valid_i_w = {(NUM_SEG){1'b0}};     
	assign cfg_cpl_sop_i_w   = {(NUM_SEG){1'b0}} ;    
	assign cfg_cpl_eop_i_w   = {(NUM_SEG){1'b0}}  ;   
	assign cfg_cpl_hdr_i_w   = {(128*NUM_SEG){1'b0}}; 
	assign cfg_cpl_data_i_w  = {(256*NUM_SEG){1'b0}} ;
end
endgenerate   

  arbiter_v4  
    #( .NUM_SEG  (NUM_SEG),
    .BITS_PER_SEG (BITS_PER_SEG)) arb0 (
    .clk           (clk),
    .srstn         (srstn_5),

    .cpld_valid_i  ({{(NUM_SEG-1){1'b0}}, cpld_valid}),    		   
    .cpld_sop_i    ({{(NUM_SEG-1){1'b0}}, cpld_sop}),    		   
    .cpld_eop_i    ({{(NUM_SEG-1){1'b0}}, cpld_eop}),    		   
    .cpld_hdr_i    ({{(128*(NUM_SEG-1)){1'b0}}, cpld_hdr[127:0]}),    
    .cpld_data_i   ({{(256*(NUM_SEG-2)){1'b0}}, cpld_data[511:0]}),  
    .cpld_ready_o  (cpld_ready), 

    .mrd_valid_i   (mrd_valid),  		   
    .mrd_sop_i     (mrd_sop),  		   
    .mrd_eop_i     (mrd_eop),  		   
    .mrd_hdr_i     (mrd_hdr),
    .mrd_data_i 	 (mrd_data),
    .mrd_ready_o	 (mrd_ready),

    .mwr_valid_i   (mwr_valid),  		   
    .mwr_sop_i     (mwr_sop),  		   
    .mwr_eop_i     (mwr_eop),  		   
    .mwr_hdr_i     (mwr_hdr),  
    .mwr_data_i    (mwr_data),
    .mwr_ready_o	 (mwr_ready),

    .arb_valid_o   (tx_st_valid_w),  		   
    .arb_sop_o     (tx_st_sop_w),  		   
    .arb_eop_o     (tx_st_eop_w),  		   
    .arb_hdr_o     (tx_st_header_w),  
    .arb_data_o    (tx_st_data_w),
    .arb_ready_i	 (tx_st_ready_i),

  .cfg_cpl_valid_i  (cfg_cpl_valid_i_w),   		   
  .cfg_cpl_sop_i    (cfg_cpl_sop_i_w),  		   
  .cfg_cpl_eop_i    (cfg_cpl_eop_i_w),  		   
  .cfg_cpl_hdr_i    (cfg_cpl_hdr_i_w),     
  .cfg_cpl_data_i   (cfg_cpl_data_i_w),    
  .cfg_cpl_ready_o  (cfg_cpl_ready_w) 

  );


endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "cKSxlSR/FkSZtfd/P9gfDXnAfn6DDoHjtdgH+ilCiCW2yzncx3x93hd/axVwXlLf7JqdXSbwBGQhE/LGuHaqiWm8NVMnl7WStDps9AFJYtE8NX7v2V/sQprdQxsFVLQX+h8xmVXX9SwnP69VVbkaKxFwXQlFFUOriiPMuJRg+jx1ezwfkUHsodUBUJAML+oXp7c+ZWYRz4AtRuPxF+tgpywHV+vnFv6H49MUi24XJVV6b7O7kSFLOX6/cd3mRztK1Sb5LbpSZL9sQptN/+u3NsPwOYEa03LkdkZdQnPNFWlY/cYglt1AsmrIqzeL2fx2+LjnHwBg3/bul2TcMKUIrdsJL0ng18x5ZZD/Ow8Nb4sLORn05DolW8MvyLD9Z3FbKqC7/y/v6wQMYuhEe/koj7QXDZ379WJ2vu56/QjRgUSjVnQgh1csQ5tsECVylpbV0GxFSBMu6UNizv9ME4052KzJKi6brvseoqY7EiXAe88BnEHnlhuoC4Re7gZ4PSZ2r2K1VbdmKISedmmvOOS7eiRPgr1OfFOWDaANhbBY4aaQL82tpiYOeXaQ1G/NGg64leLLdiSGu3nJq6JUD+rOVUU5QQRcjanZkcp157J/EqEj2jabJRr5nGhMZOfsGSdhOB0/Ue/vNIyUeHRIZzj3i3fkdKsk8KftoHjyBExzSMza9cSZJuATYgMq7Sue4z7dqalOY223wSlATFAAoGwDaygpgt8SUmweidM87fIdW0U3zTn6Cl3rQVXT57wgxwLvavaQsMAYewUspGNb8LUTtEPGhoOmZawtdS3kzUZEcp0AM835mQ8VDWObifpW/266kWzK8xt2BF1i6eKx21WX01YoHtsiAxrGi0brd0B1N4uDDHCDc4hoHtPv359yeY2Ts/cHavA0GKym3EgWLVIwbtiaBfap8TkAEEyGACY8yJNNfZETvCkCGxJ1e6KaXa2unqqZtg6COmqqyyKwY4pf5BIedzIvPE4lCLKb0jm2Uj+yHSVCdXUF7coOrsftgOSo"
`endif
