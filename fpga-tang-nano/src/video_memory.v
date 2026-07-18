module video_memory (
    // PORT A: Zapis (podłączany do modułu compaq_capture)
    input  wire        write_clk, // Zegar pclk
    input  wire        write_en,
    input  wire [13:0] write_addr,
    input  wire [15:0] write_data,

    // PORT B: Odczyt (podłączany do układu HDMI)
    input  wire        read_clk,  // Zegar clk_pixel
    input  wire [13:0] read_addr,
    output reg  [15:0] read_data
);

    // 16384 słów 16-bitowych (potęga dwójki gwarantuje użycie bloków BSRAM)
    reg [15:0] video_ram [0:16383];

    // -- PORT ZAPISU --
    // Zapis realizujemy na zboczu rosnącym. Ponieważ capture wystawia dane 
    // na zboczu opadającym, daje nam to doskonały margines czasu (setup time).
    always @(posedge write_clk) begin
        if (write_en) begin
            video_ram[write_addr] <= write_data;
        end
    end

    // -- PORT ODCZYTU --
    always @(posedge read_clk) begin
        read_data <= video_ram[read_addr];
    end

endmodule





/*

// Prostokąt 
module video_memory (
    input  wire clk_pixel,
    input  wire [13:0] read_addr,
    output reg  [15:0] ram_data
);

    // KOREKTA 3: Wymuszenie potęgi dwójki (16384) dla stabilnej syntezy BRAM
    reg [15:0] video_ram [0:16383];
    integer k;

    initial begin
        for (k = 0; k < 2000; k = k + 1) begin
            video_ram[k] = 16'h0000;
        end

        // 4 prostokąty
        video_ram[(40 * 0) + 0]   = 16'h8080;
        video_ram[(40 * 0) + 39]  = 16'h8080;
        video_ram[(40 * 5) + 0]   = 16'h8080;
        video_ram[(40 * 11) + 0]  = 16'h8080;
        video_ram[(40 * 399) + 0] = 16'h8080;
        video_ram[(40 * 399) + 39] = 16'h8080;

        for (k = 0; k < 40; k = k + 1) begin
            video_ram[k] = 16'hFFFF;
            video_ram[(40*399) + k] = 16'hFFFF;
        end


        for (k = 1; k < 399; k = k + 1) begin
            video_ram[(40 * k) + 0] = 16'h8000;
            video_ram[(40 * k) + 39] = 16'h0001;
        end


        // Środek (X=320, Y=200)
        video_ram[(40 * 200) + 20] = 16'h8000;
    end

    always @(posedge clk_pixel) begin
        ram_data <= video_ram[read_addr];
    end

endmodule

*/