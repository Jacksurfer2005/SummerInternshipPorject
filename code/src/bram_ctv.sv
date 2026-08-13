//============================================================================
//  bram_ctv.sv -- "BRAM CTV" (Figure 1)
//
//  Luu ban tin check-to-variable cho toan bo canh cua ma tran:
//     do sau = MB * DR_MAX  (so hang khoi x trong so hang toi da)
//     do rong = z * DW      (z lane song song, moi lane DW bit)
//  Tuong duong "z memory instances of size
//   (rowWeight x inputDataSize x numberOfRow)" trong muc III.B.
//============================================================================
`timescale 1ns/1ns

module bram_ctv #(
  parameter int DEPTH = 96,
  parameter int WIDTH = 144
)(
  input  logic                     clk,
  input  logic                     rd_en,
  input  logic [DEPTH-1:0]         rd_addr,
  output logic [WIDTH-1:0]         rd_data,
  input  logic                     wr_en,
  input  logic [DEPTH-1:0]         wr_addr,
  input  logic [WIDTH-1:0]         wr_data
);

  logic [WIDTH-1:0] mem [0:DEPTH-1];

  always_ff @(posedge clk) begin
    if (wr_en) mem[wr_addr] <= wr_data;
    if (rd_en) rd_data      <= mem[rd_addr];
  end

endmodule
