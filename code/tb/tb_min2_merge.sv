//============================================================================
//  tb_min2_merge.sv -- Kiem tra te bao so sanh min/submin
//  Bao phu: vet can khong gian nho (MAGW rut gon) + huong dan cac truong hop
//           bang nhau, min1=min2, bien 0 va gia tri lon nhat.
//============================================================================
`timescale 1ns/1ps
import ldpc_pkg::*;

module tb_min2_merge;

  localparam int W = 3;   // dung MAGW nho de vet can
  localparam int I = 3;

  logic [W-1:0] a1, a2, b1, b2, y1, y2;
  logic [I-1:0] ai, bi, yi;
  int errors = 0;

  min2_merge #(.MAGW(W), .IDXW(I)) dut (
    .a_min1(a1), .a_min2(a2), .a_idx(ai),
    .b_min1(b1), .b_min2(b2), .b_idx(bi),
    .y_min1(y1), .y_min2(y2), .y_idx(yi));

  task automatic check(input int e1, input int e2, input int ei);
    if (y1 !== e1[W-1:0] || y2 !== e2[W-1:0] || yi !== ei[I-1:0]) begin
      $display("FAIL a=(%0d,%0d,%0d) b=(%0d,%0d,%0d) -> (%0d,%0d,%0d) exp (%0d,%0d,%0d)",
               a1,a2,ai,b1,b2,bi,y1,y2,yi,e1,e2,ei);
      errors++;
    end
  endtask

  int e1, e2, ei;
  int nvec = 0;

  initial begin
    // vet can a1,a2,b1,b2 (a2>=a1, b2>=b1 la bat bien cua cay)
    for (int va1 = 0; va1 < 2**W; va1++)
    for (int va2 = va1; va2 < 2**W; va2++)
    for (int vb1 = 0; vb1 < 2**W; vb1++)
    for (int vb2 = vb1; vb2 < 2**W; vb2++) begin
      a1 = va1[W-1:0]; a2 = va2[W-1:0]; ai = 3'd2;
      b1 = vb1[W-1:0]; b2 = vb2[W-1:0]; bi = 3'd5;
      #1;
      if (va1 <= vb1) begin
        e1 = va1; ei = 2;
        e2 = (vb1 <= va2) ? vb1 : va2;
      end else begin
        e1 = vb1; ei = 5;
        e2 = (va1 <= vb2) ? va1 : vb2;
      end
      check(e1, e2, ei);
      nvec++;
    end

    if (errors == 0) $display("[tb_min2_merge] PASS - vet can %0d vector", nvec);
    else             $display("[tb_min2_merge] FAIL - %0d loi", errors);
    $finish;
  end

endmodule
