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


`timescale 1 ns / 1 ps
`include "include_h.sv"

    localparam NUM_SEG = 2;
    localparam BITS_PER_SEG	= 'd128;
    localparam EMPTY_BIT_SIZE = 1;

module intel_pcie_perf_ed_gen5 #(
  parameter PLD_CLK_FREQ = 500,
  parameter LANE_MODE ="PCIE_X16",
  parameter DEVICE_FAMILY = "Agilex 7")
 (                   
   input  wire        p0_reset_status_n,


    input  wire        p1_reset_status_n,    
    input  wire        p2_reset_status_n,
    input  wire        p3_reset_status_n,

   // Rx Interface
   output  wire       p0_rx_st_ready_o,  //
   input wire [BITS_PER_SEG-1:0] p0_rx_st0_data_i, //       
   input wire         p0_rx_st0_sop_i,  //       
   input wire         p0_rx_st0_eop_i,  //       
   input wire         p0_rx_st0_dvalid_i,//      
   input wire [EMPTY_BIT_SIZE:0]   p0_rx_st0_empty_i, // Floating

   input wire [BITS_PER_SEG-1:0] p0_rx_st1_data_i,     
   input wire         p0_rx_st1_sop_i,      
   input wire         p0_rx_st1_eop_i,      
   input wire         p0_rx_st1_dvalid_i,   
   input wire [EMPTY_BIT_SIZE:0]   p0_rx_st1_empty_i,
   input wire [127:0] p0_rx_st0_hdr_i,   //        
   input wire [31:0]  p0_rx_st0_prefix_i,//      
   input wire         p0_rx_st0_hvalid_i,//      
   input wire         p0_rx_st0_pvalid_i,//      
   input wire [2:0]   p0_rx_st0_bar_i,   //      
 //  input wire         p0_rx_st0_pt_parity_i,// Floating
   
   input wire [127:0] p0_rx_st1_hdr_i,         
   input wire [31:0]  p0_rx_st1_prefix_i,      
   input wire         p0_rx_st1_hvalid_i,      
   input wire         p0_rx_st1_pvalid_i,      
   input wire [2:0]   p0_rx_st1_bar_i,         
//   input wire         p0_rx_st1_pt_parity_i, 
   //HIP Crdt Intf
   
    // rx header credit
   output  wire [2:0]   p0_rx_st_hcrdt_init_o,        
   output  wire [2:0]   p0_rx_st_hcrdt_update_o,      
   output  wire [5:0]   p0_rx_st_hcrdt_update_cnt_o,  
   input   wire [2:0]   p0_rx_st_hcrdt_init_ack_i,    
   
	// rx data credit 
   output  wire [2:0]   p0_rx_st_dcrdt_init_o,        
   output  wire [2:0]   p0_rx_st_dcrdt_update_o,      
   output  wire [11:0]  p0_rx_st_dcrdt_update_cnt_o,  
   input   wire [2:0]   p0_rx_st_dcrdt_init_ack_i,    
   
   // Tx interface
   
    //HIP Crdt Intf
   
   // tx header credit  
   input   wire [2:0]   p0_tx_st_hcrdt_init_i,        
   input   wire [2:0]   p0_tx_st_hcrdt_update_i,      
   input   wire [5:0]   p0_tx_st_hcrdt_update_cnt_i,  
   output  wire [2:0]   p0_tx_st_hcrdt_init_ack_o,    
   
   // tx data credit 
   input   wire [2:0]   p0_tx_st_dcrdt_init_i,        
   input   wire [2:0]   p0_tx_st_dcrdt_update_i,      
   input   wire [11:0]  p0_tx_st_dcrdt_update_cnt_i,  
   output  wire [2:0]   p0_tx_st_dcrdt_init_ack_o,  
   
   output  wire [127:0] p0_tx_st0_hdr_o, //      
   output  wire [31:0]  p0_tx_st0_prefix_o, //   
   output  wire         p0_tx_st0_hvalid_o,    //
   output  wire         p0_tx_st0_pvalid_o,  //  
   
   output  wire [127:0] p0_tx_st1_hdr_o,       
   output  wire [31:0]  p0_tx_st1_prefix_o,    
   output  wire         p0_tx_st1_hvalid_o,    
   output  wire         p0_tx_st1_pvalid_o,    
   input wire          p0_tx_st0_ready_i, //
   
   output wire [BITS_PER_SEG-1:0] p0_tx_st0_data_o, //   
   output wire         p0_tx_st0_sop_o, //   
   output wire         p0_tx_st0_eop_o, //    
   output wire         p0_tx_st0_dvalid_o,// 
   
   output wire [BITS_PER_SEG-1:0] p0_tx_st1_data_o,   
   output wire         p0_tx_st1_sop_o,    
   output wire         p0_tx_st1_eop_o,    
   output wire         p0_tx_st1_dvalid_o, 
  
      output  wire       p1_rx_st_ready_o,  //
      input wire [BITS_PER_SEG-1:0] p1_rx_st0_data_i, //       
      input wire         p1_rx_st0_sop_i,  //       
      input wire         p1_rx_st0_eop_i,  //       
      input wire         p1_rx_st0_dvalid_i,//      
      input wire [EMPTY_BIT_SIZE:0]   p1_rx_st0_empty_i, // Floating
      
      input wire [BITS_PER_SEG-1:0] p1_rx_st1_data_i,     
      input wire         p1_rx_st1_sop_i,      
      input wire         p1_rx_st1_eop_i,      
      input wire         p1_rx_st1_dvalid_i,   
      input wire [EMPTY_BIT_SIZE:0]   p1_rx_st1_empty_i,
      
      input wire [127:0] p1_rx_st0_hdr_i,   //        
      input wire [31:0]  p1_rx_st0_prefix_i,//      
      input wire         p1_rx_st0_hvalid_i,//      
      input wire         p1_rx_st0_pvalid_i,//      
      input wire [2:0]   p1_rx_st0_bar_i,   //      
//      input wire         p1_rx_st0_pt_parity_i,// Floating
      
      input wire [127:0] p1_rx_st1_hdr_i,         
      input wire [31:0]  p1_rx_st1_prefix_i,      
      input wire         p1_rx_st1_hvalid_i,      
      input wire         p1_rx_st1_pvalid_i,      
      input wire [2:0]   p1_rx_st1_bar_i,         
//      input wire         p1_rx_st1_pt_parity_i,
      
      //HIP Crdt Intf
      
       // rx header credit
      output  wire [2:0]   p1_rx_st_hcrdt_init_o,        
      output  wire [2:0]   p1_rx_st_hcrdt_update_o,      
      output  wire [5:0]   p1_rx_st_hcrdt_update_cnt_o,  
      input   wire [2:0]   p1_rx_st_hcrdt_init_ack_i,    
      
	   // rx data credip1
      output  wire [2:0]   p1_rx_st_dcrdt_init_o,        
      output  wire [2:0]   p1_rx_st_dcrdt_update_o,      
      output  wire [11:0]  p1_rx_st_dcrdt_update_cnt_o,  
      input   wire [2:0]   p1_rx_st_dcrdt_init_ack_i,    
      
      // Tx interface
      
       //HIP Crdt Intf
      
      // tx header credit  p1
      input   wire [2:0]   p1_tx_st_hcrdt_init_i,        
      input   wire [2:0]   p1_tx_st_hcrdt_update_i,      
      input   wire [5:0]   p1_tx_st_hcrdt_update_cnt_i,  
      output  wire [2:0]   p1_tx_st_hcrdt_init_ack_o,    
      
      // tx data credit 
      input   wire [2:0]   p1_tx_st_dcrdt_init_i,        
      input   wire [2:0]   p1_tx_st_dcrdt_update_i,      
      input   wire [11:0]  p1_tx_st_dcrdt_update_cnt_i,  
      output  wire [2:0]   p1_tx_st_dcrdt_init_ack_o,  
      
      output  wire [127:0] p1_tx_st0_hdr_o, //      
      output  wire [31:0]  p1_tx_st0_prefix_o, //   
      output  wire         p1_tx_st0_hvalid_o,    //
      output  wire         p1_tx_st0_pvalid_o,  //  
      
      output  wire [127:0] p1_tx_st1_hdr_o,       
      output  wire [31:0]  p1_tx_st1_prefix_o,    
      output  wire         p1_tx_st1_hvalid_o,    
      output  wire         p1_tx_st1_pvalid_o,    
      
      input wire          p1_tx_st0_ready_i, //
      
      output wire [BITS_PER_SEG-1:0] p1_tx_st0_data_o, //   
      output wire         p1_tx_st0_sop_o, //   
      output wire         p1_tx_st0_eop_o, //    
      output wire         p1_tx_st0_dvalid_o,// 
      
      output wire [BITS_PER_SEG-1:0] p1_tx_st1_data_o,   
      output wire         p1_tx_st1_sop_o,    
      output wire         p1_tx_st1_eop_o,    
      output wire         p1_tx_st1_dvalid_o, 

	
	  output  wire       p2_rx_st_ready_o,  
      input wire [BITS_PER_SEG-1:0] p2_rx_st0_data_i,        
      input wire         p2_rx_st0_sop_i,         
      input wire         p2_rx_st0_eop_i,         
      input wire         p2_rx_st0_dvalid_i,      
      input wire [EMPTY_BIT_SIZE:0]   p2_rx_st0_empty_i, 
      
      input wire [BITS_PER_SEG-1:0] p2_rx_st1_data_i,     
      input wire         p2_rx_st1_sop_i,      
      input wire         p2_rx_st1_eop_i,      
      input wire         p2_rx_st1_dvalid_i,   
      input wire [EMPTY_BIT_SIZE:0]   p2_rx_st1_empty_i,
      
      input wire [127:0] p2_rx_st0_hdr_i,           
      input wire [31:0]  p2_rx_st0_prefix_i,      
      input wire         p2_rx_st0_hvalid_i,      
      input wire         p2_rx_st0_pvalid_i,      
      input wire [2:0]   p2_rx_st0_bar_i,         
//      input wire         p2_rx_st0_pt_parity_i,
      
      input wire [127:0] p2_rx_st1_hdr_i,         
      input wire [31:0]  p2_rx_st1_prefix_i,      
      input wire         p2_rx_st1_hvalid_i,      
      input wire         p2_rx_st1_pvalid_i,      
      input wire [2:0]   p2_rx_st1_bar_i,         
//      input wire         p2_rx_st1_pt_parity_i,
      
      //HIP Crdt Intf
      
       // rx header credit
      output  wire [2:0]   p2_rx_st_hcrdt_init_o,        
      output  wire [2:0]   p2_rx_st_hcrdt_update_o,      
      output  wire [5:0]   p2_rx_st_hcrdt_update_cnt_o,  
      input   wire [2:0]   p2_rx_st_hcrdt_init_ack_i,    
      
	   // rx data credip2
      output  wire [2:0]   p2_rx_st_dcrdt_init_o,        
      output  wire [2:0]   p2_rx_st_dcrdt_update_o,      
      output  wire [11:0]  p2_rx_st_dcrdt_update_cnt_o,  
      input   wire [2:0]   p2_rx_st_dcrdt_init_ack_i,    
      
      // Tx interface
      
       //HIP Crdt Intf
      
      // tx header credit  p2
      input   wire [2:0]   p2_tx_st_hcrdt_init_i,        
      input   wire [2:0]   p2_tx_st_hcrdt_update_i,      
      input   wire [5:0]   p2_tx_st_hcrdt_update_cnt_i,  
      output  wire [2:0]   p2_tx_st_hcrdt_init_ack_o,    
      
      // tx data credit 
      input   wire [2:0]   p2_tx_st_dcrdt_init_i,        
      input   wire [2:0]   p2_tx_st_dcrdt_update_i,      
      input   wire [11:0]  p2_tx_st_dcrdt_update_cnt_i,  
      output  wire [2:0]   p2_tx_st_dcrdt_init_ack_o,  
      
      output  wire [127:0] p2_tx_st0_hdr_o,      
      output  wire [31:0]  p2_tx_st0_prefix_o,   
      output  wire         p2_tx_st0_hvalid_o,
      output  wire         p2_tx_st0_pvalid_o,  
      
      output  wire [127:0] p2_tx_st1_hdr_o,       
      output  wire [31:0]  p2_tx_st1_prefix_o,    
      output  wire         p2_tx_st1_hvalid_o,    
      output  wire         p2_tx_st1_pvalid_o,    
      
      input wire          p2_tx_st0_ready_i, 
      
      output wire [BITS_PER_SEG-1:0] p2_tx_st0_data_o,   
      output wire         p2_tx_st0_sop_o,    
      output wire         p2_tx_st0_eop_o,     
      output wire         p2_tx_st0_dvalid_o, 
      
      output wire [BITS_PER_SEG-1:0] p2_tx_st1_data_o,   
      output wire         p2_tx_st1_sop_o,    
      output wire         p2_tx_st1_eop_o,    
      output wire         p2_tx_st1_dvalid_o, 
	  
	  ////////////////////////////////////////////////////
	  
	  output  wire       p3_rx_st_ready_o,  
      input wire [BITS_PER_SEG-1:0] p3_rx_st0_data_i,        
      input wire         p3_rx_st0_sop_i,         
      input wire         p3_rx_st0_eop_i,         
      input wire         p3_rx_st0_dvalid_i,      
      input wire [EMPTY_BIT_SIZE:0]   p3_rx_st0_empty_i, 
      
      input wire [BITS_PER_SEG-1:0] p3_rx_st1_data_i,     
      input wire         p3_rx_st1_sop_i,      
      input wire         p3_rx_st1_eop_i,      
      input wire         p3_rx_st1_dvalid_i,   
      input wire [EMPTY_BIT_SIZE:0]   p3_rx_st1_empty_i,
      
      input wire [127:0] p3_rx_st0_hdr_i,           
      input wire [31:0]  p3_rx_st0_prefix_i,      
      input wire         p3_rx_st0_hvalid_i,      
      input wire         p3_rx_st0_pvalid_i,      
      input wire [2:0]   p3_rx_st0_bar_i,         
//      input wire         p3_rx_st0_pt_parity_i,
      
      input wire [127:0] p3_rx_st1_hdr_i,         
      input wire [31:0]  p3_rx_st1_prefix_i,      
      input wire         p3_rx_st1_hvalid_i,      
      input wire         p3_rx_st1_pvalid_i,      
      input wire [2:0]   p3_rx_st1_bar_i,         
//      input wire         p3_rx_st1_pt_parity_i,
      
      //HIP Crdt Intf
      
       // rx header credit
      output  wire [2:0]   p3_rx_st_hcrdt_init_o,        
      output  wire [2:0]   p3_rx_st_hcrdt_update_o,      
      output  wire [5:0]   p3_rx_st_hcrdt_update_cnt_o,  
      input   wire [2:0]   p3_rx_st_hcrdt_init_ack_i,    
      
	   // rx data credip3
      output  wire [2:0]   p3_rx_st_dcrdt_init_o,        
      output  wire [2:0]   p3_rx_st_dcrdt_update_o,      
      output  wire [11:0]  p3_rx_st_dcrdt_update_cnt_o,  
      input   wire [2:0]   p3_rx_st_dcrdt_init_ack_i,    
      
      // Tx interface
      
       //HIP Crdt Intf
      
      // tx header credit  p3
      input   wire [2:0]   p3_tx_st_hcrdt_init_i,        
      input   wire [2:0]   p3_tx_st_hcrdt_update_i,      
      input   wire [5:0]   p3_tx_st_hcrdt_update_cnt_i,  
      output  wire [2:0]   p3_tx_st_hcrdt_init_ack_o,    
      
      // tx data credit 
      input   wire [2:0]   p3_tx_st_dcrdt_init_i,        
      input   wire [2:0]   p3_tx_st_dcrdt_update_i,      
      input   wire [11:0]  p3_tx_st_dcrdt_update_cnt_i,  
      output  wire [2:0]   p3_tx_st_dcrdt_init_ack_o,  
      
      output  wire [127:0] p3_tx_st0_hdr_o,      
      output  wire [31:0]  p3_tx_st0_prefix_o,   
      output  wire         p3_tx_st0_hvalid_o,
      output  wire         p3_tx_st0_pvalid_o,  
      
      output  wire [127:0] p3_tx_st1_hdr_o,       
      output  wire [31:0]  p3_tx_st1_prefix_o,    
      output  wire         p3_tx_st1_hvalid_o,    
      output  wire         p3_tx_st1_pvalid_o,    
      
      input wire          p3_tx_st0_ready_i, 
      
      output wire [BITS_PER_SEG-1:0] p3_tx_st0_data_o,   
      output wire         p3_tx_st0_sop_o,    
      output wire         p3_tx_st0_eop_o,     
      output wire         p3_tx_st0_dvalid_o, 
      
      output wire [BITS_PER_SEG-1:0] p3_tx_st1_data_o,   
      output wire         p3_tx_st1_sop_o,    
      output wire         p3_tx_st1_eop_o,    
      output wire         p3_tx_st1_dvalid_o, 
	



   input  wire        coreclkout_hip,

    // Between CXL and PCIe
    input logic                         trace_valid_0,
    input logic                         trace_valid_1,
    input logic [511:0]                 trace_data_0,
    input logic [511:0]                 trace_data_1,
    input logic [63:0]                  trace_buffer_base_addr_0,
    input logic [63:0]                  trace_buffer_base_addr_1,
    input logic [63:0]                  trace_buffer_size_0,
    input logic [63:0]                  trace_buffer_size_1,
    input logic [63:0]                  control_register_0,
    input logic [63:0]                  control_register_1,
    output  logic [63:0]                  dropped_traces_0,
    output  logic [63:0]                  dropped_traces_1,
    output  logic [63:0]                  written_traces_0,
    output  logic [63:0]                  written_traces_1
	);


