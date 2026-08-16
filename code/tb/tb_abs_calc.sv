`timescale 1ns/1ns

module tb_abs_calc();
    logic clk;
    logic [7:0] x[8];
    logic [7:0] y_1, y_2, y_3, y_4, y_5, y_6, y_7, y_8;
    logic [6:0] sign_o;

    abs_calc dut (
        .x_1(x[0]), .x_2(x[1]), .x_3(x[2]), .x_4(x[3]),
        .x_5(x[4]), .x_6(x[5]), .x_7(x[6]), .x_8(x[7]),
        .y_1(y_1), .y_2(y_2), .y_3(y_3), .y_4(y_4),
        .y_5(y_5), .y_6(y_6), .y_7(y_7), .y_8(y_8),
        .sign_o(sign_o)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("tb_abs_calc.vcd");
        $dumpvars(0, tb_abs_calc);
    end

    initial begin
        $monitor("Time = %0t | x_1..8 = {%h,%h,%h,%h,%h,%h,%h,%h} | y_1..8 = {%h,%h,%h,%h,%h,%h,%h,%h} | sign_o = %b",
                 $time, x[0], x[1], x[2], x[3], x[4], x[5], x[6], x[7],
                 y_1, y_2, y_3, y_4, y_5, y_6, y_7, y_8, sign_o);
    end

    initial begin
        // Case 1: Tất cả đều là số dương
        x = '{8'd10, 8'd20, 8'd30, 8'd40, 8'd50, 8'd60, 8'd70, 8'd80}; #10;
        // Case 2: Tất cả đều là số âm (-1 đến -8)
        x = '{8'hFF, 8'hFE, 8'hFD, 8'hFC, 8'hFB, 8'hFA, 8'hF9, 8'hF8}; #10;
        // Case 3: Xen kẽ âm/dương
        x = '{8'd1, 8'hFF, 8'd2, 8'hFE, 8'd3, 8'hFD, 8'd4, 8'hFC}; #10;
        // Case 4: Tất cả bằng 0
        x = '{8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0}; #10;
        // Case 5: Giá trị âm biên (-128)
        x = '{8'h80, 8'h80, 8'h80, 8'h80, 8'h80, 8'h80, 8'h80, 8'h80}; #10;
        // Case 6: Giá trị dương lớn nhất (127)
        x = '{8'h7F, 8'h7F, 8'h7F, 8'h7F, 8'h7F, 8'h7F, 8'h7F, 8'h7F}; #10;
        // Case 7: Ngẫu nhiên 1
        x = '{8'd15, 8'hE1, 8'd55, 8'hC4, 8'd99, 8'hA1, 8'd12, 8'h11}; #10;
        // Case 8: Ngẫu nhiên 2
        x = '{8'hAA, 8'h55, 8'hAA, 8'h55, 8'hAA, 8'h55, 8'hAA, 8'h55}; #10;

        $finish;
    end
endmodule