// HDMI transmitter: RGB + sync -> 4x differential TMDS pairs
// Uses Gowin OSER10 (10:1 serializer) + ELVDS_OBUF

module hdmi_tx (
    input        pclk,      // pixel clock (27MHz)
    input        tmds_clk,  // 10x pixel clock (270MHz)
    input        lock,
    input        de,
    input        hsync,
    input        vsync,
    input  [7:0] r, g, b,
    output       tmds_clk_p, tmds_clk_n,
    output       tmds_d0_p,  tmds_d0_n,   // blue  + hsync/vsync
    output       tmds_d1_p,  tmds_d1_n,   // green
    output       tmds_d2_p,  tmds_d2_n    // red
);

wire rst = ~lock;

// TMDS encode each channel
wire [9:0] tmds_ch0, tmds_ch1, tmds_ch2;

tmds_encoder enc0 (.clk(pclk), .de(de), .data(b), .c0(hsync), .c1(vsync), .tmds(tmds_ch0));
tmds_encoder enc1 (.clk(pclk), .de(de), .data(g), .c0(1'b0),  .c1(1'b0),  .tmds(tmds_ch1));
tmds_encoder enc2 (.clk(pclk), .de(de), .data(r), .c0(1'b0),  .c1(1'b0),  .tmds(tmds_ch2));

// Serialize each channel with OSER10, then ELVDS_OBUF
wire serial_clk, serial_d0, serial_d1, serial_d2;

// Clock channel: 11111 00000 pattern
OSER10 #(.GSREN("false"), .LSREN("true")) oser_clk (
    .D0(1'b1), .D1(1'b1), .D2(1'b1), .D3(1'b1), .D4(1'b1),
    .D5(1'b0), .D6(1'b0), .D7(1'b0), .D8(1'b0), .D9(1'b0),
    .FCLK(tmds_clk), .PCLK(pclk), .RESET(rst), .Q(serial_clk)
);

OSER10 #(.GSREN("false"), .LSREN("true")) oser_d0 (
    .D0(tmds_ch0[0]), .D1(tmds_ch0[1]), .D2(tmds_ch0[2]), .D3(tmds_ch0[3]), .D4(tmds_ch0[4]),
    .D5(tmds_ch0[5]), .D6(tmds_ch0[6]), .D7(tmds_ch0[7]), .D8(tmds_ch0[8]), .D9(tmds_ch0[9]),
    .FCLK(tmds_clk), .PCLK(pclk), .RESET(rst), .Q(serial_d0)
);

OSER10 #(.GSREN("false"), .LSREN("true")) oser_d1 (
    .D0(tmds_ch1[0]), .D1(tmds_ch1[1]), .D2(tmds_ch1[2]), .D3(tmds_ch1[3]), .D4(tmds_ch1[4]),
    .D5(tmds_ch1[5]), .D6(tmds_ch1[6]), .D7(tmds_ch1[7]), .D8(tmds_ch1[8]), .D9(tmds_ch1[9]),
    .FCLK(tmds_clk), .PCLK(pclk), .RESET(rst), .Q(serial_d1)
);

OSER10 #(.GSREN("false"), .LSREN("true")) oser_d2 (
    .D0(tmds_ch2[0]), .D1(tmds_ch2[1]), .D2(tmds_ch2[2]), .D3(tmds_ch2[3]), .D4(tmds_ch2[4]),
    .D5(tmds_ch2[5]), .D6(tmds_ch2[6]), .D7(tmds_ch2[7]), .D8(tmds_ch2[8]), .D9(tmds_ch2[9]),
    .FCLK(tmds_clk), .PCLK(pclk), .RESET(rst), .Q(serial_d2)
);

// Differential output buffers
ELVDS_OBUF obuf_clk (.I(serial_clk), .O(tmds_clk_p), .OB(tmds_clk_n));
ELVDS_OBUF obuf_d0  (.I(serial_d0),  .O(tmds_d0_p),  .OB(tmds_d0_n));
ELVDS_OBUF obuf_d1  (.I(serial_d1),  .O(tmds_d1_p),  .OB(tmds_d1_n));
ELVDS_OBUF obuf_d2  (.I(serial_d2),  .O(tmds_d2_p),  .OB(tmds_d2_n));

endmodule