/////////////////////////////////////////////////////////////////////////////////	
	credit_info   p0_my_credit_info;
	
    credit_info   p1_my_credit_info;

    credit_info   p2_my_credit_info;
    credit_info   p3_my_credit_info;

	wire [NUM_SEG -1 :0]    				p0_rx_st_sop;   
	wire [NUM_SEG -1:0]                   	p0_rx_st_eop;   
	wire [BITS_PER_SEG*NUM_SEG -1:0] 		p0_rx_st_data;  
	wire [128*NUM_SEG -1:0]  	p0_rx_st_hdr;   
	wire [NUM_SEG -1:0]    					p0_rx_st_dvalid;
	wire [3*NUM_SEG -1:0]   				p0_rx_st_bar;   
	wire [32*NUM_SEG -1:0]  				p0_rx_st_prefix;
	wire [NUM_SEG -1:0]    					p0_rx_st_hvalid;
	wire [NUM_SEG -1:0]    					p0_rx_st_pvalid;
	wire [NUM_SEG -1:0]    					p0_tx_st_sop;    
	wire [NUM_SEG -1:0]    					p0_tx_st_eop;    
	wire [BITS_PER_SEG*NUM_SEG -1:0] 		p0_tx_st_data;   
	wire [128*NUM_SEG -1:0]  	p0_tx_st_hdr;    
	wire [NUM_SEG -1:0]    					p0_tx_st_dvalid; 
	wire [32*NUM_SEG -1:0]  				p0_tx_st_prefix; 
	wire [NUM_SEG -1:0]    					p0_tx_st_hvalid; 
	wire [NUM_SEG -1:0]    					p0_tx_st_pvalid;

    wire [NUM_SEG -1:0]    					p1_rx_st_sop;   
	wire [NUM_SEG -1:0]    					p1_rx_st_eop;   
	wire [BITS_PER_SEG*NUM_SEG -1:0] 				p1_rx_st_data;  
	wire [128*NUM_SEG -1:0]  	p1_rx_st_hdr;   
	wire [NUM_SEG -1:0]   					p1_rx_st_dvalid;
	wire [3*NUM_SEG -1:0]   				p1_rx_st_bar;   
	wire [32*NUM_SEG -1:0]  				p1_rx_st_prefix;
	wire [NUM_SEG -1:0]    					p1_rx_st_hvalid;
	wire [NUM_SEG -1:0]    					p1_rx_st_pvalid;
	wire [NUM_SEG -1:0]    					p1_tx_st_sop;    
	wire [NUM_SEG -1:0]    					p1_tx_st_eop;    
	wire [BITS_PER_SEG*NUM_SEG -1:0] 				p1_tx_st_data;   
	wire [128*NUM_SEG -1:0] 	p1_tx_st_hdr;    
	wire [NUM_SEG -1:0]    					p1_tx_st_dvalid; 
	wire [32*NUM_SEG -1:0]  				p1_tx_st_prefix; 
	wire [NUM_SEG -1:0]    					p1_tx_st_hvalid; 
	wire [NUM_SEG -1:0]    					p1_tx_st_pvalid;

	wire [NUM_SEG -1:0]    					p2_rx_st_sop;   
	wire [NUM_SEG -1:0]    					p2_rx_st_eop;   
	wire [BITS_PER_SEG*NUM_SEG -1:0] 		p2_rx_st_data;
	wire [128*NUM_SEG -1:0]  	p2_rx_st_hdr;
	wire [NUM_SEG -1:0]    					p2_rx_st_dvalid;
	wire [3*NUM_SEG -1:0]   				p2_rx_st_bar;   
	wire [32*NUM_SEG -1:0]  				p2_rx_st_prefix;
	wire [NUM_SEG -1:0]    					p2_rx_st_hvalid;
	wire [NUM_SEG -1:0]    					p2_rx_st_pvalid;
	
	wire [NUM_SEG -1:0]    					p3_rx_st_sop;   
	wire [NUM_SEG -1:0]    					p3_rx_st_eop;   
	wire [BITS_PER_SEG*NUM_SEG -1:0] 		p3_rx_st_data;
	wire [128*NUM_SEG -1:0]  	p3_rx_st_hdr;
	wire [NUM_SEG -1:0]    					p3_rx_st_dvalid;
	wire [3*NUM_SEG -1:0]   				p3_rx_st_bar;   
	wire [32*NUM_SEG -1:0]  				p3_rx_st_prefix;
	wire [NUM_SEG -1:0]    					p3_rx_st_hvalid;
	wire [NUM_SEG -1:0]    					p3_rx_st_pvalid;
	
	wire [NUM_SEG -1:0]    					p2_tx_st_sop;    
	wire [NUM_SEG -1:0]    					p2_tx_st_eop;    
	wire [BITS_PER_SEG*NUM_SEG -1:0] 		p2_tx_st_data;
	wire [128*NUM_SEG -1:0]  	p2_tx_st_hdr;
	wire [NUM_SEG -1:0]    					p2_tx_st_dvalid;
	wire [32*NUM_SEG -1:0]  				p2_tx_st_prefix; 
	wire [NUM_SEG -1:0]    					p2_tx_st_hvalid; 
	wire [NUM_SEG -1:0]    					p2_tx_st_pvalid;
	
	wire [NUM_SEG -1:0]    					p3_tx_st_sop;    
	wire [NUM_SEG -1:0]    					p3_tx_st_eop;    
	wire [BITS_PER_SEG*NUM_SEG -1:0] 		p3_tx_st_data;
	wire [128*NUM_SEG -1:0]  	p3_tx_st_hdr;
	wire [NUM_SEG -1:0]    					p3_tx_st_dvalid;
	wire [32*NUM_SEG -1:0]  				p3_tx_st_prefix; 
	wire [NUM_SEG -1:0]    					p3_tx_st_hvalid; 
	wire [NUM_SEG -1:0]    					p3_tx_st_pvalid;

	wire p0_np_cdts_ready;
	
	wire p1_np_cdts_ready;
	wire p2_np_cdts_ready;
	wire p3_np_cdts_ready;

	wire p0_p_cdts_ready;
	wire p1_p_cdts_ready;

	wire p2_p_cdts_ready;
	wire p3_p_cdts_ready;

    dma_cfg    p0_dma_wr_cfg;
    dma_cfg    p1_dma_wr_cfg;

    dma_cfg    p2_dma_wr_cfg;
    dma_cfg    p3_dma_wr_cfg;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////


    assign p0_rx_st_sop    = {p0_rx_st1_sop_i,p0_rx_st0_sop_i};             
	assign p0_rx_st_eop    = {p0_rx_st1_eop_i,p0_rx_st0_eop_i};             
	assign p0_rx_st_data   = {p0_rx_st1_data_i,p0_rx_st0_data_i};         
	assign p0_rx_st_hdr    = {p0_rx_st1_hdr_i,p0_rx_st0_hdr_i};             
	assign p0_rx_st_dvalid = {p0_rx_st1_dvalid_i,p0_rx_st0_dvalid_i}; 
	assign p0_rx_st_bar    = {p0_rx_st1_bar_i,p0_rx_st0_bar_i};             
	assign p0_rx_st_prefix = {p0_rx_st1_prefix_i,p0_rx_st0_prefix_i};    
	assign p0_rx_st_hvalid = {p0_rx_st1_hvalid_i,p0_rx_st0_hvalid_i}; 
	assign p0_rx_st_pvalid = {p0_rx_st1_pvalid_i,p0_rx_st0_pvalid_i};

	assign p1_rx_st_sop    = {p1_rx_st1_sop_i,   p1_rx_st0_sop_i};             
	assign p1_rx_st_eop    = {p1_rx_st1_eop_i,   p1_rx_st0_eop_i};             
	assign p1_rx_st_data   = {p1_rx_st1_data_i,  p1_rx_st0_data_i};         
	assign p1_rx_st_hdr    = {p1_rx_st1_hdr_i,   p1_rx_st0_hdr_i};             
	assign p1_rx_st_dvalid = {p1_rx_st1_dvalid_i,p1_rx_st0_dvalid_i}; 
	assign p1_rx_st_bar    = {p1_rx_st1_bar_i,   p1_rx_st0_bar_i};             
	assign p1_rx_st_prefix = {p1_rx_st1_prefix_i,p1_rx_st0_prefix_i};    
	assign p1_rx_st_hvalid = {p1_rx_st1_hvalid_i,p1_rx_st0_hvalid_i}; 
	assign p1_rx_st_pvalid = {p1_rx_st1_pvalid_i,p1_rx_st0_pvalid_i};

	assign p2_rx_st_sop    = {p2_rx_st1_sop_i,   p2_rx_st0_sop_i};             
	assign p2_rx_st_eop    = {p2_rx_st1_eop_i,   p2_rx_st0_eop_i};             
	assign p2_rx_st_data   = {p2_rx_st1_data_i,  p2_rx_st0_data_i};         
	assign p2_rx_st_hdr    = {p2_rx_st1_hdr_i,   p2_rx_st0_hdr_i};             
	assign p2_rx_st_dvalid = {p2_rx_st1_dvalid_i,p2_rx_st0_dvalid_i}; 
	assign p2_rx_st_bar    = {p2_rx_st1_bar_i,   p2_rx_st0_bar_i};             
	assign p2_rx_st_prefix = {p2_rx_st1_prefix_i,p2_rx_st0_prefix_i};    
	assign p2_rx_st_hvalid = {p2_rx_st1_hvalid_i,p2_rx_st0_hvalid_i}; 
	assign p2_rx_st_pvalid = {p2_rx_st1_pvalid_i,p2_rx_st0_pvalid_i};
	
	assign p3_rx_st_sop    = {p3_rx_st1_sop_i,   p3_rx_st0_sop_i};             
	assign p3_rx_st_eop    = {p3_rx_st1_eop_i,   p3_rx_st0_eop_i};             
	assign p3_rx_st_data   = {p3_rx_st1_data_i,  p3_rx_st0_data_i};         
	assign p3_rx_st_hdr    = {p3_rx_st1_hdr_i,   p3_rx_st0_hdr_i};             
	assign p3_rx_st_dvalid = {p3_rx_st1_dvalid_i,p3_rx_st0_dvalid_i}; 
	assign p3_rx_st_bar    = {p3_rx_st1_bar_i,   p3_rx_st0_bar_i};             
	assign p3_rx_st_prefix = {p3_rx_st1_prefix_i,p3_rx_st0_prefix_i};    
	assign p3_rx_st_hvalid = {p3_rx_st1_hvalid_i,p3_rx_st0_hvalid_i}; 
	assign p3_rx_st_pvalid = {p3_rx_st1_pvalid_i,p3_rx_st0_pvalid_i};	
	

    assign {p0_tx_st1_sop_o   ,p0_tx_st0_sop_o}       = p0_tx_st_sop;    
	assign {p0_tx_st1_eop_o   ,p0_tx_st0_eop_o}       = p0_tx_st_eop;    
	assign {p0_tx_st1_data_o  ,p0_tx_st0_data_o}      = p0_tx_st_data;   
	assign {p0_tx_st1_hdr_o   ,p0_tx_st0_hdr_o}       = p0_tx_st_hdr;    
	assign {p0_tx_st1_dvalid_o,p0_tx_st0_dvalid_o}    = p0_tx_st_dvalid; 
	assign {p0_tx_st1_prefix_o,p0_tx_st0_prefix_o}    = p0_tx_st_prefix; 
	assign {p0_tx_st1_hvalid_o,p0_tx_st0_hvalid_o}    = p0_tx_st_hvalid; 
	assign {p0_tx_st1_pvalid_o,p0_tx_st0_pvalid_o}    = p0_tx_st_pvalid;
	
	assign {p1_tx_st1_sop_o   ,p1_tx_st0_sop_o}       = p1_tx_st_sop;    
	assign {p1_tx_st1_eop_o   ,p1_tx_st0_eop_o}       = p1_tx_st_eop;    
	assign {p1_tx_st1_data_o  ,p1_tx_st0_data_o}      = p1_tx_st_data;   
	assign {p1_tx_st1_hdr_o   ,p1_tx_st0_hdr_o}       = p1_tx_st_hdr;    
	assign {p1_tx_st1_dvalid_o,p1_tx_st0_dvalid_o}    = p1_tx_st_dvalid; 
	assign {p1_tx_st1_prefix_o,p1_tx_st0_prefix_o}    = p1_tx_st_prefix; 
	assign {p1_tx_st1_hvalid_o,p1_tx_st0_hvalid_o}    = p1_tx_st_hvalid; 
	assign {p1_tx_st1_pvalid_o,p1_tx_st0_pvalid_o}    = p1_tx_st_pvalid;

    assign {p2_tx_st1_sop_o   ,p2_tx_st0_sop_o}       = p2_tx_st_sop;    
	assign {p2_tx_st1_eop_o   ,p2_tx_st0_eop_o}       = p2_tx_st_eop;    
	assign {p2_tx_st1_data_o  ,p2_tx_st0_data_o}      = p2_tx_st_data;   
	assign {p2_tx_st1_hdr_o   ,p2_tx_st0_hdr_o}       = p2_tx_st_hdr;    
	assign {p2_tx_st1_dvalid_o,p2_tx_st0_dvalid_o}    = p2_tx_st_dvalid; 
	assign {p2_tx_st1_prefix_o,p2_tx_st0_prefix_o}    = p2_tx_st_prefix; 
	assign {p2_tx_st1_hvalid_o,p2_tx_st0_hvalid_o}    = p2_tx_st_hvalid; 
	assign {p2_tx_st1_pvalid_o,p2_tx_st0_pvalid_o}    = p2_tx_st_pvalid;
	
	assign {p3_tx_st1_sop_o   ,p3_tx_st0_sop_o}       = p3_tx_st_sop;    
	assign {p3_tx_st1_eop_o   ,p3_tx_st0_eop_o}       = p3_tx_st_eop;    
	assign {p3_tx_st1_data_o  ,p3_tx_st0_data_o}      = p3_tx_st_data;   
	assign {p3_tx_st1_hdr_o   ,p3_tx_st0_hdr_o}       = p3_tx_st_hdr;    
	assign {p3_tx_st1_dvalid_o,p3_tx_st0_dvalid_o}    = p3_tx_st_dvalid; 
	assign {p3_tx_st1_prefix_o,p3_tx_st0_prefix_o}    = p3_tx_st_prefix; 
	assign {p3_tx_st1_hvalid_o,p3_tx_st0_hvalid_o}    = p3_tx_st_hvalid; 
	assign {p3_tx_st1_pvalid_o,p3_tx_st0_pvalid_o}    = p3_tx_st_pvalid;


    wire      p0_slw_reset_status_n;
    wire      slw_clk;
    wire [7:0]           p0_hip_reconfig_readdata_w;
	wire  [7:0]           p0_hip_reconfig_writedata_w;
    wire                 p0_hip_reconfig_readdatavalid_w;
    wire                 p0_hip_reconfig_waitrequest_w;
    wire [31:0]          p0_hip_reconfig_address_w;
    wire                  p0_hip_reconfig_write_w;
    wire                  p0_hip_reconfig_read_w;
	

