//============================================================================
//  ldpc_core.sv -- "Check node unit calculation block" (Figure 3)
//
//  Day chinh la mot CORE cua kien truc song song: so core bang kich thuoc
//  circulant z (muc III.B: "the number of cores is equal to the codeword
//  circulant size (z)").
//
//  Vao : d_r ban tin VTC (co dau) cua mot hang kiem tra
//  Ra  : d_r ban tin CTV moi theo cong thuc (6) + bit syndrome cua hang
//============================================================================
`timescale 1ns/1ps

import ldpc_pkg::*;

module ldpc_core
(
  input  logic [DR_MAX*DW-1:0] vtc_i,
  input  logic [DRW-1:0]       row_weight,
  input  logic [ALPHA_W-1:0]   alpha,
  output logic [DR_MAX*DW-1:0] ctv_o,
  output logic [MAGW-1:0]      min_o,      // quan sat/debug
  output logic [MAGW-1:0]      submin_o,
  output logic                 sign_prod_o
);

  logic [DR_MAX-1:0]      signs;
  logic [DR_MAX*MAGW-1:0] mags;
  logic [MAGW-1:0]        min1, min2;
  logic [IDXW-1:0]        min_idx;
  logic                   sign_prod;

  // ---- ABS: tach dau va modulo -----------------------------------------
  genvar i;
  generate
    for (i = 0; i < DR_MAX; i++) begin : g_abs
      abs_sign u_abs (
        .din  (vtc_i[i*DW +: DW]),
        .sign (signs[i]),
        .mag  (mags[i*MAGW +: MAGW]));
    end
  endgenerate

  // ---- Signs XORing -----------------------------------------------------
  signs_xoring u_sx (
    .signs      (signs),
    .row_weight (row_weight),
    .sign_prod  (sign_prod));

  // ---- Tim min / submin -------------------------------------------------
  min_submin u_ms (
    .mag_i      (mags),
    .row_weight (row_weight),
    .min1       (min1),
    .min2       (min2),
    .min_idx    (min_idx));

  // ---- Chen dau + he so alpha ------------------------------------------
  sign_insertion u_si (
    .min1       (min1),
    .min2       (min2),
    .min_idx    (min_idx),
    .sign_prod  (sign_prod),
    .signs      (signs),
    .row_weight (row_weight),
    .alpha      (alpha),
    .ctv_o      (ctv_o));

  assign min_o       = min1;
  assign submin_o    = min2;
  assign sign_prod_o = sign_prod;

endmodule
