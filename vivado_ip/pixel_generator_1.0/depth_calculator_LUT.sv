module depth_calculator_LUT#(
	// verilator lint_off UNUSED
	parameter FRAC = 60,
	parameter WORD_LENGTH = 64
	// verilator lint_on UNUSED
)(
	input logic sysclk, start, reset,
	// verilator lint_off UNUSED
    //input logic [10:0]        x,
   //
    //input logic [10:0]        y,
 	// verilator lint_on UNUSED
    input logic [WORD_LENGTH-1:0]       re_c,
    input logic [WORD_LENGTH-1:0]       im_c,
	output logic [23:0] color,
	output logic done
);
logic [9:0]       final_depth;
//logic             done;
//logic [23:0]	color;
depth_calculator #(.FRAC(FRAC),.WORD_LENGTH(WORD_LENGTH)) DC(.sysclk(sysclk),.start(start),.reset(reset),.re_c(re_c),.im_c(im_c),.final_depth(final_depth),.done(done));
table_color TC(.depth(final_depth),.max_iterations(200),.clk(sysclk),.en(done), .color(color));
endmodule
