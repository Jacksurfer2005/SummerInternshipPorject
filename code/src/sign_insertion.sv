//============================================================================
//  sign_insertion.sv -- Khoi "Sign insertion" (Figure 3)
//
//  Voi moi canh n cua hang kiem tra:
//      |CTV_n| = alpha * ( n == idx_min ? min2 : min1 )
//      sign(CTV_n) = sign_prod XOR sign(VTC_n)          (cong thuc (4),(6))
//  alpha o dang Q1.4 : alpha_thuc = alpha/16 (vd 12 -> 0.75, 16 -> 1.0)
//============================================================================
`timescale 1ns/1ps

import ldpc_pkg::*;

module sign_insertion
(
  input  logic [MAGW-1:0]        min1,
  input  logic [MAGW-1:0]        min2,
  input  logic [IDXW-1:0]        min_idx,
  input  logic                   sign_prod,
  input  logic [DR_MAX-1:0]      signs,
  input  logic [DRW-1:0]         row_weight,
  input  logic [ALPHA_W-1:0]     alpha,
  output logic [DR_MAX*DW-1:0]   ctv_o     // {ctv[7],...,ctv[0]} phang
);

  localparam int PW = MAGW + ALPHA_W;

  // Bien trung gian khai bao o pham vi module (tranh tu kich hoat lai
  // always_comb tren mot so trinh mo phong)
  logic [MAGW-1:0]      sel_mag;
  logic [PW-1:0]        prod;
  logic [PW-1:0]        scaled;
  logic [MAGW-1:0]      mag_sat;
  logic                 s;
  logic signed [DW-1:0] ctv;

  always_comb begin
    ctv_o = '0;
    for (int n = 0; n < DR_MAX; n++) begin
      sel_mag = (n[IDXW-1:0] == min_idx) ? min2 : min1;
      prod    = sel_mag * alpha;
      scaled  = prod >> 4;                      // chia cho 16 (Q1.4)
      mag_sat = (scaled > MAGMAX) ? MAGMAX : scaled[MAGW-1:0];
      s       = sign_prod ^ signs[n];
      ctv     = s ? -$signed({1'b0, mag_sat}) : $signed({1'b0, mag_sat});
      ctv_o[n*DW +: DW] = (n < row_weight) ? ctv : {DW{1'b0}};
    end
  end

endmodule
