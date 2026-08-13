`timescale 1ns/1ns

module abs_calc (
	input logic [7:0] x_1,
	input logic [7:0] x_2,
	input logic [7:0] x_3,
	input logic [7:0] x_4,
	input logic [7:0] x_5,
	input logic [7:0] x_6,
	input logic [7:0] x_7,
	input logic [7:0] x_8,

	output logic [7:0] y_1,
	output logic [7:0] y_2,
	output logic [7:0] y_3,
	output logic [7:0] y_4,
	output logic [7:0] y_5,
	output logic [7:0] y_6,
	output logic [7:0] y_7,
	output logic [7:0] y_8,

	output logic [6:0] sign_o
);
	fa_calc dut_abs_calc1 (.A(8'b0), .B(x_1), .Sel(x_1[7]),.S(y_1), .Co(), .Ov());
	fa_calc dut_abs_calc2 (.A(8'b0), .B(x_2), .Sel(x_2[7]),.S(y_2), .Co(), .Ov());
	fa_calc dut_abs_calc3 (.A(8'b0), .B(x_3), .Sel(x_3[7]),.S(y_3), .Co(), .Ov());
	fa_calc dut_abs_calc4 (.A(8'b0), .B(x_4), .Sel(x_4[7]),.S(y_4), .Co(), .Ov());
	fa_calc dut_abs_calc5 (.A(8'b0), .B(x_5), .Sel(x_5[7]),.S(y_5), .Co(), .Ov());
	fa_calc dut_abs_calc6 (.A(8'b0), .B(x_6), .Sel(x_6[7]),.S(y_6), .Co(), .Ov());
	fa_calc dut_abs_calc7 (.A(8'b0), .B(x_7), .Sel(x_7[7]),.S(y_7), .Co(), .Ov());
	fa_calc dut_abs_calc8 (.A(8'b0), .B(x_8), .Sel(x_8[7]),.S(y_8), .Co(), .Ov());

	assign sign_o = {x_7[7], x_6[7], x_5[7], x_4[7], x_3[7], x_2[7], x_1[7]};
endmodule
