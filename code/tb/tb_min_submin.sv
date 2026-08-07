//============================================================================
//  tb_min_submin.sv -- Kiem tra khoi tim min / submin (Figure 2)
//  Bao phu:
//   1. Moi trong so hang d_r = 1..8
//   2. Vector ngau nhien (so sanh voi mo hinh vang)
//   3. Truong hop bang nhau (tat ca bang nhau, hai gia tri min trung nhau)
//   4. Bien: tat ca = 0, tat ca = MAGMAX, min o dau/cuoi day
//============================================================================
`timescale 1ns/1ps
import ldpc_pkg::*;

module tb_min_submin;

  logic [DR_MAX*MAGW-1:0] mag_i;
  logic [DRW-1:0]         rw;
  logic [MAGW-1:0]        min1, min2;
  logic [IDXW-1:0]        idx;

  int errors = 0, nvec = 0;

  min_submin dut (.mag_i(mag_i), .row_weight(rw), .min1(min1), .min2(min2), .min_idx(idx));

  // ---- mo hinh vang -------------------------------------------------------
  int gm1, gm2, gidx;
  task automatic golden(input int w);
    int v;
    begin
      gm1 = MAGMAX_I; gm2 = MAGMAX_I; gidx = 0;
      for (int i = 0; i < DR_MAX; i++) begin
        v = (i < w) ? mag_i[i*MAGW +: MAGW] : MAGMAX_I;
        if (v < gm1) begin gm2 = gm1; gm1 = v; gidx = i; end
        else if (v < gm2) gm2 = v;
      end
    end
  endtask

  task automatic run(input int w);
    begin
      rw = w[DRW-1:0];
      #1;
      golden(w);
      nvec++;
      if (min1 !== gm1[MAGW-1:0] || min2 !== gm2[MAGW-1:0] || idx !== gidx[IDXW-1:0]) begin
        $display("FAIL rw=%0d mag=%h -> (%0d,%0d,%0d) exp (%0d,%0d,%0d)",
                 w, mag_i, min1, min2, idx, gm1, gm2, gidx);
        errors++;
      end
    end
  endtask

  task automatic set_all(input int v);
    for (int i = 0; i < DR_MAX; i++) mag_i[i*MAGW +: MAGW] = v[MAGW-1:0];
  endtask

  initial begin
    // 1-2. ngau nhien cho moi trong so hang
    for (int w = 1; w <= DR_MAX; w++)
      for (int t = 0; t < 2000; t++) begin
        for (int i = 0; i < DR_MAX; i++) mag_i[i*MAGW +: MAGW] = $urandom_range(0, MAGMAX_I);
        run(w);
      end

    // 3. tat ca bang nhau
    for (int v = 0; v <= MAGMAX_I; v++) begin
      set_all(v);
      for (int w = 1; w <= DR_MAX; w++) run(w);
    end

    // 3b. hai gia tri nho nhat bang nhau
    for (int w = 2; w <= DR_MAX; w++)
      for (int a = 0; a < w; a++)
        for (int b = 0; b < w; b++) if (a != b) begin
          set_all(MAGMAX_I);
          mag_i[a*MAGW +: MAGW] = 3;
          mag_i[b*MAGW +: MAGW] = 3;
          run(w);
        end

    // 4. bien: gia tri nho nhat o tung vi tri
    for (int w = 1; w <= DR_MAX; w++)
      for (int p = 0; p < w; p++) begin
        set_all(MAGMAX_I);
        mag_i[p*MAGW +: MAGW] = 0;
        run(w);
      end

    // 4b. day tang dan / giam dan
    for (int i = 0; i < DR_MAX; i++) mag_i[i*MAGW +: MAGW] = i[MAGW-1:0];
    for (int w = 1; w <= DR_MAX; w++) run(w);
    for (int i = 0; i < DR_MAX; i++) mag_i[i*MAGW +: MAGW] = (DR_MAX-1-i);
    for (int w = 1; w <= DR_MAX; w++) run(w);

    if (errors == 0) $display("[tb_min_submin] PASS - %0d vector", nvec);
    else             $display("[tb_min_submin] FAIL - %0d/%0d loi", errors, nvec);
    $finish;
  end

endmodule
