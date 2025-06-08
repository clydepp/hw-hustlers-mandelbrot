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

output [7:0] r_out,
output [7:0] g_out,
output [7:0] b_out,

output [10:0] x_out,
output [10:0] y_out

);
localparam [WORD_LENGTH-1:0] ZOOM = 1024; // 0.25 in fixed point, 65536 = 2^16
localparam FRAC = 60;
localparam WORD_LENGTH = 64;
localparam X_SIZE = 640;
localparam Y_SIZE = 480;
wire signed [WORD_LENGTH-1:0] real_center = -(3 * (64'd1 << (FRAC-2))); // -0.75 in fixed point
// wire signed [WORD_LENGTH-1:0] real_center = $rtoi(-0.75 * (2.0 ** FRAC)); // -0.75 in fixed point
wire signed  [WORD_LENGTH-1:0] imag_center =  (64'd1 <<< FRAC)/10; // 0 in fixed point
//$display("Real center: %d, Imaginary center: %d", real_center, imag_center);
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

//FSM to control signals
typedef enum logic [1:0]{
    IDLE = 2'b00,
    START = 2'b01,
    WAIT_DONE = 2'b10,
    SEND_PIXEL = 2'b11
} fsm_state_engine;
fsm_state_engine state = IDLE;
reg start_reg;
wire start;
wire valid_int;
assign start = start_reg;
reg valid_int_reg;
assign valid_int = valid_int_reg;

always_ff @(posedge out_stream_aclk or negedge periph_resetn) begin
    if (!periph_resetn) begin
        state <= IDLE;
        start_reg <= 0;
        valid_int_reg <= 0;
    end else begin
        case (state)
            IDLE: begin
                start_reg <= 1'b1;
                valid_int_reg <= 1'b0;
                state <= START;
            end
            START: begin
                start_reg <= 1'b0;
                state <= WAIT_DONE;
            end
            WAIT_DONE: begin
                if (engine_done) begin
                    valid_int_reg <= 1'b1;  // Data is valid now
                    state <= SEND_PIXEL;
                end
            end
            SEND_PIXEL: begin
                if (ready) begin
                    valid_int_reg <= 1'b0;
                    state <= IDLE;  // move to next pixel on x/y counters outside this FSM
                end
            end
        endcase
    end
end

//end FSM

reg [10:0] x;
reg [10:0] y;
reg [23:0] engine_color;
reg engine_done;
wire reset = ~periph_resetn;
reg [WORD_LENGTH-1:0] re_c;
reg [WORD_LENGTH-1:0] im_c;
wire first = (x == 0) & (y==0);
wire lastx = (x == X_SIZE - 1);
wire lasty = (y == Y_SIZE - 1);
wire [7:0] frame = regfile[0];
wire ready;
pixel_to_complex#(
    .WORD_LENGTH(WORD_LENGTH),
    .FRAC(FRAC)
) complex_gen(
    .SCREEN_WIDTH(X_SIZE),
    .SCREEN_HEIGHT(Y_SIZE),
    .ZOOM(ZOOM),
    .real_center(real_center),
    .imag_center(imag_center),
    .clk(out_stream_aclk),
    .x(x),
    .y(y),
    .real_part(re_c),
    .im_part(im_c)
);
depth_calculator_LUT#(
    .WORD_LENGTH(WORD_LENGTH),
    .FRAC(FRAC)
) depth_calc_color(
    .sysclk(out_stream_aclk),
    .start(start),
    .reset(reset),
    .re_c(re_c),
    .im_c(im_c),
    .color(engine_color),
    .done(engine_done)

    );
always @(posedge out_stream_aclk) begin
    if (periph_resetn) begin
        if (ready & valid_int) begin
            if (lastx) begin
                x <= 11'd0;
                if (lasty) y <= 11'd0;
                else y <= y + 11'd1;
            end
            else x <= x + 11'd1;
        end
    end
    else begin
        x <= 0;
        y <= 0;
    end
end
//assign ready = out_stream_tready & out_stream_tvalid;

// wire [7:0] r, g, b;
// assign r = engine_color[23:16];
// assign g = engine_color[15:8];
// assign b = engine_color[7:0];

reg [7:0] r_reg/*verilator public*/, g_reg/*verilator public*/, b_reg/*verilator public*/;
//reg [7:0] r_reg, g_reg, b_reg;

always @(posedge out_stream_aclk) begin
    if (!periph_resetn) begin
        r_reg <= 0;
        g_reg <= 0;
        b_reg <= 0;
    end else if (valid_int) begin
        r_reg <= engine_color[23:16];
        g_reg <= engine_color[15:8];
        b_reg <= engine_color[7:0];
       
    end
end

assign r_out = r_reg;
assign g_out = g_reg;
assign b_out = b_reg;

assign x_out = x;
assign y_out = y;
//assign g = y[7:0] + frame;
//assign b = x[6:0]+y[6:0] + frame;
// pixel_packer_simple pixel_packer(    .aclk(out_stream_aclk),
//                         .aresetn(periph_resetn),
//                         .r(r_reg), .g(g_reg), .b(b_reg),
//                         .eol(lastx), .in_stream_ready(ready), .valid(valid_int), .sof(first),
//                         .out_stream_tdata(out_stream_tdata), .out_stream_tkeep(out_stream_tkeep),
//                         .out_stream_tlast(out_stream_tlast), .out_stream_tready(out_stream_tready),
//                         .out_stream_tvalid(out_stream_tvalid), .out_stream_tuser(out_stream_tuser) );

packer pixel_packer(    .aclk(out_stream_aclk),
                        .aresetn(periph_resetn),
                        .r(r_reg), .g(g_reg), .b(b_reg),
                        .eol(lastx), .in_stream_ready(ready), .valid(valid_int), .sof(first),
                        .out_stream_tdata(out_stream_tdata), .out_stream_tkeep(out_stream_tkeep),
                        .out_stream_tlast(out_stream_tlast), .out_stream_tready(out_stream_tready),
                        .out_stream_tvalid(out_stream_tvalid), .out_stream_tuser(out_stream_tuser) );
// new_rgb_stream_packer pixel_packer_new (
//     .aclk(out_stream_aclk),
//     .aresetn(periph_resetn),     // Ensure this is the correct reset for the packer

//     // Pixel data input from pixel_generator
//     .r_in(r_reg),
//     .g_in(g_reg),
//     .b_in(b_reg),
//     .eol_in(lastx),             // Assuming lastx is your end-of-line signal
//     .sof_in(first),             // Assuming first is your start-of-frame signal
//     .valid_in(valid_int), // The valid signal for r_reg,g_reg,b_reg

//     // Output to pixel_generator
//     .in_stream_ready(ready), // Wire this to control your pixel_generator FSM

//     // AXI4-Stream Video Output
//     .out_stream_tdata(out_stream_tdata),
//     .out_stream_tkeep(out_stream_tkeep),
//     .out_stream_tlast(out_stream_tlast),
//     .out_stream_tready(out_stream_tready), // From downstream HDMI IP
//     .out_stream_tvalid(out_stream_tvalid),
//     .out_stream_tuser(out_stream_tuser)
// );

 
endmodule