assign p0_slw_reset_status_n = 'd0;
assign slw_clk = 'd0;
assign p0_hip_reconfig_readdata_w = 'd0;
assign p0_hip_reconfig_readdatavalid_w = 'd0;
assign p0_hip_reconfig_waitrequest_w =  'd0;



pioperf_user_app_top #(.PLD_CLK_FREQ(PLD_CLK_FREQ),.DEVICE_FAMILY(DEVICE_FAMILY),.LANE_MODE(LANE_MODE),.NUM_SEG(NUM_SEG), .BITS_PER_SEG(BITS_PER_SEG)) user_app_0 (
    .clk                (coreclkout_hip          ),
    .srstn              (p0_reset_status_n       ),
    .slow_clk           (slw_clk		 ),
    .slow_srstn         (p0_slw_reset_status_n	 ),
    .rx_st_sop_i        (p0_rx_st_sop            ), 
    .rx_st_eop_i        (p0_rx_st_eop            ), 
    .rx_st_data_i       (p0_rx_st_data           ), 
    .rx_st_header_i     (p0_rx_st_hdr            ), 
    .rx_st_dvalid_i     (p0_rx_st_dvalid         ),
    .rx_st_bar_range_i  (p0_rx_st_bar	         ),
    .rx_st_ready_o      (p0_rx_st_ready_o        ), 
    .rx_st_prefix_i     (p0_rx_st_prefix         ), 
    .rx_st_hvalid_i     (p0_rx_st_hvalid         ), 
    .rx_st_pvalid_i     (p0_rx_st_pvalid         ), 
    .tx_st_sop_o        (p0_tx_st_sop            ), 
    .tx_st_eop_o        (p0_tx_st_eop            ), 
    .tx_st_data_o       (p0_tx_st_data           ), 
    .tx_st_header_o     (p0_tx_st_hdr            ), 
    .tx_st_valid_o      (p0_tx_st_dvalid         ), 
    .tx_st_ready_i      (p0_tx_st0_ready_i       ),
    .tx_st_prefix_o     (p0_tx_st_prefix 		 ), 
    .tx_st_hvalid_o     (p0_tx_st_hvalid 		 ), 
    .tx_st_pvalid_o     (p0_tx_st_pvalid		 ),

    .hip_reconfig_readdata_i		(p0_hip_reconfig_readdata_w),
    .hip_reconfig_readdatavalid_i	(p0_hip_reconfig_readdatavalid_w),
    .hip_reconfig_waitrequest_i		(p0_hip_reconfig_waitrequest_w), 
    .hip_reconfig_address_o			(p0_hip_reconfig_address_w),
    .hip_reconfig_write_o			(p0_hip_reconfig_write_w),
    .hip_reconfig_writedata_o		(p0_hip_reconfig_writedata_w),
    .hip_reconfig_read_o			(p0_hip_reconfig_read_w),

    .my_credit_info     (p0_my_credit_info),
    .dma_wr_cfg_o		(p0_dma_wr_cfg),      
    .p_cdts_ready_i     (p0_p_cdts_ready),
    .np_cdts_ready_i    (p0_np_cdts_ready),

    // CSR <-> Trace Recorder
    .trace_valid                       ( trace_valid_0 ), // Output from CSR Top
    .trace_data                        ( trace_data_0 ), // Output from CSR Top
    .trace_buffer_base_addr            ( trace_buffer_base_addr_0 ), // Output from CSR Top
    .trace_buffer_size                 ( trace_buffer_size_0      ), // Output from CSR Top
    .control_register                  ( control_register_0       ), // Output from CSR Top
    .dropped_traces                    ( dropped_traces_0         ), // Input to CSR Top
    .written_traces                    ( written_traces_0         ) // Input to CSR Top

	
    );

