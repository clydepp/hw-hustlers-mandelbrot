module pixel_to_complex #(
    parameter int WORD_LENGTH = 32,
    parameter int FRAC = 28,
    parameter int SCREEN_WIDTH = 960,
    parameter int SCREEN_HEIGHT = 720
)(
    // Interface does NOT change
    input  logic [31:0] ZOOM,
    input  logic signed [WORD_LENGTH-1:0] real_center,
    input  logic signed [WORD_LENGTH-1:0] imag_center,
    input  logic clk,
    input  logic rst,
    input  logic [10:0] x,
    input  logic [10:0] y,
    output logic signed [WORD_LENGTH-1:0] real_part,
    output logic signed [WORD_LENGTH-1:0] im_part
);

    // --- Signals for High/Low Multiplication ---
    logic signed [WORD_LENGTH-1:0] step_real, step_imag;
    logic signed [WORD_LENGTH-1:0] real_min, imag_max;
    
    logic signed [24:0] step_real_h, step_imag_h;
    logic signed [6:0]  step_real_l, step_imag_l;

    // --- Combinational Logic for Setup ---
    always_comb begin
        // ... (This logic is fast enough)
        logic signed [WORD_LENGTH-1:0] real_width = (3 * (1 <<< FRAC)) >>> ZOOM;
        logic signed [WORD_LENGTH-1:0] imag_height = (2 * (1 <<< FRAC)) >>> ZOOM;
        
        real_min = real_center - (real_width >>> 1);
        imag_max = imag_center + (imag_height >>> 1);
        step_real = real_width / SCREEN_WIDTH;
        step_imag = imag_height / SCREEN_HEIGHT;
        
        step_real_h = step_real >>> 7;
        step_real_l = step_real[6:0];
        step_imag_h = step_imag >>> 7;
        step_imag_l = step_imag[6:0];
    end

    // --- Pipelined Hardware Implementation ---
    logic signed [42:0] dsp_prod_re, dsp_prod_im;
    logic signed [17:0] fabric_prod_re, fabric_prod_im;
    logic signed [WORD_LENGTH-1:0] real_min_reg, imag_max_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            real_part <= 0;
            im_part <= 0;
            // ... reset pipeline registers if needed
        end else begin
            // --- STAGE 1: Parallel Multiplications ---
            dsp_prod_re    <= x * step_real_h;
            fabric_prod_re <= x * step_real_l;
            dsp_prod_im    <= y * step_imag_h;
            fabric_prod_im <= y * step_imag_l;
            real_min_reg   <= real_min;
            imag_max_reg   <= imag_max;

            // --- STAGE 2: Final Addition ---
            // The result of this stage will appear on the outputs on the next clock edge
            real_part <= real_min_reg + ((dsp_prod_re << 7) + fabric_prod_re);
            im_part   <= imag_max_reg - ((dsp_prod_im << 7) + fabric_prod_im);
        end
    end

endmodule