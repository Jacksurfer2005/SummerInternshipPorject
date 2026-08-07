//============================================================================
//  barrel_shifter.sv -- Bo dich vong cho ma QC-LDPC
//
//  "The parallel multicore decoding architecture implies a prior shift of
//   values based on the LDPC matrix" (Abstract).
//
//  dir = 0 : xoay trai  -> dout[i] = din[(i+shift) mod LANES]
//            (can chinh khoi bien theo chi so nut kiem tra)
//  dir = 1 : xoay phai  -> phep nghich dao, dung khi ghi nguoc ve BRAM APP
//============================================================================
`timescale 1ns/1ps

module barrel_shifter #(
  parameter int LANES = 24,
  parameter int LW    = 6,
  parameter int SW    = 5
)(
  input  logic [LANES*LW-1:0] din,
  input  logic [SW-1:0]       shift,
  input  logic                dir,
  output logic [LANES*LW-1:0] dout
);
  int s;
  always_comb begin
    for (int i = 0; i < LANES; i++) begin
      if (dir == 1'b0) s = (i + int'(shift)) % LANES;
      else             s = (i - int'(shift) + LANES) % LANES;
      dout[i*LW +: LW] = din[s*LW +: LW];
    end
  end
endmodule