pioperf_user_app_top #(.PLD_CLK_FREQ(PLD_CLK_FREQ),.DEVICE_FAMILY(DEVICE_FAMILY),.NUM_SEG(NUM_SEG),.BITS_PER_SEG(BITS_PER_SEG)) user_app_1 (
    .clk                (coreclkout_hip          ),
    .srstn              (p1_reset_status_n       ),
    .rx_st_sop_i        (p1_rx_st_sop            ), 
    .rx_st_eop_i        (p1_rx_st_eop            ), 
    .rx_st_data_i       (p1_rx_st_data           ), 
    .rx_st_header_i     (p1_rx_st_hdr            ), 
    .rx_st_dvalid_i     (p1_rx_st_dvalid         ), 
    .rx_st_bar_range_i  (p1_rx_st_bar	         ), 
    .rx_st_ready_o      (p1_rx_st_ready_o        ), 
    .rx_st_prefix_i     (p1_rx_st_prefix         ), 
    .rx_st_hvalid_i     (p1_rx_st_hvalid         ), 
    .rx_st_pvalid_i     (p1_rx_st_pvalid         ), 
    .tx_st_sop_o        (p1_tx_st_sop            ), 
    .tx_st_eop_o        (p1_tx_st_eop            ), 
    .tx_st_data_o       (p1_tx_st_data           ), 
    .tx_st_header_o     (p1_tx_st_hdr            ), 
    .tx_st_valid_o      (p1_tx_st_dvalid         ), 
    .tx_st_ready_i      (p1_tx_st0_ready_i        ),
    .tx_st_prefix_o     (p1_tx_st_prefix 		 ), 
    .tx_st_hvalid_o     (p1_tx_st_hvalid 		 ), 
    .tx_st_pvalid_o     (p1_tx_st_pvalid		 ),	
    .my_credit_info     (p1_my_credit_info),
    .dma_wr_cfg_o		(p1_dma_wr_cfg),      
    .p_cdts_ready_i     (p1_p_cdts_ready),
    .np_cdts_ready_i	(p1_np_cdts_ready)
	
    );
	



