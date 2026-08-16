`timescale 1ns/1ns

module tb_comp_min();
    logic clk;
    logic [7:0] A, B, min_o;

    comp_min dut (.A(A), .B(B), .min_o(min_o));

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("tb_comp_min.vcd");
        $dumpvars(0, tb_comp_min);
    end

    initial begin
        $monitor("Time = %0t | A = %h (%0d) | B = %h (%0d) | min_o = %h (%0d)",
                 $time, A, A, B, B, min_o, min_o);
    end

    initial begin
        // Case 1: A > B
        A = 8'd50; B = 8'd20; #10;
        // Case 2: A < B
        A = 8'd10; B = 8'd90; #10;
        // Case 3: A = B
        A = 8'd45; B = 8'd45; #10;
        // Case 4: A dương, B âm
        A = 8'd5;  B = 8'hFF; #10;
        // Case 5: Cả 2 đều âm
        A = 8'h80; B = 8'hFF; #10;
        // Case 6: Cả 2 bằng 0
        A = 8'd0;  B = 8'd0;  #10;
        // Case 7: A Max, B bình thường
        A = 8'h7F; B = 8'd12; #10;
        // Case 8: B Max, A bình thường
        A = 8'd33; B = 8'h7F; #10;

        $finish;
    end
endmodule