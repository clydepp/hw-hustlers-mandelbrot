// Taking input screen pixel coordinates and mapping them to a complex coordinate
// To add: panning and zooming functionality also adjustability in word length

module pixel_to_complex#(
    parameter int SCREEN_WIDTH  = 640,
    parameter int SCREEN_HEIGHT = 480,

    // defining span of image for start
    // For mandelbrot, we want to see -2 -> +1 on the real axis and -2 -> 2 on the imaginary axis (Pre panning zooming implementation)
    parameter int FRAC = 16, // ensures 16.16 format for the time being may have to adjust
    
    // Have picked easier values for below to avoid issues with *2.5 for example but will need to look at with more diligence

    parameter logic signed [31:0]   REAL_MIN      = -2 <<< FRAC,   // start from left of x for pixels
    parameter logic signed [31:0]   REAL_WIDTH    = 3  <<< FRAC,
    parameter logic signed [31:0]   IMAG_MAX      = 2  <<< FRAC, // Start from top of y for pixels
    parameter logic signed [31:0]   IMAG_HEIGHT   = 4  <<< FRAC


)(
    input logic                                    clk,
    input logic [9:0]                              x,           // hardcoded for 640
    input logic [8:0]                              y,           // hardcoded for 480
    output logic signed [31:0]                     real_part,
    output logic signed [31:0]                     im_part
);


assign real_part = REAL_MIN + (x * REAL_WIDTH) / SCREEN_WIDTH;

assign im_part = IMAG_MAX - (y * IMAG_HEIGHT) / SCREEN_HEIGHT;




endmodule

