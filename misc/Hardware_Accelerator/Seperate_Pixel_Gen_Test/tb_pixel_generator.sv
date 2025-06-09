`timescale 1ns/1ps

module tb_pixel_generator;

  // Clock and reset
  logic clk = 0;
  logic axi_clk = 0;
  logic axi_resetn = 0;
  logic periph_resetn = 0;

  always #5 clk = ~clk;        // 100 MHz
  always #7 axi_clk = ~axi_clk; // ~71 MHz for AXI

  // Stream outputs
  wire [31:0] out_stream_tdata;
  wire [3:0]  out_stream_tkeep;
  wire        out_stream_tlast;
  logic       out_stream_tready = 1;  // Always ready
  wire        out_stream_tvalid;
  wire [0:0]  out_stream_tuser;

  // AXI-Lite signals
  localparam AXI_LITE_ADDR_WIDTH = 8;

  logic [AXI_LITE_ADDR_WIDTH-1:0] s_axi_lite_araddr = 0;
  wire                            s_axi_lite_arready;
  logic                           s_axi_lite_arvalid = 0;

  logic [AXI_LITE_ADDR_WIDTH-1:0] s_axi_lite_awaddr = 0;
  wire                            s_axi_lite_awready;
  logic                           s_axi_lite_awvalid = 0;

  logic                           s_axi_lite_bready = 0;
  wire [1:0]                      s_axi_lite_bresp;
  wire                            s_axi_lite_bvalid;

  wire [31:0]                     s_axi_lite_rdata;
  logic                           s_axi_lite_rready = 0;
  wire [1:0]                      s_axi_lite_rresp;
  wire                            s_axi_lite_rvalid;

  logic [31:0]                    s_axi_lite_wdata = 0;
  wire                            s_axi_lite_wready;
  logic                           s_axi_lite_wvalid = 0;

  // DUT
  pixel_generator #(
    .AXI_LITE_ADDR_WIDTH(AXI_LITE_ADDR_WIDTH)
  ) dut (
    .out_stream_aclk(clk),
    .s_axi_lite_aclk(axi_clk),
    .axi_resetn(axi_resetn),
    .periph_resetn(periph_resetn),

    .out_stream_tdata(out_stream_tdata),
    .out_stream_tkeep(out_stream_tkeep),
    .out_stream_tlast(out_stream_tlast),
    .out_stream_tready(out_stream_tready),
    .out_stream_tvalid(out_stream_tvalid),
    .out_stream_tuser(out_stream_tuser),

    .s_axi_lite_araddr(s_axi_lite_araddr),
    .s_axi_lite_arready(s_axi_lite_arready),
    .s_axi_lite_arvalid(s_axi_lite_arvalid),

    .s_axi_lite_awaddr(s_axi_lite_awaddr),
    .s_axi_lite_awready(s_axi_lite_awready),
    .s_axi_lite_awvalid(s_axi_lite_awvalid),

    .s_axi_lite_bready(s_axi_lite_bready),
    .s_axi_lite_bresp(s_axi_lite_bresp),
    .s_axi_lite_bvalid(s_axi_lite_bvalid),

    .s_axi_lite_rdata(s_axi_lite_rdata),
    .s_axi_lite_rready(s_axi_lite_rready),
    .s_axi_lite_rresp(s_axi_lite_rresp),
    .s_axi_lite_rvalid(s_axi_lite_rvalid),

    .s_axi_lite_wdata(s_axi_lite_wdata),
    .s_axi_lite_wready(s_axi_lite_wready),
    .s_axi_lite_wvalid(s_axi_lite_wvalid)
  );

  // Simulation control
  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, tb_pixel_generator);

    // Initial reset
    axi_resetn = 0;
    periph_resetn = 0;
    #100;
    axi_resetn = 1;
    periph_resetn = 1;

    // Optionally write to AXI register 0
    // s_axi_lite_awaddr <= 8'h00;
    // s_axi_lite_awvalid <= 1;
    // s_axi_lite_wdata <= 32'd5;
    // s_axi_lite_wvalid <= 1;
    // s_axi_lite_bready <= 1;
    // wait (s_axi_lite_bvalid);
    // s_axi_lite_awvalid <= 0;
    // s_axi_lite_wvalid <= 0;
    // s_axi_lite_bready <= 0;

    // Run simulation
    #10000;
    $finish;
  end

  // Debugging output
  always_ff @(posedge clk) begin
    if (out_stream_tvalid && out_stream_tready) begin
      $display("Pixel Data: %h, TLAST=%b, TUSER=%b, Time=%t",
        out_stream_tdata, out_stream_tlast, out_stream_tuser, $time);
    end
  end

endmodule
