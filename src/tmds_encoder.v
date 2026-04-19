// TMDS encoder: 8-bit data + control -> 10-bit TMDS symbol
// Per DVI 1.0 spec section 3.3.3

module tmds_encoder (
    input        clk,
    input        de,        // display enable (active pixel)
    input  [7:0] data,      // pixel data
    input        c0, c1,    // control bits (hsync/vsync during blanking)
    output reg [9:0] tmds
);

// Count ones in data
function [3:0] count_ones;
    input [7:0] d;
    integer i;
    begin
        count_ones = 0;
        for (i = 0; i < 8; i = i+1)
            count_ones = count_ones + d[i];
    end
endfunction

wire [3:0] n1d = count_ones(data);

// Step 1: XOR or XNOR encode to 9 bits
wire use_xnor = (n1d > 4) || (n1d == 4 && data[0] == 0);
wire [8:0] q_m;
assign q_m[0] = data[0];
assign q_m[1] = use_xnor ? ~(q_m[0] ^ data[1]) : (q_m[0] ^ data[1]);
assign q_m[2] = use_xnor ? ~(q_m[1] ^ data[2]) : (q_m[1] ^ data[2]);
assign q_m[3] = use_xnor ? ~(q_m[2] ^ data[3]) : (q_m[2] ^ data[3]);
assign q_m[4] = use_xnor ? ~(q_m[3] ^ data[4]) : (q_m[3] ^ data[4]);
assign q_m[5] = use_xnor ? ~(q_m[4] ^ data[5]) : (q_m[4] ^ data[5]);
assign q_m[6] = use_xnor ? ~(q_m[5] ^ data[6]) : (q_m[5] ^ data[6]);
assign q_m[7] = use_xnor ? ~(q_m[6] ^ data[7]) : (q_m[6] ^ data[7]);
assign q_m[8] = ~use_xnor;

// Count ones/zeros in q_m[7:0]
wire [3:0] n1q = count_ones(q_m[7:0]);
wire [3:0] n0q = 4'd8 - n1q;

// Step 2: DC balance
reg signed [4:0] cnt; // running disparity

wire signed [4:0] diff = $signed({1'b0, n1q}) - $signed({1'b0, n0q});

always @(posedge clk) begin
    if (!de) begin
        // Control period - use control tokens, reset disparity
        case ({c1, c0})
            2'b00: tmds <= 10'b1101010100;
            2'b01: tmds <= 10'b0010101011;
            2'b10: tmds <= 10'b0101010100;
            2'b11: tmds <= 10'b1010101011;
        endcase
        cnt <= 5'sd0;
    end else begin
        if (cnt == 0 || n1q == n0q) begin
            tmds[9]   <= ~q_m[8];
            tmds[8]   <= q_m[8];
            tmds[7:0] <= q_m[8] ? q_m[7:0] : ~q_m[7:0];
            cnt <= q_m[8] ? (cnt + diff) : (cnt - diff);
        end else begin
            if ((cnt > 0 && n1q > n0q) || (cnt < 0 && n0q > n1q)) begin
                tmds[9]   <= 1'b1;
                tmds[8]   <= q_m[8];
                tmds[7:0] <= ~q_m[7:0];
                cnt <= cnt + {3'b0, q_m[8], 1'b0} - diff;
            end else begin
                tmds[9]   <= 1'b0;
                tmds[8]   <= q_m[8];
                tmds[7:0] <= q_m[7:0];
                cnt <= cnt - {3'b0, ~q_m[8], 1'b0} + diff;
            end
        end
    end
end

endmodule
