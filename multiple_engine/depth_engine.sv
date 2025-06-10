// ===================================================================
// CORRECTED: depth_engine
// Key Changes:
// 1. Removed the 'eol' input port entirely.
// 2. The 'DONE_WAIT' state now correctly handles the full handshake.
// 3. The `always_ff` block is cleaned up to handle the state reset
//    in one logical place.
// ===================================================================
module depth_engine #(
    parameter   FRAC = 28,
    parameter   WORD_LENGTH = 32
)(
    input logic              sysclk,
    input logic              start,         // Controls when we begin calculating
    input logic              reset,
    input logic [9:0]        x,
    input logic [8:0]        y,
    input logic [9:0]        max_iter,
    // input logic              eol,        // REMOVED - This was part of the original bug
 
    input logic [WORD_LENGTH-1:0]       re_c,
    input logic [WORD_LENGTH-1:0]       im_c,
    output logic [9:0]       final_depth,
    output logic             done
);

typedef enum {
  IDLE,
  ITER_1,
  ITER_2,
  ITER_3,
  FINISHED,
  DONE_WAIT // New state for robust handshake
} my_states;

my_states current_state, next_state;

// Internal signal declarations (unchanged)
logic signed [WORD_LENGTH-1:0] re_z;
logic signed [WORD_LENGTH-1:0] im_z;
logic signed [2*WORD_LENGTH-1:0] re_z_2;
logic signed [2*WORD_LENGTH-1:0] im_z_2;
logic signed [2*WORD_LENGTH-1:0] cross_product;
logic [9:0] depth;
localparam logic [2*WORD_LENGTH-1:0] THRESHOLD = 32'd4 * (1<<FRAC) * (1<<FRAC);
localparam int HALF_WIDTH = WORD_LENGTH / 2;
logic signed [2*WORD_LENGTH-1:0] pr0, pr1, pr2;
logic signed [2*WORD_LENGTH-1:0] pi0, pi1, pi2;
logic signed [2*WORD_LENGTH-1:0] pc0, pc1, pc2, pc3;
logic signed [HALF_WIDTH-1:0] re_z_lo, re_z_hi;
logic signed [HALF_WIDTH-1:0] im_z_lo, im_z_hi;

// Combinational logic for splitting z (unchanged)
always_comb begin
    re_z_lo = re_z[HALF_WIDTH-1:0];
    re_z_hi = re_z[WORD_LENGTH-1:HALF_WIDTH];
    im_z_lo = im_z[HALF_WIDTH-1:0];
    im_z_hi = im_z[WORD_LENGTH-1:HALF_WIDTH];
end

// Main sequential state machine logic
always_ff @(posedge sysclk) begin
    if(reset) begin
        current_state <= IDLE;
        re_z <= 0;
        im_z <= 0;
        depth <= 0;
        done <= 0;
        final_depth <= 0;
    end else begin
        current_state <= next_state;

        // --- Start of Corrected Logic ---
        // This 'if (start)' block handles the reset of the engine's values.
        // It's triggered when the manager acknowledges a finished pixel in DONE_WAIT.
        if (start && (current_state == DONE_WAIT || current_state == IDLE)) begin
            re_z <= 0;
            im_z <= 0;
            depth <= 0;
        end
        // --- End of Corrected Logic ---

        case(current_state)
            IDLE: begin
                done <= 0;
            end

            ITER_1: begin
                pr0 <= re_z_lo * re_z_lo;
                pr1 <= re_z_hi * re_z_lo;
                pr2 <= re_z_hi * re_z_hi;
                pi0 <= im_z_lo * im_z_lo;
                pi1 <= im_z_hi * im_z_lo;
                pi2 <= im_z_hi * im_z_hi;
                pc0 <= re_z_lo * im_z_lo;
                pc1 <= re_z_hi * im_z_lo;
                pc2 <= re_z_lo * im_z_hi;
                pc3 <= re_z_hi * im_z_hi;
            end

            ITER_2: begin
                re_z_2 <= ({{(WORD_LENGTH-2*HALF_WIDTH){pr2[2*HALF_WIDTH-1]}}, pr2} << WORD_LENGTH) + 
                         ({{(HALF_WIDTH){pr1[2*HALF_WIDTH-1]}}, pr1} << (HALF_WIDTH + 1)) + 
                         {{(WORD_LENGTH-2*HALF_WIDTH){pr0[2*HALF_WIDTH-1]}}, pr0};
                im_z_2 <= ({{(WORD_LENGTH-2*HALF_WIDTH){pi2[2*HALF_WIDTH-1]}}, pi2} << WORD_LENGTH) + 
                         ({{(HALF_WIDTH){pi1[2*HALF_WIDTH-1]}}, pi1} << (HALF_WIDTH + 1)) + 
                         {{(WORD_LENGTH-2*HALF_WIDTH){pi0[2*HALF_WIDTH-1]}}, pi0};
                cross_product <= ((({{(WORD_LENGTH-2*HALF_WIDTH){pc3[2*HALF_WIDTH-1]}}, pc3} << WORD_LENGTH) + 
                                  ({{(HALF_WIDTH){pc2[2*HALF_WIDTH-1]}}, pc2} << HALF_WIDTH) + 
                                  ({{(HALF_WIDTH){pc1[2*HALF_WIDTH-1]}}, pc1} << HALF_WIDTH) + 
                                  {{(WORD_LENGTH-2*HALF_WIDTH){pc0[2*HALF_WIDTH-1]}}, pc0}) << 1);
            end

            ITER_3: begin
                re_z  <= (re_z_2   >>> FRAC) - (im_z_2  >>> FRAC) + re_c;
                im_z  <= (cross_product >>> FRAC)   + im_c;
                depth <= depth + 1;
                done <= 0;
            end

            FINISHED: begin
                done <= 1; // Assert done to signal completion
                final_depth <= depth;
            end

            DONE_WAIT: begin
                if (start) begin
                    done <= 0;
                end
            end

            default: begin
                done <= 1'b0;
            end
        endcase
    end
end

// Combinational logic for state transitions
always_comb begin
    logic escaped;
    escaped = (re_z_2 + im_z_2) > THRESHOLD;
    next_state = current_state;
    
    case(current_state)
        IDLE: begin
            if(start) next_state = ITER_1;
        end
        ITER_1: begin
            next_state = ITER_2;
        end
        ITER_2: begin
            next_state = ITER_3;
        end
        ITER_3: begin
            if(escaped || max_iter == depth) next_state = FINISHED;
            else next_state = ITER_1;
        end
        FINISHED: begin
            next_state = DONE_WAIT; // Go to wait state
        end
        DONE_WAIT: begin
            if(start) next_state = ITER_1; // When new work starts, go to ITER_1
            else next_state = DONE_WAIT;   // Otherwise, keep waiting
        end
        default: next_state = IDLE;
    endcase
end

endmodule