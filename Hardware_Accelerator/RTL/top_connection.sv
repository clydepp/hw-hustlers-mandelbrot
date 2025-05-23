module top_connection(
    input logic         sysclk,
    input logic         reset,

    output logic                   ready,
    //output logic                   start,
    output logic signed [31:0]     re_c, im_c,
    output logic        [9:0]      x_cnt,
    output logic        [8:0]      y_cnt,
    output logic        [9:0]      final_depth
);

// logic                   ready;
// logic                   start;
// logic signed [31:0]     re_c, im_c;
// logic        [9:0]      x_cnt;
// logic        [8:0]      y_cnt;
// logic        [9:0]      final_depth;



wire start = 1'b1;

pixel_distributor u_pixel_distributor ( //default params for the moment
    .sysclk(sysclk),
    .ready_Signal(ready),
    .re_c(re_c),
    .im_c(im_c),
    .x_cnt(x_cnt),
    .y_cnt(y_cnt)
);

// Instantiate depth_calculator here
depth_calculator u_depth_calc (
  .sysclk       (sysclk), // system clock
  .start        (start), // start pulse
  .reset        (reset), // synchronous reset
  .x            (x_cnt), // pixel X coordinate [9:0]
  .y            (y_cnt), // pixel Y coordinate [8:0]
  .re_c         (re_c), // input real part of c (Q-format)
  .im_c         (im_c), // input imag part of c (Q-format)
  .final_depth  (final_depth), // final depth at done [9:0]
  .done         (ready)  // done flag
);

endmodule
