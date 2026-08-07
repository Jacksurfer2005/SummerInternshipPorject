//============================================================================
//  tb_sign_insertion.sv -- Kiem tra khoi Sign insertion + he so alpha
//  Bao phu:
//   1. Ngau nhien tren toan bo dau vao (min1<=min2, idx, sign_prod, signs)
//   2. Quet toan bo alpha 0..31 (Q1.4)
//   3. Kiem tra bao hoa khi alpha > 1.0
//   4. Kiem tra lane khong dung (n >= row_weight) phai bang 0
//============================================================================
`timescale 1ns/1ps
import ldpc_pkg::*;

module tb_sign_insertion;

  logic [MAGW-1:0]      min1, min2;
  logic [IDXW-1:0]      midx;
  logic                 sp;
  logic [DR_MAX-1:0]    signs;
  logic [DRW-1:0]       rw;
  logic [ALPHA_W-1:0]   alpha;
  logic [DR_MAX*DW-1:0] ctv;

  int errors = 0, nvec = 0;

  sign_insertion dut (.min1(min1), .min2(min2), .min_idx(midx), .sign_prod(sp),
                      .signs(signs), .row_weight(rw), .alpha(alpha), .ctv_o(ctv));

  task automatic check;
    int sel, scaled, expv, got;
    begin
      #1; nvec++;
      for (int n = 0; n < DR_MAX; n++) begin
        sel    = (n == midx) ? min2 : min1;
        scaled = (sel * alpha) >> 4;
        if (scaled > MAGMAX_I) scaled = MAGMAX_I;
        expv = (sp ^ signs[n]) ? -scaled : scaled;
        if (n >= rw) expv = 0;
        got = $signed(ctv[n*DW +: DW]);
        if (got !== expv) begin
          $display("FAIL n=%0d min1=%0d min2=%0d idx=%0d a=%0d sp=%b sg=%b rw=%0d got=%0d exp=%0d",
                   n, min1, min2, midx, alpha, sp, signs[n], rw, got, expv);
          errors++;
        end
      end
    end
  endtask

  initial begin
    // 1. ngau nhien
    for (int t = 0; t < 5000; t++) begin
      min1  = $urandom_range(0, MAGMAX_I);
      min2  = $urandom_range(min1, MAGMAX_I);
      midx  = $urandom_range(0, DR_MAX-1);
      sp    = $urandom_range(0,1);
      signs = $urandom_range(0, 255);
      rw    = $urandom_range(1, DR_MAX);
      alpha = $urandom_range(0, 31);
      check();
    end
    // 2/3. quet alpha, ke ca alpha > 16 (>1.0) de kiem tra bao hoa
    for (int a = 0; a <= 31; a++) begin
      min1 = MAGMAX; min2 = MAGMAX; midx = 0; sp = 0; signs = '0;
      rw = DR_MAX; alpha = a[ALPHA_W-1:0];
      check();
    end
    // 4. lane khong dung
    for (int w = 1; w <= DR_MAX; w++) begin
      min1 = 5; min2 = 9; midx = 1; sp = 1; signs = 8'hA5;
      rw = w[DRW-1:0]; alpha = 5'd12;
      check();
    end
    if (errors == 0) $display("[tb_sign_insertion] PASS - %0d vector", nvec);
    else             $display("[tb_sign_insertion] FAIL - %0d loi", errors);
    $finish;
  end
endmodule
