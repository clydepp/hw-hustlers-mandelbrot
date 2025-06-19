module engine_top #(
    parameter   SCREEN_WIDTH  = 960,
    parameter   SCREEN_HEIGHT = 720,
    parameter   NUM_ENGINES = 12,
    // parameter   MAX_ITER = 200,
    parameter   DATA_WIDTH = DEPTH_WIDTH + 22, //y (11 bits) + x (11 bits) + depth (10 bits)
    // parameter   ZOOM = 1,
    // parameter   ZOOM_RECIPROCAL = 32'h00000001, // 1/ZOOM in Qm.n format
    // parameter   REAL_CENTER = 32'hC0000000, // in Q4.28 format
    // parameter   IMAG_CENTER = 32'h00000000, // in Q4.28 format
    parameter   FRAC = 28, // Fractional bits for Q-format
    parameter   WORD_LENGTH = 32, // Word length for Q-format
    parameter    FIFO_DEPTH = 16, // Depth of the FIFO
	parameter 	DEPTH_WIDTH = 13
)(
    input logic clk,
    input logic reset,
    input logic [10:0] pixel_x, //x coordinate from pixel_gen
    input logic [10:0] pixel_y, //y coordinate from pixel_gen
    input logic init_start, //start the module
    input logic ready, //pixel_gen ready 
    input logic [31:0] ZOOM,
    input logic [31:0] REAL_CENTER, 
    input logic [31:0] IMAG_CENTER,
    input logic sof,
    input logic [DEPTH_WIDTH-1:0] MAX_ITER, 
    input logic julia,
    input logic signed [31:0] julia_re,
    input logic signed [31:0] julia_im,
    
    //input logic [8:0] pixel_y, //
    //input logic start, // signal to start the next pixel calculation
    //output logic module_done, //if fifo has finished writing all depth values
    output logic valid_int, //if data is available in fifo
    output logic [DEPTH_WIDTH-1:0] depth_out
);

//logic busy; //signal for start of frame
logic [NUM_ENGINES-1:0] engine_start; // Signal to start each engine
logic [NUM_ENGINES-1:0] engine_done; //hmm
logic [NUM_ENGINES-1:0] engine_written; // if engine has written to fifo
logic [10:0] next_x; // next x coordinate to assign to the engines
logic [10:0] y;
logic [10:0] engine_x [NUM_ENGINES-1:0]; // x assigned to each engine
logic [10:0] engine_y [NUM_ENGINES-1:0]; 
logic [NUM_ENGINES-1:0] fifo_full, fifo_empty;
logic [10:0] fifo_out_x [NUM_ENGINES-1:0]; // x coordinate from each engine
logic [10:0] fifo_out_y [NUM_ENGINES-1:0]; // y coordinate from each engine
logic [DEPTH_WIDTH-1:0] fifo_out_depth [NUM_ENGINES-1:0]; //depth from each engine
logic [NUM_ENGINES-1:0] fifo_ren; // Read enable for each FIFO
  
logic [10:0] temp_x;
logic [10:0] temp_y;

logic started; // Signal to indicate if the module has started

//engine assignment logic
always_ff @(posedge clk) begin
    if(reset) begin
        engine_start <= '0; 
        next_x <= NUM_ENGINES;
        y <= 0; 
        started <= 0; // Reset started signal
        for (int i = 0; i < NUM_ENGINES; i++) begin
            engine_x[i] <= i; //0,1,2,3,4 
            engine_y[i] <= 0; 
        end
    end else begin
        engine_start <= '0; // Reset engine start signals

        if(init_start && !started) begin //first start
            engine_start <= '1; 
            started <= 1; 
        end

        
        temp_x = next_x; 
        temp_y = y;

        for (int i = 0; i < NUM_ENGINES; i++) begin
            if (engine_written[i] && !fifo_full[i]) begin
                engine_start[i] <= 1;
                engine_x[i] <= temp_x;
                engine_y[i] <= temp_y;
                temp_x = temp_x + 1;
                // Handle x overflow
                if (temp_x >= SCREEN_WIDTH) begin
                    temp_x = 0;
                    temp_y = temp_y + 1;
                    // Handle y overflow (new frame)
                    if (temp_y >= SCREEN_HEIGHT) begin
                        temp_y = 0;
                    end
                end
            end
            // end else begin
            //     engine_start[i] <= 0;
            // end
        end 

        next_x <= temp_x; 
        y <= temp_y;
    end
end

