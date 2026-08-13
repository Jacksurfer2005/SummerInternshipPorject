//============================================================================
//  h_rom.sv -- "Memory for check matrix" (Figure 1), muc III.B
//
//  Cach luu tru theo bai bao: chi luu ma tran co so Hb, va nen no thanh
//  ba vector (bo nho phan tan / distributed memory):
//      vals        - cac phan tu khac -1 (luong dich vong, da chia ti le z)
//      pos         - chi so cot khoi cua tung phan tu trong vals
//      elementSize - so phan tu khac -1 cua tung hang (row weight d_r)
//
//  ROM doc file .mem chua Hb (1 byte / phan tu, 0xFF = -1) va tu tinh
//  ba vector tren khi khoi tao => thay ma tran chi can thay file .mem.
//  Luong dich duoc chia ti le theo chuan: p(f,i,j) = floor(p(i,j)*z/z0).
//============================================================================
`timescale 1ns/1ns

import ldpc_pkg::*;

module h_rom
#(
  parameter INIT_FILE = "h_base.mem"
)(
  input  logic [MB_W-1:0]  layer,       // hang khoi hien tai
  input  logic [DRW-1:0]   idx,         // chi so canh trong hang (0..d_r-1)
  output logic [DRW-1:0]   row_weight,  // elementSize[layer]
  output logic [NB_W-1:0]  col_pos,     // pos[layer][idx]
  output logic [Z_W-1:0]   shift,       // vals[layer][idx]
  output logic             edge_valid   // idx < row_weight
);

  // Ma tran co so tho
  logic [7:0]      hb  [0:MB*NB-1];
  // Ba vector nen
  logic [DRW-1:0]  esz [0:MB-1];
  logic [NB_W-1:0] pos [0:MB*DR_MAX-1];
  logic [Z_W-1:0]  val [0:MB*DR_MAX-1];

  integer r, c, k, tmp;

  initial begin
    for (k = 0; k < MB*NB; k++)      hb[k]  = HB_NEG;
    for (k = 0; k < MB*DR_MAX; k++) begin pos[k] = '0; val[k] = '0; end

    $readmemh(INIT_FILE, hb);

    for (r = 0; r < MB; r++) begin
      k = 0;
      for (c = 0; c < NB; c++) begin
        if (hb[r*NB + c] !== HB_NEG) begin
          if (k >= DR_MAX) begin
            $display("h_rom: LOI - trong so hang %0d vuot qua DR_MAX=%0d", r, DR_MAX);
            $finish;
          end
          tmp                = hb[r*NB + c];
          pos[r*DR_MAX + k]  = c[NB_W-1:0];
          val[r*DR_MAX + k]  = ((tmp * Z) / Z0);   // p(f,i,j)
          k = k + 1;
        end
      end
      esz[r] = k[DRW-1:0];
    end
  end

  // Doc to hop (distributed RAM/ROM)
  assign row_weight = esz[layer];
  assign col_pos    = pos[layer*DR_MAX + idx];
  assign shift      = val[layer*DR_MAX + idx];
  assign edge_valid = (idx < esz[layer]);

endmodule
