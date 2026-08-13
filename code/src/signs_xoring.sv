`timescale 1ns/1ns

module signs_xoring (
    input  logic [6:0] sign_i,
    output logic       sign_o
);

    logic temp1, temp2, temp3, temp4, temp5;
    logic co1, co2, co3, co4, co5, co6;

    fa fa_sign1(.a(sign_i[0]), .b(sign_i[1]), .ci(1'b0), .s(temp1), .co(co1));
    fa fa_sign2(.a(temp1),     .b(sign_i[2]), .ci(1'b0), .s(temp2), .co(co2));
    fa fa_sign3(.a(temp2),     .b(sign_i[3]), .ci(1'b0), .s(temp3), .co(co3));
    fa fa_sign4(.a(temp3),     .b(sign_i[4]), .ci(1'b0), .s(temp4), .co(co4));
    fa fa_sign5(.a(temp4),     .b(sign_i[5]), .ci(1'b0), .s(temp5), .co(co5));
    fa fa_sign6(.a(temp5),     .b(sign_i[6]), .ci(1'b0), .s(sign_o),.co(co6));

endmodule
