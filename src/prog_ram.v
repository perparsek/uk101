// 4KB single-port program RAM
// Gowin infererar SPB korrekt med posedge clk
module prog_ram (
    input  wire        clk,
    input  wire        we,
    input  wire [11:0] addr,
    input  wire [7:0]  din,
    output reg  [7:0]  dout
);
    reg [7:0] mem [0:4095];

    always @(posedge clk) begin
        if (we) begin
            mem[addr] <= din;
            dout <= din;           // WRITE_FIRST → WRITE_MODE=2'b00
        end else
            dout <= mem[addr];
    end
endmodule
