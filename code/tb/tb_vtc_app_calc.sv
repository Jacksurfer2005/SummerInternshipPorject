//============================================================================
//  tb_vtc_app_calc.sv -- Kiem tra khoi VTC calculation (5) va APP calculation (7)
//  Bao phu:
//   1. VET CAN toan bo cap (APP, CTV) tren lane 0  -> 64 x 64 = 4096 to hop
//      (bao gom moi truong hop tran duong/tran am can bao hoa)
//   2. Ngau nhien dong thoi tren ca z lane
//============================================================================
`timescale 1ns/1ps
import ldpc_pkg::*;

module tb_vtc_app_calc;

  logic [Z*DW-1:0] a, b, vtc, app;
  int errors = 0, nvec = 0;

  vtc_calc #(.LANES(Z)) u_vtc (.app_i(a), .ctv_i(b), .vtc_o(vtc));
  app_calc #(.LANES(Z)) u_app (.vtc_i(a), .ctv_i(b), .app_o(app));

  function automatic int sat(input int x);
    if (x > DMAX_I)      sat = DMAX_I;
    else if (x < DMIN_I) sat = DMIN_I;
    else                 sat = x;
  endfunction

  task automatic check;
    int x, y, e, g;
    begin
      #1; nvec++;
      for (int i = 0; i < Z; i++) begin
        x = $signed(a[i*DW +: DW]);
        y = $signed(b[i*DW +: DW]);
        e = sat(x - y); g = $signed(vtc[i*DW +: DW]);
        if (g !== e) begin
          $display("FAIL SUB lane%0d %0d-%0d got %0d exp %0d", i, x, y, g, e); errors++;
        end
        e = sat(x + y); g = $signed(app[i*DW +: DW]);
        if (g !== e) begin
          $display("FAIL ADD lane%0d %0d+%0d got %0d exp %0d", i, x, y, g, e); errors++;
        end
      end
    end
  endtask

  initial begin
    // 1. vet can tren lane 0 (cac lane khac giu 0)
    a = '0; b = '0;
    for (int x = 0; x < 2**DW; x++)
      for (int y = 0; y < 2**DW; y++) begin
        a[0 +: DW] = x[DW-1:0];
        b[0 +: DW] = y[DW-1:0];
        check();
      end
    // 2. ngau nhien tren toan bo z lane
    for (int t = 0; t < 500; t++) begin
      for (int i = 0; i < Z; i++) begin
        a[i*DW +: DW] = $urandom_range(0, (2**DW)-1);
        b[i*DW +: DW] = $urandom_range(0, (2**DW)-1);
      end
      check();
    end
    if (errors == 0) $display("[tb_vtc_app_calc] PASS - %0d vector", nvec);
    else             $display("[tb_vtc_app_calc] FAIL - %0d loi", errors);
    $finish;
  end
endmodule
