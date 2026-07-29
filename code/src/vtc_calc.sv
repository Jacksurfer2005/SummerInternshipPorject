`timescale 1ns / 1ns

module vtc_calc #(
    parameter W = 8
)(
    input  logic signed [W-1:0] app_in,
    input  logic signed [W-1:0] ctv_in,
    output logic signed [W-1:0] vtc_out
);

    assign vtc_out = app_in - ctv_in;

endmodule 