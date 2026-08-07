//============================================================================
//  min_submin.sv -- Khoi "Min/submin calculation" (Figure 2)
//
//  - Nhan DR_MAX = 8 gia tri modulo |VTC|.
//  - Cac dau vao co chi so >= row_weight duoc nap gia tri duong lon nhat
//    (MAGMAX) dung nhu mo ta trong bai bao ("the remaining inputs are fed
//     with the maximum positive values for the current input bitness").
//  - Tra ve min1 (gia tri nho nhat), min2 (gia tri nho nhi) va chi so cua
//    min1. Cascade gom 4 tang so sanh: 1 tang tao cap (trong min2_merge
//    la tang la) + 3 tang ghep.
//============================================================================
`timescale 1ns/1ps

import ldpc_pkg::*;

module min_submin
(
  input  logic [DR_MAX*MAGW-1:0] mag_i,       // {mag[7],...,mag[0]} phang
  input  logic [DRW-1:0]         row_weight,  // d_r
  output logic [MAGW-1:0]        min1,
  output logic [MAGW-1:0]        min2,
  output logic [IDXW-1:0]        min_idx
);

  // --------------------------------------------------------------------
  // Tang la: che cac dau vao khong dung
  // --------------------------------------------------------------------
  logic [MAGW-1:0] l_min1 [0:DR_MAX-1];
  logic [MAGW-1:0] l_min2 [0:DR_MAX-1];
  logic [IDXW-1:0] l_idx  [0:DR_MAX-1];

  genvar i;
  generate
    for (i = 0; i < DR_MAX; i++) begin : g_leaf
      always_comb begin
        l_min1[i] = (i < row_weight) ? mag_i[i*MAGW +: MAGW] : MAGMAX;
        l_min2[i] = MAGMAX;
        l_idx [i] = i[IDXW-1:0];
      end
    end
  endgenerate

  // --------------------------------------------------------------------
  // Tang 1 : 8 -> 4
  // --------------------------------------------------------------------
  logic [MAGW-1:0] s1_min1 [0:3];
  logic [MAGW-1:0] s1_min2 [0:3];
  logic [IDXW-1:0] s1_idx  [0:3];

  generate
    for (i = 0; i < 4; i++) begin : g_s1
      min2_merge #(.MAGW(MAGW), .IDXW(IDXW)) u_m (
        .a_min1(l_min1[2*i]),   .a_min2(l_min2[2*i]),   .a_idx(l_idx[2*i]),
        .b_min1(l_min1[2*i+1]), .b_min2(l_min2[2*i+1]), .b_idx(l_idx[2*i+1]),
        .y_min1(s1_min1[i]),    .y_min2(s1_min2[i]),    .y_idx(s1_idx[i]));
    end
  endgenerate

  // --------------------------------------------------------------------
  // Tang 2 : 4 -> 2
  // --------------------------------------------------------------------
  logic [MAGW-1:0] s2_min1 [0:1];
  logic [MAGW-1:0] s2_min2 [0:1];
  logic [IDXW-1:0] s2_idx  [0:1];

  generate
    for (i = 0; i < 2; i++) begin : g_s2
      min2_merge #(.MAGW(MAGW), .IDXW(IDXW)) u_m (
        .a_min1(s1_min1[2*i]),   .a_min2(s1_min2[2*i]),   .a_idx(s1_idx[2*i]),
        .b_min1(s1_min1[2*i+1]), .b_min2(s1_min2[2*i+1]), .b_idx(s1_idx[2*i+1]),
        .y_min1(s2_min1[i]),     .y_min2(s2_min2[i]),     .y_idx(s2_idx[i]));
    end
  endgenerate

  // --------------------------------------------------------------------
  // Tang 3 : 2 -> 1
  // --------------------------------------------------------------------
  min2_merge #(.MAGW(MAGW), .IDXW(IDXW)) u_s3 (
    .a_min1(s2_min1[0]), .a_min2(s2_min2[0]), .a_idx(s2_idx[0]),
    .b_min1(s2_min1[1]), .b_min2(s2_min2[1]), .b_idx(s2_idx[1]),
    .y_min1(min1),       .y_min2(min2),       .y_idx(min_idx));

endmodule
