//============================================================================
//  bram_app.sv -- "BRAM APP" (Figure 1)
//
//  Bo nho khoi 2 cong (dual-port) chua xac suat hau nghiem APP.
//  Bo nho duoc chia thanh K = N/z khoi, moi khoi rong z*DW bit
//  (muc III.A: "the block memory is divided into K = N/z blocks").
//    - Cong A : doc  (giai ma / xuat ket qua)
//    - Cong B : ghi  (nap du lieu kenh / ghi nguoc APP_new)
//============================================================================
`timescale 1ns/1ps

module bram_app #(
  parameter int DEPTH = 24,
  parameter int WIDTH = 144
)(
  input  logic                     clk,
  // cong A - doc
  input  logic                     a_en,
  input  logic [$clog2(DEPTH)-1:0] a_addr,
  output logic [WIDTH-1:0]         a_dout,
  // cong B - ghi
  input  logic                     b_we,
  input  logic [$clog2(DEPTH)-1:0] b_addr,
  input  logic [WIDTH-1:0]         b_din
);

  logic [WIDTH-1:0] mem [0:DEPTH-1];

  always_ff @(posedge clk) begin
    if (b_we) mem[b_addr] <= b_din;
  end

  always_ff @(posedge clk) begin
    if (a_en) a_dout <= mem[a_addr];
  end

endmodule
