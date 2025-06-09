module pixel_distributor #(

 // parameter int SCREEN_WIDTH  = 640,
 // parameter int SCREEN_HEIGHT = 480
 parameter int FRAC  = 60,
 parameter int WORD_LENGTH = 64
  
)
(
  input int SCREEN_WIDTH,
  input int SCREEN_HEIGHT,
  input int ZOOM,
  input logic signed [WORD_LENGTH-1:0] real_center,// = -32768,  // -0.5 in 16.16
  input logic signed [WORD_LENGTH-1:0] imag_center,// = 0
  input  logic                       sysclk,
  input  logic                       ready_Signal,
  output logic signed [WORD_LENGTH-1:0]         re_c,
  output logic signed [WORD_LENGTH-1:0]         im_c,
  output logic [10:0]                 x_cnt,
  output logic [10:0]                 y_cnt
);

  // enough bits to count up to SCREEN_WIDTH-1 and SCREEN_HEIGHT-1
  // localparam int XW = $clog2(SCREEN_WIDTH); //$clog2 simply ensures you have enough bits to represent screen_width
  // localparam int YW = $clog2(SCREEN_HEIGHT);

//   localparam logic [XW-1:0] MAX_X = (SCREEN_WIDTH - 1)[XW-1:0];
//   localparam logic [YW-1:0] MAX_Y = (SCREEN_HEIGHT - 1)[YW-1:0]; need to configure properly


//   logic [XW-1:0] x_cnt;
//   logic [YW-1:0] y_cnt;

  // instantiate your mapper
  pixel_to_complex #(
    .FRAC(FRAC),
    .WORD_LENGTH(WORD_LENGTH)
  ) mapper (
    .SCREEN_WIDTH     (SCREEN_WIDTH),
    .SCREEN_HEIGHT    (SCREEN_HEIGHT),
    .ZOOM       (ZOOM),
    .real_center(real_center),
    .imag_center(imag_center),
    .clk        (sysclk),
    .x         (x_cnt),
    .y         (y_cnt),
    .real_part  (re_c),
    .im_part    (im_c)
  );



  // advance the pixel counters whenever Ready_Signal is asserted
  always_ff @(posedge sysclk) begin
    if (ready_Signal) begin
      if (x_cnt == SCREEN_WIDTH) begin        // Hardcoded for the screen width
        x_cnt <= 0;
        if (y_cnt == SCREEN_HEIGHT)            // Hardcoded for the screen height
          y_cnt <= 0;
        else
          y_cnt <= y_cnt + 1;
      end else begin
        x_cnt <= x_cnt + 1;
      end
    end
  end

endmodule
