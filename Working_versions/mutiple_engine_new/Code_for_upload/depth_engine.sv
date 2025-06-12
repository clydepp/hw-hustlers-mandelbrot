module depth_engine #(
    parameter FRAC = 28,
    parameter WORD_LENGTH = 32
)(
    input logic                          sysclk,
    input logic                          start,
    input logic                          reset,
    input logic                          fifo_full,
    input logic [9:0]                   max_iter,  // Now configurable from registers
    input logic signed [WORD_LENGTH-1:0] re_c,
    input logic signed [WORD_LENGTH-1:0] im_c,
    output logic [9:0]                  final_depth,
    output logic                         done,
    output logic                         fifo_wen,      // Write enable for FIFO
    output logic                         written //written to fifo
);

typedef enum logic [2:0] {
    IDLE      = 3'd0,
    WAIT      = 3'd1,
    ITERATING = 3'd2,
    FINISHED  = 3'd3,
    WAIT_FIFO = 3'd4
} my_states;

my_states current_state, next_state;

logic signed [WORD_LENGTH-1:0] re_z;
logic signed [WORD_LENGTH-1:0] im_z;

logic signed [2*WORD_LENGTH-1:0] re_z_2;
logic signed [2*WORD_LENGTH-1:0] im_z_2;
logic signed [2*WORD_LENGTH-1:0] cp;  // cross product 2 * re_z * im_z

logic [9:0] depth;  // Made wider to match max_iter for comparison

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
            final_depth <= depth;
            if(fifo_full) begin
                fifo_wen <= 0; // Do not write to FIFO if it is full
            end else begin
                fifo_wen <= 1; // Write to FIFO if it is not full
                written <= 1; // Indicate that data has been written to FIFO
            end
            // final_depth <= depth-1;
        end

        WAIT_FIFO: begin
            fifo_wen <= 0; 
            written <= 0; // Indicate that data has been written to FIFO
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

        WAIT: next_state = ITERATING; 
        
        ITERATING: begin
            if(escaped || (depth >= max_iter)) next_state = FINISHED;
            else next_state = WAIT;
        end
    
        FINISHED: begin
            if(fifo_full) next_state = FINISHED; 
            else next_state = WAIT_FIFO; //assign fifo_wen = 1; assign written = 1; // Indicate that data has been written to FIFO
        end
        WAIT_FIFO: begin
            next_state = IDLE;
        end      
        default: next_state = IDLE;
    endcase
end

endmodule