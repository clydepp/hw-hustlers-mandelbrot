/**
 * @brief Converts a screen pixel coordinate (x, y) to a complex number (C).
 *
 * @details This module implements a high-performance, two-stage pipeline to meet
 * a 140 MHz clock target. It uses a high/low parts multiplication
 * technique to perform full-precision calculations while efficiently
 * mapping to FPGA resources (1 DSP + Fabric Logic per coordinate).
 * Arithmetic is handled explicitly to ensure correctness and prevent
 * synthesis tool ambiguity.
 *
 * Pipeline Stages:
 * - Stage 1: Performs the parallel high-part (DSP) and low-part (Fabric)
 * multiplications. Latches all necessary values for Stage 2.
 * - Stage 2: Combinationally reconstructs the full multiplication offset,
 * then performs the final addition. The result is registered at the output.
 *
 * Latency: 2 clock cycles.
 */
module pixel_to_complex #(
    parameter int WORD_LENGTH   = 32,
    parameter int FRAC          = 28,
    parameter int SCREEN_WIDTH  = 960,
    parameter int SCREEN_HEIGHT = 720
)(
    // Interface
    input  logic [31:0]                  ZOOM,
    input  logic signed [WORD_LENGTH-1:0]  real_center,
    input  logic signed [WORD_LENGTH-1:0]  imag_center,
    input  logic                         clk,
    input  logic                         rst,
    input  logic signed [10:0]             x,
    input  logic signed [10:0]             y,
    output logic signed [WORD_LENGTH-1:0]  real_part,
    output logic signed [WORD_LENGTH-1:0]  im_part
);

    // --- Internal Signals ---

    // Combinational signals calculated from inputs
    logic signed [WORD_LENGTH-1:0] step_real, step_imag;
    logic signed [WORD_LENGTH-1:0] real_min, imag_max;
    logic signed [24:0]            step_real_h, step_imag_h;
    logic        [6:0]             step_real_l, step_imag_l; // Unsigned is correct for decomposition

    // Stage 1 Pipeline Registers
    logic signed [42:0]            dsp_prod_re_reg, dsp_prod_im_reg;
    logic signed [17:0]            fabric_prod_re_reg, fabric_prod_im_reg;
    logic signed [WORD_LENGTH-1:0] real_min_reg, imag_max_reg;

    // Stage 2 Intermediate Combinational Signals
    logic signed [WORD_LENGTH-1:0] offset_re, offset_im;


    // --- Combinational Logic for Per-Frame Setup ---
    // This block calculates constants based on the current ZOOM and center.
    always_comb begin
        logic signed [WORD_LENGTH-1:0] real_width  = (3 * (1 <<< FRAC)) >>> ZOOM;
        logic signed [WORD_LENGTH-1:0] imag_height = (2 * (1 <<< FRAC)) >>> ZOOM;

        real_min = real_center - (real_width >>> 1);
        imag_max = imag_center + (imag_height >>> 1);

        step_real = real_width / SCREEN_WIDTH;
        step_imag = imag_height / SCREEN_HEIGHT;

        // Split step values into a 25-bit high part and 7-bit low part
        step_real_h = step_real >>> 7;
        step_real_l = step_real[6:0];
        step_imag_h = step_imag >>> 7;
        step_imag_l = step_imag[6:0];
    end


    // --- Pipeline Stage 1: Multiplications ---
    // On each clock edge, perform the multiplications and latch all values needed for Stage 2.
    always_ff @(posedge clk) begin
        if (rst) begin
            // Reset all pipeline registers to a known state
            dsp_prod_re_reg    <= 0;
            fabric_prod_re_reg <= 0;
            dsp_prod_im_reg    <= 0;
            fabric_prod_im_reg <= 0;
            real_min_reg       <= 0;
            imag_max_reg       <= 0;
        end else begin
            // Perform high-part multiplication (maps to DSP slice)
            dsp_prod_re_reg    <= x * step_real_h;
            dsp_prod_im_reg    <= y * step_imag_h;
            
            // Perform low-part multiplication (maps to Fabric Logic/LUTs)
            fabric_prod_re_reg <= x * step_real_l;
            fabric_prod_im_reg <= y * step_imag_l;
            
            // Latch the base values to align them in the pipeline for Stage 2
            real_min_reg       <= real_min;
            imag_max_reg       <= imag_max;
        end
    end


    // --- Pipeline Stage 2: Reconstruction and Final Addition ---
    
    // Step 2a: Combinational logic to reconstruct the full offset from Stage 1's results.
    // This explicitly reconstructs and casts the full product to WORD_LENGTH, removing ambiguity.
    always_comb begin
        offset_re = (dsp_prod_re_reg << 7) + fabric_prod_re_reg;
        offset_im = (dsp_prod_im_reg << 7) + fabric_prod_im_reg;
    end

    // Step 2b: Final clocked stage to perform the simple addition and register the output.
    always_ff @(posedge clk) begin
        if (rst) begin
             real_part <= 0;
             im_part   <= 0;
        end else begin
            // Perform a clean, unambiguous, same-width addition.
            real_part <= real_min_reg + offset_re;
            im_part   <= imag_max_reg - offset_im;
        end
    end

endmodule