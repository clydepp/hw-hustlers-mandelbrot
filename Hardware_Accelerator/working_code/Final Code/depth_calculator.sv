// BUGS TO FIX: WHITE PIXELS AT EDGE OF FRAME
module depth_calculator #(
    parameter FRAC = 28,
    parameter WORD_LENGTH = 32
)(
    input logic                          sysclk,
    input logic                          start,
    input logic                          reset,
    input logic unsigned [10:0]          x,
    input logic unsigned [10:0]          y,
    input logic [10:0]                   max_iter,  // Now configurable from registers
    input logic signed [WORD_LENGTH-1:0] re_c,
    input logic signed [WORD_LENGTH-1:0] im_c,
    input logic unsigned [1:0]           WAIT_STAGES, // Used to test timing errors
    output logic [10:0]                  final_depth,
    output logic                         done
);

typedef enum logic [2:0] {
    IDLE      = 3'd0,
    WAIT_1    = 3'd1,
    WAIT_2    = 3'd2,
    WAIT_3    = 3'd3,
    ITERATING = 3'd4,
    FINISHED  = 3'd5
} my_states;

my_states current_state, next_state;

logic signed [WORD_LENGTH-1:0] re_z;
logic signed [WORD_LENGTH-1:0] im_z;

logic signed [2*WORD_LENGTH-1:0] re_z_2;
logic signed [2*WORD_LENGTH-1:0] im_z_2;
logic signed [2*WORD_LENGTH-1:0] cp;  // cross product 2 * re_z * im_z

logic [10:0] depth;  // Made wider to match max_iter for comparison

// Threshold: 4.0 in fixed-point format
localparam logic [2*WORD_LENGTH-1:0] THRESHOLD = (64'd4 << (2*FRAC));

// Main state machine
always_ff @(posedge sysclk) begin
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
                done <= 0;
                re_z <= 0;
                im_z <= 0;
                depth <= 0;
            end
            
            ITERATING: begin
                // Fixed Q-format arithmetic with proper bit selection
                // For Q(WORD_LENGTH-FRAC).FRAC format, we need to shift right by FRAC
                re_z <= ((re_z_2 - im_z_2) >>> FRAC) + re_c;
                im_z <= (cp >>> FRAC) + im_c;
                depth <= depth + 1;
                done <= 0;
            end
            
            FINISHED: begin
                done <= 1;
                final_depth <= depth;  // Truncate to output width
            end
            
            default: begin
                re_z <= re_z;
                im_z <= im_z;
                depth <= depth;
                done <= 1'b0;
                final_depth <= final_depth;
            end
        endcase
    end
end

// Combinational multiplication block
always_comb begin
    re_z_2 = re_z * re_z;
    im_z_2 = im_z * im_z;
    cp = (re_z * im_z) << 1;  // 2 * re_z * im_z
end

// State transition logic
always_comb begin
    logic escaped;
    escaped = (re_z_2 + im_z_2) > THRESHOLD;
    
    next_state = current_state;
    
    case(current_state)
        IDLE: begin
            if(start) next_state = ITERATING;
        end
        
        ITERATING: begin
            if(escaped || (depth >= max_iter)) next_state = FINISHED;
            else next_state = WAIT_1;
        end

        WAIT_1: begin
            if(WAIT_STAGES <= 1) next_state = ITERATING;
            else next_state = WAIT_2;
        end

        WAIT_2: begin
            if(WAIT_STAGES <= 2) next_state = ITERATING;
            else next_state = WAIT_3;
        end

        WAIT_3: next_state = ITERATING;            
        
        FINISHED: begin
            next_state = IDLE;
        end
        
        default: next_state = IDLE;
    endcase
end

endmodule