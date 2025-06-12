module pixel_to_complex #(
    parameter int WORD_LENGTH = 32,
    parameter int FRAC = 28,
    parameter int SCREEN_WIDTH = 640,
    parameter int SCREEN_HEIGHT = 480
    
)(
    input  logic [31:0] ZOOM,  // Q4.28 or similar, passed in as fixed-point integer
    input  logic signed [WORD_LENGTH-1:0] real_center, // Qm.n
    input  logic signed [WORD_LENGTH-1:0] imag_center, // Qm.n
    input  logic clk,
    input  logic rst,
    input  logic [10:0] x,  // pixel x
    input  logic [10:0] y,  // pixel y
    output logic signed [WORD_LENGTH-1:0] real_part,
    output logic signed [WORD_LENGTH-1:0] im_part
);

    localparam int TOTAL_BITS = 2 * WORD_LENGTH;
    // localparam int SCREEN_WIDTH = 640;
    // parameter int SCREEN_HEIGHT = 480;
    localparam [WORD_LENGTH-1:0] one_fp = 1 <<< FRAC;

    // Precomputed per-frame constants (do once per frame, externally or in control FSM)
    logic signed [WORD_LENGTH-1:0] step_real, step_imag;
    logic signed [WORD_LENGTH-1:0] real_min, imag_max;

    // Intermediate signals
    logic signed [TOTAL_BITS-1:0] x_scaled_temp, y_scaled_temp;
    logic signed [WORD_LENGTH-1:0] x_scaled, y_scaled;
    logic signed [WORD_LENGTH-1:0] imag_height;
    logic signed [WORD_LENGTH-1:0] real_width;
    logic [10:0] prev_x, prev_y;
    always_comb begin
        if (rst) begin
            step_real = 0;
            step_imag = 0;
            real_min  = 0;
            imag_max  = 0;
        end 
        else begin
            real_width  = (3 * one_fp) >>> ZOOM;
            imag_height = (2 * one_fp) >>> ZOOM;

            step_real = real_width  / SCREEN_WIDTH;
            step_imag = imag_height / SCREEN_HEIGHT;

            real_min  = real_center - (real_width >>> 1);
            imag_max  = imag_center + (imag_height >>> 1);
        end
    end


    // Per-pixel logic
    always_ff @(posedge clk) begin
         if (rst) begin
            prev_x     <= 0;
            prev_y     <= 0;
            real_part  <= real_min;
            im_part<= imag_max;  // start at real_min
        end else begin
            prev_x <= x;
            prev_y <= y;
            if (x == 0) begin
            // beginning of a new scan‐line:
                real_part <= real_min;
            end 
            else if (x != prev_x) begin
      // x has just incremented:
                real_part <= real_part + step_real;
            end
            if (y == 0) begin
            // beginning of a new frame:
                im_part <= imag_max;
            end 
            else if (y != prev_y) begin
      // y has just incremented:
                im_part <= im_part - step_imag;
            end
        end
    end

endmodule
