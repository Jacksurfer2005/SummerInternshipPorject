//============================================================================
//  app_calc.sv -- Phan "APP calculation" cua khoi "CTV and APP calculation"
//                 (Figure 1), cong thuc (7)
//      APP_new_n = VTC_n + CTV_new_n
//============================================================================
`timescale 1ns/1ps

import ldpc_pkg::*;

module app_calc
#(
  parameter int LANES = Z
)(
  input  logic [LANES*DW-1:0] vtc_i,
  input  logic [LANES*DW-1:0] ctv_i,
  output logic [LANES*DW-1:0] app_o
);
  always_comb begin
    for (int i = 0; i < LANES; i++)
      app_o[i*DW +: DW] = ldpc_pkg::sat_add($signed(vtc_i[i*DW +: DW]),
                                  $signed(ctv_i[i*DW +: DW]));
  end
endmodule
