
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
output logic [8:0] y_out

// output logic valid_int_out

//driven in parallel_engine
// output [11:0]   bram_addr_a,
// output          bram_clk_a,
// output [31:0]   bram_wrdata_a,
// input  [31:0]   bram_rddata_a,
// output          bram_en_a,
// output          bram_rst_a,
// output [3:0]    bram_we_a
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

localparam MAX_ITER = 8'd200;

// localparam NUM_ENGINES = 1; 

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

// 


// Need to define all logic

// Idea for simulation: Make valid_int high after 100 clock cycles once final values been established

// reg max_iter [7:0] = 200;

// Idea: delay valid_int by an extra cycle to ensure ready and valid_int both high at the same time

// reg delayed_valid_int;

// always @(posedge out_stream_aclk) begin
//     delayed_valid_int <= valid_int;
// end

reg start;
wire done;
reg [9:0] results [639:0]; //640 pixels, 10 bit depth
wire [9:0] results_din; 
wire [$clog2(640)-1:0] results_addr; 
wire results_we;

engine_top parallel_engine (
    .clk(out_stream_aclk),
    .reset(!periph_resetn),
    .start(start), ///--------------------------------------------------
    .module_done(done),
    .depth_out(results_din),
    .we_out(results_we),
    .addr_out(results_addr)
    // .bram_addr_a(bram_addr_a),
    // .bram_clk_a(bram_clk_a),
    // .bram_wrdata_a(bram_wrdata_a),
    // .bram_en_a(bram_en_a),
    // .bram_rst_a(bram_rst_a),
    // .bram_we_a(bram_we_a)
);

reg init_started = 0;

//engine start logic 
always @(posedge out_stream_aclk) begin
    if (!periph_resetn) begin
        start <= 0;
        init_started <= 0;
    end else if (!init_started) begin
        start <= 1;
        init_started <= 1;
    end else if (lastx) begin
        start <= 1;
    end else begin
        start <= 0;
    end
end

//write results each line
always @(posedge out_stream_aclk) begin
    if (!periph_resetn) begin
        for(int i=0; i < 640; i = i + 1) begin
            results[i] = 10'd0; // Initialize all results to zero
        end
    end 
    else if (results_we) begin
        results[results_addr] <= results_din;
    end
end

// state machine for table lookup
localparam LUT_IDLE = 2'b00;
localparam LUT_LOOKUP = 2'b01;
localparam LUT_DONE = 2'b10;

reg [1:0] lut_state = LUT_IDLE;

wire valid_int;
reg [23:0] color;
reg lut_en; 
reg [9:0] final_depth; // Final depth to be used for color mapping

//always @(posedge out_stream_aclk) begin
    //     if (periph_resetn) begin
    //         if (ready & valid_int) begin
    //             if (lastx) begin
    //                 x <= 9'd0;
    //                 if (lasty) y <= 9'd0;
    //                 else y <= y + 9'd1;
    //             end
    //             else x <= x + 9'd1;
    //         end
    //     end
    //     else begin
    //         x <= 0;
    //         y <= 0;
    //     end
    // end



always @(posedge out_stream_aclk) begin
    if(!periph_resetn) begin
        lut_state <= LUT_IDLE;
        x <= 0;
        y <= 0;
        start <= 0;
        lut_en <= 0; 
    end
    else begin
        //start <= 0; 
        lut_en <= 0; 

        case(lut_state)
            LUT_IDLE: begin
                
                lut_state <= LUT_IDLE; // Stay in idle state until start signal
                lut_en <= 0; // Disable LUT lookup

                if(done) begin
                    lut_state <= LUT_LOOKUP;
                    x <= 0;
                    lut_en <= 1; 
                    final_depth <= results[x]; //process x=0 correctly
                    //lut_depth <= results[0]; // Start with the first pixel
                end
            end
            LUT_LOOKUP: begin
                final_depth <= results[x];
                lut_state <= LUT_DONE;
                x <= 0; // 1 cycle for lut_en, 1 cycle for result to be output
                lut_en <= 1; // Enable the LUT lookup
            end
            LUT_DONE: begin
                if(ready & valid_int) begin
                    if(lastx) begin
                        x <= 0;
                        //start <= 1; // Signal the engine to start processing the next line
                        lut_en <= 0; // Disable LUT lookup 
                        if(lasty) begin
                            y <= 0;
                        end
                        else begin
                            y <= y + 1;
                        end
                        lut_state <= LUT_IDLE; // Go back to idle after processing a line
                    end
                    else begin
                        final_depth <= results[x];  
                        x <= x + 1; // Move to the next pixel
                        lut_en <= 1; // Enable the LUT lookup for the next pixel
                    end
                end
            end
            default: begin
                lut_state <= LUT_IDLE; // or safe reset state
            end
        endcase            
    end
end

table_color lut_table (
    .clk(out_stream_aclk),
    .depth(final_depth),
    .max_iterations(MAX_ITER),
    .en(lut_en),
    .color(color),
    .valid(valid_int)
);

//wire valid_int = 1'b1; // Internal signal used to indicate when a new pixel is ready
// valid_int high when you have finished generating a pixel

wire [7:0] r, g, b;

assign r = color[23:16];
assign g = color[15:8];
assign b = color[7:0];

assign r_out = r;
assign g_out = g;
assign b_out = b;

assign x_out = x;
assign y_out = y;

// assign valid_int_out = valid_int;

// If you can't see something on the top level look to make sure all signals connected properly

// // DEFAULT PIXEL_GEN START //

// reg [9:0] x;
// reg [8:0] y;

// wire first = (x == 0) & (y==0);
// wire lastx = (x == X_SIZE - 1);
// wire lasty = (y == Y_SIZE - 1);
// wire [7:0] frame = regfile[0];
// wire ready;

// always @(posedge out_stream_aclk) begin
//     if (periph_resetn) begin
//         if (ready & valid_int) begin
//             if (lastx) begin
//                 x <= 9'd0;
//                 if (lasty) y <= 9'd0;
//                 else y <= y + 9'd1;
//             end
//             else x <= x + 9'd1;
//         end
//     end
//     else begin
//         x <= 0;
//         y <= 0;
//     end
// end

// wire valid_int = 1'b1;

// wire [7:0] r, g, b;
// assign r = x[7:0] + frame;
// assign g = y[7:0] + frame;
// assign b = x[6:0]+y[6:0] + frame;


// // DEFAULT PIXEL_Gen END //

packer pixel_packer(    .aclk(out_stream_aclk),
                        .aresetn(periph_resetn),
                        .r(r), .g(g), .b(b),
                        .eol(lastx), .in_stream_ready(ready), .valid_int(valid_int), .lut_en(lut_en), .sof(first),
                        .out_stream_tdata(out_stream_tdata), .out_stream_tkeep(out_stream_tkeep),
                        .out_stream_tlast(out_stream_tlast), .out_stream_tready(out_stream_tready),
                        .out_stream_tvalid(out_stream_tvalid), .out_stream_tuser(out_stream_tuser) );
 
endmodule
