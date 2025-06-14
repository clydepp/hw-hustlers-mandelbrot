// To add to module:
// Make word lengths variable such that we can adjust precision
// Take max_iter from registers on the PYNQ
// Speed up


module depth_calculator #(
    parameter   FRAC = 28,
    parameter   WORD_LENGTH = 32 // Total bits for fixed-point representation
)(
    input logic              sysclk,
    input logic              start,         // Controls when we begin calculating
    input logic              reset,
    input logic [9:0]        x,
    input logic [8:0]        y,
    input logic [9:0]        max_iter,
 
    input logic signed  [WORD_LENGTH-1:0]       re_c,
    input logic signed  [WORD_LENGTH-1:0]       im_c,
    output logic signed [9:0]       final_depth,
    output logic signed            done           // might need to make it such that it can output x and y
);

typedef enum logic [2:0] {
  IDLE,
  ITER_1,
  ITER_2,
  ITER_3,
  FINISHED,
  JUMP_THROUGH
} my_states;

my_states current_state, next_state;

logic signed [WORD_LENGTH-1:0] re_z;
logic signed [WORD_LENGTH-1:0] im_z;

logic signed [2*WORD_LENGTH-1:0] re_z_2;
logic signed [2*WORD_LENGTH-1:0] im_z_2;
logic signed [2*WORD_LENGTH-1:0] cross_product;                             // cross product 2 * re_z * im_z

//logic [7:0] max_iter = 10;                          // need to get maximum depth from registers when actually implemented

logic [9:0] depth;

//logic [2:0] count;      // Created in testing to see gap between signals to hopefully fix issues

localparam logic [2*WORD_LENGTH-1:0] THRESHOLD = 32'd4 * (1<<FRAC) * (1<<FRAC);
localparam int HALF_WIDTH = WORD_LENGTH / 2;
localparam int lim1 = (WORD_LENGTH >> 1) - 1; // limit for low part of the word
localparam int lim2 = WORD_LENGTH - 1; // limit for high part of the word
logic signed [2*WORD_LENGTH-1:0] pr0, pr1, pr2;  // re low×low, hi×low, hi×hi
logic signed [2*WORD_LENGTH-1:0] pi0, pi1, pi2;  // im low×low, hi×low, hi×hi
logic signed [2*WORD_LENGTH-1:0] pc0, pc1, pc2, pc3; // re_lo×im_lo, re_hi×im_lo, re_lo×im_hi, re_hi×im_hi
// next_state logic
logic signed [HALF_WIDTH-1:0] re_z_lo, re_z_hi;
logic signed [HALF_WIDTH-1:0] im_z_lo, im_z_hi;

// Always split the current z values
always_comb begin
    re_z_lo = re_z[HALF_WIDTH-1:0];
    re_z_hi = re_z[WORD_LENGTH-1:HALF_WIDTH];
    im_z_lo = im_z[HALF_WIDTH-1:0];
    im_z_hi = im_z[WORD_LENGTH-1:HALF_WIDTH];
end

// for adjusting to julia set want to feed in re_c, im_c to Z0 and have C some constant

logic [31:0] re_c_manual = 32'h0000;
logic [31:0] im_c_manual = 32'h0000;

always_ff @(posedge sysclk, posedge reset) begin

    if(reset) begin
        current_state <= IDLE;
        re_z <= 0;
        im_z <= 0;
        depth <= 0;
        done <= 0;
        final_depth <= 0;
    end
    
    else begin

    current_state <= next_state;
    case(current_state)

        IDLE: begin
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
            final_depth <= depth-1;
        end

        JUMP_THROUGH: begin
            done <= 1;
            final_depth <= 0;
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


localparam logic signed [WORD_LENGTH - 1:0] Q_THREE_16TH   = 5 <<< (FRAC-5);   // 3/16 * 2^28     5/32    
localparam logic signed [WORD_LENGTH - 1:0] Q_FIFTEEN_16TH = 61 <<< (FRAC-6);   // 15/16 * 2^28  63/64        *with FRAC = 28  

// Possibly could just do to 16 bit precision

// Main cardioid & period 2 bulb check
logic signed [WORD_LENGTH - 1 : 0] inside_cardioid;  
logic signed [WORD_LENGTH - 1 : 0] inside_bulb; 
logic inside_boundary;

// Need to recast re_z_2 & im_z_2

// Big issue with re_z_2 * im_z_2 being 0 for ages: if doesn't complete a whole cycle then re_z_2 is 0 which then causes the inequality to not be satisfied as expected

// Interdependency between moving forward and inside_boundary 

logic signed [WORD_LENGTH - 1 : 0] recast_re = re_z_2 >>> FRAC;
logic signed [WORD_LENGTH - 1 : 0] recast_im = im_z_2 >>> FRAC;
logic signed [WORD_LENGTH - 1 : 0] shifted_re_c = re_c >>> 1;


assign inside_cardioid = recast_re + shifted_re_c + recast_im;  //   x^2 +0.5x +y^2 < 3/16
assign inside_bulb = inside_cardioid + re_c + shifted_re_c; // x^2 +2x +y^2 < -15/16 e.g (x^2 + 0.5x +y^2 +1.5x)

// assign inside_boundary = (inside_cardioid < Q_THREE_16TH);

logic delayed_inside_boundary, jump_through;

always_ff @(posedge sysclk) begin
    inside_boundary <= ((inside_cardioid < Q_THREE_16TH) || (inside_bulb < -Q_FIFTEEN_16TH));
end

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
        if(escaped || (max_iter == depth)) next_state = FINISHED;
        else if(inside_boundary && (depth == 2)) next_state = JUMP_THROUGH;

        else next_state = ITER_1;
//        done = 0;
    end
    FINISHED: begin 
        next_state = IDLE;
//        done = 1;
    end

    JUMP_THROUGH: begin
        next_state = IDLE;
    end

    default: next_state = IDLE;
    endcase
end

endmodule
