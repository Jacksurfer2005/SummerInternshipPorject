`timescale 1ns/1ns

module tb_fa();
    logic clk;
    logic a, b, ci, s, co;

    fa dut (
        .a(a), .b(b), .ci(ci),
        .s(s), .co(co)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("tb_fa.vcd");
        $dumpvars(0, tb_fa);
    end

    initial begin
        $monitor("Time = %0t | a = %b | b = %b | ci = %b | s = %b | co = %b",
                 $time, a, b, ci, s, co);
    end

    initial begin
        a = 0; b = 0; ci = 0; #10; // Case 1
        a = 0; b = 0; ci = 1; #10; // Case 2
        a = 0; b = 1; ci = 0; #10; // Case 3
        a = 0; b = 1; ci = 1; #10; // Case 4
        a = 1; b = 0; ci = 0; #10; // Case 5
        a = 1; b = 0; ci = 1; #10; // Case 6
        a = 1; b = 1; ci = 0; #10; // Case 7
        a = 1; b = 1; ci = 1; #10; // Case 8

        $finish;
    end
endmodule