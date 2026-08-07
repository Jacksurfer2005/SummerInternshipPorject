//============================================================================
//  mode_select.sv -- "Operating mode selection" (Figure 1)
//
//  Chuyen che do lam viec giua "decoding" va "result output".
//  Khi nhan muc cao tu Iterations counter: bat READY, va lay quyet dinh
//  cung tu APP de dua ra ngo OUT (muc III.A).
//============================================================================
`timescale 1ns/1ps

import ldpc_pkg::*;

module mode_select
#(
  parameter int LANES = Z
)(
  input  logic                 mode_out,    // 1 = che do "result output"
  input  logic                 blk_valid,   // khoi APP tren app_word hop le
  input  logic [LANES*DW-1:0]  app_word,
  output logic                 ready,       // READY
  output logic                 out_valid,
  output logic [LANES-1:0]     out_bits     // OUT (quyet dinh cung)
);

  always_comb begin
    ready     = mode_out;
    out_valid = mode_out & blk_valid;
    for (int i = 0; i < LANES; i++)
      out_bits[i] = ldpc_pkg::hard_bit($signed(app_word[i*DW +: DW]));
  end

endmodule
