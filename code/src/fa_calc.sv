`timescale 1ns/1ns

module fa_calc (
    input  logic [7:0] A,
    input  logic [7:0] B,
    input  logic       Sel,
    output logic [7:0] S,
    output logic       Co,
    output logic       Ov
);
    logic [7:0] temp;
    fa fa0 (.a(A[0]),.b(B[0] ^ Sel),.ci(Sel)    ,.s(S[0]),.co(temp[0]));
    fa fa1 (.a(A[1]),.b(B[1] ^ Sel),.ci(temp[0]),.s(S[1]),.co(temp[1]));
    fa fa2 (.a(A[2]),.b(B[2] ^ Sel),.ci(temp[1]),.s(S[2]),.co(temp[2]));
    fa fa3 (.a(A[3]),.b(B[3] ^ Sel),.ci(temp[2]),.s(S[3]),.co(temp[3]));
    fa fa4 (.a(A[4]),.b(B[4] ^ Sel),.ci(temp[3]),.s(S[4]),.co(temp[4]));
    fa fa5 (.a(A[5]),.b(B[5] ^ Sel),.ci(temp[4]),.s(S[5]),.co(temp[5]));
    fa fa6 (.a(A[6]),.b(B[6] ^ Sel),.ci(temp[5]),.s(S[6]),.co(temp[6]));
    fa fa7 (.a(A[7]),.b(B[7] ^ Sel),.ci(temp[6]),.s(S[7]),.co(temp[7]));
    assign Co = temp[7];          // Carry out 
    assign Ov = temp[7] ^ temp[6];      // Overflow 
endmodule
