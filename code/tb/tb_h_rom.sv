//============================================================================
//  tb_h_rom.sv -- Kiem tra bo nho ma tran kiem tra (vals / pos / elementSize)
//  Bao phu:
//   1. Doi chieu ba vector nen voi ma tran co so goc 802.16e rate 1/2
//   2. Kiem tra tung (layer, idx) cho toan bo MB x DR_MAX
//   3. Kiem tra edge_valid, gioi han luong dich < Z, ti le p*Z/Z0
//============================================================================
`timescale 1ns/1ps
import ldpc_pkg::*;

module tb_h_rom;

  logic [MB_W-1:0]  layer;
  logic [DRW-1:0]   idx;
  logic [DRW-1:0]   rw;
  logic [NB_W-1:0]  col;
  logic [Z_W-1:0]   sh;
  logic             ev;

  int errors = 0, nvec = 0;

  h_rom #(.INIT_FILE("mem/h_base_16e_r12.mem")) dut (
    .layer(layer), .idx(idx), .row_weight(rw),
    .col_pos(col), .shift(sh), .edge_valid(ev));

  // Ma tran co so tham chieu (IEEE 802.16e, rate 1/2, z0 = 96)
  int HB [0:11][0:23];
  int exp_pos [0:11][0:7];
  int exp_val [0:11][0:7];
  int exp_rw  [0:11];

  initial begin
    // nap ma tran tham chieu tu chinh file .mem nhung theo duong doc doc lap
    begin
      integer fd, r, c, v, k;
      logic [7:0] raw [0:MB*NB-1];
      for (k = 0; k < MB*NB; k++) raw[k] = 8'hff;
      $readmemh("mem/h_base_16e_r12.mem", raw);
      for (r = 0; r < MB; r++) begin
        k = 0;
        for (c = 0; c < NB; c++) begin
          v = (raw[r*NB+c] === 8'hff) ? -1 : raw[r*NB+c];
          HB[r][c] = v;
          if (v >= 0) begin
            exp_pos[r][k] = c;
            exp_val[r][k] = (v * Z) / Z0;
            k++;
          end
        end
        exp_rw[r] = k;
        for (; k < DR_MAX; k++) begin exp_pos[r][k] = 0; exp_val[r][k] = 0; end
      end
    end

    #1;
    for (int r = 0; r < MB; r++) begin
      layer = r[MB_W-1:0];
      for (int e = 0; e < DR_MAX; e++) begin
        idx = e[DRW-1:0];
        #1; nvec++;
        if (rw !== exp_rw[r][DRW-1:0]) begin
          $display("FAIL rowWeight layer %0d: %0d exp %0d", r, rw, exp_rw[r]); errors++;
        end
        if (ev !== ((e < exp_rw[r]) ? 1'b1 : 1'b0)) begin
          $display("FAIL edge_valid layer %0d idx %0d", r, e); errors++;
        end
        if (e < exp_rw[r]) begin
          if (col !== exp_pos[r][e][NB_W-1:0]) begin
            $display("FAIL pos  (%0d,%0d): %0d exp %0d", r, e, col, exp_pos[r][e]); errors++;
          end
          if (sh !== exp_val[r][e][Z_W-1:0]) begin
            $display("FAIL vals (%0d,%0d): %0d exp %0d", r, e, sh, exp_val[r][e]); errors++;
          end
          if (sh >= Z) begin
            $display("FAIL shift >= Z tai (%0d,%0d)", r, e); errors++;
          end
        end
      end
      if (exp_rw[r] > DR_MAX) begin
        $display("FAIL row weight vuot DR_MAX tai hang %0d", r); errors++;
      end
    end

    if (errors == 0) $display("[tb_h_rom] PASS - %0d vector, max d_r kiem tra OK", nvec);
    else             $display("[tb_h_rom] FAIL - %0d loi", errors);
    $finish;
  end
endmodule
