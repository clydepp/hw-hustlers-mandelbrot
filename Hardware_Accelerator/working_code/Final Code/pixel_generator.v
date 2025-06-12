module pixel_generator(
input           out_stream_aclk,
input           s_axi_lite_aclk,
input           axi_resetn,
input           periph_resetn,

//Stream output
output [31:0]   out_stream_tdata,
output [3:0]    out_stream_tkeep,
output          out_stream_tlast,
input           out_stream_tready,
output          out_stream_tvalid,
output [0:0]    out_stream_tuser, 

//AXI-Lite S
input [AXI_LITE_ADDR_WIDTH-1:0]     s_axi_lite_araddr,
output          s_axi_lite_arready,
input           s_axi_lite_arvalid,

input [AXI_LITE_ADDR_WIDTH-1:0]     s_axi_lite_awaddr,
output          s_axi_lite_awready,
input           s_axi_lite_awvalid,

input           s_axi_lite_bready,
output [1:0]    s_axi_lite_bresp,
output          s_axi_lite_bvalid,

output [31:0]   s_axi_lite_rdata,
input           s_axi_lite_rready,
output [1:0]    s_axi_lite_rresp,
output          s_axi_lite_rvalid,

input  [31:0]   s_axi_lite_wdata,
output          s_axi_lite_wready,
input           s_axi_lite_wvalid

//Added below to make visible for testing

// output logic [7:0] r_out, g_out, b_out,

// output logic [10:0] x_out,
// output logic [10:0] y_out,

// output logic valid_int_out
);

// Watch out for hardcoding in mandelplot
localparam X_SIZE = 1920;
localparam Y_SIZE = 1080;

parameter  REG_FILE_SIZE = 8;
localparam REG_FILE_AWIDTH = $clog2(REG_FILE_SIZE);
parameter  AXI_LITE_ADDR_WIDTH = 8;

localparam AWAIT_WADD_AND_DATA = 3'b000;
localparam AWAIT_WDATA = 3'b001;
localparam AWAIT_WADD = 3'b010;
localparam AWAIT_WRITE = 3'b100;
localparam AWAIT_RESP = 3'b101;

localparam AWAIT_RADD = 2'b00;
localparam AWAIT_FETCH = 2'b01;
localparam AWAIT_READ = 2'b10;

localparam AXI_OK = 2'b00;
localparam AXI_ERR = 2'b10;


// Added localparams to be interfaced with overlay

localparam WORD_LENGTH = 32;
localparam FRAC = 28;

// localparam MAX_ITER = 1024;
// localparam MAX_ITER_LOG = 9; // Change in accordance with max_iter
// localparam ZOOM = 4;
// localparam ZOOM_RECIPROCAL = 32'd1<<(FRAC - 1); // Reciprocal of zoom in Q-format
// localparam [WORD_LENGTH-1:0] REAL_CENTER = -(3 * (16'd1 << (FRAC-2))); ;
// localparam [WORD_LENGTH-1:0] IMAG_CENTER = (16'd1 <<< FRAC)/10; 
// // localparam WAIT_STAGES = 3;


// UNCOMMENT BEFORE COMPILATION

wire[31:0] MAX_ITER = regfile[0]; // Register to hold the maximum iterations value
wire[31:0] MAX_ITER_LOG = regfile[1]; // Register to hold the maximum iterations log value
wire[31:0] ZOOM = regfile[2]; // Register to hold the zoom value
wire[31:0] REAL_CENTER = regfile[3]; // Register to hold the real center value
wire[31:0] IMAG_CENTER = regfile[4]; // Register to hold the imaginary center value
wire[31:0] WAIT_STAGES = regfile[5];


// localparam REAL_CENTER = 0;
// localparam IMAG_CENTER = 0;
// wire [RECIP_W-1:0] max_iter_recip = (max_iterations != 0)
//       ? ( (32'd1 << RECIP_W) / max_iterations )
//       : {RECIP_W{1'b0}};
reg [31:0]                          regfile [REG_FILE_SIZE-1:0];
reg [REG_FILE_AWIDTH-1:0]           writeAddr, readAddr;
reg [31:0]                          readData, writeData;
reg [1:0]                           readState = AWAIT_RADD;
reg [2:0]                           writeState = AWAIT_WADD_AND_DATA;

//Read from the register file
always @(posedge s_axi_lite_aclk) begin
    
    readData <= regfile[readAddr];

    if (!axi_resetn) begin
    readState <= AWAIT_RADD;
    end

    else case (readState)

        AWAIT_RADD: begin
            if (s_axi_lite_arvalid) begin
                readAddr <= s_axi_lite_araddr[2+:REG_FILE_AWIDTH];
                readState <= AWAIT_FETCH;
            end
        end

        AWAIT_FETCH: begin
            readState <= AWAIT_READ;
        end

        AWAIT_READ: begin
            if (s_axi_lite_rready) begin
                readState <= AWAIT_RADD;
            end
        end

        default: begin
            readState <= AWAIT_RADD;
        end

    endcase
end

assign s_axi_lite_arready = (readState == AWAIT_RADD);
assign s_axi_lite_rresp = (readAddr < REG_FILE_SIZE) ? AXI_OK : AXI_ERR;
assign s_axi_lite_rvalid = (readState == AWAIT_READ);
assign s_axi_lite_rdata = readData;

