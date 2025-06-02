
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.05.2024 22:03:08
// Design Name: 
// Module Name: test_block_v
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


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
input           s_axi_lite_wvalid,

// //Added below to make visible for testing

output logic [7:0] r_out, g_out, b_out,

output logic [9:0] x_out,
output logic [8:0] y_out,

output logic valid_int_out
);

localparam X_SIZE = 640;
localparam Y_SIZE = 480;
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

localparam MAX_ITER = 8'd200;
localparam WORD_LENGTH = 16;
localparam FRAC = 8;
localparam ZOOM = 1;
//localparam REAL_CENTER = -(3 * (16'd1 << (FRAC-2))); ;
//localparam IMAG_CENTER = (16'd1 <<< FRAC)/10;
localparam REAL_CENTER = 0;
localparam IMAG_CENTER = 0;

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



reg [9:0] x;  // Will want to take input for x and y to get screen dimensions
reg [8:0] y;

wire first = (x == 0) & (y==0);
wire lastx = (x == X_SIZE - 1);
wire lasty = (y == Y_SIZE - 1);
//wire [7:0] frame = regfile[0];
wire ready;

always @(posedge out_stream_aclk) begin
    if (periph_resetn) begin
        if (ready & valid_int) begin
            if (lastx) begin
                x <= 9'd0;
                if (lasty) y <= 9'd0;
                else y <= y + 9'd1;
            end
            else x <= x + 9'd1;
        end
    end
    else begin
        x <= 0;
        y <= 0;
    end
end


// Need to define all logic

// Idea for simulation: Make valid_int high after 100 clock cycles once final values been established

wire [15:0] re_c, im_c;
wire [7:0] final_depth;
wire valid_int;

// reg max_iter [7:0] = 200;
wire [23:0] color;
// Idea: delay valid_int by an extra cycle to ensure ready and valid_int both high at the same time

// reg delayed_valid_int;

// always @(posedge out_stream_aclk) begin
//     delayed_valid_int <= valid_int;
// end

depth_calculator u_depth_calc (
  .sysclk       (out_stream_aclk), // system clock
  .start        (ready), // start pulse
  .reset        (~periph_resetn), // synchronous reset
  .x            (x), // pixel X coordinate [9:0]
  .y            (y), // pixel Y coordinate [8:0]
  .re_c         (re_c), // input real part of c (Q-format)
  .im_c         (im_c), // input imag part of c (Q-format)
  .final_depth  (final_depth), // final depth at done [9:0]
  .done         (valid_int),  // done flag
  .max_iter     (MAX_ITER)
);

// pixel_to_complex mapper (
// .clk        (out_stream_aclk),
// .x         (x),
// .y         (y),
// .real_part  (re_c),
// .im_part    (im_c)
// );


pixel_to_complex#(
    .WORD_LENGTH(WORD_LENGTH),
    .FRAC(FRAC)
) mapper (
    .SCREEN_WIDTH(X_SIZE),
    .SCREEN_HEIGHT(Y_SIZE),
    .ZOOM(ZOOM),
    .real_center(REAL_CENTER),
    .imag_center(IMAG_CENTER),
    .clk(out_stream_aclk),
    .x(x),
    .y(y),
    .real_part(re_c),
    .im_part(im_c)
);





table_color lut_table (
    .clk(out_stream_aclk),
    .depth(final_depth),
    .max_iterations(MAX_ITER),
    .en(1'b1),
    .color(color)
);
//wire valid_int = 1'b1;
//wire start = 1'b1;

//wire valid_int = 1'b1; // Internal signal used to indicate when a new pixel is ready
// valid_int high when you have finished generating a pixel




wire [7:0] r, g, b;

// always @(posedge out_stream_aclk) begin
//     r <= final_depth * 3 / 2;
//     g <= final_depth * 3 / 2;
//     b <= final_depth * 3 / 2;
//     delayed_valid_int <= valid_int;
// end

assign r = color[23:16];
assign g = color[15:8];
assign b = color[7:0];


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
