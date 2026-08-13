`timescale 1ns/1ns

module ctv_app_calc (
    input  logic [7:0] vtc_1,
    input  logic [7:0] vtc_2,
    input  logic [7:0] vtc_3,
    input  logic [7:0] vtc_4,
    input  logic [7:0] vtc_5,
    input  logic [7:0] vtc_6,
    input  logic [7:0] vtc_7,

    input  logic [7:0] ctv_1,
    input  logic [7:0] ctv_2,
    input  logic [7:0] ctv_3,
    input  logic [7:0] ctv_4,
    input  logic [7:0] ctv_5,
    input  logic [7:0] ctv_6,
    input  logic [7:0] ctv_7,

    output logic [7:0] app_1,
    output logic [7:0] app_2,
    output logic [7:0] app_3,
    output logic [7:0] app_4,
    output logic [7:0] app_5,
    output logic [7:0] app_6,
    output logic [7:0] app_7
);

    fa_calc app_calc1 (.A(vtc_1), .B(ctv_1), .Sel(1'b0), .S(app_1), .Co(), .Ov());
    fa_calc app_calc2 (.A(vtc_2), .B(ctv_2), .Sel(1'b0), .S(app_2), .Co(), .Ov());
    fa_calc app_calc3 (.A(vtc_3), .B(ctv_3), .Sel(1'b0), .S(app_3), .Co(), .Ov());
    fa_calc app_calc4 (.A(vtc_4), .B(ctv_4), .Sel(1'b0), .S(app_4), .Co(), .Ov());
    fa_calc app_calc5 (.A(vtc_5), .B(ctv_5), .Sel(1'b0), .S(app_5), .Co(), .Ov());
    fa_calc app_calc6 (.A(vtc_6), .B(ctv_6), .Sel(1'b0), .S(app_6), .Co(), .Ov());
    fa_calc app_calc7 (.A(vtc_7), .B(ctv_7), .Sel(1'b0), .S(app_7), .Co(), .Ov());

endmodule
