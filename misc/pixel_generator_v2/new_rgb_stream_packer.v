module new_rgb_stream_packer (
    input               aclk,
    input               aresetn,

    // Pixel data input from pixel_generator
    input      [7:0]    r_in,
    input      [7:0]    g_in,
    input      [7:0]    b_in,
    input               eol_in,     // End Of Line for the current r_in,g_in,b_in pixel
    input               sof_in,     // Start Of Frame for the current r_in,g_in,b_in pixel
    input               valid_in,   // Indicates that r_in,g_in,b_in, eol_in, sof_in are valid

    output              in_stream_ready, // To pixel_generator: packer is ready for a new pixel

    // AXI4-Stream Video Output (to HDMI IP)
    output reg [31:0]   out_stream_tdata,
    output reg [3:0]    out_stream_tkeep,
    output reg          out_stream_tlast,
    input               out_stream_tready, // From HDMI IP: indicates it can accept data
    output reg          out_stream_tvalid,
    output reg [0:0]    out_stream_tuser   // tuser[0] for Start Of Frame (SOF)
);

    // Internal registers to store one pixel
    reg [7:0] r_buffered;
    reg [7:0] g_buffered;
    reg [7:0] b_buffered;
    reg       eol_buffered;
    reg       sof_buffered;

    // Flag: true if the internal buffer holds a valid pixel ready to be sent
    reg       buffer_has_valid_pixel;

    // Logic for in_stream_ready:
    // The packer is ready to accept a new pixel if:
    // 1. Its internal buffer is empty.
    // OR
    // 2. Its internal buffer is full, BUT the downstream consumer (HDMI IP) is ready to take it NOW
    //    (meaning the buffer will be emptied in the current cycle, making space for new input).
    assign in_stream_ready = !buffer_has_valid_pixel || out_stream_tready;

    always @(posedge aclk) begin
        if (!aresetn) begin
            // Reset state
            buffer_has_valid_pixel <= 1'b0;
            out_stream_tvalid      <= 1'b0;

            r_buffered             <= 8'd0;
            g_buffered             <= 8'd0;
            b_buffered             <= 8'd0;
            eol_buffered           <= 1'b0;
            sof_buffered           <= 1'b0;

            out_stream_tdata       <= 32'd0;
            out_stream_tkeep       <= 4'h0;
            out_stream_tlast       <= 1'b0;
            out_stream_tuser       <= 1'b0;
        end else begin
            // --- Stage 1: Handle existing buffered data and out_stream_tvalid ---
            if (buffer_has_valid_pixel && out_stream_tready) begin
                // Pixel was in buffer and downstream was ready: it's consumed.
                // Buffer will become free unless new data also arrives this cycle.
                buffer_has_valid_pixel <= 1'b0; // Mark buffer as becoming free
                out_stream_tvalid      <= 1'b0; // De-assert tvalid for next cycle unless new data overrides
            end
            // If buffer_has_valid_pixel && !out_stream_tready, data remains in buffer, tvalid remains high.

            // --- Stage 2: Accept new input pixel if available and space ---
            if (valid_in && in_stream_ready) begin
                // Latch the new incoming pixel into the buffer
                r_buffered   <= r_in;
                g_buffered   <= g_in;
                b_buffered   <= b_in;
                eol_buffered <= eol_in;
                sof_buffered <= sof_in;
                buffer_has_valid_pixel <= 1'b1; // Buffer is now full with this new pixel
            end

            // --- Stage 3: Update AXI Stream output signals based on buffered state ---
            // (This determines the values for the *next* clock edge based on current decisions)
            if (buffer_has_valid_pixel) begin // If buffer will hold a valid pixel for output
                out_stream_tvalid <= 1'b1;
                // Pack the RGB data. Using 8'h00 for the most significant byte (Alpha/padding).
                out_stream_tdata  <= {8'h00, r_buffered, g_buffered, b_buffered};
                out_stream_tkeep  <= 4'hf;     // All 4 bytes are valid
                out_stream_tlast  <= eol_buffered;
                out_stream_tuser  <= sof_buffered; // Transmit SOF with the first pixel data
            end
            // If buffer_has_valid_pixel became false (consumed, no new input), out_stream_tvalid is already set to 1'b0.
        end
    end

endmodule