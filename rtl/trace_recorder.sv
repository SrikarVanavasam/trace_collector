`timescale 1 ns / 1 ps
`include "include_h.sv"
module trace_recorder #(
  parameter NUM_SEG            = 2,            // Number of TLP segments
  parameter BITS_PER_SEG       = 'd128,        // Bits per TLP segment
  parameter TRACE_RECORDS      = 4,            // Number of 128-bit trace records
  parameter TRACE_FIFO_DEPTH   = 64            // Depth of trace buffer
  ) (
    input clk,
    input srstn,

    input completion_info    cpl_info_i,      // RX_intf command
    input  dma_cfg           dma_wr_cfg_i,    // Configuration (kept for compatibility)
    output dma_info          dma_wr_info_o,   // Status output

    // TLP output interface
    output   [NUM_SEG-1 : 0] tlp_dvalid_o,
      output   [NUM_SEG-1 : 0] tlp_sop_o,
      output   [NUM_SEG-1 : 0] tlp_eop_o,
      output   [128*NUM_SEG-1 : 0] tlp_hdr_o,
      output   [BITS_PER_SEG*NUM_SEG-1 : 0] tlp_data_o,
      input    tlp_ready_i,

      input    p_cdts_ready_i,
      input    link_info link_info_i,

      // Trace input interface
      input logic trace_valid,
        input logic [128*TRACE_RECORDS-1:0] trace_data,
        input  logic [63:0]                  trace_buffer_base_addr,
        input  logic [63:0]                  trace_buffer_size,
        input  logic [63:0]                  control_register,
        output logic [63:0]                  dropped_traces,
        output logic [63:0]                  written_traces
        );

        // Link info
        link_info my_link_info;
        assign my_link_info = link_info_i;

        // Control register bits
        // Bit 0: Start recording
        // Bit 1: Abort current recording
        // Bit 2: Reset after buffer full (software reset signal)
        // Bit 3: Clear counters
        logic ctrl_start;
        logic ctrl_abort;
        logic ctrl_reset;

        // State machine
        enum int unsigned {IDLE = 0, SOP = 2, WAIT = 3, EOP = 5, BUFFER_FULL = 7} state;

        // Simplified control register decoding and registration
        always_ff @(posedge clk) begin
          if (!srstn) begin
            ctrl_start <= 1'b0;
            ctrl_abort <= 1'b0;
            ctrl_reset <= 1'b0;
        end else begin
          ctrl_start <= control_register[0];
          ctrl_abort <= control_register[1];
          ctrl_reset <= control_register[2];
        end
      end

      // State machine and counter signals
      logic [63:0] tlp_cnt_init, tlp_cnt;
      logic [63:0] beat_cnt_init, beat_cnt;

      // Full 64-bit address counter to support buffers > 4GB
      logic [63:0] addr_64bit;

      // TLP output signals
      logic [NUM_SEG-1:0] tlp_dvalid, tlp_sop, tlp_eop;
      logic [BITS_PER_SEG * NUM_SEG-1 : 0] tlp_data;
      logic [128 - 1 : 0] header0, header1;
      logic [31:0] low_addr0, low_addr1;
      logic [9:0] tlp_len;

      // Constants for 512B payload
      localparam TLP_DATA_WIDTH = NUM_SEG * BITS_PER_SEG;
      localparam RECORDS_PER_TLP = (512 * 8) / 128;  // 512B * 8bits/B / 128bits/record = 32 records

      // How many records we need per transfer cycle
      localparam RECORDS_PER_BEAT = TLP_DATA_WIDTH / 128; // 128 bits per record

      // Trace buffer interface
      logic buffer_full;
      logic dequeue_en;
      logic [$clog2(RECORDS_PER_BEAT+1)-1:0] dequeue_count;
      logic [128*RECORDS_PER_BEAT-1:0] dequeue_data;
      logic dequeue_valid;
      logic [$clog2(TRACE_FIFO_DEPTH+1)-1:0] available_count;

      // Trace counters for tracking written and dropped traces
      logic [63:0] written_count;
      logic [63:0] dropped_count;
      logic [TRACE_RECORDS-1:0] valid_record_mask; // To track valid records in each beat

      // Generate valid record mask by checking valid bit at bit position 63 of each record
      always_comb begin
        for (int i = 0; i < TRACE_RECORDS; i++) begin
          valid_record_mask[i] = trace_valid && trace_data[i*128 + 63];
        end
      end

      // Count valid records in the input trace data
      logic [5:0] valid_trace_count;
      always_comb begin
        valid_trace_count = 0;
        for (int i = 0; i < TRACE_RECORDS; i++) begin
          if (valid_record_mask[i]) begin
            valid_trace_count++;
          end
        end
      end

      // Counter for traces written and dropped
      always_ff @(posedge clk) begin
        if (!srstn) begin
          written_count <= '0;
          dropped_count <= '0;
        end else if (ctrl_reset) begin
          written_count <= '0;
          dropped_count <= '0;
        end else begin
          if (ctrl_start && state != BUFFER_FULL && dequeue_en) begin
            written_count <= written_count + dequeue_count;
          end
          if (ctrl_start && (buffer_full || state == BUFFER_FULL) &&
            trace_valid && valid_trace_count > 0) begin
            dropped_count <= dropped_count + valid_trace_count;
          end
        end
      end
      // Assign counter outputs
      assign written_traces = written_count;
      assign dropped_traces = dropped_count;

      // Trace buffer instantiation
      trace_buffer #(
        .FIFO_DEPTH(TRACE_FIFO_DEPTH),
        .RECORD_WIDTH(128),
        .MAX_ENQUEUE(TRACE_RECORDS),
        .MAX_DEQUEUE(RECORDS_PER_BEAT ),
        .VALID_BIT_POS(63)
        ) trace_buffer_inst (
          .clk(clk),
          .reset_n(srstn && ctrl_start),
          .trace_valid(trace_valid),
          .trace_data(trace_data),
          .fifo_full(buffer_full),
          .dequeue_en(dequeue_en),
          .dequeue_count(dequeue_count),
          .dequeue_data(dequeue_data),
          .dequeue_valid(dequeue_valid),
          .available_count(available_count)
          );

          // Status output
          assign dma_wr_info_o.status = state;
          assign dma_wr_info_o.perf = '0;  // No performance measurement

          // TLP headers - Always use 512B payload (128 DW)
          // Full 64-bit address handling
          assign tlp_len = 10'd128;  // Fixed at 128 DW (512B)

          // Dynamically calculate headers with full 64-bit addressing using new trace_buffer_base_addr
          logic [63:0] calculated_addr;
          assign calculated_addr = trace_buffer_base_addr + (addr_64bit << 9); // Base addr + offset (512B aligned)

          assign low_addr0 = calculated_addr[31:0];
          assign header0 = {8'h60, 1'b0, 3'b0, 1'b0, 9'h0, tlp_len, my_link_info.bdf, 8'h00, 8'hFF,
            calculated_addr[63:32], low_addr0};

            // In this implementation we only use header0 for addressing
            assign low_addr1 = 32'h0;
            assign header1 = {8'h60, 1'b0, 3'b0, 1'b0, 9'h0, tlp_len, my_link_info.bdf, 8'h00, 8'hFF,
              32'h0, low_addr1};

              // TLP output assignments
              assign tlp_dvalid_o = tlp_dvalid;
              assign tlp_sop_o = tlp_sop;
              assign tlp_eop_o = tlp_eop;

              // Format TLP headers according to segment configuration
              if (NUM_SEG==4) begin
                assign tlp_hdr_o = {128'b0, header1, 128'b0, header0};
            end else if (NUM_SEG==2) begin
              assign tlp_hdr_o = {header1, header0};
            end

            assign tlp_data_o = tlp_data;

            // Properly format trace data into TLP data based on segment size
            always_comb begin
              // Initialize TLP data to all zeros
              tlp_data = '0;

              // Copy available trace records to TLP data
              // Only copy as many records as we have available
              for (int i = 0; i < (TLP_DATA_WIDTH / 128) && i < TRACE_RECORDS; i++) begin
                tlp_data[i*128 +: 128] = dequeue_data[i*128 +: 128];
              end
            end

            // Configuration register pipeline for beat count
            always_ff @ (posedge clk) begin
              // Calculate required beats for 512B payload based on interface width
              if (NUM_SEG == 4 && BITS_PER_SEG == 'd256) begin
                // 4 segments * 256 bits = 1024 bits per beat = 128B per beat
                // 512B / 128B = 4 beats
                beat_cnt_init <= 11'd4;
              end else if (NUM_SEG == 2 && BITS_PER_SEG == 'd256) begin
                beat_cnt_init <= 11'd8;  // 512B / 64B = 8 beats
              end else if (NUM_SEG == 2 && BITS_PER_SEG == 'd128) begin
                beat_cnt_init <= 11'd16; // 512B / 32B = 16 beats
              end
            end

            // Address calculation based on trace_buffer_size
            always_comb begin
              // Calculate number of TLPs to send based on total size
              tlp_cnt_init = trace_buffer_size >> 9; // Divide by 512B
            end

            // PCIe credit and ready signals
            logic p_cdts_ready;
            assign p_cdts_ready = p_cdts_ready_i;

            logic tlp_ready_comb;
            assign tlp_ready_comb = tlp_ready_i;

            // Trace buffer dequeue control logic
            always_comb begin
              // Default values
              dequeue_en = 1'b0;
              dequeue_count = '0;

              case (state)

                IDLE: begin
                  dequeue_en = 1'b0;
                  dequeue_count = 0;
                end

                SOP: begin
                  dequeue_en = 1'b1;
                  dequeue_count = RECORDS_PER_BEAT;
                end

                WAIT: begin
                  if (tlp_ready_comb) begin
                    dequeue_en = 1'b1;
                    dequeue_count = RECORDS_PER_BEAT;
                  end
                end

                EOP: begin
                  if (tlp_ready_comb && tlp_cnt > 1 && !ctrl_abort &&
                    available_count >= RECORDS_PER_TLP) begin
                    dequeue_en = 1'b1;
                    dequeue_count = RECORDS_PER_BEAT;
                  end
                end

                BUFFER_FULL: begin
                  dequeue_en = 1'b0;
                  dequeue_count = 0;
                end
              endcase
            end


            // Main state machine with simplified control and new BUFFER_FULL state
            always_ff @ (posedge clk) begin
              if (srstn==1'b0) begin
                state <= IDLE;
                beat_cnt <= beat_cnt_init;
                tlp_dvalid <= '0;
                tlp_sop <= '0;
                tlp_eop <= '0;
                dma_wr_info_o.clr <= 1'b0;
              end else begin
                case (state)
                  IDLE: begin
                    beat_cnt <= beat_cnt_init;
                    tlp_dvalid <= '0;
                    tlp_sop <= '0;
                    tlp_eop <= '0;
                    dma_wr_info_o.clr <= 1'b0;

                    // Reset counts if stopped
                    if (ctrl_reset) begin
                      tlp_cnt <= tlp_cnt_init;
                      addr_64bit <= 64'h0;
                    end

                    // Start when we get the start signal and have enough trace data
                    // Simplified control logic using directly registered signals
                    if (ctrl_start && !ctrl_abort) begin
                      if (available_count >= RECORDS_PER_TLP && p_cdts_ready) begin
                        // Go to SOP state to start packet
                        state <= SOP;
                      end
                    end
                  end

                  SOP: begin
                    // Start of Packet
                    if (NUM_SEG == 4) begin
                      tlp_sop <= 4'b0001;  // SOP on segment 0
                      tlp_eop <= 4'b0000;  // No EOP yet
                      tlp_dvalid <= 4'b1111; // All segments active
                    end else if (NUM_SEG == 2) begin
                      tlp_sop <= 2'b01;    // SOP on segment 0
                      tlp_eop <= 2'b00;    // No EOP yet
                      tlp_dvalid <= 2'b11; // Both segments active
                    end

                    if (ctrl_abort) begin
                      state <= IDLE;
                    end else if (beat_cnt_init == 1) begin
                      // Single beat TLP (unusual but possible)
                      state <= EOP;
                    end else begin
                      state <= WAIT;
                      beat_cnt <= beat_cnt_init - 1'b1;
                    end
                  end

                  WAIT: begin
                    // Middle beats of multi-beat TLP
                    if (tlp_ready_comb) begin
                      tlp_dvalid <= 2'b11; // Both segments active
                      if (beat_cnt > 1) begin
                        // Continue with middle beats
                        state <= WAIT;
                        beat_cnt <= beat_cnt - 1'b1;

                        // Middle beats: No SOP, No EOP
                        tlp_sop <= '0;
                        tlp_eop <= '0;
                      end else if (beat_cnt == 1) begin
                        // Last beat - transition to EOP
                        state <= EOP;

                        // Final beat: Set EOP in this cycle (becomes visible next cycle)
                        // while simultaneously requesting data (also available next cycle)
                        tlp_sop <= '0;
                        if (NUM_SEG == 4) begin
                          tlp_eop <= 4'b1000;  // EOP on segment 3
                        end else if (NUM_SEG == 2) begin
                          tlp_eop <= 2'b10;    // EOP on segment 1
                        end
                      end
                    end
                  end

                  EOP: begin
                    // EOP state - tlp_eop was set in previous cycle and is now visible
                    // dequeue_data is also available from previous cycle's request

                    // Update for next packet
                    tlp_cnt <= tlp_cnt - 1'b1;
                    addr_64bit <= addr_64bit + 1'b1;

                    // Check for more packets or buffer full condition
                    if (tlp_cnt > 1 && !ctrl_abort) begin
                      // More packets to send
                      if (available_count >= RECORDS_PER_TLP && p_cdts_ready) begin

                        if (NUM_SEG == 4) begin
                          tlp_sop <= 4'b0001;  // SOP on segment 0
                          tlp_eop <= 4'b0000;  // No EOP yet
                          tlp_dvalid <= 4'b1111; // All segments active
                        end else if (NUM_SEG == 2) begin
                          tlp_sop <= 2'b01;    // SOP on segment 0
                          tlp_eop <= 2'b00;    // No EOP yet
                          tlp_dvalid <= 2'b11; // Both segments active
                        end

                        // Skip SOP state and go directly to WAIT
                        // (or stay in EOP if only 1 beat needed)
                        if (beat_cnt_init == 1) begin
                          beat_cnt <= beat_cnt_init;
                          // Stay in EOP state
                        end else begin
                          // Multi-beat TLP case
                          beat_cnt <= beat_cnt_init - 1'b1; // First beat handled here
                          state <= WAIT;
                        end
                      end else begin
                        // Not enough trace data, wait in IDLE
                        state <= IDLE;
                        tlp_dvalid <= '0;
                        tlp_sop <= '0;
                        tlp_eop <= '0;
                      end
                    end else begin
                      // Final packet completed or abort requested
                      // Clear TLP signals
                      tlp_dvalid <= '0;
                      tlp_sop <= '0;
                      tlp_eop <= '0;

                      if (ctrl_abort) begin
                        state <= IDLE;
                        tlp_cnt <= tlp_cnt_init;
                        addr_64bit <= 64'h0;
                      end else begin
                        // Buffer is now full - go to BUFFER_FULL state
                        state <= BUFFER_FULL;
                        dma_wr_info_o.clr <= 1'b1;  // Signal completion
                      end
                    end
                  end

                  BUFFER_FULL: begin
                    // Buffer is full, waiting for software reset
                    tlp_dvalid <= '0;
                    tlp_sop <= '0;
                    tlp_eop <= '0;

                    // Wait for reset signal from software and reset counts
                    if (ctrl_reset) begin
                      state <= IDLE;
                      tlp_cnt <= tlp_cnt_init;
                      addr_64bit <= 64'h0;
                    end
                  end

                  default: begin
                  end
                endcase
              end
            end


            // Debug stuff 
            logic [63:0] timestamp0, previous_timestamp0;
            (* noprune *) logic duplicate;
            always_ff @ (posedge clk) begin
              if (srstn==1'b0) begin
                timestamp0 <= '0;
                previous_timestamp0 <= '0;
                duplicate <= 1'b0;
              end else begin
                timestamp0 <= trace_data[127:64];
                previous_timestamp0 <= timestamp0;
                duplicate <= (timestamp0 == previous_timestamp0);
              end
            end
            endmodule

