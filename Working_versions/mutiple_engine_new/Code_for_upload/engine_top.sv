module engine_top #(
    parameter   SCREEN_WIDTH  = 960,
    parameter   SCREEN_HEIGHT = 720,
    parameter   NUM_ENGINES = 5,
    parameter   MAX_ITER = 200,
    parameter   DATA_WIDTH = 32, //y (11 bits) + x (11 bits) + depth (10 bits)
    parameter   ZOOM = 1,
    // parameter   ZOOM_RECIPROCAL = 32'h00000001, // 1/ZOOM in Qm.n format
    parameter   REAL_CENTER = 32'hC0000000, // in Q4.28 format
    parameter   IMAG_CENTER = 32'h00000000, // in Q4.28 format
    parameter   FRAC = 28, // Fractional bits for Q-format
    parameter   WORD_LENGTH = 32, // Word length for Q-format
    parameter    FIFO_DEPTH = 16 // Depth of the FIFO
)(
    input logic clk,
    input logic reset,
    input logic [10:0] pixel_x, //x coordinate from pixel_gen
    input logic [10:0] pixel_y, //y coordinate from pixel_gen
    input logic init_start, //start the module
    input logic ready, //pixel_gen ready 
    //input logic [8:0] pixel_y, //
    //input logic start, // signal to start the next pixel calculation
    //output logic module_done, //if fifo has finished writing all depth values
    output logic valid_int, //if data is available in fifo
    output logic [9:0] depth_out
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
logic [9:0] fifo_out_depth [NUM_ENGINES-1:0]; //depth from each engine
logic [NUM_ENGINES-1:0] fifo_ren; // Read enable for each FIFO
  
logic [10:0] temp_x;
logic [10:0] temp_y;

logic started; // Signal to indicate if the module has started

//engine assignment logic
always_ff @(posedge clk) begin
    if(reset) begin
        engine_start <= '0; 
        next_x <= 5;
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

genvar i;

generate
    for(i=0;i<NUM_ENGINES;i=i+1) begin
        
        wire [WORD_LENGTH-1:0] re_c, im_c;
        wire [9:0] engine_depth; //to fifo
        wire [31:0] fifo_dout; //10 bits for depth, 11 bits for x, 11 bits for y
        wire fifo_wen; // 
        assign fifo_out_x[i] = fifo_dout[20:10]; // Extract x coordinate from FIFO output
        assign fifo_out_y[i] = fifo_dout[31:21]; // Extract y coordinate from FIFO output
        assign fifo_out_depth[i] = fifo_dout[9:0]; // Extract depth from FIFO output

        pixel_to_complex #(
            .WORD_LENGTH(WORD_LENGTH),
            .FRAC(FRAC),
            .SCREEN_WIDTH(SCREEN_WIDTH),
            .SCREEN_HEIGHT(SCREEN_HEIGHT)
        )  mapper (
            .ZOOM(ZOOM),
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
            .WORD_LENGTH(WORD_LENGTH) // Word length for Q-format
        ) engine (
            .sysclk(clk),
            .start(engine_start[i]),   // Controls when we begin calculating
            .reset(reset),
            .re_c(re_c),            // input real part of c (Q-format)
            .im_c(im_c),            // input imag part of c (Q-format)
            .max_iter(MAX_ITER),    // Maximum iterations for the mandelbrot calculation
            .fifo_full(fifo_full[i]), //backpressure signal from FIFO
            .written(engine_written[i]), //if data has been saved to fifo
            .fifo_wen(fifo_wen), 
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

logic [9:0] matched_depth;
logic [$clog2(NUM_ENGINES)-1:0] matched_engine;
logic match_found;
logic [NUM_ENGINES-1:0] fifo_ren_req; // request signal

always_comb begin
    match_found = 0;
    matched_engine = 0;
    valid_int = 0; // Default to not valid

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

//match x is always the next x coordinate to be read
// always_comb begin
//     if(pixel_x == SCREEN_WIDTH-1) begin
//         match_x = 0;
//         if(pixel_y == SCREEN_HEIGHT-1) begin
//             match_y = 0; // Reset y to 0
//         end else begin
//             match_y = pixel_y + 1; // Increment y
//         end 
//     end else begin
//         match_x = pixel_x + 1; // Increment x
//         match_y = pixel_y; // Keep y the same
//     end
// end

// typedef enum logic [1:0] {FIRST, IDLE, INIT} state_fifo;
// state_fifo current_state_f, next_state_f;

// always_ff @(posedge clk) begin
//     if(reset) begin
//         shift_reg_valid <= '0; 
//     end else begin
//         if (match_found) begin
//             shift_reg[1] <= shift_reg[0];
//             shift_reg[0] <= {fifo_out_y[matched_engine], fifo_out_x[matched_engine], fifo_out_depth[matched_engine]};
//             shift_reg_valid[1] <= shift_reg_valid[0];
//             shift_reg_valid[0] <= 1;
//             fifo_ren[matched_engine] <= 1; 
//         end else if (ready && shift_reg_valid[1] && current_state_f != FIRST) begin
//             // Shift out when pixel_gen is ready
//             shift_reg[1] <= 0;
//             shift_reg_valid[1] <= 0;
//         end
//     end
// end

// always_comb begin
//     if(pixel_x == shift_reg[1][19:10] && pixel_y == shift_reg[1][28:20]) begin
//         valid_int = 1; 
//         matched_depth = shift_reg[1][9:0]; 
//     end else begin
//         valid_int = 0;      
//     end
// end

// always_ff @(posedge clk) begin
//     if(reset) begin
//         current_state_f <= FIRST;
//     end else begin
//         current_state_f <= next_state_f;
//     end
// end

// always_comb begin
//     match_found = 0;
//     matched_engine = 0;

//     case(current_state_f)
//         FIRST: begin
            
//             for (int j = 0; j < NUM_ENGINES; j++) begin
//                 if(!fifo_empty[j] && fifo_out_x[j] == 0 && fifo_out_y[j] == 0 && !match_found) begin
//                     match_found = 1;
//                     matched_engine = j;
//                 end
//             end
//             if(match_found) begin
//                 next_state_f = IDLE;
//             end else begin
//                 next_state_f = FIRST; // Stay in FIRST state until a match is found
//             end
//         end
//         IDLE: begin
//             for(int j = 0; j < NUM_ENGINES; j++) begin
//                 if(!fifo_empty[j] && fifo_out_x[j] == match_x && fifo_out_y[j] == match_y && !match_found) begin
//                     match_found = 1;
//                     matched_engine = j;
//                 end
//             end
//             if(match_found) begin
//                 next_state_f = INIT;
//             end else begin
//                 next_state_f = IDLE; // Stay in IDLE state until a match is found
//             end
//         end
//         INIT: begin
//             for(int j = 0; j < NUM_ENGINES; j++) begin
//                 if(!fifo_empty[j] && fifo_out_x[j] == match_x && fifo_out_y[j] == match_y && !match_found) begin
//                     match_found = 1;
//                     matched_engine = j;
//                 end
//             end
//             if(match_found) begin
//                 next_state_f = INIT;
//             end else begin
//                 next_state_f = IDLE; // Stay in IDLE state until a match is found
//             end
//         end
//     endcase
// end



// logic output_fifo_full; // Output FIFO full signal 
// logic output_fifo_ren, output_fifo_empty, output_fifo_wen;
// logic [DATA_WIDTH-1:0] output_fifo_data_out, output_fifo_data_in;
// logic [9:0] output_fifo_depth, output_fifo_x;
// logic [8:0] output_fifo_y; 
// // don't need any backpressure because same speed going in and out



// single_fifo #(
//     .DATA_WIDTH(29), // 10 bits for depth, 10 bits for x, 9 bits for y
//     .DEPTH(FIFO_DEPTH)
// ) output_fifo (
//     .clk(clk),
//     .reset(reset),
//     .data_in(output_fifo_data_in), 
//     .full(output_fifo_full),
//     .write_en(output_fifo_wen),
//     .read_en(output_fifo_ren),
//     .empty(output_fifo_empty),
//     .data_out(output_fifo_data_out)
// );

// always_comb begin
//     match_found = 0;
//     matched_engine = 0;
//     for (int j = 0; j < NUM_ENGINES; j++) begin
//         if (!fifo_empty[j] && fifo_out_x[j] == order_x && fifo_out_y[j] == order_y && !match_found) begin
//             match_found = 1;
//             matched_engine = j;
//         end
//     end
// end

// always_ff @(posedge clk) begin
//     if(reset) begin
//         state_f<=IDLE;
//         fifo_ren <= '0;
//         order_x <= 0;
//         order_y <= 0;
//     end else begin 
//         fifo_ren <= '0; 
//         output_fifo_wen <= 0; // Reset output FIFO write enable
//         case (state_f)
//             IDLE: begin
//                 if(match_found && !fifo_empty[matched_engine]) begin
//                     fifo_ren[matched_engine]<= 1;
//                     output_fifo_data_in <= {fifo_out_y[matched_engine], fifo_out_x[matched_engine],fifo_out_depth[matched_engine]}; 
//                     output_fifo_wen <= 1;
//                     if(order_x == SCREEN_WIDTH - 1) begin
//                         order_x <= 0; // Reset x to 0
//                         if(order_y == SCREEN_HEIGHT - 1) begin
//                             order_y <= 0; // Reset y to 0
//                         end else begin
//                             order_y <= order_y + 1; // Increment y
//                         end
//                     end else begin
//                         order_x <= order_x + 1; // Increment x
//                     end
//                     state_f <= INIT;
//                 end
//             end
//             INIT: begin
//                 // output fifo is connected already
//                 if(match_found && !fifo_empty[matched_engine]) begin
//                     fifo_ren[matched_engine]<= 1;
//                     output_fifo_data_in <= {fifo_out_y[matched_engine], fifo_out_x[matched_engine],fifo_out_depth[matched_engine]}; 
//                     output_fifo_wen <= 1;
//                     if(order_x == SCREEN_WIDTH - 1) begin
//                         order_x <= 0; // Reset x to 0
//                         if(order_y == SCREEN_HEIGHT - 1) begin
//                             order_y <= 0; // Reset y to 0
//                         end else begin
//                             order_y <= order_y + 1; // Increment y
//                         end
//                     end else begin
//                         order_x <= order_x + 1; // Increment x
//                     end
//                     state_f <= INIT;
//                 end else begin
//                     state_f <= IDLE; 
//                 end
//             end
//             default: begin
//                 state_f <= IDLE;
//             end
//         endcase
//     end
// end

// logic matched_out;
// assign matched_out = (pixel_x == output_fifo_x) && (pixel_y == output_fifo_y);

// typedef enum logic [1:0] {O_IDLE, O_READY} state_output;
// state_output state_o;

// assign output_fifo_depth = output_fifo_data_out[9:0];
// assign output_fifo_x = output_fifo_data_out[19:10];
// assign output_fifo_y = output_fifo_data_out[28:20];

// always_ff @(posedge clk) begin
//     if (reset) begin
//         state_o <= O_IDLE;
//         output_fifo_ren <= 0;
//         data_avail <= 0;
//         // output_fifo_depth <= 0;
//         // output_fifo_x <= 0;
//         // output_fifo_y <= 0;
//     end else begin
//         output_fifo_ren <= 0;
//         data_avail <= 0;

//         case (state_o)
//             O_IDLE: begin
//                 if (!output_fifo_empty) begin
//                     // Latch first value from FIFO
//                     // output_fifo_depth <= output_fifo_data_out[9:0];
//                     // output_fifo_x     <= output_fifo_data_out[19:10];
//                     // output_fifo_y     <= output_fifo_data_out[28:20];
//                     data_avail <= 1;
//                     state_o <= O_READY;
//                 end
//             end
//             O_READY: begin
//                 data_avail <= 1;
//                 if (ready && matched_out) begin
//                     output_fifo_ren <= 1; // Pop FIFO for next value
//                     if (!output_fifo_empty) begin
//                         // Latch next value immediately (pipeline)
//                         // output_fifo_depth <= output_fifo_data_out[9:0];
//                         // output_fifo_x     <= output_fifo_data_out[19:10];
//                         // output_fifo_y     <= output_fifo_data_out[28:20];

//                         state_o <= O_READY;
//                     end else begin
//                         // FIFO is empty after pop, go idle
//                         state_o <= O_IDLE;
//                         data_avail <= 0;
//                     end
//                 end
//             end
//             default: state_o <= O_IDLE;
//         endcase
//     end
// end

endmodule

