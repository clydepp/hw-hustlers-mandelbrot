module top_connection//#(
    //parameter int SCREEN_WIDTH  = 640,
    //parameter int SCREEN_HEIGHT = 480
//)(
(
    input int SCREEN_HEIGHT,
    input int SCREEN_WIDTH,

    input logic         sysclk,
    input logic         reset,
    output logic done,
    output logic                   ready,
    input logic start,
    //output logic signed [31:0]     re_c, im_c,
    output logic        [10:0]      x_cnt,
    output logic        [10:0]      y_cnt,
    //output logic        [9:0]      final_depth,
    output logic        [23:0]      color,
    input int ZOOM,
    input logic signed [63:0] real_center, // -0.5 in 16.16
    input logic signed [63:0] imag_center
);
 assign                   ready = start | done;
 
//logic                   start = 1;
logic signed [63:0]     re_c, im_c;
// logic        [9:0]      x_cnt;
// logic        [8:0]      y_cnt;
// logic        [9:0]      final_depth;



//wire start = 1'b1;
localparam int FRAC = 60; // Fractional bits for fixed-point representation
localparam int WORD_LENGTH = 64; // Total bits for fixed-point representation
pixel_distributor #(
    .FRAC(FRAC),
    .WORD_LENGTH(WORD_LENGTH) 
) u_pixel_distributor (
    .SCREEN_WIDTH(SCREEN_WIDTH),
    .SCREEN_HEIGHT(SCREEN_HEIGHT),
    .sysclk(sysclk),
    .ready_Signal(ready),
    .re_c(re_c),
    .im_c(im_c),
    .x_cnt(x_cnt),
    .y_cnt(y_cnt),
    .real_center(real_center),
    .imag_center(imag_center),
    .ZOOM(ZOOM)
);


depth_calculator_LUT #(
    .FRAC(FRAC),
    .WORD_LENGTH(WORD_LENGTH)
)
    depth_calc_color (
      .sysclk(sysclk),
      .start(start),
      .reset(reset),
      .x(x_cnt),
      .y(y_cnt),
      .re_c(re_c),
      .im_c(im_c),
      .color(color),
      .done(done)
);

endmodule