pioperf_user_app_top #(.PLD_CLK_FREQ(PLD_CLK_FREQ),.DEVICE_FAMILY(DEVICE_FAMILY),.NUM_SEG(NUM_SEG),.BITS_PER_SEG(BITS_PER_SEG)) user_app_2 (
    .clk                (coreclkout_hip          ),
    .srstn              (p2_reset_status_n       ),
    .rx_st_sop_i        (p2_rx_st_sop            ), 
    .rx_st_eop_i        (p2_rx_st_eop            ), 
    .rx_st_data_i       (p2_rx_st_data           ), 
    .rx_st_header_i     (p2_rx_st_hdr            ), 
    .rx_st_dvalid_i     (p2_rx_st_dvalid         ), 
    .rx_st_bar_range_i  (p2_rx_st_bar	         ), 
    .rx_st_ready_o      (p2_rx_st_ready_o        ), 
    .rx_st_prefix_i     (p2_rx_st_prefix         ), 
    .rx_st_hvalid_i     (p2_rx_st_hvalid         ), 
    .rx_st_pvalid_i     (p2_rx_st_pvalid         ), 
    .tx_st_sop_o        (p2_tx_st_sop            ), 
    .tx_st_eop_o        (p2_tx_st_eop            ), 
    .tx_st_data_o       (p2_tx_st_data           ), 
    .tx_st_header_o     (p2_tx_st_hdr            ), 
    .tx_st_valid_o      (p2_tx_st_dvalid         ), 
    .tx_st_ready_i      (p2_tx_st0_ready_i        ),
    .tx_st_prefix_o     (p2_tx_st_prefix 		 ), 
    .tx_st_hvalid_o     (p2_tx_st_hvalid 		 ), 
    .tx_st_pvalid_o     (p2_tx_st_pvalid		 ),	
    .my_credit_info     (p2_my_credit_info),
    .dma_wr_cfg_o		(p2_dma_wr_cfg),      
    .p_cdts_ready_i     (p2_p_cdts_ready),
    .np_cdts_ready_i	(p2_np_cdts_ready),

    // CSR <-> Trace Recorder
    .trace_valid                       ( trace_valid_1 ), // Output from CSR Top
    .trace_data                        ( trace_data_1 ), // Output from CSR Top
    .trace_buffer_base_addr            ( trace_buffer_base_addr_1 ), // Output from CSR Top
    .trace_buffer_size                 ( trace_buffer_size_1      ), // Output from CSR Top
    .control_register                  ( control_register_1       ), // Output from CSR Top
    .dropped_traces                    ( dropped_traces_1         ), // Input to CSR Top
    .written_traces                    ( written_traces_1         ) // Input to CSR Top

    );
	
