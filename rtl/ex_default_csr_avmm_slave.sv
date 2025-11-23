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

module ex_default_csr_avmm_slave(
 
// AVMM Slave Interface
   input               clk,
   input               reset_n,
   input  logic [63:0] writedata,
   input  logic        read,
   input  logic        write,
   input  logic [7:0]  byteenable,
   output logic [63:0] readdata,
   output logic        readdatavalid,
   input  logic [31:0] address,
   input  logic        poison,
   output logic        waitrequest,
    // CSR <-> Trace recorder
    output logic [63:0]            trace_buffer_base_addr_0,
    output logic [63:0]            trace_buffer_base_addr_1,
    output logic [63:0]            trace_buffer_size_0,
    output logic [63:0]            trace_buffer_size_1,
    output logic [63:0]            control_register_0,
    output logic [63:0]            control_register_1,
    input  logic [63:0]            dropped_traces_0,
    input  logic [63:0]            dropped_traces_1,
    input  logic [63:0]            written_traces_0,
    input  logic [63:0]            written_traces_1
);

  localparam ADDR_WIDTH = 22;
  // Register declarations
 logic [31:0] csr_test_reg;

logic [63:0] trace_buffer_base_addr_0_reg;
logic [63:0] trace_buffer_base_addr_1_reg;
logic [63:0] trace_buffer_size_0_reg;
logic [63:0] trace_buffer_size_1_reg;
logic [63:0] control_register_0_reg;
logic [63:0] control_register_1_reg;
logic [63:0] dropped_traces_0_reg;
logic [63:0] dropped_traces_1_reg;
logic [63:0] written_traces_0_reg;
logic [63:0] written_traces_1_reg;

 logic [63:0] mask ;
 logic config_access; 

 assign mask[7:0]   = byteenable[0]? 8'hFF:8'h0; 
 assign mask[15:8]  = byteenable[1]? 8'hFF:8'h0; 
 assign mask[23:16] = byteenable[2]? 8'hFF:8'h0; 
 assign mask[31:24] = byteenable[3]? 8'hFF:8'h0; 
 assign mask[39:32] = byteenable[4]? 8'hFF:8'h0; 
 assign mask[47:40] = byteenable[5]? 8'hFF:8'h0; 
 assign mask[55:48] = byteenable[6]? 8'hFF:8'h0; 
 assign mask[63:56] = byteenable[7]? 8'hFF:8'h0; 
 assign config_access = address[21];  

logic [ADDR_WIDTH-1:0] csr_address;
assign csr_address = address[ADDR_WIDTH-1:0];

//Terminating extented capability header
 localparam EX_CAP_HEADER  = 32'h00000000;

 // Input/Outputs assignments
 assign trace_buffer_base_addr_0 = trace_buffer_base_addr_0_reg;
 assign trace_buffer_base_addr_1 = trace_buffer_base_addr_1_reg;
 assign trace_buffer_size_0      = trace_buffer_size_0_reg;
 assign trace_buffer_size_1      = trace_buffer_size_1_reg;
 assign control_register_0       = control_register_0_reg;
 assign control_register_1       = control_register_1_reg;

