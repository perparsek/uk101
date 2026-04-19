// UK101 top-level för Tang Nano 20K
// 27MHz kristall, 720x480@60Hz HDMI, PS2-tangentbord

module uk101_top (
    input  wire       clk,           // 27MHz
    // HDMI
    output wire       tmds_clk_p, tmds_clk_n,
    output wire       tmds_d0_p,  tmds_d0_n,
    output wire       tmds_d1_p,  tmds_d1_n,
    output wire       tmds_d2_p,  tmds_d2_n,
    // LEDs (active-low)
    output wire [5:0] led_n,
    // Knappar
    input  wire       btn_reset,     // S1, pin 88, active-high
    // PS2
    input  wire       ps2_clk,
    input  wire       ps2_data
);

// ---- PLL: 27MHz → 270MHz TMDS ----
wire tmds_clk;
pll pll_inst (
    .clkin(clk),
    .clkout(tmds_clk),
    .lock()
);
wire pclk = clk;  // 27MHz pixelklocka, direkt från kristall

// ---- Power-on reset + knapp-reset ----
reg [15:0] por_count = 0;
always @(posedge clk) if (!por_count[15]) por_count <= por_count + 1;
wire n_reset = por_count[15] && !btn_reset;

// ---- CPU-klocka: 27MHz / 27 ≈ 1MHz ----
reg [4:0] cpuClkCount = 0;
reg       cpuClock    = 0;
always @(posedge clk) begin
    if (cpuClkCount < 26) cpuClkCount <= cpuClkCount + 1;
    else                  cpuClkCount <= 0;
    cpuClock <= (cpuClkCount >= 13);
end

// ---- Serieklocka: 16x 9600 baud ≈ 153.4kHz (27MHz / 176) ----
reg [7:0] serialClkCount = 0;
reg       serialClock    = 0;
always @(posedge clk) begin
    if (serialClkCount < 175) serialClkCount <= serialClkCount + 1;
    else                      serialClkCount <= 0;
    serialClock <= (serialClkCount >= 88);
end

// ---- CPU (T65 / 6502) ----
wire [23:0] cpuAddrWide;
wire [15:0] cpuAddress = cpuAddrWide[15:0];
wire [7:0]  cpuDataOut;
wire [7:0]  cpuDataIn;
wire        n_WR;

