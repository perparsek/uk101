// 1KB dual-port display RAM
// Port A: CPU (läs + skriv), Port B: video (läs)
// Båda portar posedge — Gowin infererar DPB korrekt
module disp_ram (
    input  wire        clk,
    // CPU-port
    input  wire        we,
    input  wire [9:0]  addr_a,
    input  wire [7:0]  din_a,
    output reg  [7:0]  dout_a,
    // Video-port (läs)
    input  wire [9:0]  addr_b,
    output reg  [7:0]  dout_b
);
    reg [7:0] mem [0:1023];

    always @(posedge clk) begin
        if (we) begin
            mem[addr_a] <= din_a;
            dout_a <= din_a;       // WRITE_FIRST → WRITE_MODE0=2'b00
        end else
            dout_a <= mem[addr_a];
    end

    always @(posedge clk)
        dout_b <= mem[addr_b];
endmodule
