//============================================================================
//  tb_signs_xoring.sv -- Kiem tra khoi Signs XORing
//  Bao phu: VET CAN 2^8 to hop dau x 9 gia tri row_weight (0..8)
//============================================================================
`timescale 1ns/1ps
import ldpc_pkg::*;

module tb_signs_xoring;

  logic [DR_MAX-1:0] signs;
  logic [DRW-1:0]    rw;
  logic              sp;
  int errors = 0, nvec = 0, exp;

  signs_xoring dut (.signs(signs), .row_weight(rw), .sign_prod(sp));

  initial begin
    for (int s = 0; s < 2**DR_MAX; s++)
      for (int w = 0; w <= DR_MAX; w++) begin
        signs = s[DR_MAX-1:0];
        rw    = w[DRW-1:0];
        #1;
        exp = 0;
        for (int i = 0; i < w; i++) exp = exp ^ ((s >> i) & 1);
        nvec++;
        if (sp !== exp[0]) begin
          $display("FAIL signs=%b rw=%0d sp=%b exp=%b", signs, w, sp, exp[0]);
          errors++;
        end
      end
    if (errors == 0) $display("[tb_signs_xoring] PASS - %0d vector", nvec);
    else             $display("[tb_signs_xoring] FAIL - %0d loi", errors);
    $finish;
  end
endmodule