T65 cpu (
    .Mode   (2'b00),
    .Res_n  (n_reset),
    .Enable (1'b1),
    .Clk    (cpuClock),
    .Rdy    (1'b1),
    .Abort_n(1'b1),
    .IRQ_n  (1'b1),
    .NMI_n  (1'b1),
    .SO_n   (1'b1),
    .R_W_n  (n_WR),
    .Sync   (),
    .EF     (),
    .MF     (),
    .XF     (),
    .ML_n   (),
    .VP_n   (),
    .VDA    (),
    .VPA    (),
    .A      (cpuAddrWide),
    .DI     (cpuDataIn),
    .DO     (cpuDataOut)
);

// ---- Adressavkodning ----
wire n_memWR     = cpuClock | n_WR;   // skriv när cpuClock=0 OCH n_WR=0

wire n_ramCS     = ~(cpuAddress[15:12] == 4'b0000);    // $0000-$0FFF  4KB RAM
wire n_basRomCS  = ~(cpuAddress[15:13] == 3'b101);     // $A000-$BFFF  8KB BASIC
wire n_dispRamCS = ~(cpuAddress[15:10] == 6'b110100);  // $D000-$D3FF  1KB display-RAM
wire n_kbCS      = ~(cpuAddress[15:10] == 6'b110111);  // $DC00-$DFFF  tangentbord
wire n_aciaCS    = ~(cpuAddress[15:1]  == 15'b111100000000000); // $F000-$F001 UART
wire n_monRomCS  = ~(cpuAddress[15:11] == 5'b11111);   // $F800-$FFFF  2KB monitor-ROM

// ---- BASIC ROM (8KB, synkron rising edge) ----
wire [7:0] basRomData;
rom_basic_uk101 basic_rom (
    .clk (clk),
    .addr(cpuAddress[12:0]),
    .data(basRomData)
);

// ---- Monitor ROM / CEGMON (2KB, kombinatorisk) ----
wire [7:0] monRomData;
CegmonRom cegmon_rom (
    .address(cpuAddress[10:0]),
    .q      (monRomData)
);

// ---- Arbets-RAM (4KB, Verilog SPB) ----
wire [7:0] ramDataOut;
prog_ram prog_ram_inst (
    .clk  (clk),
    .we   (!n_memWR && !n_ramCS),
    .addr (cpuAddress[11:0]),
    .din  (cpuDataOut),
    .dout (ramDataOut)
);

// ---- Display-RAM (1KB, Verilog DPB: CPU + video) ----
wire [9:0]  dispAddr;     // från video-modulen
wire [7:0]  dispData;     // till video-modulen
wire [7:0]  dispRamCpuOut;

disp_ram disp_ram_inst (
    .clk    (clk),
    // CPU-port (läs + skriv)
    .we     (!n_memWR && !n_dispRamCS),
    .addr_a (cpuAddress[9:0]),
    .din_a  (cpuDataOut),
    .dout_a (dispRamCpuOut),
    // Video-port (läs)
    .addr_b (dispAddr),
    .dout_b (dispData)
);

// ---- Tecken-ROM (2KB, kombinatorisk) ----
wire [10:0] charAddr;     // från video-modulen
wire [7:0]  charData;     // till video-modulen

CharRom char_rom (
    .address(charAddr),
    .q      (charData)
);

// ---- Tangentbord (UK101 via PS2) ----
wire [7:0] kbReadData;
reg  [7:0] kbRowSel = 8'hFF;

always @(negedge clk) begin
    if (!n_kbCS && !n_memWR)
        kbRowSel <= cpuDataOut;
end

UK101keyboard kb (
    .CLK     (clk),
    .nRESET  (n_reset),
    .PS2_CLK (ps2_clk),
    .PS2_DATA(ps2_data),
    .A       (kbRowSel),
    .KEYB    (kbReadData)
);

// ---- UART (serieport, rxd=idle) ----
wire [7:0] aciaData;
bufferedUART uart (
    .n_wr    (n_aciaCS | cpuClock | n_WR),
    .n_rd    (n_aciaCS | cpuClock | (~n_WR)),
    .regSel  (cpuAddress[0]),
    .dataIn  (cpuDataOut),
    .dataOut (aciaData),
    .n_int   (),
    .rxClock (serialClock),
    .txClock (serialClock),
    .rxd     (1'b1),
    .txd     (),
    .n_rts   (),
    .n_cts   (1'b0),
    .n_dcd   (1'b0)
);

// ---- CPU data-buss mux ----
assign cpuDataIn =
    !n_basRomCS  ? basRomData    :
    !n_monRomCS  ? monRomData    :
    !n_aciaCS    ? aciaData      :
    !n_ramCS     ? ramDataOut    :
    !n_dispRamCS ? dispRamCpuOut :
    !n_kbCS      ? kbReadData    :
    8'hFF;

// ---- Videokontroller ----
wire hsync, vsync, de;
wire [7:0] vr, vg, vb;

video video_inst (
    .pclk    (pclk),
    .dispAddr(dispAddr),
    .dispData(dispData),
    .charAddr(charAddr),
    .charData(charData),
    .hsync   (hsync),
    .vsync   (vsync),
    .de      (de),
    .r       (vr),
    .g       (vg),
    .b       (vb)
);

// ---- HDMI-sändare ----
hdmi_tx hdmi_inst (
    .pclk     (pclk),
    .tmds_clk (tmds_clk),
    .lock     (1'b1),
    .de       (de),
    .hsync    (hsync),
    .vsync    (vsync),
    .r        (vr),
    .g        (vg),
    .b        (vb),
    .tmds_clk_p(tmds_clk_p), .tmds_clk_n(tmds_clk_n),
    .tmds_d0_p (tmds_d0_p),  .tmds_d0_n (tmds_d0_n),
    .tmds_d1_p (tmds_d1_p),  .tmds_d1_n (tmds_d1_n),
    .tmds_d2_p (tmds_d2_p),  .tmds_d2_n (tmds_d2_n)
);

// ---- Status-LED: blinkar när CPU kör ----
reg [24:0] blink = 0;
always @(posedge pclk) blink <= blink + 1;
assign led_n[0] = ~blink[24];
assign led_n[5:1] = 5'b11111;

endmodule
