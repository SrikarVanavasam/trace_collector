// Trace buffer with variable enqueue and fixed dequeue capability
module trace_buffer #(
    parameter FIFO_DEPTH = 64,           // FIFO depth (power of 2)
    parameter RECORD_WIDTH = 128,        // Width of each record
    parameter MAX_ENQUEUE = 4,           // Max records to enqueue per cycle
    parameter MAX_DEQUEUE = 4,           // Max records to dequeue per cycle
    parameter VALID_BIT_POS = 63         // Position of valid bit in each record
) (
    input  logic                                clk,
    input  logic                                reset_n,

    // Trace input interface
    input  logic                                trace_valid,
    input  logic [RECORD_WIDTH*MAX_ENQUEUE-1:0] trace_data,
    output logic                                fifo_full,

    // Dequeue interface
    input  logic                                dequeue_en,
    input  logic [$clog2(MAX_DEQUEUE+1)-1:0]    dequeue_count,  // How many records to dequeue
    output logic [RECORD_WIDTH*MAX_DEQUEUE-1:0] dequeue_data,   // Dequeued data
    output logic                                dequeue_valid,  // Dequeued data valid
    output logic [$clog2(FIFO_DEPTH+1)-1:0]     available_count // How many records available
);
    // FIFO buffer storage
    logic [RECORD_WIDTH-1:0] buffer [0:FIFO_DEPTH-1];

    // FIFO pointers and counters
    logic [$clog2(FIFO_DEPTH):0] write_ptr;     // Write pointer
    logic [$clog2(FIFO_DEPTH):0] read_ptr;      // Read pointer
    logic [$clog2(FIFO_DEPTH+1)-1:0] count;     // Number of valid elements in FIFO

    // Enqueue tracking
    logic [$clog2(MAX_ENQUEUE+1)-1:0] valid_enqueue_count; // Number of valid records this cycle
    logic [MAX_ENQUEUE-1:0] record_valid;                  // Valid bit for each input record
    logic [RECORD_WIDTH-1:0] enqueue_records [0:MAX_ENQUEUE-1]; // Individual records

    // FIFO status
    assign fifo_full = (count >= (FIFO_DEPTH - MAX_ENQUEUE));
    wire fifo_empty = (count == 0);
    assign available_count = count;

    // Extract and check validity of individual input records
    genvar i;
    generate
        for (i = 0; i < MAX_ENQUEUE; i++) begin : gen_records
            assign enqueue_records[i] = trace_data[i*RECORD_WIDTH +: RECORD_WIDTH];
            assign record_valid[i] = trace_valid && enqueue_records[i][VALID_BIT_POS];
        end
    endgenerate

    // Count valid records in the input
    always_comb begin
        valid_enqueue_count = 0;
        for (int j = 0; j < MAX_ENQUEUE; j++) begin
            if (record_valid[j]) valid_enqueue_count += 1;
        end
    end

    // Enqueue and dequeue operations
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            write_ptr <= '0;
            read_ptr <= '0;
            count <= '0;
            dequeue_valid <= 1'b0;
        end else begin
            // Default values
            dequeue_valid <= 1'b0;

            // Handle enqueue
            if (trace_valid && valid_enqueue_count > 0 && !fifo_full) begin
                // Store only the valid records
                automatic int valid_idx = 0;
                for (int j = 0; j < MAX_ENQUEUE; j++) begin
                    if (record_valid[j] && valid_idx < valid_enqueue_count) begin
                        buffer[(write_ptr + valid_idx) % FIFO_DEPTH] <= enqueue_records[j];
                        valid_idx++;
                    end
                end
                write_ptr <= (write_ptr + valid_enqueue_count) % FIFO_DEPTH;
            end

            // Handle dequeue
            if (dequeue_en && dequeue_count > 0 && count >= dequeue_count) begin
                for (int j = 0; j < MAX_DEQUEUE; j++) begin
                    if (j < dequeue_count) begin
                        dequeue_data[j*RECORD_WIDTH +: RECORD_WIDTH] <= buffer[(read_ptr + j) % FIFO_DEPTH];
                    end else begin
                        dequeue_data[j*RECORD_WIDTH +: RECORD_WIDTH] <= '0;
                    end
                end
                read_ptr <= (read_ptr + dequeue_count) % FIFO_DEPTH;
                dequeue_valid <= 1'b1;
            end

            // Update count - handle both operations happening in the same cycle
            if (trace_valid && valid_enqueue_count > 0 && !fifo_full &&
                dequeue_en && dequeue_count > 0 && count >= dequeue_count) begin
                // Both enqueue and dequeue in same cycle
                count <= count + valid_enqueue_count - dequeue_count;
            end else if (trace_valid && valid_enqueue_count > 0 && !fifo_full) begin
                // Only enqueue
                count <= count + valid_enqueue_count;
            end else if (dequeue_en && dequeue_count > 0 && count >= dequeue_count) begin
                // Only dequeue
                count <= count - dequeue_count;
            end
        end
    end
endmodule
