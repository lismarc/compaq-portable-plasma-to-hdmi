module pll_clocks (
    input  wire sys_clk,
    output wire clk_serial,
    output wire clk_pixel
);

    // Parametry dla standardu zbliżonego do VESA WXGA 1280x800
    // Wejście 27 MHz -> CLKOUT 357.75 MHz -> VCO 715.5 MHz
    rPLL #(
        .FCLKIN("27.0"),
        .IDIV_SEL(3),      // Dzielnik wejściowy N: 4 (3+1)
        .FBDIV_SEL(52),    // Mnożnik M: 53 (52+1)  <-- Teraz bezpiecznie poniżej 63!
        .ODIV_SEL(2)       // Dzielnik VCO: 2
    ) pll_inst (
        .CLKIN(sys_clk), 
        .CLKOUT(clk_serial), // Wychodzi idealne 357.75 MHz
        .CLKOUTD(), 
        .CLKOUTP(), 
        .CLKOUTD3(), 
        .RESET(1'b0),
        .RESET_P(1'b0),
        .CLKFB(1'b0),
        .FBDSEL(6'b000000),
        .IDSEL(6'b000000),
        .ODSEL(6'b000000),
        .PSDA(4'b0000),    
        .DUTYDA(4'b0000),  
        .FDLY(4'b0000),    
        .LOCK()
    );

    // Dzielnik zegara dla pikseli (357.75 MHz / 5 = 71.55 MHz)
    CLKDIV #(.DIV_MODE("5")) clk_div_inst (
        .CLKOUT(clk_pixel), 
        .HCLKIN(clk_serial), 
        .RESETN(1'b1), 
        .CALIB(1'b0)
    );

endmodule