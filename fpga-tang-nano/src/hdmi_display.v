module hdmi_display (
    input  wire clk_pixel,
    input  wire clk_serial,
    input  wire [15:0] ram_data,
    output wire [13:0] read_addr,
    output wire [2:0] hdmi_tx_p,
    output wire [2:0] hdmi_tx_n,
    output wire hdmi_tx_clk_p,
    output wire hdmi_tx_clk_n
);

// Parametry dla PC VESA 1280x800@60Hz (Zmodyfikowane CVT-RB dla zegara 71.55 MHz)
    // Obliczenia: 1440 (H_TOTAL) * 828 (V_TOTAL) * 60.009 Hz = 71.55 MHz
    parameter H_ACTIVE = 1280, H_FP = 48, H_SYNC = 32, H_BP = 80, H_TOTAL = 1440;
    parameter V_ACTIVE = 800,  V_FP = 3,  V_SYNC = 6,  V_BP = 19,  V_TOTAL = 828;

    reg [11:0] cx = 0;
    reg [11:0] cy = 0;

    always @(posedge clk_pixel) begin
        if (cx == H_TOTAL - 1) begin
            cx <= 12'd0;
            if (cy == V_TOTAL - 1) cy <= 12'd0;
            else cy <= cy + 12'd1;
        end else begin
            cx <= cx + 12'd1;
        end
    end

    wire hsync = (cx >= H_ACTIVE + H_FP) && (cx < H_ACTIVE + H_FP + H_SYNC);
    wire vsync = (cy >= V_ACTIVE + V_FP) && (cy < V_ACTIVE + V_FP + V_SYNC);
    
    wire de    = (cx < H_ACTIVE) && (cy < V_ACTIVE);

    // Obraz pokrywa teraz całą aktywną wysokość ekranu (800 linii)
    wire in_img_y = (cy < V_ACTIVE); 
    wire img_de = de && in_img_y;

    // KOREKTA PIONOWA: Duplikowanie linii. 
    // Przesunięcie bitowe o 1 w prawo (cy[9:1]) dzieli Y przez 2. 
    // Dzięki temu 800 fizycznych linii monitora mapuje się na 400 linii z RAM.
    wire [8:0] img_y = in_img_y ? cy[9:1] : 9'd0;
    wire [13:0] base_y = {5'd0, img_y};

    // Przesunięcia bitowe zamiast bloku DSP mnożenia (odpowiednik img_y * 40)
    wire [13:0] y_offset = (base_y << 5) + (base_y << 3);
    
    // ZMIANA X: Adresowanie X zostaje jak było, cx[10:5] realizuje podział bloków pamięci
    assign read_addr = y_offset + {8'd0, cx[10:5]};

    reg [11:0] cx_delay;
    reg img_de_delay, hsync_delay, vsync_delay, de_delay;

    always @(posedge clk_pixel) begin
        cx_delay     <= cx;
        img_de_delay <= img_de;
        hsync_delay  <= hsync;
        vsync_delay  <= vsync;
        de_delay     <= de;
    end

    // Dzielenie X przez 2 realizowane na poziomie bitów (duplikacja w poziomie)
    wire [3:0] bit_sel = cx_delay[4:1]; 
    wire [3:0] shift_idx = 4'd15 - bit_sel; 
    wire pixel_bit = ram_data[shift_idx];
    
    wire pixel_out = img_de_delay ? pixel_bit : 1'b0;

    // Kolory typowe dla plazmy - zostawiłem bez zmian
    wire [7:0] red_data   = pixel_out ? 8'hE0 : 8'h00;
    wire [7:0] green_data = pixel_out ? 8'h73 : 8'h00;
    wire [7:0] blue_data  = 8'h00;

    wire [9:0] tmds_r, tmds_g, tmds_b;

    tmds_encoder encode_b (.clk(clk_pixel), .vd(blue_data),  .cd({vsync_delay, hsync_delay}), .de(de_delay), .tmds(tmds_b));
    tmds_encoder encode_g (.clk(clk_pixel), .vd(green_data), .cd(2'b00),                      .de(de_delay), .tmds(tmds_g));
    tmds_encoder encode_r (.clk(clk_pixel), .vd(red_data),   .cd(2'b00),                      .de(de_delay), .tmds(tmds_r));

    wire [2:0] tmds_serial;
    wire       tmds_clk_serial;

    generate
        genvar i;
        for (i = 0; i < 3; i = i + 1) begin : serialize
            wire [9:0] tmds_channel = (i==0) ? tmds_b : (i==1) ? tmds_g : tmds_r;
            OSER10 oser (
                .Q(tmds_serial[i]),
                .D0(tmds_channel[0]), .D1(tmds_channel[1]), .D2(tmds_channel[2]), .D3(tmds_channel[3]), .D4(tmds_channel[4]),
                .D5(tmds_channel[5]), .D6(tmds_channel[6]), .D7(tmds_channel[7]), .D8(tmds_channel[8]), .D9(tmds_channel[9]),
                .PCLK(clk_pixel), .FCLK(clk_serial), .RESET(1'b0)
            );
            ELVDS_OBUF diff_buf (
                .O(hdmi_tx_p[i]), .OB(hdmi_tx_n[i]), .I(tmds_serial[i])
            );
        end
    endgenerate

    OSER10 oser_clk (
        .Q(tmds_clk_serial),
        .D0(1'b1), .D1(1'b1), .D2(1'b1), .D3(1'b1), .D4(1'b1),
        .D5(1'b0), .D6(1'b0), .D7(1'b0), .D8(1'b0), .D9(1'b0),
        .PCLK(clk_pixel), .FCLK(clk_serial), .RESET(1'b0)
    );

    ELVDS_OBUF diff_clk (
        .O(hdmi_tx_clk_p), .OB(hdmi_tx_clk_n), .I(tmds_clk_serial)
    );

endmodule