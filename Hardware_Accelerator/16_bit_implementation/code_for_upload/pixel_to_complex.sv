module pixel_to_complex#(
    parameter int WORD_LENGTH = 64,
    parameter int FRAC = 60
 )(
    
    input int SCREEN_WIDTH,
    input int SCREEN_HEIGHT,
    input  int ZOOM,
    input  logic signed [WORD_LENGTH-1:0] real_center, // in Q16.16
    input  logic signed [WORD_LENGTH-1:0] imag_center, // in Q16.16
    input  logic        clk,
    input  logic [10:0]  x,
    input  logic [10:0]  y,
    output logic signed [WORD_LENGTH-1:0] real_part,
    output logic signed [WORD_LENGTH-1:0] im_part
);
    logic signed [WORD_LENGTH-1:0] real_min, real_width;
    logic signed [WORD_LENGTH-1:0] imag_max, imag_height;
    logic signed [WORD_LENGTH-1:0] x_scaled, y_scaled;
    logic signed [(2*WORD_LENGTH)-1:0] x_scaled_temp, y_scaled_temp;
    logic signed [WORD_LENGTH-1:0] one = 1 <<< FRAC;
    always_comb begin
        

        real_width  = ((3 * one) / ZOOM);
        imag_height = ((2 * one) / ZOOM);

        real_min = real_center - (real_width >>> 1);
        imag_max = imag_center + (imag_height >>> 1);

        // Scale coordinates to Q16.16 with rounding
       x_scaled_temp = (x * real_width);  // Q11 * Qm.n = Q(m+11).n
        x_scaled      = x_scaled_temp / (SCREEN_WIDTH-1);  // Truncate back to Qm.n
       // x_scaled = (x_scaled_temp + (SCREEN_WIDTH >> 1)) / SCREEN_WIDTH;
        y_scaled_temp = (y * imag_height);
        y_scaled      = y_scaled_temp / (SCREEN_HEIGHT-1);
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