//Write to the register file, use a state machine to track address write, data write and response read events
always @(posedge s_axi_lite_aclk) begin

    if (!axi_resetn) begin
        writeState <= AWAIT_WADD_AND_DATA;
    end

    else case (writeState)

        AWAIT_WADD_AND_DATA: begin  //Idle, awaiting a write address or data
            case ({s_axi_lite_awvalid, s_axi_lite_wvalid})
                2'b10: begin
                    writeAddr <= s_axi_lite_awaddr[2+:REG_FILE_AWIDTH];
                    writeState <= AWAIT_WDATA;
                end
                2'b01: begin
                    writeData <= s_axi_lite_wdata;
                    writeState <= AWAIT_WADD;
                end
                2'b11: begin
                    writeData <= s_axi_lite_wdata;
                    writeAddr <= s_axi_lite_awaddr[2+:REG_FILE_AWIDTH];
                    writeState <= AWAIT_WRITE;
                end
                default: begin
                    writeState <= AWAIT_WADD_AND_DATA;
                end
            endcase        
        end

        AWAIT_WDATA: begin //Received address, waiting for data
            if (s_axi_lite_wvalid) begin
                writeData <= s_axi_lite_wdata;
                writeState <= AWAIT_WRITE;
            end
        end

        AWAIT_WADD: begin //Received data, waiting for address
            if (s_axi_lite_awvalid) begin
                writeAddr <= s_axi_lite_awaddr[2+:REG_FILE_AWIDTH];
                writeState <= AWAIT_WRITE;
            end
        end

        AWAIT_WRITE: begin //Perform the write
            regfile[writeAddr] <= writeData;
            writeState <= AWAIT_RESP;
        end

        AWAIT_RESP: begin //Wait to send response
            if (s_axi_lite_bready) begin
                writeState <= AWAIT_WADD_AND_DATA;
            end
        end

        default: begin
            writeState <= AWAIT_WADD_AND_DATA;
        end
    endcase
end

assign s_axi_lite_awready = (writeState == AWAIT_WADD_AND_DATA || writeState == AWAIT_WADD);
assign s_axi_lite_wready = (writeState == AWAIT_WADD_AND_DATA || writeState == AWAIT_WDATA);
assign s_axi_lite_bvalid = (writeState == AWAIT_RESP);
assign s_axi_lite_bresp = (writeAddr < REG_FILE_SIZE) ? AXI_OK : AXI_ERR;



reg [10:0] x;  // Will want to take input for x and y to get screen dimensions
reg [10:0] y;

wire first = (x == 0) & (y==0);
wire lastx = (x == X_SIZE - 1);
wire lasty = (y == Y_SIZE - 1);
wire ready;

always @(posedge out_stream_aclk) begin
    if (periph_resetn) begin
        if (ready & valid_int) begin
            if (lastx) begin
                x <= 32'd0;
                if (lasty) y <= 32'd0;
                else y <= y + 32'd1;
            end
            else x <= x + 32'd1;
        end
    end
    else begin
        x <= 0;
        y <= 0;
    end
end

wire [WORD_LENGTH-1:0] re_c, im_c;
wire [10:0] final_depth;
reg valid_int;
wire done;

depth_calculator#(
    .FRAC(FRAC), // Fractional bits for Q-format
    .WORD_LENGTH(WORD_LENGTH) // Word length for Q-format    
) u_depth_calc (
  .sysclk       (out_stream_aclk), // system clock
  .start        (ready), // start pulse
  .reset        (~periph_resetn), // synchronous reset
  .re_c         (re_c), // input real part of c (Q-format)
  .im_c         (im_c), // input imag part of c (Q-format)
  .final_depth  (final_depth), // final depth at done [9:0]
  .done         (done),  // done flag
  .WAIT_STAGES  (WAIT_STAGES),
  .max_iter     (MAX_ITER)
);


pixel_to_complex#(
    .WORD_LENGTH(WORD_LENGTH),
    .FRAC(FRAC),
    .SCREEN_HEIGHT(Y_SIZE),
    .SCREEN_WIDTH(X_SIZE)
) mapper (
    .ZOOM(ZOOM),
    .real_center(REAL_CENTER),
    .imag_center(IMAG_CENTER),
    .clk(out_stream_aclk),
    .rst(~periph_resetn),
    .x(x),
    .y(y),
    .real_part(re_c),
    .im_part(im_c)
);

// valid_int high when you have finished generating a pixel
always_ff @(posedge out_stream_aclk) begin
    if (done) begin
        valid_int <= 1'b1; // Set valid_int high when done
    end
    else begin
        valid_int <= 1'b0; // Reset valid_int otherwise
    end
end

wire [7:0] r, g, b;
wire [7:0] intensity, color;
// always @(posedge out_stream_aclk) begin
//     r <= final_depth * 3 / 2;
//     g <= final_depth * 3 / 2;
//     b <= final_depth * 3 / 2;
//     delayed_valid_int <= valid_int;
// end

assign b = intensity;
assign g = intensity;
assign r = intensity;
assign color = (final_depth >= MAX_ITER) ? 255 :
                   ((MAX_ITER_LOG > 8) ? (final_depth >> (MAX_ITER_LOG - 8)) :
                                          (final_depth << (8 - MAX_ITER_LOG)));
assign intensity = 255 - color; // Invert the color for visualization                                         



assign r_out = r;
assign g_out = g;
assign b_out = b;

assign x_out = x;
assign y_out = y;

assign valid_int_out = valid_int;

// // DEFAULT PIXEL_Gen END //

packer pixel_packer(    .aclk(out_stream_aclk),
                        .aresetn(periph_resetn),
                        .r(r), .g(g), .b(b),
                        .eol(lastx), .in_stream_ready(ready), .valid(valid_int), .sof(first),
                        .out_stream_tdata(out_stream_tdata), .out_stream_tkeep(out_stream_tkeep),
                        .out_stream_tlast(out_stream_tlast), .out_stream_tready(out_stream_tready),
                        .out_stream_tvalid(out_stream_tvalid), .out_stream_tuser(out_stream_tuser) );
 
endmodule
