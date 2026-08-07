//============================================================================
//  signs_xoring.sv -- Khoi "Signs XORing" (Figure 2 / Figure 3)
//  Cong modulo 2 tat ca bit dau cua d_r dau vao hop le.
//  Cac lane khong dung mang gia tri duong (sign = 0) nen khong anh huong.
//============================================================================
`timescale 1ns/1ps

import ldpc_pkg::*;

module signs_xoring
(
  input  logic [DR_MAX-1:0] signs,
  input  logic [DRW-1:0]    row_weight,
  output logic              sign_prod   // prod(sign(q_mn')) duoi dang bit
);

  logic [DR_MAX-1:0] masked;

  always_comb begin
    for (int i = 0; i < DR_MAX; i++)
      masked[i] = (i < row_weight) ? signs[i] : 1'b0;
    sign_prod = ^masked;
  end

endmodule
