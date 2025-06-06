module engine_top #(
    parameter int SCREEN_WIDTH  = 640,
    parameter int SCREEN_HEIGHT = 480,
    parameter int NUM_ENGINES = 5,
    parameter int MAX_ITER = 200,
    parameter int DATA_WIDTH = 20 // x (10 bits) + depth (10 bits)
)(
    input logic clk,
    input logic reset,
    input logic start, // signal to start the next pixel calculation
    output logic done,

    output logic [9:0] depth_out,
    output logic we_out, //write enable for depth output
    output logic [$clog2(SCREEN_WIDTH)-1:0] addr_out //x coordinate for depth output
    // output [11:0]   bram_addr_a,
    // output          bram_clk_a,
    // output [31:0]   bram_wrdata_a,
    // // input  [31:0]   bram_rddata_a,
    // output          bram_en_a,
    // output          bram_rst_a,
    // output [3:0]    bram_we_a
);

logic busy; //signal for start of frame
logic [NUM_ENGINES-1:0] engine_start; // Signal to start each engine
logic [NUM_ENGINES-1:0] engine_done;
logic [9:0] next_x;
logic [8:0] next_y;
logic [9:0] engine_x [NUM_ENGINES-1:0]; // x assigned to each engine
// logic [9:0] top_depth;
logic [9:0] engine_depth [NUM_ENGINES-1:0]; // depth result for each engine

//x coordinate assignment logic
always_ff @(posedge clk) begin

    if(reset) begin
        
        busy <= 0;
        next_x <= 0;
        next_y <= 0;
        // engine_x <= 0;

    end else begin

        if(start && !busy) begin

            busy <= 1; // Set busy to true when start is received
            // next_x <= 0; // Reset next_x to 0 at the start of a new calculation
            next_y <= 0; // Reset next_y to 0 at the start of a new calculation
            // engine_x <= 0; // Reset engine_x to 0 at the start of a new calculation
            engine_start <= '1; // Signal engines to start

            for (int i = 0; i<NUM_ENGINES; i++) begin
                engine_x[i] <= i; // Assign initial x coordinates to each engine
            end

            next_x <= NUM_ENGINES; // Set next_x to the first available x coordinate after the engines

        end else begin

            if(next_x >= SCREEN_WIDTH-1) begin

                // if engines all done reset
                if(engine_done == '1) begin
                    busy <= 0; 
                    next_x <= 0; 
                    if(next_y >= SCREEN_HEIGHT-1) begin
                        next_y <= 0; // Reset y to 0 if we reach the end of the screen
                    end else begin
                        next_y <= next_y + 1; 
                    end

                    done <= 1; // Signal that the line is done

                end
                //if not all engines done, wait for them to finish
                else begin
                    engine_start <= '0;
                end
            
            // if next x not greater than screen width, continue
            end else begin

                int temp_x = next_x; // in case multiple engines are done in the same cycle

                for(int i = 0; i < NUM_ENGINES; i++) begin
                    if(engine_done[i]) begin
                        engine_x[i] <= temp_x; // Assign the x coordinate to the engine
                        temp_x = temp_x + 1; // Increment x for the next engine                
                    end
                end

                next_x <= temp_x; // Update the next x coordinate

            end
            
        end
    end
    
end

genvar i;

generate
    for(i=0;i<NUM_ENGINES;i=i+1) begin
        
        wire [15:0] re_c, im_c;

        depth_engine engine(
            .sysclk(clk),
            .start(engine_start[i]),   // Controls when we begin calculating
            .reset(reset),
            .x(engine_x[i]),        // x coordinate assigned to each engine
            .y(next_y),             // y coordinate assigned to each engine
            .re_c(re_c),            // input real part of c (Q-format)
            .im_c(im_c),            // input imag part of c (Q-format)
            .max_iter(MAX_ITER),    // Maximum iterations for the mandelbrot calculation
            
            .final_depth(engine_depth[i]), // output depth for each engine
            .done(engine_done[i])  // might need to make it such that it can output x and y
        );

        pixel_to_complex mapper(
            .clk(clk),
            .x(engine_x[i]),        // x coordinate assigned to each engine
            .y(next_y),             // y coordinate assigned to each engine
            .real_part(re_c),       // output real part of c (Q-format)
            .im_part(im_c)          // output imag part of c (Q-format)
        );

    end 
endgenerate

// instatiate fifo
logic [DATA_WIDTH * NUM_ENGINES-1:0] fifo_din;
logic [19:0] fifo_dout;
logic [NUM_ENGINES-1:0] fifo_wren;
logic fifo_full, fifo_empty, fifo_ren;

//read first fifo 
pixel_fifo #(
    .DATA_WIDTH(20), // x (10 bits) + depth (10 bits)
    .DEPTH(32),
    .NUM_ENGINES(NUM_ENGINES)
) output_fifo (
    .clk(clk),
    .reset(reset),
    .data_in(fifo_din),
    .full(fifo_full),
    .write_en(fifo_wren),
    .read_en(fifo_ren),
    .empty(fifo_empty),
    .data_out(fifo_dout)
);

