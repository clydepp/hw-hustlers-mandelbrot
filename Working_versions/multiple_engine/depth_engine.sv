// To add to module:
// Make word lengths variable such that we can adjust precision
// Take max_iter from registers on the PYNQ
// Speed up


module depth_engine #(
    parameter   FRAC = 28,
    parameter   WORD_LENGTH = 32 // Total bits for fixed-point representation
)(
    input logic              sysclk,
    input logic              start,         // Controls when we begin calculating
    input logic              reset,
    input logic [9:0]        x,
    input logic [8:0]        y,
    input logic [9:0]        max_iter,
    input logic              eol,
 
    input logic [WORD_LENGTH-1:0]       re_c,
    input logic [WORD_LENGTH-1:0]       im_c,
    output logic [9:0]       final_depth,
    output logic             done           // might need to make it such that it can output x and y
);

typedef enum {
  IDLE,
  ITER_1,
  ITER_2,
  ITER_3,
  FINISHED
} my_states;

my_states current_state, next_state;

logic signed [WORD_LENGTH-1:0] re_z;
logic signed [WORD_LENGTH-1:0] im_z;

logic signed [2*WORD_LENGTH-1:0] re_z_2;
logic signed [2*WORD_LENGTH-1:0] im_z_2;
logic signed [2*WORD_LENGTH-1:0] cross_product;                            
logic [9:0] depth;
localparam logic [2*WORD_LENGTH-1:0] THRESHOLD = 32'd4 * (1<<FRAC) * (1<<FRAC);
localparam int HALF_WIDTH = WORD_LENGTH / 2;
logic signed [2*WORD_LENGTH-1:0] pr0, pr1, pr2;  // re low×low, hi×low, hi×hi
logic signed [2*WORD_LENGTH-1:0] pi0, pi1, pi2;  // im low×low, hi×low, hi×hi
logic signed [2*WORD_LENGTH-1:0] pc0, pc1, pc2, pc3; // re_lo×im_lo, re_hi×im_lo, re_lo×im_hi, re_hi×im_hi
logic signed [HALF_WIDTH-1:0] re_z_lo, re_z_hi;
logic signed [HALF_WIDTH-1:0] im_z_lo, im_z_hi;

// Always split the current z values
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
        cross_product <= 0;
        pr0 <= 0; pr1 <= 0; pr2 <= 0;
        pi0 <= 0; pi1 <= 0; pi2 <= 0;
        pc0 <= 0; pc1 <= 0; pc2 <= 0; pc3 <= 0;
        re_z_2 <= 0;
        im_z_2 <= 0;
    end
    
    else begin

    current_state <= next_state;
    case(current_state)

        IDLE: begin
            if(eol) begin
                done <= 0;
            end
            if(start) begin
                re_z <= 0;
                im_z <= 0;
                depth <= 0;
                done <= 0;              // important change take note
            end
        end

        ITER_1: begin


            pr0 <= re_z_lo * re_z_lo;           // re_lo²
                pr1 <= re_z_hi * re_z_lo;           // re_hi×re_lo (will be doubled and shifted)
                pr2 <= re_z_hi * re_z_hi;           // re_hi²

                // Imaginary part: (im_hi * 2^n + im_lo)^2
                pi0 <= im_z_lo * im_z_lo;           // im_lo²
                pi1 <= im_z_hi * im_z_lo;           // im_hi×im_lo (will be doubled and shifted)
                pi2 <= im_z_hi * im_z_hi;           // im_hi²

                // Cross product: 2 * re_z * im_z = 2 * (re_hi*2^n + re_lo) * (im_hi*2^n + im_lo)
                pc0 <= re_z_lo * im_z_lo;           // re_lo×im_lo
                pc1 <= re_z_hi * im_z_lo;           // re_hi×im_lo
                pc2 <= re_z_lo * im_z_hi;           // re_lo×im_hi
                pc3 <= re_z_hi * im_z_hi;           // re_hi×im_hi
            // re_z_2 <= re_z * re_z;
            // im_z_2 <= im_z * im_z;
            // cross_product <= (re_z * im_z) <<< 1;
        end
        ITER_2: begin
            //lim1 <= lim1 + 1;
        //    re_z_2 <= (pr2 << WORD_LENGTH) + (pr1 << (WORD_LENGTH/2)) + pr0;
        //     im_z_2 <= (pi2 << WORD_LENGTH) + (pi1 << (WORD_LENGTH/2)) + pi0;
        //     cross_product <= ((pc3 << WORD_LENGTH) + (pc2 << (WORD_LENGTH/2)) + (pc1 << (WORD_LENGTH/2)) + pc0) << 1;
         re_z_2 <= ({{(WORD_LENGTH-2*HALF_WIDTH){pr2[2*HALF_WIDTH-1]}}, pr2} << WORD_LENGTH) + 
                         ({{(HALF_WIDTH){pr1[2*HALF_WIDTH-1]}}, pr1} << (HALF_WIDTH + 1)) + 
                         {{(WORD_LENGTH-2*HALF_WIDTH){pr0[2*HALF_WIDTH-1]}}, pr0};
                
        // For im_z²: pi2*2^(2n) + 2*pi1*2^n + pi0  
        im_z_2 <= ({{(WORD_LENGTH-2*HALF_WIDTH){pi2[2*HALF_WIDTH-1]}}, pi2} << WORD_LENGTH) + 
                    ({{(HALF_WIDTH){pi1[2*HALF_WIDTH-1]}}, pi1} << (HALF_WIDTH + 1)) + 
                    {{(WORD_LENGTH-2*HALF_WIDTH){pi0[2*HALF_WIDTH-1]}}, pi0};
                
        // For cross product: 2 * (pc3*2^(2n) + pc2*2^n + pc1*2^n + pc0)
        cross_product <= ((({{(WORD_LENGTH-2*HALF_WIDTH){pc3[2*HALF_WIDTH-1]}}, pc3} << WORD_LENGTH) + 
                            ({{(HALF_WIDTH){pc2[2*HALF_WIDTH-1]}}, pc2} << HALF_WIDTH) + 
                            ({{(HALF_WIDTH){pc1[2*HALF_WIDTH-1]}}, pc1} << HALF_WIDTH) + 
                            {{(WORD_LENGTH-2*HALF_WIDTH){pc0[2*HALF_WIDTH-1]}}, pc0}) << 1);
        end
        // need to compute Z_re
        ITER_3: begin
         
            re_z  <= (re_z_2   >>> FRAC) - (im_z_2  >>> FRAC) + re_c;
            im_z  <= (cross_product >>> FRAC)   + im_c;
            depth <= depth + 1;
            done <= 0;
        end

        FINISHED: begin
            done <= 1;
            final_depth <= depth;
            // final_depth <= depth-1;
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


/// making sure we calculate with the correct current values
// always_comb begin
//     re_z_2 = re_z * re_z;
//     im_z_2 = im_z * im_z;
//     cross_product = (re_z * im_z) <<< 1;
// end


always_comb begin

    // Computed combinationally to get current values
    logic escaped;
    escaped = (re_z_2 + im_z_2) > THRESHOLD;

    next_state = current_state;
    
    case(current_state)

    IDLE: begin
        if(start) next_state = ITER_1;
//        done = 1;
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
//        done = 0;
    end
    FINISHED: begin 
        next_state = IDLE;
//        done = 1;
    end

    default: next_state = IDLE;
    endcase
end

endmodule
