module compaq_capture (
    input  wire clk_fast, 
    input  wire pclk,     
    input  wire vs_n,     
    input  wire hs_n,     
    input  wire ena,      
    input  wire [3:0] d,  

    output reg         we,     
    output reg  [13:0] waddr,  
    output reg  [15:0] wdata
);

    // -----------------------------------------------------------
    // 1. SZYBKIE SYGNAŁY (Tylko 2-stopniowy synchronizator)
    // -----------------------------------------------------------
    reg [1:0] pclk_sync;
    reg [1:0] ena_sync;
    reg [3:0] d_sync [1:0];

    // -----------------------------------------------------------
    // 2. WOLNE SYGNAŁY (8-stopniowy filtr wygładzający - Debouncer)
    // -----------------------------------------------------------
    reg [7:0] hs_sr;
    reg [7:0] vs_sr;
    reg hs_clean;
    reg vs_clean;

    // Historia do wykrywania zboczy
    reg pclk_prev;
    reg hs_prev;
    reg vs_prev;

    // Liczniki bufora
    reg [8:0] line_cnt;
    reg [5:0] word_cnt;
    reg [1:0] nibble_cnt;
    reg [15:0] shift_reg;
    
    // NOWE: Liczniki marginesów (Back Porch)
    reg [4:0] v_skip_cnt; // Pomijanie linii po VSYNC
    reg [3:0] h_skip_cnt; // Pomijanie taktów po HSYNC

    // Lustrzane odbicie bitów i czarne tło (na czystych, zsynchronizowanych danych)
    wire [3:0] d_corrected = { ~d_sync[1][0], ~d_sync[1][1], ~d_sync[1][2], ~d_sync[1][3] };

    always @(posedge clk_fast) begin
        // --- PRZEPISYWANIE SZYBKICH SYGNAŁÓW ---
        pclk_sync <= {pclk_sync[0], pclk};
        ena_sync  <= {ena_sync[0], ena};
        
        d_sync[0] <= d;
        d_sync[1] <= d_sync[0];

        // --- FILTROWANIE WOLNYCH SYGNAŁÓW ---
        hs_sr <= {hs_sr[6:0], hs_n};
        vs_sr <= {vs_sr[6:0], vs_n};

        if (hs_sr == 8'hFF) hs_clean <= 1'b1;
        else if (hs_sr == 8'h00) hs_clean <= 1'b0;

        if (vs_sr == 8'hFF) vs_clean <= 1'b1;
        else if (vs_sr == 8'h00) vs_clean <= 1'b0;

        // --- HISTORIA ZBOCZY ---
        pclk_prev <= pclk_sync[1];
        hs_prev   <= hs_clean;    
        vs_prev   <= vs_clean;    
        we <= 1'b0; 

        // --- LOGIKA PRZECHWYTYWANIA ---

        // VSYNC (Wykrycie początku nowej klatki)
        if (vs_prev == 1'b1 && vs_clean == 1'b0) begin
            line_cnt   <= 9'd0;
            word_cnt   <= 6'd0;
            nibble_cnt <= 2'd0;
            h_skip_cnt <= 4'd0;
            
            // Zapisany przez Ciebie, idealnie skalibrowany parametr pionowy
            v_skip_cnt <= 5'd9; 
        end
        // HSYNC (Koniec linii / przejście do następnej)
        else if (hs_prev == 1'b1 && hs_clean == 1'b0) begin
            word_cnt   <= 6'd0;
            nibble_cnt <= 2'd0;
            
            // NOWE: Pomijamy 1 takt PCLK na początku linii. 
            // 1 takt = dokładnie 4 przesłane piksele!
            h_skip_cnt <= 4'd2; 
            
            if (v_skip_cnt > 0) begin
                v_skip_cnt <= v_skip_cnt - 5'd1; 
            end else if (word_cnt > 0 && line_cnt < 9'd409) begin
                line_cnt   <= line_cnt + 9'd1;
            end
        end
        // PCLK (Pobieranie danych pikseli)
        else if (pclk_prev == 1'b1 && pclk_sync[1] == 1'b0) begin
            // Zezwól dopiero, gdy licznik pomijanych linii spadnie do zera
            if (ena_sync[1] == 1'b1 && v_skip_cnt == 5'd0) begin
                
                // Zezwól dopiero, gdy odczekamy startowe takty PCLK
                if (h_skip_cnt > 0) begin
                    h_skip_cnt <= h_skip_cnt - 4'd1;
                end else begin
                    // Właściwe przechwytywanie
                    shift_reg <= {shift_reg[11:0], d_corrected};
                    nibble_cnt <= nibble_cnt + 2'd1;
                    if (nibble_cnt == 2'd3) begin
                        we <= 1'b1;
                        wdata <= {shift_reg[11:0], d_corrected};
                        waddr <= (line_cnt * 14'd40) + word_cnt;
                        word_cnt <= word_cnt + 6'd1;
                    end
                end
                
            end
        end
    end

endmodule