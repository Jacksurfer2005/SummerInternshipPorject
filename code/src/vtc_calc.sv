//============================================================================
//  vtc_calc.sv -- Khoi "VTC calculation" (Figure 1), cong thuc (5)
//      VTC_n = APP_n - CTV_n        (thuc hien song song cho z lane)
//============================================================================
`timescale 1ns/1ns

module vtc_calc #(
  parameter int DW = 6,
  parameter int Z = 24
)(
  input  logic signed [Z-1:0][DW-1:0] app_i, 
  input  logic signed [Z-1:0][DW-1:0] ctv_i,
  output logic signed [Z-1:0][DW-1:0] vtc_o
);

  parameter logic signed [DW-1:0] MAX = 8'h7F;
  parameter logic signed [DW-1:0] MIN = 8'h80;

  always_comb begin
    for (int i = 0; i < Z; i++) begin
      automatic int diff = app_i[i] - ctv_i[i];
      if (diff > 8'h7F)
        vtc_o[i] = MAX;
      else if (diff < 8'h80)
        vtc_o[i] = MIN;
      else
        vtc_o[i] = diff[DW-1:0];
    end
  end
endmodule
