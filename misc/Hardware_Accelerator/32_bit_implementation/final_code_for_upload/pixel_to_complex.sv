module pixel_to_complex #(
    parameter int WORD_LENGTH = 64,
    parameter int FRAC = 60,
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
    output logic signed [WORD_LENGTH-1:0] im_part,
    input logic sof, // Pulse this when config changes (1 cycle)
    input logic eol
);

    localparam int TOTAL_BITS = 2 * WORD_LENGTH;

    logic signed [WORD_LENGTH-1:0] one_fp = 1 <<< FRAC;

    // Precomputed per-frame constants (do once per frame, externally or in control FSM)
    logic signed [WORD_LENGTH-1:0] step_real, step_imag;
    logic signed [WORD_LENGTH-1:0] real_min, imag_max;

    // Intermediate signals
    logic signed [TOTAL_BITS-1:0] x_scaled_temp, y_scaled_temp;
    logic signed [WORD_LENGTH-1:0] x_scaled, y_scaled;
    logic signed [WORD_LENGTH-1:0] imag_height;
    logic signed [WORD_LENGTH-1:0] real_width;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            step_real <= 0;
            step_imag <= 0;
            real_min  <= 0;
            imag_max  <= 0;
        end else if (sof || eol) begin
            real_width  <= (3 * one_fp) / ZOOM;
            imag_height <= (2 * one_fp) / ZOOM;

            step_real <= real_width  / (SCREEN_WIDTH - 1);
            step_imag <= imag_height / (SCREEN_HEIGHT - 1);

            real_min  <= real_center - (real_width >>> 1);
            imag_max  <= imag_center + (imag_height >>> 1);
        end
    end


    // Per-pixel logic
    always_ff @(posedge clk) begin
        real_part <= real_min + ($signed(x) * $signed(step_real));
        im_part   <= imag_max - ($signed(y) * $signed(step_imag));
    end

endmodule
