`timescale 1ns/1ns

module sign_insertion (
    input  logic [7:0] x_1,
    input  logic [7:0] x_2,
    input  logic [7:0] x_3,
    input  logic [7:0] x_4,
    input  logic [7:0] x_5,
    input  logic [7:0] x_6,
    input  logic [7:0] x_7,

    input  logic [6:0] sign_i,
    input  logic       sign_total,

    output logic [7:0] y_1,
    output logic [7:0] y_2,
    output logic [7:0] y_3,
    output logic [7:0] y_4,
    output logic [7:0] y_5,
    output logic [7:0] y_6,
    output logic [7:0] y_7
);

    logic s1, s2, s3, s4, s5, s6, s7;
    logic co1, co2, co3, co4, co5, co6, co7;

    // Sign của từng CTV
    assign s1 = sign_total ^ sign_i[0];
    assign s2 = sign_total ^ sign_i[1];
    assign s3 = sign_total ^ sign_i[2];
    assign s4 = sign_total ^ sign_i[3];
    assign s5 = sign_total ^ sign_i[4];
    assign s6 = sign_total ^ sign_i[5];
    assign s7 = sign_total ^ sign_i[6];

    // Chuyển magnitude thành signed CTV
    fa_calc y_calc1(.A(8'b0),.B(x_1),.Sel(s1),.S(y_1),.Co(co1),.Ov());
    fa_calc y_calc2(.A(8'b0),.B(x_2),.Sel(s2),.S(y_2),.Co(co2),.Ov());
    fa_calc y_calc3(.A(8'b0),.B(x_3),.Sel(s3),.S(y_3),.Co(co3),.Ov());
    fa_calc y_calc4(.A(8'b0),.B(x_4),.Sel(s4),.S(y_4),.Co(co4),.Ov());
    fa_calc y_calc5(.A(8'b0),.B(x_5),.Sel(s5),.S(y_5),.Co(co5),.Ov());
    fa_calc y_calc6(.A(8'b0),.B(x_6),.Sel(s6),.S(y_6),.Co(co6),.Ov());
    fa_calc y_calc7(.A(8'b0),.B(x_7),.Sel(s7),.S(y_7),.Co(co7),.Ov());

endmodule
