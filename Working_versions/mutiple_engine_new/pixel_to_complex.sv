module pixel_to_complex#(
    parameter int WORD_LENGTH = 32,
    parameter int FRAC = 28
 )(
    
    // input int SCREEN_WIDTH,
    // input int SCREEN_HEIGHT,
    input  int ZOOM,
    //input logic unsigned [31:0] ZOOM_RECIPROCAL, // 1/ZOOM in Qm.n format
    input  logic signed [WORD_LENGTH-1:0] real_center, // in Q4.28
    input  logic signed [WORD_LENGTH-1:0] imag_center, // 
    input  logic        clk,
    input  logic [10:0]  x,
    input  logic [10:0]  y,
    output logic signed [WORD_LENGTH-1:0] real_part,
    output logic signed [WORD_LENGTH-1:0] im_part
);
    localparam int SCREEN_HEIGHT = 480;
    localparam int SCREEN_WIDTH  = 640;
    logic signed [WORD_LENGTH-1:0] real_min, real_width;
    logic signed [WORD_LENGTH-1:0] imag_max, imag_height;
    logic signed [WORD_LENGTH-1:0] x_scaled, y_scaled;
    logic signed [(2*WORD_LENGTH)-1:0] x_scaled_temp, y_scaled_temp;
    logic signed [(2*WORD_LENGTH)-1:0] real_width_temp, imag_height_temp;
    logic signed [WORD_LENGTH-1:0] one = 1 <<< FRAC;
    always_comb begin
        

        //real_width_temp  = (3 * one) >>> ZOOM; // Qm.n * Q0.16 = Qm.n
       // imag_height_temp = (2 * one) >>> ZOOM; // Qm.n * Q0.16 = Qm.n
        real_width  = (3 * one) >>> ZOOM; // same for imag_height
        imag_height = (2 * one) >>> ZOOM; // Qm.n * Q0.16 = Qm.n
        //imag_height = imag_height_temp >>> FRAC;
        real_min = real_center - (real_width >>> 1);
        imag_max = imag_center + (imag_height >>> 1);

        x_scaled_temp = (x * real_width);  // Q11 * Qm.n = Q(m+11).n
        x_scaled      = x_scaled_temp / SCREEN_WIDTH;  // Truncate back to Qm.n
       // x_scaled = (x_scaled_temp + (SCREEN_WIDTH >> 1)) / SCREEN_WIDTH;
        y_scaled_temp = (y * imag_height);
        y_scaled      = y_scaled_temp / SCREEN_HEIGHT;
       // y_scaled = (y_scaled_temp + (SCREEN_HEIGHT >> 1)) / SCREEN_HEIGHT;
       // real_part = real_min + x_scaled;
       // im_part   = imag_max - y_scaled;
    end
    always_ff @(posedge clk) begin
        // Update outputs on clock edge
        real_part <= real_min + x_scaled;
        im_part   <= imag_max - y_scaled;
    end
   // assign real_part = real_min + (x * real_width) / SCREEN_WIDTH;
   // assign im_part   = imag_max - (y * imag_height) / SCREEN_HEIGHT;
endmodule
