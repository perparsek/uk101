// PLL: 27MHz -> 270MHz (TMDS serial clock, 10x pixel clock)
// IDIV=0 (÷1), FBDIV=19 (×20): FVCO = 27 * 20 / 1 = 540MHz
// CLKOUT = 540 / 2 = 270MHz  (TMDS serial clock)
// Pixel clock = input clk (27MHz) used directly — no CLKOUTD needed

module pll (
    input  clkin,    // 27MHz
    output clkout,   // 270MHz - TMDS serial clock (10x pixel clock)
    output lock
);

rPLL #(
    .FCLKIN("27"),
    .DEVICE("GW2AR-18C"),
    .DYN_IDIV_SEL("false"),
    .IDIV_SEL(0),
    .DYN_FBDIV_SEL("false"),
    .FBDIV_SEL(19),
    .DYN_ODIV_SEL("false"),
    .ODIV_SEL(2),
    .CLKOUT_BYPASS("false"),
    .CLKOUTP_BYPASS("false"),
    .CLKOUTD_BYPASS("false"),
    .CLKOUTD_SRC("CLKOUT"),
    .DYN_SDIV_SEL(2)
) pll_inst (
    .CLKIN(clkin),
    .CLKOUT(clkout),
    .CLKOUTD(),
    .LOCK(lock),
    .CLKOUTP(),
    .CLKOUTD3(),
    .RESET(1'b0),
    .RESET_P(1'b0),
    .CLKFB(1'b0),
    .FBDSEL(6'b0),
    .IDSEL(6'b0),
    .ODSEL(6'b0),
    .PSDA(4'b0),
    .DUTYDA(4'b0),
    .FDLY(4'b0)
);

endmodule
