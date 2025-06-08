// To add to module:
// Make word lengths variable such that we can adjust precision
// Take max_iter from registers on the PYNQ
// Speed up


module depth_calculator #(
    parameter   int FRAC = 60,
    parameter   int WORD_LENGTH = 64
)(
    input logic              sysclk,
    input logic              start,       
    input logic              reset,
    input logic [WORD_LENGTH-1:0]       re_c,
    input logic [WORD_LENGTH-1:0]       im_c,
    output logic [9:0]       final_depth,
    output logic             done           
);

typedef enum {IDLE, ITER_1, ITER_2, ITER_3, FINISHED} my_states;

my_states current_state, next_state;

logic signed [WORD_LENGTH-1:0] re_z;
logic signed [WORD_LENGTH-1:0] im_z;

logic signed [(2*WORD_LENGTH)-1:0] re_z_2;
logic signed [(2*WORD_LENGTH)-1:0] im_z_2;
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
        ITER_1: begin
            re_z_2 <= re_z * re_z;
            im_z_2 <= im_z * im_z;
            cross_product <= (re_z * im_z) <<< 1; // cross_product product 2 * re_z * im_z
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
            final_depth <= depth-1;
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

    IDLE: if(start) next_state = ITER_1;

    ITER_1: next_state = ITER_2;

    ITER_2: next_state = ITER_3;

    ITER_3: if(escaped || max_iter == depth) next_state = FINISHED; 
             else next_state = ITER_1;

    FINISHED: next_state = IDLE;

    default: next_state = IDLE;
    endcase
end

endmodule