wire [9:0] fifo_out_x;
wire [9:0] fifo_out_depth;
assign fifo_out_x = fifo_dout[19:10]; // Extract x coordinate from FIFO output
assign fifo_out_depth = fifo_dout[9:0]; // Extract depth from FIFO output

//push result to fifo
always_ff @(posedge clk) begin
    
    if(reset) begin
    
        fifo_wren <= '0; // Reset write enable signals
        fifo_din <= '0; // Reset FIFO data input
    
    end else begin
        fifo_wren <= '0; // Reset write enable signals

        //multiple write 
        for (int j = 0; j < NUM_ENGINES; j++) begin
            if (engine_done[j] && !fifo_full) begin        
                fifo_wren[j] <= 1;
                fifo_din[j] <= {engine_x[j], engine_depth[j]};
            end
        end
    end
end

typedef enum {IDLE, INIT, CONT} state_t;
state_t state;
// State machine to control BRAM write operations

always_ff @(posedge clk) begin
    if (reset) begin
        state <= IDLE;
        fifo_ren <= 0;
        depth_out <= 0;
        addr_out <= 0;
        we_out <= 0;
        // bram_en_a <= 0;
        // bram_we_a <= 4'b0000;
    end else begin
        case (state)
            IDLE: begin
                if (!fifo_empty) begin
                    fifo_ren <= 1; // Request data
                    state <= INIT;
                end else begin
                    fifo_ren <= 0;
                    depth_out <= 0;
                    addr_out <= 0;
                    we_out <= 0;
                    // bram_en_a <= 0;
                    // bram_we_a <= 4'b0000;
                end
            end

            //first read
            INIT: begin

                depth_out <= fifo_out_depth; // Output the depth
                addr_out <= fifo_out_x; // Output the x coordinate
                we_out <= 1; // Enable write to output

                // bram_addr_a   <= {2'b0, fifo_out_x};
                // bram_wrdata_a <= {22'b0, fifo_out_depth};
                // bram_en_a     <= 1;
                // bram_we_a     <= 4'b1111;

                if(!fifo_empty) begin

                    fifo_ren <= 1; // Continue reading from FIFO
                    state <= CONT; // Move to WRITE state after reading
                    
                end else begin

                    fifo_ren <= 0; // Stop reading if FIFO is empty
                    state <= IDLE; // Go back to IDLE if FIFO is empty

                end
            end

            //continue reading
            CONT: begin

                
                depth_out <= fifo_out_depth; // Output the depth
                addr_out <= fifo_out_x; // Output the x coordinate
                we_out <= 1; // Enable write to output
                // bram_addr_a   <= {2'b0, fifo_out_x};
                // bram_wrdata_a <= {22'b0, fifo_out_depth};
                // bram_en_a     <= 1;
                // bram_we_a     <= 4'b1111;

                if(!fifo_empty) begin

                    fifo_ren <= 1;
                    state <= CONT; // Continue writing if FIFO is not empty

                end else begin
                    
                    fifo_ren <= 0; // Stop reading from FIFO
                    state <= IDLE; // Go back to IDLE if FIFO is empty
                
                end
            end
        endcase
    end
end


endmodule

