module tmds_encoder (
    input clk,
    input [7:0] vd,
    input [1:0] cd,
    input de,
    output reg [9:0] tmds
);
    wire [3:0] n1d = vd[0] + vd[1] + vd[2] + vd[3] + vd[4] + vd[5] + vd[6] + vd[7];
    wire xnor_k = (n1d > 4) || (n1d == 4 && vd[0] == 0);
    
    wire [8:0] q_m;
    assign q_m[0] = vd[0];
    assign q_m[1] = q_m[0] ^ vd[1] ^ xnor_k;
    assign q_m[2] = q_m[1] ^ vd[2] ^ xnor_k;
    assign q_m[3] = q_m[2] ^ vd[3] ^ xnor_k;
    assign q_m[4] = q_m[3] ^ vd[4] ^ xnor_k;
    assign q_m[5] = q_m[4] ^ vd[5] ^ xnor_k;
    assign q_m[6] = q_m[5] ^ vd[6] ^ xnor_k;
    assign q_m[7] = q_m[6] ^ vd[7] ^ xnor_k;
    assign q_m[8] = ~xnor_k;

    // KOREKTA 4: Rejestr TMDS disparity ze statusem 'signed'
    reg signed [4:0] dc_bias = 0;
    wire [3:0] n1q = q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7];
    wire [3:0] n0q = 4'd8 - n1q;
    
    // Wymuszone rzutowanie matematyczne ze znakiem
    wire signed [4:0] n1q_s = {1'b0, n1q};
    wire signed [4:0] n0q_s = {1'b0, n0q};
    
    always @(posedge clk) begin
        if (!de) begin
            case (cd)
                2'b00: tmds <= 10'b1101010100;
                2'b01: tmds <= 10'b0010101011;
                2'b10: tmds <= 10'b0101010100;
                2'b11: tmds <= 10'b1010101011;
            endcase
            dc_bias <= 5'sd0;
        end else begin
            if (dc_bias == 0 || n1q == n0q) begin
                tmds <= { ~q_m[8], q_m[8], (q_m[8] ? q_m[7:0] : ~q_m[7:0]) };
                dc_bias <= dc_bias + (q_m[8] ? (n1q_s - n0q_s) : (n0q_s - n1q_s));
            end else if ((dc_bias > 0 && n1q > n0q) || (dc_bias < 0 && n0q > n1q)) begin
                tmds <= { 1'b1, q_m[8], ~q_m[7:0] };
                dc_bias <= dc_bias + n0q_s - n1q_s + (q_m[8] ? 5'sd2 : 5'sd0);
            end else begin
                tmds <= { 1'b0, q_m[8], q_m[7:0] };
                dc_bias <= dc_bias + n1q_s - n0q_s - (q_m[8] ? 5'sd0 : 5'sd2);
            end
        end
    end
endmodule