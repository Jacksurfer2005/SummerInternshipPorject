`timescale 1ns/1ns

module tb_fa_calc();
    logic clk;
    logic [7:0] A, B, S;
    logic Sel, Co, Ov;

    fa_calc dut (
        .A(A), .B(B), .Sel(Sel),
        .S(S), .Co(Co), .Ov(Ov)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("tb_fa_calc.vcd");
        $dumpvars(0, tb_fa_calc);
    end

    initial begin
        $monitor("Time = %0t | Sel = %b | A = %h (%0d) | B = %h (%0d) | S = %h (%0d) | Co = %b | Ov = %b",
                 $time, Sel, A, A, B, B, S, S, Co, Ov);
    end

    initial begin
        // Case 1: Cộng hai số dương (10 + 5)
        A = 8'd10; B = 8'd5; Sel = 0; #10; 
        // Case 2: Trừ hai số dương (10 - 5)
        A = 8'd10; B = 8'd5; Sel = 1; #10; 
        // Case 3: Trừ sinh ra số âm (5 - 10)
        A = 8'd5;  B = 8'd10; Sel = 1; #10; 
        // Case 4: Tràn số có dấu (127 + 1 -> Overflow)
        A = 8'd127; B = 8'd1; Sel = 0; #10; 
        // Case 5: Cộng hai số 0
        A = 8'd0; B = 8'd0; Sel = 0; #10; 
        // Case 6: Tràn số không dấu (255 + 1 -> Carry out)
        A = 8'd255; B = 8'd1; Sel = 0; #10; 
        // Case 7: Trừ hai số bằng nhau (50 - 50 = 0)
        A = 8'd50; B = 8'd50; Sel = 1; #10; 
        // Case 8: Trừ với số âm (0 - (-1))
        A = 8'd0; B = 8'hFF; Sel = 1; #10; 

        $finish;
    end
endmodule