`timescale 1ns/1ns

module tb_comp_tree();
    logic clk;
    logic [7:0] x[7];
    logic [7:0] y_1, y_2, y_3, y_4, y_5, y_6, y_7;
    logic [7:0] min_o, submin_o;
    logic [7:0] vtc_o[7];
    logic [3:0] rowWeight;

    comp_tree dut (
        .x_1(x[0]), .x_2(x[1]), .x_3(x[2]), .x_4(x[3]),
        .x_5(x[4]), .x_6(x[5]), .x_7(x[6]),
        .y_1(y_1), .y_2(y_2), .y_3(y_3), .y_4(y_4),
        .y_5(y_5), .y_6(y_6), .y_7(y_7),
        .min_o(min_o), .submin_o(submin_o),
        .vtc_o_1(vtc_o[0]), .vtc_o_2(vtc_o[1]), .vtc_o_3(vtc_o[2]),
        .vtc_o_4(vtc_o[3]), .vtc_o_5(vtc_o[4]), .vtc_o_6(vtc_o[5]),
        .vtc_o_7(vtc_o[6]),
        .rowWeight(rowWeight)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("tb_comp_tree.vcd");
        $dumpvars(0, tb_comp_tree);
    end

    initial begin
        $monitor("Time = %0t | x_1..7 = {%0d,%0d,%0d,%0d,%0d,%0d,%0d} | min_o = %0d | submin_o = %0d | rowWeight = %0d",
                 $time, x[0], x[1], x[2], x[3], x[4], x[5], x[6], min_o, submin_o, rowWeight);
    end

    initial begin
        // Case 1: Min đầu, Submin cuối
        x = '{8'd1, 8'd10, 8'd20, 8'd30, 8'd40, 8'd50, 8'd2}; #10;
        // Case 2: Min ở giữa
        x = '{8'd55, 8'd60, 8'd7, 8'd90, 8'd80, 8'd12, 8'd40}; #10;
        // Case 3: Nhiều giá trị bằng nhau
        x = '{8'd15, 8'd15, 8'd15, 8'd50, 8'd60, 8'd70, 8'd80}; #10;
        // Case 4: Dãy giảm dần
        x = '{8'd70, 8'd60, 8'd50, 8'd40, 8'd30, 8'd20, 8'd10}; #10;
        // Case 5: Có số âm
        x = '{8'hFF, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7}; #10;
        // Case 6: Tất cả bằng 0
        x = '{8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0}; #10;
        // Case 7: Dãy số ngẫu nhiên lớn
        x = '{8'h7F, 8'h7E, 8'h7D, 8'h7C, 8'h7B, 8'h7A, 8'h79}; #10;
        // Case 8: Min và Submin đứng liền nhau
        x = '{8'd100, 8'd100, 8'd10, 8'd11, 8'd99, 8'd88, 8'd77}; #10;

        $finish;
    end
endmodule