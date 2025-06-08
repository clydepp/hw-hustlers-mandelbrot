module depth_calculator_LUT#(
	// verilator lint_off UNUSED
	parameter FRAC = 16
	// verilator lint_on UNUSED
)(
	input logic sysclk, start, reset,
	// verilator lint_off UNUSED
    input logic [9:0]        x,
    input logic [8:0]        y,
 	// verilator lint_on UNUSED
    input logic [31:0]       re_c,
    input logic [31:0]       im_c,
	output logic [23:0] color,
	output logic done
);
logic [9:0]       final_depth;
//logic             done;
//logic [23:0]	color;
depth_calculator DC(.sysclk(sysclk),.start(start),.reset(reset),.x(x),.y(y),.re_c(re_c),.im_c(im_c),.final_depth(final_depth),.done(done));
table_color TC(.depth(final_depth),.max_iterations(200),.clk(sysclk),.en(done), .color(color));
endmodule
