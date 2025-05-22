module table_color(
    input logic [9:0] depth, max_iterations,
    input logic clk,
    input logic en,
    output logic [23:0] color
);
    logic escape;
    logic [23:0] color_lut [0:1023];

    // Intermediate variables
    logic [19:0] scaled_mult;
   // verilator lint_off UNUSED
	logic [19:0] div_result;
// verilator lint_on UNUSED
    logic [9:0] address;

    assign escape = (depth != max_iterations);
    assign scaled_mult = depth * 10'd1023;
    assign div_result = (max_iterations != 0) ? (scaled_mult / {{10{1'b0}},max_iterations}) : 20'd0;
    assign address = div_result[9:0]; // safely truncate to 10 bits

    initial $readmemh("color_lut.txt", color_lut);

    always_ff @(posedge clk) begin
        if (en) begin
            if (!escape)
                color <= 24'h000000;
            else
                color <= color_lut[address];
        end
    end
endmodule
