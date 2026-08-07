//============================================================================
//  iter_counter.sv -- "Iterations counter" (Figure 1)
//
//  Dem so vong lap giai ma. Khi dat so vong lap cho truoc (hoac khi
//  syndrome = 0 neu bat dung sang som) thi dua ngo ra len muc cao de
//  khoi "Operating mode selection" chuyen sang che do xuat ket qua.
//============================================================================
`timescale 1ns/1ps

import ldpc_pkg::*;

module iter_counter
#(
  parameter bit EARLY_TERM = 1
)(
  input  logic              clk,
  input  logic              rst_n,
  input  logic              clear,      // bat dau khung moi
  input  logic              iter_done,  // xung: ket thuc 1 vong lap
  input  logic              converged,  // Hx = 0
  input  logic [ITER_W-1:0] max_iter,
  output logic [ITER_W-1:0] iter_cnt,
  output logic              done        // muc cao -> ket thuc giai ma
);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      iter_cnt <= '0;
      done     <= 1'b0;
    end else if (clear) begin
      iter_cnt <= '0;
      done     <= 1'b0;
    end else if (iter_done) begin
      iter_cnt <= iter_cnt + 1'b1;
      if ((iter_cnt + 1'b1) >= max_iter)         done <= 1'b1;
      else if (EARLY_TERM && converged)          done <= 1'b1;
    end
  end

endmodule
