module top (
    // Zegar główny (27 MHz)
    input  wire sys_clk,        
    
    // Wejścia z komputera Compaq (pamiętaj o konwerterze na 3.3V!)
    input  wire compaq_pclk,
    input  wire compaq_vsync,
    input  wire compaq_hsync,
    input  wire compaq_ena,
    input  wire [3:0] compaq_data,

    // Wyjścia HDMI (kierowane do złącza na płytce)
    output wire [2:0] hdmi_tx_p,  
    output wire [2:0] hdmi_tx_n,  
    output wire hdmi_tx_clk_p,    
    output wire hdmi_tx_clk_n     
);

    // HDMI
    wire clk_serial;
    wire clk_pixel;
    wire [13:0] read_addr;
    wire [15:0] ram_data;

    // Compaq
    wire        we;
    wire [13:0] waddr;
    wire [15:0] wdata;

    // Moduł 2: Generacja zegarów
    pll_clocks u_clocks (
        .sys_clk(sys_clk),
        .clk_serial(clk_serial),
        .clk_pixel(clk_pixel)
    );
/*
    // Moduł 3: Pamięć i jej zawartość
    video_memory u_memory (
        .clk_pixel(clk_pixel),
        .read_addr(read_addr),
        .ram_data(ram_data)
    );
*/

    // Zaktualizowana pamięć, teraz obsługująca dwa porty
    video_memory u_memory (
        .write_clk(clk_pixel), // ZMIANA: Pamięć RAM też jest teraz taktowana naszym czystym zegarem
        .write_en(we),
        .write_addr(waddr),
        .write_data(wdata),
        
        .read_clk(clk_pixel),
        .read_addr(read_addr),
        .read_data(ram_data)
    );

    // Moduł 1 i 4: Logika wyświetlania i Enkodery
    hdmi_display u_display (
        .clk_pixel(clk_pixel),
        .clk_serial(clk_serial),
        .ram_data(ram_data),
        .read_addr(read_addr),
        .hdmi_tx_p(hdmi_tx_p),
        .hdmi_tx_n(hdmi_tx_n),
        .hdmi_tx_clk_p(hdmi_tx_clk_p),
        .hdmi_tx_clk_n(hdmi_tx_clk_n)
    );

    // Instancja Twojego nowego przechwytywacza
    compaq_capture u_capture (
        .clk_fast(clk_pixel),  // NOWE: podajemy nasz szybki zegar
        .pclk(compaq_pclk),    // pclk staje się zwykłym sygnałem wejściowym
        .vs_n(compaq_vsync),
        .hs_n(compaq_hsync),   
        .ena(compaq_ena),
        .d(compaq_data),
        .we(we),               
        .waddr(waddr),         
        .wdata(wdata)          
    );

endmodule