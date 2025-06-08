module pixel_fifo #(
    parameter int DATA_WIDTH = 20, // x, depth
    parameter int DEPTH = 64,
    parameter NUM_ENGINES = 5
)(
    input logic clk,
    input logic reset,
    input [DATA_WIDTH * NUM_ENGINES-1:0] data_in, //no 2d inputs allowed. 
    output logic full,

    input logic [NUM_ENGINES-1:0] write_en,
    input logic read_en,
    output logic empty,
    output logic [DATA_WIDTH-1:0] data_out
);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];  // Memory for the FIFO
    localparam ADDR_WIDTH = $clog2(DEPTH);
    logic [ADDR_WIDTH-1:0] write_ptr, read_ptr;
    logic [ADDR_WIDTH-1:0] count; // Count of elements in the FIFO

    assign full = (count >= DEPTH - $countones(write_en)); // check current count + number of writes
    assign empty = (count == 0);
    // assign data_out = mem[read_ptr];

    always_ff @(posedge clk) begin
        logic [ADDR_WIDTH-1:0] temp_write_ptr;

        if (reset) begin
            write_ptr <= 0;
            read_ptr <= 0;
            count  <= 0;
            data_out <= 0;
        end else begin
            
            int temp_count = count; // Temporary variable to hold count
            
            // Read
            if (read_en && !empty) begin
                read_ptr <= (read_ptr + 1);
                temp_count = temp_count - 1;
                data_out <= mem[read_ptr]; 
            end
            
            //logic [ADDR_WIDTH-1:0] temp_write_ptr = write_ptr; // Temporary variable to hold write pointer
            temp_write_ptr = write_ptr; // Temporary variable to hold write pointer

            // Write
            for(int i = 0; i < NUM_ENGINES; i++) begin
                if (write_en[i] && (temp_count<DEPTH)) begin
                    ///////////////////////////////////////////
                    
                    mem[temp_write_ptr] <= data_in[DATA_WIDTH*i +: DATA_WIDTH]; //DATA IN 2d array wrong ggfdggfdfdggfdgfdgf
                    temp_write_ptr = (temp_write_ptr + 1);
                    temp_count = temp_count + 1;
                end
            end

            write_ptr <= temp_write_ptr; // Update write pointer after all writes
            count <= temp_count; 

            
        end
    end
endmodule