pioperf_user_app_top #(.PLD_CLK_FREQ(PLD_CLK_FREQ),.DEVICE_FAMILY(DEVICE_FAMILY),.NUM_SEG(NUM_SEG),.BITS_PER_SEG(BITS_PER_SEG)) user_app_3 (
    .clk                (coreclkout_hip          ),
    .srstn              (p3_reset_status_n       ),
    .rx_st_sop_i        (p3_rx_st_sop            ), 
    .rx_st_eop_i        (p3_rx_st_eop            ), 
    .rx_st_data_i       (p3_rx_st_data           ), 
    .rx_st_header_i     (p3_rx_st_hdr            ), 
    .rx_st_dvalid_i     (p3_rx_st_dvalid         ), 
    .rx_st_bar_range_i  (p3_rx_st_bar	         ), 
    .rx_st_ready_o      (p3_rx_st_ready_o        ), 
    .rx_st_prefix_i     (p3_rx_st_prefix         ), 
    .rx_st_hvalid_i     (p3_rx_st_hvalid         ), 
    .rx_st_pvalid_i     (p3_rx_st_pvalid         ), 
    .tx_st_sop_o        (p3_tx_st_sop            ), 
    .tx_st_eop_o        (p3_tx_st_eop            ), 
    .tx_st_data_o       (p3_tx_st_data           ), 
    .tx_st_header_o     (p3_tx_st_hdr            ), 
    .tx_st_valid_o      (p3_tx_st_dvalid         ), 
    .tx_st_ready_i      (p3_tx_st0_ready_i        ),
    .tx_st_prefix_o     (p3_tx_st_prefix 		 ), 
    .tx_st_hvalid_o     (p3_tx_st_hvalid 		 ), 
    .tx_st_pvalid_o     (p3_tx_st_pvalid		 ),	
    .my_credit_info     (p3_my_credit_info),
    .dma_wr_cfg_o		(p3_dma_wr_cfg),      
    .p_cdts_ready_i     (p3_p_cdts_ready),
    .np_cdts_ready_i	(p3_np_cdts_ready)
    );
	
       
