// 32‐bit depth calculator (Q4.28) using 16×16→32 partial multiplies
// — fix: check “escaped” in ITER_2, since in ITER_2
//   (re_z_2 + im_z_2) is already (zₙ.real² + zₙ.imag²)>>FRAC.

module ali_depth_calculator #(
    parameter int FRAC        = 28,
    parameter int WORD_LENGTH = 32
)(
    input  logic                        sysclk,
    input  logic                        start,
    input  logic                        reset,
    input  logic [WORD_LENGTH-1:0]      re_c,
    input  logic [WORD_LENGTH-1:0]      im_c,
    input  logic [7:0]                  max_iter,
    output logic [9:0]                  final_depth,
    output logic                        done
);

    // ── State encoding ───────────────────────────────────────────────────────
    typedef enum logic [2:0] {
        IDLE    = 3'd0,
        ITER_1a = 3'd1,
        ITER_1b = 3'd2,
        ITER_2  = 3'd3,
        ITER_3  = 3'd4,
        FINISHED= 3'd5
    } my_states;

    my_states current_state, next_state;

    // ── “Current zₙ” (each is Q[FRAC]) ─────────────────────────────────────────
    logic signed [WORD_LENGTH-1:0] re_z, im_z;

    // ── After squaring but *before* shifting → these are 64‐bit raw results ──
    logic signed [2*WORD_LENGTH-1:0] raw_re2, raw_im2, raw_cross;

    // ── After shifting right by FRAC → each is back in Q[FRAC] ───────────────
    logic signed [2*WORD_LENGTH-1:0] re_z_2, im_z_2, cross_product;

    // ── 16×16 → 32 partial products for re_z², im_z², re_z·im_z ────────────
    logic signed [31:0] pr0, pr1, pr2;  // re low×low, hi×low, hi×hi
    logic signed [31:0] pi0, pi1, pi2;  // im low×low, hi×low, hi×hi
    logic signed [31:0] pc0, pc1, pc2, pc3; // re_lo×im_lo, re_hi×im_lo, re_lo×im_hi, re_hi×im_hi

    logic [9:0]  depth;        // iteration counter
    logic        escaped;      // combinational: (re_z_2 + im_z_2) > 4<<FRAC
    localparam logic [2*WORD_LENGTH-1:0] THRESHOLD = (64'd4 <<< FRAC);

    // ── Sequential (clocked) logic ────────────────────────────────────────────
    always_ff @(posedge sysclk or posedge reset) begin
        if (reset) begin
            current_state  <= IDLE;
            re_z           <= '0;
            im_z           <= '0;
            raw_re2        <= '0;
            raw_im2        <= '0;
            raw_cross      <= '0;
            re_z_2         <= '0;
            im_z_2         <= '0;
            cross_product  <= '0;
            depth          <= '0;
            done           <= 1'b0;
            final_depth    <= 10'd0;
        end else begin
            current_state <= next_state;
            case (current_state)
                IDLE: begin
                    if (start) begin
                        re_z        <= '0;    // z₀ = 0 + j·0
                        im_z        <= '0;
                        depth       <= '0;
                        done        <= 1'b0;
                        re_z_2 <= 0;
                        im_z_2 <= 0;
                    end
                end

                // ── ITER_1a: form all 16×16 partial products based on old zₙ ──────
                ITER_1a: begin
                    pr0 <= $signed(re_z[15:0])   * $signed(re_z[15:0]);   // re_lo²
                    pr1 <= $signed(re_z[31:16])  * $signed(re_z[15:0]);   // re_hi×re_lo
                    pr2 <= $signed(re_z[31:16])  * $signed(re_z[31:16]);  // re_hi²

                    pi0 <= $signed(im_z[15:0])   * $signed(im_z[15:0]);   // im_lo²
                    pi1 <= $signed(im_z[31:16])  * $signed(im_z[15:0]);   // im_hi×im_lo
                    pi2 <= $signed(im_z[31:16])  * $signed(im_z[31:16]);  // im_hi²

                    pc0 <= $signed(re_z[15:0])   * $signed(im_z[15:0]);   // re_lo×im_lo
                    pc1 <= $signed(re_z[31:16])  * $signed(im_z[15:0]);   // re_hi×im_lo
                    pc2 <= $signed(re_z[15:0])   * $signed(im_z[31:16]);  // re_lo×im_hi
                    pc3 <= $signed(re_z[31:16])  * $signed(im_z[31:16]);  // re_hi×im_hi
                    final_depth <= 0;
                    re_z_2 <= 0;
                    im_z_2 <= 0;
                end

                // ── ITER_1b: reconstruct 64-bit “raw” squares/cross from 16×16 parts ─
                ITER_1b: begin
                    // raw_re2 = (re_hi²)<<32  +  2·(re_hi·re_lo)<<16  +  (re_lo²)
                    raw_re2 <= ($signed(pr2) <<< 32)
                               + ($signed(pr1) <<< 17)    // pr1<<<17 == (pr1<<1)<<16
                               + $signed(pr0);

                    // raw_im2 = (im_hi²)<<32  +  2·(im_hi·im_lo)<<16  +  (im_lo²)
                    raw_im2 <= ($signed(pi2) <<< 32)
                               + ($signed(pi1) <<< 17)
                               + $signed(pi0);

                    // raw_cross = (re_hi·im_hi)<<32 
                    //           + (re_hi·im_lo + re_lo·im_hi)<<16 
                    //           + (re_lo·im_lo)
                    raw_cross <= ($signed(pc3) <<< 32)
                                 + ( ($signed(pc1) + $signed(pc2)) <<< 16 )
                                 + $signed(pc0);
                end

                // ── ITER_2: shift right by FRAC to get back to Q[FRAC], also *2 for cross  ─
                ITER_2: begin
                    // Now re_z_2 = (raw_re2 >> FRAC), in Q[FRAC]
                    re_z_2        <= $signed(raw_re2) >>> FRAC;
                    im_z_2        <= $signed(raw_im2) >>> FRAC;
                    // cross = 2·raw_cross >> FRAC  (i.e. 2·(re·im) in Q[FRAC])
                    cross_product <= ($signed(raw_cross) <<< 1) >>> FRAC;
                end

                // ── ITER_3: form next zₙ₊₁ = (re_z_2 - im_z_2 + re_c) + j·(cross_product + im_c)
                //           then bump depth
                ITER_3: begin
                    re_z  <= $signed(re_z_2 - im_z_2) + $signed(re_c);
                    im_z  <= $signed(cross_product)   + $signed(im_c);
                    depth <= depth + 10'd1;
                end

                // ── FINISHED: latch done =1, final_depth=depth-1 (or depth)
                FINISHED: begin
                    done        <= 1'b1;
                    final_depth <= depth;  // extend 8-bit depth → 10 bits
                end

                default: begin
                    re_z        <= re_z;
                    im_z        <= im_z;
                    depth       <= depth;
                    done        <= 1'b0;
                    final_depth <= final_depth;                    
                end
            endcase
        end
    end

    // ── Combinational: decide next_state + “escaped” flag ────────────────────
    always_comb begin
        next_state = current_state;
        // “escaped” uses (re_z_2 + im_z_2) *after* they were shifted >> FRAC in ITER_2
        escaped = ((re_z_2 + im_z_2) > THRESHOLD) || (depth >= max_iter);

        case (current_state)
            IDLE: begin
                if (start)
                    next_state = ITER_1a;
            end

            ITER_1a: next_state = ITER_1b;
            ITER_1b: next_state = ITER_2;

            ITER_2: begin
                // Immediately check escape _before_ we form zₙ₊₁ in ITER_3
                    next_state = ITER_3;
            end

            ITER_3: begin
                // We always go back and square “new z” next
                if(!escaped) next_state = ITER_1a;
                else next_state = FINISHED;
            end

            FINISHED: begin
                next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

endmodule
