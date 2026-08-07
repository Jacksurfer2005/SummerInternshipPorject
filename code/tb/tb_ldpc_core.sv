//============================================================================
//  tb_ldpc_core.sv -- Kiem tra CORE / Check Node Unit (Figure 3)
//  So sanh truc tiep voi cong thuc (4) & (6) cua bai bao:
//     CTV_n = (prod_{n'!=n} sign(VTC_n')) * alpha * min_{n'!=n} |VTC_n'|
//  Bao phu:
//   1. Ngau nhien tren moi d_r = 1..8, moi alpha
//   2. Toan bo VTC = 0  (truong hop suy bien)
//   3. VTC = gia tri bao hoa am -2^(DW-1)
//   4. Chi mot VTC am (dau ra phai doi dau)
//   5. Cac gia tri modulo trung nhau (tie) tai vi tri min
//   6. Vet can hoan toan cho d_r = 3 voi DW rut gon (mien +-3)
//============================================================================
`timescale 1ns/1ps
import ldpc_pkg::*;

module tb_ldpc_core;

  logic [DR_MAX*DW-1:0] vtc, ctv;
  logic [DRW-1:0]       rw;
  logic [ALPHA_W-1:0]   alpha;
  logic [MAGW-1:0]      min_o, submin_o;
  logic                 sp_o;

  int errors = 0, nvec = 0;

  ldpc_core dut (.vtc_i(vtc), .row_weight(rw), .alpha(alpha), .ctv_o(ctv),
                 .min_o(min_o), .submin_o(submin_o), .sign_prod_o(sp_o));

  // --- mo hinh vang theo dinh nghia truc tiep (khong dung min/submin) ------
  task automatic check;
    int v, m, ex, got, sgn, scaled;
    begin
      #1; nvec++;
      for (int n = 0; n < DR_MAX; n++) begin
        got = $signed(ctv[n*DW +: DW]);
        if (n >= rw) begin
          ex = 0;
        end else begin
          m   = MAGMAX_I;
          sgn = 0;
          for (int k = 0; k < rw; k++) if (k != n) begin
            v = $signed(vtc[k*DW +: DW]);
            if (v < 0) begin sgn = sgn ^ 1; v = -v; end
            if (v > MAGMAX_I) v = MAGMAX_I;
            if (v < m) m = v;
          end
          scaled = (m * alpha) >> 4;
          if (scaled > MAGMAX_I) scaled = MAGMAX_I;
          ex = sgn ? -scaled : scaled;
        end
        if (got !== ex) begin
          $display("FAIL n=%0d rw=%0d alpha=%0d vtc=%h got=%0d exp=%0d",
                   n, rw, alpha, vtc, got, ex);
          errors++;
        end
      end
    end
  endtask

  task automatic set_all(input int v);
    for (int i = 0; i < DR_MAX; i++) vtc[i*DW +: DW] = v[DW-1:0];
  endtask

  initial begin
    // 1. ngau nhien
    for (int w = 1; w <= DR_MAX; w++)
      for (int t = 0; t < 3000; t++) begin
        for (int i = 0; i < DR_MAX; i++)
          vtc[i*DW +: DW] = $urandom_range(0, (2**DW)-1);
        rw    = w[DRW-1:0];
        alpha = $urandom_range(1, 16);
        check();
      end

    // 2. tat ca bang 0
    set_all(0);
    for (int w = 1; w <= DR_MAX; w++) begin rw = w[DRW-1:0]; alpha = 5'd12; check(); end

    // 3. tat ca bang -2^(DW-1) (bao hoa modulo)
    set_all(DMIN_I);
    for (int w = 1; w <= DR_MAX; w++) begin rw = w[DRW-1:0]; alpha = 5'd16; check(); end

    // 4. chi mot phan tu am
    for (int p = 0; p < DR_MAX; p++) begin
      set_all(5);
      vtc[p*DW +: DW] = -6;
      rw = DR_MAX[DRW-1:0]; alpha = 5'd12; check();
    end

    // 5. hai gia tri modulo nho nhat bang nhau (tie)
    for (int a = 0; a < DR_MAX; a++)
      for (int b = 0; b < DR_MAX; b++) if (a != b) begin
        set_all(DMAX_I);
        vtc[a*DW +: DW] = -3;
        vtc[b*DW +: DW] =  3;
        rw = DR_MAX[DRW-1:0]; alpha = 5'd12; check();
      end

    // 6. vet can d_r = 3, mien gia tri [-3..3]
    for (int x0 = -3; x0 <= 3; x0++)
    for (int x1 = -3; x1 <= 3; x1++)
    for (int x2 = -3; x2 <= 3; x2++) begin
      set_all(DMAX_I);
      vtc[0*DW +: DW] = x0[DW-1:0];
      vtc[1*DW +: DW] = x1[DW-1:0];
      vtc[2*DW +: DW] = x2[DW-1:0];
      rw = 3; alpha = 5'd12; check();
      rw = 3; alpha = 5'd16; check();
    end

    if (errors == 0) $display("[tb_ldpc_core] PASS - %0d vector", nvec);
    else             $display("[tb_ldpc_core] FAIL - %0d loi / %0d vector", errors, nvec);
    $finish;
  end
endmodule