logic [NUM_ENGINES-1:0] engine_start_d1;
always_ff @(posedge clk) begin
    engine_start_d1 <= engine_start;
end
genvar i;

generate
    for(i=0;i<NUM_ENGINES;i=i+1) begin
        
        wire [WORD_LENGTH-1:0] re_c, im_c;
        wire [DEPTH_WIDTH-1:0] engine_depth; //to fifo
        wire [DATA_WIDTH-1:0] fifo_dout; //10 bits for depth, 11 bits for x, 11 bits for y
        wire fifo_wen; // 
        assign fifo_out_x[i] = fifo_dout[DEPTH_WIDTH+10:DEPTH_WIDTH]; // Extract x coordinate from FIFO output
        assign fifo_out_y[i] = fifo_dout[DATA_WIDTH-1:24]; // Extract y coordinate from FIFO output
        assign fifo_out_depth[i] = fifo_dout[DEPTH_WIDTH-1:0]; // Extract depth from FIFO output

        pixel_to_complex #(
            .WORD_LENGTH(WORD_LENGTH),
            .FRAC(FRAC),
            .SCREEN_WIDTH(SCREEN_WIDTH),
            .SCREEN_HEIGHT(SCREEN_HEIGHT)
        )  mapper (
            .ZOOM(ZOOM),
            .sof(sof),
            //.ZOOM_RECIPROCAL(ZOOM_RECIPROCAL),
            .real_center(REAL_CENTER),
            .imag_center(IMAG_CENTER),
            .clk(clk),
            .x(engine_x[i]),        // x coordinate assigned to each engine
            .y(engine_y[i]),             // y coordinate assigned to each engine
            .real_part(re_c),       // output real part of c (Q-format)
            .im_part(im_c)          // output imag part of c (Q-format)
        );

        depth_engine #(
            .FRAC(FRAC), // Fractional bits for Q-format
            .WORD_LENGTH(WORD_LENGTH), // Word length for Q-format
			.DEPTH_WIDTH(DEPTH_WIDTH)
        ) engine (
            .sysclk(clk),
            .start(engine_start_d1[i]),   // Controls when we begin calculating
            .reset(reset),
            .re_c(re_c),            // input real part of c (Q-format)
            .im_c(im_c),            // input imag part of c (Q-format)
            .max_iter(MAX_ITER),    // Maximum iterations for the mandelbrot calculation
            .fifo_full(fifo_full[i]), //backpressure signal from FIFO
            .written(engine_written[i]), //if data has been saved to fifo
            .fifo_wen(fifo_wen), 
            .julia(julia),
            .julia_im(julia_im),
            .julia_re(julia_re),
            .final_depth(engine_depth), // output depth for each engine to fifo
            .done(engine_done[i])  // might need to make it such that it can output x and y
        );

        // fifo 
        single_fifo #(
            .DATA_WIDTH(DATA_WIDTH),
            .DEPTH(FIFO_DEPTH)
        ) single_fifo (
            .clk(clk),
            .reset(reset),
            .data_in({engine_y[i], engine_x[i], engine_depth}), 
            .full(fifo_full[i]),
            .write_en(fifo_wen),
            .read_en(fifo_ren[i]),
            .empty(fifo_empty[i]),
            .data_out(fifo_dout)
        );
        
    end 
endgenerate

logic [DEPTH_WIDTH-1:0] matched_depth;
logic [$clog2(NUM_ENGINES)-1:0] matched_engine;
logic match_found;
logic [NUM_ENGINES-1:0] fifo_ren_req; // request signal

always_comb begin
    match_found = 0;
    matched_engine = 0;
    valid_int = 0; // Default to not valid
    depth_out = 0;

    for (int j = 0; j < NUM_ENGINES; j++) begin
        if (!fifo_empty[j] && fifo_out_x[j] == pixel_x && fifo_out_y[j] == pixel_y && !match_found) begin
            match_found = 1;
            matched_engine = j;
            depth_out = fifo_out_depth[j];
            valid_int = 1; 
        end
    end

end

always_ff @(posedge clk) begin
    if (reset) begin
        //valid_int <= 0;
        fifo_ren <= '0;
    end else begin
        fifo_ren <= '0;
        if (valid_int && ready) begin
            fifo_ren[matched_engine] <= 1; // Read from the FIFO of the matched engine
        end 
        // else begin
        //     fifo_ren <= '0; // Reset read enables if no match found or not ready
        // end   
    end
end


endmodule

