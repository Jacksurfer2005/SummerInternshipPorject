//============================================================================
//  tb_abs_sign.sv -- Kiem tra khoi ABS
//  Bao phu: VET CAN toan bo 2^DW gia tri dau vao (ke ca -2^(DW-1)).
//============================================================================
`timescale 1ns/1ps
import ldpc_pkg::*;

module tb_abs_sign;

  logic signed [DW-1:0] din;
  logic                 sign;
  logic [MAGW-1:0]      mag;

  int errors = 0;
  int exp_mag;

  abs_sign dut (.din(din), .sign(sign), .mag(mag));

  initial begin
    for (int v = DMIN_I; v <= DMAX_I; v++) begin
      din = v[DW-1:0];
      #1;
      exp_mag = (v < 0) ? -v : v;
      if (exp_mag > MAGMAX_I) exp_mag = MAGMAX_I;   // bao hoa -2^(DW-1)

      if (sign !== ((v < 0) ? 1'b1 : 1'b0)) begin
        $display("FAIL sign: din=%0d sign=%0b", v, sign);
        errors++;
      end
      if (mag !== exp_mag[MAGW-1:0]) begin
        $display("FAIL mag : din=%0d mag=%0d exp=%0d", v, mag, exp_mag);
        errors++;
      end
    end

    if (errors == 0) $display("[tb_abs_sign] PASS - %0d vector", 2**DW);
    else             $display("[tb_abs_sign] FAIL - %0d loi", errors);
    $finish;
  end

endmodule
