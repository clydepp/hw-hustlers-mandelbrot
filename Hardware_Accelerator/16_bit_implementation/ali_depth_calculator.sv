// To add to module:
// Make word lengths variable such that we can adjust precision
// Take max_iter from registers on the PYNQ
// Speed up


module depth_calculator #(
    parameter   int FRAC = 28,
    parameter   int WORD_LENGTH = 32
)(
    input logic                         sysclk,
    input logic                         start,       
    input logic                         reset,
    input logic [WORD_LENGTH-1:0]       re_c,
    input logic [WORD_LENGTH-1:0]       im_c,
    input logic [7:0]                   max_iter,
    output logic [9:0]                  final_depth,
    output logic                        done           
);

typedef enum {IDLE, ITER_1a, ITER_1b, ITER_2, ITER_3, FINISHED} my_states;

my_states current_state, next_state;

logic signed [WORD_LENGTH-1:0] re_z;
logic signed [WORD_LENGTH-1:0] im_z;

logic signed [(2*WORD_LENGTH)-1:0] re_z_2;
logic signed [(2*WORD_LENGTH)-1:0] im_z_2;
logic signed [WORD_LENGTH-1:0] pr0, pr1, pr2, pi0, pi1, pi2, pc0, pc1, pc2, pc3;                             
 // verilator lint_off UNUSED
logic signed [(2*WORD_LENGTH)-1:0] cross_product;                             // cross_product product 2 * re_z * im_z
 // verilator lint_on UNUSED
logic [9:0] max_iter = 200;                          // need to get maximum depth from registers when actually implemented

logic [9:0] depth;

localparam logic [(2*WORD_LENGTH)-1:0] THRESHOLD = 128'd4 * (1<<FRAC) * (1<<FRAC);

// next_state logic

always_ff @(posedge sysclk, posedge reset) begin

    if(reset) begin
        current_state <= IDLE;
        re_z <= 0;
        im_z <= 0;
        depth <= 0;
        done <= 0; //switch to 1
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
                done <= 0;
                final_depth <= 0;
            end
        end


        // need to compute Z_re
        ITER_1a: begin
            pr0 <= re_z[15:0] * re_z[15:0];
            pr1 <= re_z[31:16] * re_z[15:0];
            pr2 <= re_z[31:16] * re_z[31:16];
            pi0 <= im_z[15:0] * im_z[15:0];
            pi1 <= im_z[31:16] * im_z[15:0];
            pi2 <= im_z[31:16] * im_z[31:16];
            pc0 <= re_z[15:0] * im_z[15:0];
            pc1 <= re_z[31:16] * im_z[15:0];
            pc2 <= re_z[15:0] * im_z[31:16];
            pc3 <= re_z[31:16] * im_z[31:16];


            // re_z_2 <= re_z * re_z;
            // im_z_2 <= im_z * im_z;
            // cross_product <= (re_z * im_z) <<< 1; // cross_product product 2 * re_z * im_z
        end
        ITER_1b: begin
            re_z_2 <= (pr2 <<< 32) + (pr1 <<< 17) + pr0; //17 because x2
            im_z_2 <= (pi2 <<< 32) + (pi1 <<< 17) + pi0; //17 because x2
            cross_product <= (pc3 <<< 32) + (pc2 <<< 17) + (pc1 <<< 1) + pc0; // cross_product product 2 * re_z * im_z

        end
        ITER_2: begin
            re_z_2 <= $signed(re_z_2) >>> FRAC;
            im_z_2 <= $signed(im_z_2) >>> FRAC;
            cross_product <= $signed(cross_product) >>> FRAC;
        end
        ITER_3: begin
            re_z <= $signed(re_z_2 - im_z_2) + re_c;
            im_z <= $signed(cross_product + im_c);
            depth <= depth + 1;
        end
        FINISHED: begin
            done <= 1;
            final_depth <= depth;//-1;
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



always_comb begin

    // Computed combinationally to get current values
    logic escaped;
    escaped = (re_z_2 + im_z_2) > THRESHOLD;

    
    case(current_state)

    IDLE: if(start) next_state = ITER_1a; 
          else next_state = IDLE;

    ITER_1a: next_state = ITER_1b;

    ITER_1b: next_state = ITER_2;

    ITER_2: next_state = ITER_3;

    ITER_3: if(escaped || max_iter == depth) next_state = FINISHED; 
             else next_state = ITER_1;

    FINISHED: next_state = IDLE;

    default: next_state = IDLE;
    endcase
end

endmodule
