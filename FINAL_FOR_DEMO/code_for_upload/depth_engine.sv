module depth_engine #(
    parameter FRAC = 28,
    parameter WORD_LENGTH = 32,
	parameter DEPTH_WIDTH = 13
)(
    input logic                          sysclk,
    input logic                          start,
    input logic                          reset,
    input logic                          fifo_full,
    input logic [DEPTH_WIDTH-1:0]        max_iter,  // Now configurable from registers
    input logic signed [WORD_LENGTH-1:0] re_c,
    input logic signed [WORD_LENGTH-1:0] im_c,
    input logic                          julia,
    input logic signed [WORD_LENGTH-1:0] julia_im,
    input logic signed [WORD_LENGTH-1:0] julia_re,    
    output logic [DEPTH_WIDTH-1:0]       final_depth,
    output logic                         done,
    output logic                         fifo_wen,      // Write enable for FIFO
    output logic                         written //written to fifo
);

typedef enum logic [2:0] {
    IDLE      = 3'd0,
    WAIT      = 3'd1,
    ITERATING = 3'd2,
    FINISHED  = 3'd3,
    WAIT_FIFO = 3'd4,
	WAIT_2	  = 3'd5,
    INSIDE_BULB = 3'd6,
    JULIA_WAIT  = 3'd7
} my_states;

my_states current_state, next_state;

logic signed [WORD_LENGTH-1:0] re_z;
logic signed [WORD_LENGTH-1:0] im_z;

logic signed [2*WORD_LENGTH-1:0] re_z_2;
logic signed [2*WORD_LENGTH-1:0] im_z_2;
logic signed [2*WORD_LENGTH-1:0] cp;  // cross product 2 * re_z * im_z

logic [DEPTH_WIDTH-1:0] depth;  // Made wider to match max_iter for comparison

// Threshold: 4.0 in fixed-point format
localparam logic [2*WORD_LENGTH-1:0] THRESHOLD = (64'd4 << (2*FRAC));

logic signed [WORD_LENGTH-1:0] delayed_re_c;
logic signed [WORD_LENGTH-1:0] delayed_im_c;

// always_ff @(posedge sysclk) begin
//     delayed_re_c <= re_c;
//     delayed_im_c <= im_c;
// end

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

            JULIA_WAIT: begin 
                done <= 0;
                re_z <= re_c;
                im_z <= im_c;
                depth <= 0;
            end
                
            
            ITERATING: begin
                // Fixed Q-format arithmetic with proper bit selection
                // For Q(WORD_LENGTH-FRAC).FRAC format, we need to shift right by FRAC
                if (julia == 0) begin
                re_z <= ((re_z_2 - im_z_2) >>> FRAC) + re_c;
                im_z <= (cp >>> FRAC) + im_c;
                depth <= depth + 1;
                done <= 0;
                end
                else begin
                re_z <= ((re_z_2 - im_z_2) >>> FRAC) + julia_re;
                im_z <= (cp >>> FRAC) + julia_im;
                depth <= depth + 1;
                done <= 0;
                end
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
        end

        INSIDE_BULB: begin
            done <= 1;
            final_depth <= max_iter;
            if(fifo_full) begin
                fifo_wen <= 0; // Do not write to FIFO if it is full
            end else begin
                fifo_wen <= 1; // Write to FIFO if it is not full
                written <= 1; // Indicate that data has been written to FIFO
            end
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

localparam logic signed [WORD_LENGTH - 1:0] Q_THREE_16TH   = 3 <<< (FRAC-4);   // 3/16 * 2^28     5/32    
localparam logic signed [WORD_LENGTH - 1:0] Q_FIFTEEN_16TH = 15 <<< (FRAC-4);   // 15/16 * 2^28  63/64        *with FRAC = 28  

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

always_ff @(posedge sysclk) begin
    inside_boundary <= ((inside_cardioid < Q_THREE_16TH) || (inside_bulb < -Q_FIFTEEN_16TH));
end



// State transition logic
always_comb begin
    logic escaped;
    escaped = (re_z_2 + im_z_2) > THRESHOLD;
    
    next_state = current_state;
    
    case(current_state)
        IDLE: begin
            if(start && julia == 0) next_state = ITERATING; // BIG CHANGE
            else if(start && julia == 1) next_state = JULIA_WAIT;
        end

        JULIA_WAIT: next_state = ITERATING;

        WAIT: next_state = WAIT_2; 
		
		WAIT_2: next_state = ITERATING;
        
        ITERATING: begin
            if(escaped || (depth >= max_iter)) next_state = FINISHED;
            else if (depth == 1 && inside_boundary && julia == 0) next_state = INSIDE_BULB;
            else next_state = WAIT;
        end
    
        FINISHED: begin
            if(fifo_full) next_state = FINISHED; 
            else next_state = WAIT_FIFO; //assign fifo_wen = 1; assign written = 1; // Indicate that data has been written to FIFO
        end

        INSIDE_BULB: begin
            if(fifo_full) next_state = INSIDE_BULB; 
            else next_state = WAIT_FIFO;            
        end

        WAIT_FIFO: begin
            next_state = IDLE;
        end      
        default: next_state = IDLE;
    endcase
end

endmodule
