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


// Copyright 2023 Intel Corporation.
//
// THIS SOFTWARE MAY CONTAIN PREPRODUCTION CODE AND IS PROVIDED BY THE
// COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
// WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
// OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
// EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//`include "cxl_ed_defines.svh.iv"
`include "cxl_typ3ddr_ed_defines.svh.iv"

import cxlip_top_pkg::*;

module afu_top
(
    input  logic                         afu_clk,
    input  logic                         afu_rstn,
    // AXI4 signals
    input mc_axi_if_pkg::t_to_mc_axi4    [MC_CHANNEL-1:0] cxlip2iafu_to_mc_axi4,
    output mc_axi_if_pkg::t_to_mc_axi4   [MC_CHANNEL-1:0] iafu2mc_to_mc_axi4 ,
    input mc_axi_if_pkg::t_from_mc_axi4  [MC_CHANNEL-1:0] mc2iafu_from_mc_axi4,
    output mc_axi_if_pkg::t_from_mc_axi4 [MC_CHANNEL-1:0] iafu2cxlip_from_mc_axi4,
    
    // Interface to custom AFU for trace data - split per channel
    output logic                         trace_valid_0, // Valid signal for channel 0 trace
    output logic [511:0]                 trace_data_0,  // Trace data for channel 0 (Read+Write)
    output logic                         trace_valid_1, // Valid signal for channel 1 trace
    output logic [511:0]                 trace_data_1   // Trace data for channel 1 (Read+Write)
);
    // Pass through signals
    assign iafu2mc_to_mc_axi4      = cxlip2iafu_to_mc_axi4;
    assign iafu2cxlip_from_mc_axi4 = mc2iafu_from_mc_axi4;

    // Timestamp counter
    logic [63:0] timestamp_counter;
    always_ff @(posedge afu_clk or negedge afu_rstn) begin
        if (!afu_rstn)
            timestamp_counter <= 64'd0;
        else
            timestamp_counter <= timestamp_counter + 64'd1;
    end
    
    // Operation type encoding
    localparam OP_READ = 1'b0;
    localparam OP_WRITE = 1'b1;
    
    // Generate trace records for all channels
    // Each record is 128 bits: {timestamp[63:0], valid[0], op_type[0], padding[9:0], addr[51:0]}
    logic [MC_CHANNEL-1:0][127:0] read_records;
    logic [MC_CHANNEL-1:0][127:0] write_records;
    
    // Generate one record for each channel's read and write
    generate
        for (genvar i = 0; i < MC_CHANNEL; i++) begin : channel_trace_gen
            // Detect valid transactions during handshake
            logic read_valid, write_valid;
            assign read_valid = cxlip2iafu_to_mc_axi4[i].arvalid && mc2iafu_from_mc_axi4[i].arready;
            assign write_valid = cxlip2iafu_to_mc_axi4[i].awvalid && mc2iafu_from_mc_axi4[i].awready;
            
            // Create read record - set valid bit if transaction is valid
            always_comb begin
                read_records[i][63:0] = {
                    // Valid bit (MSB) - Indicates if this specific AXI transaction was valid this cycle
                    read_valid, 
                    // Operation type (1 bit)
                    OP_READ,
                    // 10 bits of padding (Original had 10'h3ff - all 1s)
                    10'h3ff, 
                    // Address (52 bits)
                    cxlip2iafu_to_mc_axi4[i].araddr[51:0]
                };
                read_records[i][127:64] = timestamp_counter; // Timestamp
            end
            
            // Create write record - set valid bit if transaction is valid
            always_comb begin
                write_records[i][63:0] = {
                    // Valid bit (MSB) - Indicates if this specific AXI transaction was valid this cycle
                    write_valid, 
                    // Operation type (1 bit)
                    OP_WRITE,
                     // 10 bits of padding (Original had 10'h3ff - all 1s)
                    10'h3ff,
                    // Address (52 bits)
                    cxlip2iafu_to_mc_axi4[i].awaddr[51:0]
                };
                write_records[i][127:64] = timestamp_counter; // Timestamp
            end
        end
    endgenerate
    
    // Registered trace outputs
    logic trace_valid_0_r, trace_valid_1_r;
    logic [511:0] trace_data_0_r, trace_data_1_r;
    
    always_ff @(posedge afu_clk or negedge afu_rstn) begin
        if (!afu_rstn) begin
            trace_valid_0_r <= 1'b0;
            trace_valid_1_r <= 1'b0;
            trace_data_0_r <= 512'b0;
            trace_data_1_r <= 512'b0;
        end else begin
            trace_valid_0_r <= 1'b1;
            trace_valid_1_r <= 1'b1;
            trace_data_0_r <= {
                write_records[0], read_records[0],
                write_records[1], read_records[1]
            };
            trace_data_1_r <= {
                write_records[0], read_records[0],
                write_records[1], read_records[1]
            };
        end
    end
    
    assign trace_valid_0 = trace_valid_0_r;
    assign trace_valid_1 = trace_valid_1_r;
    assign trace_data_0 = trace_data_0_r;
    assign trace_data_1 = trace_data_1_r;

    endmodule
