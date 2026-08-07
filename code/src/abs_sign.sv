//============================================================================
//  abs_sign.sv -- Khoi ABS trong Figure 2 cua bai bao
//  Chuyen du lieu co dau (1..8) thanh modulo khong dau (1'..8') va
//  tach bit dau dua len bus "signs".
//============================================================================
`timescale 1ns/1ps

import ldpc_pkg::*;

module abs_sign
(
  input  logic signed [DW-1:0]   din,
  output logic                   sign,   // 1 = am
  output logic [MAGW-1:0]        mag     // |din|, bao hoa tai MAGMAX
);

  assign sign = din[DW-1];

  assign mag = ldpc_pkg::sat_abs(din);

endmodule
