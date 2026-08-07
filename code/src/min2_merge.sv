//============================================================================
//  min2_merge.sv -- Te bao so sanh (Compare(min)) dung de xay cay tim
//                   min / submin trong Figure 2.
//
//  Moi nut giu bo ba (min1, min2, idx_of_min1) cua mot nhom dau vao.
//  Ghep hai nhom A va B:
//      min1 = min(A.min1, B.min1)
//      min2 = min( max(A.min1,B.min1), min2 cua nhom chua min1 )
//============================================================================
`timescale 1ns/1ps

module min2_merge #(
  parameter int MAGW = 5,
  parameter int IDXW = 3
)(
  input  logic [MAGW-1:0] a_min1,
  input  logic [MAGW-1:0] a_min2,
  input  logic [IDXW-1:0] a_idx,
  input  logic [MAGW-1:0] b_min1,
  input  logic [MAGW-1:0] b_min2,
  input  logic [IDXW-1:0] b_idx,
  output logic [MAGW-1:0] y_min1,
  output logic [MAGW-1:0] y_min2,
  output logic [IDXW-1:0] y_idx
);

  logic            a_le;
  logic [MAGW-1:0] loser_min1;
  logic [MAGW-1:0] winner_min2;

  assign a_le        = (a_min1 <= b_min1);
  assign y_min1      = a_le ? a_min1 : b_min1;
  assign y_idx       = a_le ? a_idx  : b_idx;
  assign loser_min1  = a_le ? b_min1 : a_min1;
  assign winner_min2 = a_le ? a_min2 : b_min2;
  assign y_min2      = (loser_min1 <= winner_min2) ? loser_min1 : winner_min2;

endmodule
