//============================================================================
//  tb_barrel_shifter.sv -- Kiem tra bo dich vong QC
//  Bao phu:
//   1. VET CAN moi luong dich 0..Z-1 cho ca hai chieu
//   2. Kiem tra tinh nghich dao (dich trai roi dich phai = ban dau)
//   3. Du lieu bien: toan 0, toan 1, mau danh dau tung lane
//============================================================================
`timescale 1ns/1ps
import ldpc_pkg::*;

module tb_barrel_shifter;

  logic [Z*DW-1:0] din, dl, dr_, back;
  logic [Z_W-1:0]  sh;
  int errors = 0, nvec = 0;

  barrel_shifter #(.LANES(Z), .LW(DW), .SW(Z_W)) u_l (.din(din), .shift(sh), .dir(1'b0), .dout(dl));
  barrel_shifter #(.LANES(Z), .LW(DW), .SW(Z_W)) u_r (.din(din), .shift(sh), .dir(1'b1), .dout(dr_));
  barrel_shifter #(.LANES(Z), .LW(DW), .SW(Z_W)) u_b (.din(dl),  .shift(sh), .dir(1'b1), .dout(back));

  task automatic check;
    int s, e;
    begin
      #1; nvec++;
      for (int i = 0; i < Z; i++) begin
        // dich trai: dout[i] = din[(i+sh) mod Z]
        s = (i + sh) % Z;
        e = din[s*DW +: DW];
        if (dl[i*DW +: DW] !== e[DW-1:0]) begin
          $display("FAIL LEFT sh=%0d lane %0d", sh, i); errors++;
        end
        // dich phai la phep nghich dao
        s = (i - sh + Z) % Z;
        e = din[s*DW +: DW];
        if (dr_[i*DW +: DW] !== e[DW-1:0]) begin
          $display("FAIL RIGHT sh=%0d lane %0d", sh, i); errors++;
        end
      end
      if (back !== din) begin $display("FAIL ROUNDTRIP sh=%0d", sh); errors++; end
    end
  endtask

  initial begin
    for (int s = 0; s < Z; s++) begin
      sh = s[Z_W-1:0];
      // mau danh dau lane
      for (int i = 0; i < Z; i++) din[i*DW +: DW] = i[DW-1:0];
      check();
      din = '0;                check();
      din = {(Z*DW){1'b1}};    check();
      for (int t = 0; t < 20; t++) begin
        for (int i = 0; i < Z; i++) din[i*DW +: DW] = $urandom_range(0,(2**DW)-1);
        check();
      end
    end
    if (errors == 0) $display("[tb_barrel_shifter] PASS - %0d vector", nvec);
    else             $display("[tb_barrel_shifter] FAIL - %0d loi", errors);
    $finish;
  end
endmodule
