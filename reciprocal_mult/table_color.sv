module table_color(
    input  logic [9:0]  depth,
    input  logic [9:0]  max_iterations,
    input  logic        clk,
    input  logic        en,
    output logic [23:0] color,
    output logic        valid_int,
    input logic [15:0] max_iter_recip // 1/ZOOM in Qm.n format
);
    // 1K-entry LUT
    logic [23:0] color_lut [0:1023];
    initial $readmemh("color_lut.mem", color_lut);

    // fixed-point width for the reciprocal
    localparam int RECIP_W = 16;

    // 1) run-time reciprocal in Q0.16
    //    (32-bit literal so <<16 actually survives)
    // wire [RECIP_W-1:0] max_iter_recip = (max_iterations != 0)
    //   ? ( (32'd1 << RECIP_W) / max_iterations )
    //   : {RECIP_W{1'b0}};

    // 2) map depth → [0..1023]
    wire [19:0] scaled_mult = depth * 10'd1023;  // max = 1,046,529

    // 3) multiply: 20-bit × 16-bit → 36-bit
    wire [19+RECIP_W:0] full_prod = scaled_mult * max_iter_recip;

    // 4) shift right by 16 bits → top 20 bits = quotient in Q0.16
    wire [19:0] div_result = full_prod[RECIP_W +: 20];
    // equivalently: full_prod[35:16]

    // 5) use low 10 bits of quotient to index the 1KiB LUT
    wire [9:0] address = div_result[9:0];
    wire       escape  = (depth < max_iterations);

    // 6) register & output
    always_ff @(posedge clk) begin
        if (en) begin
            color <= escape 
                     ? color_lut[address]
                     : 24'h000000;
            valid_int <= 1'b1; // Indicate that the color is valid
        end
        else begin
            valid_int <= 1'b0; // Reset valid signal when not enabled
        end
    end
endmodule