intel_pcie_bam_v2_crdt_intf crdt_intf_0 (
 .clk(coreclkout_hip),
 .rst_n(p0_reset_status_n),
 
 .rx_st_hcrdt_update_o(p0_rx_st_hcrdt_update_o),
 .rx_st_hcrdt_update_cnt_o(p0_rx_st_hcrdt_update_cnt_o),
 .rx_st_hcrdt_init_o(p0_rx_st_hcrdt_init_o),
 .rx_st_hcrdt_init_ack_i(p0_rx_st_hcrdt_init_ack_i),
 
 .rx_st_dcrdt_update_o(p0_rx_st_dcrdt_update_o),
 .rx_st_dcrdt_update_cnt_o(p0_rx_st_dcrdt_update_cnt_o),
 .rx_st_dcrdt_init_o(p0_rx_st_dcrdt_init_o),
 .rx_st_dcrdt_init_ack_i(p0_rx_st_dcrdt_init_ack_i),
 
 .tx_st_hcrdt_update_i(p0_tx_st_hcrdt_update_i),
 .tx_st_hcrdt_update_cnt_i(p0_tx_st_hcrdt_update_cnt_i),
 .tx_st_hcrdt_init_i(p0_tx_st_hcrdt_init_i),
 .tx_st_hcrdt_init_ack_o(p0_tx_st_hcrdt_init_ack_o),
 
 .tx_st_dcrdt_update_i(p0_tx_st_dcrdt_update_i),
 .tx_st_dcrdt_update_cnt_i(p0_tx_st_dcrdt_update_cnt_i),
 .tx_st_dcrdt_init_i(p0_tx_st_dcrdt_init_i),
 .tx_st_dcrdt_init_ack_o(p0_tx_st_dcrdt_init_ack_o),
 
 .rx_hdr_len_i(p0_my_credit_info.hdr_len_i),
 .rx_hdr_valid_i(p0_my_credit_info.hdr_valid_i),
 .rx_hdr_is_rd_i(p0_my_credit_info.hdr_is_rd_i),
 .rx_hdr_is_wr_i(p0_my_credit_info.hdr_is_wr_i),
 .rx_hdr_is_cpl_i(p0_my_credit_info.hdr_is_cpl_i),
 .rx_st_ready_i(p0_my_credit_info.bam_rx_signal_ready_i),

 
 .tx_hdr_len_i(p0_my_credit_info.tx_hdr_i),
 .tx_hdr_valid_i(p0_my_credit_info.tx_hdr_valid_i),
 .tx_hdr_type_i (p0_my_credit_info.tx_hdr_type_i), 
.tx_p_payload_i (p0_dma_wr_cfg.payload),
  
 
 .p_cdts_ready_o     (p0_p_cdts_ready),
 .np_cdts_ready_o    (p0_np_cdts_ready),
 .cpl_cdts_ready_o   ()												
 													
 );


 intel_pcie_bam_v2_crdt_intf crdt_intf_1 (
 .clk							(coreclkout_hip),
 .rst_n							(p1_reset_status_n),
// 
 .rx_st_hcrdt_update_o			(p1_rx_st_hcrdt_update_o),
 .rx_st_hcrdt_update_cnt_o		(p1_rx_st_hcrdt_update_cnt_o),
 .rx_st_hcrdt_init_o			(p1_rx_st_hcrdt_init_o),
 .rx_st_hcrdt_init_ack_i		(p1_rx_st_hcrdt_init_ack_i),
//
 .rx_st_dcrdt_update_o			(p1_rx_st_dcrdt_update_o),
 .rx_st_dcrdt_update_cnt_o		(p1_rx_st_dcrdt_update_cnt_o),
 .rx_st_dcrdt_init_o			(p1_rx_st_dcrdt_init_o),
 .rx_st_dcrdt_init_ack_i		(p1_rx_st_dcrdt_init_ack_i),
// 
 .tx_st_hcrdt_update_i			(p1_tx_st_hcrdt_update_i),
 .tx_st_hcrdt_update_cnt_i		(p1_tx_st_hcrdt_update_cnt_i),
 .tx_st_hcrdt_init_i			(p1_tx_st_hcrdt_init_i),
 .tx_st_hcrdt_init_ack_o		(p1_tx_st_hcrdt_init_ack_o),
// 
 .tx_st_dcrdt_update_i			(p1_tx_st_dcrdt_update_i),
 .tx_st_dcrdt_update_cnt_i		(p1_tx_st_dcrdt_update_cnt_i),
 .tx_st_dcrdt_init_i			(p1_tx_st_dcrdt_init_i),
 .tx_st_dcrdt_init_ack_o		(p1_tx_st_dcrdt_init_ack_o),
// 
 .rx_hdr_len_i					(p1_my_credit_info.hdr_len_i),
 .rx_hdr_valid_i				(p1_my_credit_info.hdr_valid_i),
 .rx_hdr_is_rd_i				(p1_my_credit_info.hdr_is_rd_i),
 .rx_hdr_is_wr_i				(p1_my_credit_info.hdr_is_wr_i),
 .rx_hdr_is_cpl_i				(p1_my_credit_info.hdr_is_cpl_i),
 .rx_st_ready_i					(p1_my_credit_info.bam_rx_signal_ready_i),
// 
 .tx_hdr_len_i					(p1_my_credit_info.tx_hdr_i),
 .tx_hdr_valid_i				(p1_my_credit_info.tx_hdr_valid_i),
 .tx_hdr_type_i 				(p1_my_credit_info.tx_hdr_type_i), 
 .tx_p_payload_i 				(p1_dma_wr_cfg.payload),
//  
 .p_cdts_ready_o     			(p1_p_cdts_ready),
 .np_cdts_ready_o    			(p1_np_cdts_ready),
 .cpl_cdts_ready_o   			()																									
 );