//Write logic
always @(posedge clk) begin
    if (!reset_n) begin
        csr_test_reg                 <= 32'h0;
        trace_buffer_base_addr_0_reg <= 64'h0;
        trace_buffer_size_0_reg      <= 64'h0;
        control_register_0_reg       <= 64'h0;
        dropped_traces_0_reg         <= 64'h0;
        written_traces_0_reg         <= 64'h0;
        trace_buffer_base_addr_1_reg <= 64'h0;
        trace_buffer_size_1_reg      <= 64'h0;
        control_register_1_reg       <= 64'h0;
        dropped_traces_1_reg         <= 64'h0;
        written_traces_1_reg         <= 64'h0;
    end
    else begin
        if (write && (csr_address == 22'h0000) && ~poison) begin 
           csr_test_reg <= (writedata[31:0] & mask[31:0]) | (csr_test_reg & ~mask[31:0]);
        end
        else if (write && (csr_address == 22'h000008)) begin // ADDR_TRACE_BASE_0
          trace_buffer_base_addr_0_reg <= (writedata & mask) | (trace_buffer_base_addr_0_reg & ~mask);
        end
        else if (write && (csr_address == 22'h000010)) begin // ADDR_TRACE_SIZE_0
          trace_buffer_size_0_reg <= (writedata & mask) | (trace_buffer_size_0_reg & ~mask);
        end
        else if (write && (csr_address == 22'h000018)) begin // ADDR_CONTROL_REG_0
          control_register_0_reg <= (writedata & mask) | (control_register_0_reg & ~mask);
        end
        else if (write && (csr_address == 22'h000108)) begin // ADDR_TRACE_BASE_1
          trace_buffer_base_addr_1_reg <= (writedata & mask) | (trace_buffer_base_addr_1_reg & ~mask);
        end
        else if (write && (csr_address == 22'h000110)) begin // ADDR_TRACE_SIZE_1
          trace_buffer_size_1_reg <= (writedata & mask) | (trace_buffer_size_1_reg & ~mask);
        end
        else if (write && (csr_address == 22'h000118)) begin // ADDR_CONTROL_REG_1
          control_register_1_reg <= (writedata & mask) | (control_register_1_reg & ~mask);
        end
        else begin
          csr_test_reg                 <= csr_test_reg;
          trace_buffer_base_addr_0_reg <= trace_buffer_base_addr_0_reg;
          trace_buffer_size_0_reg      <= trace_buffer_size_0_reg;
          control_register_0_reg       <= control_register_0_reg;
          dropped_traces_0_reg         <= dropped_traces_0;
          written_traces_0_reg         <= written_traces_0;
          trace_buffer_base_addr_1_reg <= trace_buffer_base_addr_1_reg;
          trace_buffer_size_1_reg      <= trace_buffer_size_1_reg;
          control_register_1_reg       <= control_register_1_reg;
          dropped_traces_1_reg         <= dropped_traces_1;
          written_traces_1_reg         <= written_traces_1;
        end        
    end    
end 

//Read logic
always @(posedge clk) begin
    if (!reset_n) begin
        readdata  <= 32'h0;
    end
    else begin
        if (read && (address[21:0] == 22'h0)) begin 
           readdata <= csr_test_reg & mask[31:0];
        end
        else if (address[21:0] == 22'h000008) begin // ADDR_TRACE_BASE_0
            readdata <= trace_buffer_base_addr_0_reg & mask;
        end
        else if (address[21:0] == 22'h000010) begin // ADDR_TRACE_SIZE_0
            readdata <= trace_buffer_size_0_reg & mask;
        end
        else if (address[21:0] == 22'h000018) begin // ADDR_CONTROL_REG_0
            readdata <= control_register_0_reg & mask;
        end
        else if (address[21:0] == 22'h000020) begin // ADDR_DROPPED_TRACES_0
            readdata <= dropped_traces_0_reg & mask; // Read back latched input
        end
        else if (address[21:0] == 22'h000028) begin // ADDR_WRITTEN_TRACES_0
            readdata <= written_traces_0_reg & mask; // Read back latched input
        end
        else if (address[21:0] == 22'h000108) begin // ADDR_TRACE_BASE_1
            readdata <= trace_buffer_base_addr_1_reg & mask;
        end
        else if (address[21:0] == 22'h000110) begin // ADDR_TRACE_SIZE_1
            readdata <= trace_buffer_size_1_reg & mask;
        end
        else if (address[21:0] == 22'h000118) begin // ADDR_CONTROL_REG_1
            readdata <= control_register_1_reg & mask;
        end
        else if (address[21:0] == 22'h000120) begin // ADDR_DROPPED_TRACES_1
            readdata <= dropped_traces_1_reg & mask; // Read back latched input
        end
        else if (address[21:0] == 22'h000128) begin // ADDR_WRITTEN_TRACES_1
            readdata <= written_traces_1_reg & mask; // Read back latched input
        end
        else if(read && (address[20:0] == 21'h00E00) && config_access) begin //In ED PF1 capability chain with HEADER E00 terminate here with data zero 
           readdata <= {EX_CAP_HEADER} & mask;
        end
        else begin
           readdata  <= 32'h0;
        end        
    end    
end 


//Control Logic
enum int unsigned { IDLE = 0,WRITE = 2, READ = 4 } state, next_state;

always_comb begin : next_state_logic
   next_state = IDLE;
      case(state)
      IDLE    : begin 
                   if( write ) begin
                       next_state = WRITE;
                   end
                   else begin
                     if (read) begin  
                       next_state = READ;
                     end
                     else begin
                       next_state = IDLE;
                     end
                   end 
                end
      WRITE     : begin
                   next_state = IDLE;
                end
      READ      : begin
                   next_state = IDLE;
                end
      default : next_state = IDLE;
   endcase
end


always_comb begin
   case(state)
   IDLE    : begin
               waitrequest  = 1'b1;
               readdatavalid= 1'b0;
             end
   WRITE     : begin 
               waitrequest  = 1'b0;
               readdatavalid= 1'b0;
             end
   READ     : begin 
               waitrequest  = 1'b0;
               readdatavalid= 1'b1;
             end
   default : begin 
               waitrequest  = 1'b1;
               readdatavalid= 1'b0;
             end
   endcase
end

always_ff@(posedge clk) begin
   if(~reset_n)
      state <= IDLE;
   else
      state <= next_state;
end

endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "EtAh8aN7m2BPKOTfO5tEAbNSD19BnNEklF4xQRY7YZ2oRe/8wDIRx8XCKuwkXQtjYcM5gRXSD6c+oGX77mfnvlAGw9KTmnXPBu3GU7e3qFjUTrXWlEAN76gMqJTePk91Iv2qtpAKuY2LJHLiowUVDoSuAt1Csh1O2u7qDzQRIaeVL/AJWYDMfWERE2K26wZcHHB8eTbMnhSND4m01aQODfKXixyUFYBUVJCy/gZrUwAttnSs0SWurFMnWXko55SmRc19SbptVNnjblfAN9Zexv40zEur0X8dmymU0do1gXxFJfZkPC1AfWh0CowrBD/JGKkLAK0cPA9fR2tOq7uCGCqWaYWwDaQMyW/tSV3JUMExUxTJOcFRyLFmFKLjCQASK0LOhOjN0MlpJfBN/2FiEQFVinKDuXbKLvyMNBPt2gHZpkeCvMmI93KRtdq6j87lOh7hhsLUzKKaaOy/iEcTQS/q5GtIi7iwnE1K654NVXxFgFuZg1QNpho+ZT5HetO7JgNHS2wwD67oSc1uBcAxqfqPsAW06/nHoySJ+6Wn+t4QxVG9ZWbsja5uVZfx/h8PbaX6ovE6L0dF575kbsH6DqnVBc9zGX8XHr1dz0MSkFGZlIcHcpZaDN7gpOS8yo2Lwn9YdE2Vy/9CwH40bJJx1ByT0/4OCdSFZyWdCKi1I8JgZL3ltVqpUxCwMbKQ/j7wqQ7SaANDTWtM1rVp6oDd03N/DFJcCYUCwz5jdaKBhehpVyMpBqrm6aaezRAg0LbnEm/rild2VAOleCoki9RUrGHbwAAsHbQ7EOpk32tgkcL8ZZaubZeIEYm/w/30uHE4Vb9tBmRlTVIFoYKD1sXJIjBL90uO9VJaWLgyIGJfKH7t8tVlaXQ9uySEPFXhtqdJXLbrJyckyndKWyC4wsl3sjYxVH73FXI20IzQONqsdQQhQSReqQv8p8b2J6ps6UP6TKOVY8UE4YhUf84406AiM1kJwKZjD8nUc3d8xO9gpa8Src//JKe8xVuNTnFHLQSg"
`endif
