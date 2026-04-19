// UK101 videokontroller — 720x480@60Hz HDMI
// Visar 64x16 tecken (8x8 px) centrerat på skärmen
//
// Pipeline (posedge clk):
//   Steg 0: hcnt/vcnt räknas upp, dispAddr drivs.
//   Steg 1 (posedge N): disp_ram samplar addr_b → dout_b klar vid posedge N+1.
//           Registrera pixel_x_d1, scan_line_d1, in_char_d1.
//   Steg 2 (posedge N+1): dout_b = teckenkod; charAddr = {dout_b, scan_line_d1};
//           charData kombinatorisk; pixel_on beräknas; r/g/b/de/sync registreras.
//   Netto: 1 pixel horisontell förskjutning (konsekvent för alla signaler).

module video (
    input  wire        pclk,
    // Display RAM — läs-port
    output wire [9:0]  dispAddr,
    input  wire [7:0]  dispData,
    // Tecken-ROM — kombinatorisk
    output wire [10:0] charAddr,
    input  wire [7:0]  charData,
    // HDMI
    output reg         hsync, vsync, de,
    output reg  [7:0]  r, g, b
);

// 720x480@60Hz (27MHz pixelklocka)
localparam H_ACT=720, H_FP=16, H_SYNC=62, H_BP=60, H_TOT=858;
localparam V_ACT=480, V_FP= 9, V_SYNC= 6, V_BP=30, V_TOT=525;

// UK101: 64 kolumner x 16 rader av 8x8 tecken = 512x128 pixlar
// Centrerat i 720x480
localparam X_START = 10'd104;  // (720 - 512) / 2
localparam Y_START = 10'd176;  // (480 - 128) / 2
localparam X_END   = 10'd616;  // X_START + 512
localparam Y_END   = 10'd304;  // Y_START + 128

reg [9:0] hcnt = 0;
reg [9:0] vcnt = 0;

always @(posedge pclk) begin
    if (hcnt == H_TOT - 1) begin
        hcnt <= 0;
        vcnt <= (vcnt == V_TOT - 1) ? 0 : vcnt + 1;
    end else
        hcnt <= hcnt + 1;
end

// Position relativt teckenfönstret
wire [9:0] hrel = hcnt - X_START;
wire [9:0] vrel = vcnt - Y_START;

wire [5:0] char_col  = hrel[8:3];   // hrel / 8  → 0-63
wire [3:0] char_row  = vrel[6:3];   // vrel / 8  → 0-15
wire [2:0] pixel_x   = hrel[2:0];   // hrel % 8
wire [2:0] scan_line = vrel[2:0];   // vrel % 8

wire in_char_area = (hcnt >= X_START) && (hcnt < X_END) &&
                    (vcnt >= Y_START) && (vcnt < Y_END);

// Steg 0 → 1: Display RAM-adress (naturlig 1-cykelförhämtning via nonblocking hcnt)
assign dispAddr = {char_row, char_col};

// Steg 1-register: fördröj pixelinfo 1 klockcykel
reg [2:0] pixel_x_d1   = 0;
reg [2:0] scan_line_d1 = 0;
reg       in_char_d1   = 0;
// Fördröj synk/DE för att matcha 1-cykellatensen
reg       hsync_d1, vsync_d1, de_d1;

always @(posedge pclk) begin
    pixel_x_d1   <= pixel_x;
    scan_line_d1 <= scan_line;
    in_char_d1   <= in_char_area;
    hsync_d1 <= ~((hcnt >= H_ACT + H_FP) && (hcnt < H_ACT + H_FP + H_SYNC));
    vsync_d1 <= ~((vcnt >= V_ACT + V_FP) && (vcnt < V_ACT + V_FP + V_SYNC));
    de_d1    <= (hcnt < H_ACT) && (vcnt < V_ACT);
end

// Steg 2: dispData nu tillgänglig (dout_b från disp_ram)
// charAddr är kombinatorisk → charData direkt
assign charAddr = {dispData, scan_line_d1};  // 8 + 3 = 11 bitar

wire pixel_on = in_char_d1 && charData[7 - pixel_x_d1];

// HDMI-utgång (registrerad, steg 2)
always @(posedge pclk) begin
    hsync <= hsync_d1;
    vsync <= vsync_d1;
    de    <= de_d1;
    if (de_d1) begin
        r <= pixel_on ? 8'h00 : 8'h00;
        g <= pixel_on ? 8'hCC : 8'h00;  // grön text
        b <= pixel_on ? 8'h00 : 8'h20;  // mörkblå bakgrund
    end else begin
        r <= 0; g <= 0; b <= 0;
    end
end

endmodule