intel_pcie_bam_v2_crdt_intf crdt_intf_2 (
 .clk							(coreclkout_hip),
 .rst_n							(p2_reset_status_n),
//                                
 .rx_st_hcrdt_update_o			(p2_rx_st_hcrdt_update_o),
 .rx_st_hcrdt_update_cnt_o		(p2_rx_st_hcrdt_update_cnt_o),
 .rx_st_hcrdt_init_o			(p2_rx_st_hcrdt_init_o),
 .rx_st_hcrdt_init_ack_i		(p2_rx_st_hcrdt_init_ack_i),
//                                
 .rx_st_dcrdt_update_o			(p2_rx_st_dcrdt_update_o),
 .rx_st_dcrdt_update_cnt_o		(p2_rx_st_dcrdt_update_cnt_o),
 .rx_st_dcrdt_init_o			(p2_rx_st_dcrdt_init_o),
 .rx_st_dcrdt_init_ack_i		(p2_rx_st_dcrdt_init_ack_i),
//                                
 .tx_st_hcrdt_update_i			(p2_tx_st_hcrdt_update_i),
 .tx_st_hcrdt_update_cnt_i		(p2_tx_st_hcrdt_update_cnt_i),
 .tx_st_hcrdt_init_i			(p2_tx_st_hcrdt_init_i),
 .tx_st_hcrdt_init_ack_o		(p2_tx_st_hcrdt_init_ack_o),
//                                
 .tx_st_dcrdt_update_i			(p2_tx_st_dcrdt_update_i),
 .tx_st_dcrdt_update_cnt_i		(p2_tx_st_dcrdt_update_cnt_i),
 .tx_st_dcrdt_init_i			(p2_tx_st_dcrdt_init_i),
 .tx_st_dcrdt_init_ack_o		(p2_tx_st_dcrdt_init_ack_o),
//                                
 .rx_hdr_len_i					(p2_my_credit_info.hdr_len_i),
 .rx_hdr_valid_i				(p2_my_credit_info.hdr_valid_i),
 .rx_hdr_is_rd_i				(p2_my_credit_info.hdr_is_rd_i),
 .rx_hdr_is_wr_i				(p2_my_credit_info.hdr_is_wr_i),
 .rx_hdr_is_cpl_i				(p2_my_credit_info.hdr_is_cpl_i),
 .rx_st_ready_i					(p2_my_credit_info.bam_rx_signal_ready_i),
//                                
 .tx_hdr_len_i					(p2_my_credit_info.tx_hdr_i),
 .tx_hdr_valid_i				(p2_my_credit_info.tx_hdr_valid_i),
 .tx_hdr_type_i 				(p2_my_credit_info.tx_hdr_type_i), 
 .tx_p_payload_i 				(p2_dma_wr_cfg.payload),
//                                
 .p_cdts_ready_o     			(p2_p_cdts_ready),
 .np_cdts_ready_o    			(p2_np_cdts_ready),
 .cpl_cdts_ready_o   			()																									
 );
 
intel_pcie_bam_v2_crdt_intf crdt_intf_3 (
 .clk							(coreclkout_hip),
 .rst_n							(p3_reset_status_n),
//                                
 .rx_st_hcrdt_update_o			(p3_rx_st_hcrdt_update_o),
 .rx_st_hcrdt_update_cnt_o		(p3_rx_st_hcrdt_update_cnt_o),
 .rx_st_hcrdt_init_o			(p3_rx_st_hcrdt_init_o),
 .rx_st_hcrdt_init_ack_i		(p3_rx_st_hcrdt_init_ack_i),
//                                
 .rx_st_dcrdt_update_o			(p3_rx_st_dcrdt_update_o),
 .rx_st_dcrdt_update_cnt_o		(p3_rx_st_dcrdt_update_cnt_o),
 .rx_st_dcrdt_init_o			(p3_rx_st_dcrdt_init_o),
 .rx_st_dcrdt_init_ack_i		(p3_rx_st_dcrdt_init_ack_i),
//                                
 .tx_st_hcrdt_update_i			(p3_tx_st_hcrdt_update_i),
 .tx_st_hcrdt_update_cnt_i		(p3_tx_st_hcrdt_update_cnt_i),
 .tx_st_hcrdt_init_i			(p3_tx_st_hcrdt_init_i),
 .tx_st_hcrdt_init_ack_o		(p3_tx_st_hcrdt_init_ack_o),
//                                
 .tx_st_dcrdt_update_i			(p3_tx_st_dcrdt_update_i),
 .tx_st_dcrdt_update_cnt_i		(p3_tx_st_dcrdt_update_cnt_i),
 .tx_st_dcrdt_init_i			(p3_tx_st_dcrdt_init_i),
 .tx_st_dcrdt_init_ack_o		(p3_tx_st_dcrdt_init_ack_o),
//                                
 .rx_hdr_len_i					(p3_my_credit_info.hdr_len_i),
 .rx_hdr_valid_i				(p3_my_credit_info.hdr_valid_i),
 .rx_hdr_is_rd_i				(p3_my_credit_info.hdr_is_rd_i),
 .rx_hdr_is_wr_i				(p3_my_credit_info.hdr_is_wr_i),
 .rx_hdr_is_cpl_i				(p3_my_credit_info.hdr_is_cpl_i),
 .rx_st_ready_i					(p3_my_credit_info.bam_rx_signal_ready_i),
//                                
 .tx_hdr_len_i					(p3_my_credit_info.tx_hdr_i),
 .tx_hdr_valid_i				(p3_my_credit_info.tx_hdr_valid_i),
 .tx_hdr_type_i 				(p3_my_credit_info.tx_hdr_type_i), 
 .tx_p_payload_i 				(p3_dma_wr_cfg.payload),
//                                
 .p_cdts_ready_o     			(p3_p_cdts_ready),
 .np_cdts_ready_o    			(p3_np_cdts_ready),
 .cpl_cdts_ready_o   			()																									
 );
 

endmodule		

