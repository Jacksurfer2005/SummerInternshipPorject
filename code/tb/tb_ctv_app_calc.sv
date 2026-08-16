`timescale 1ns/1ns

module tb_ctv_app_calc();
    logic clk;
    logic [7:0] vtc[7];
    logic [7:0] ctv[7];
    logic [7:0] app_1, app_2, app_3, app_4, app_5, app_6, app_7;

    ctv_app_calc dut (
        .vtc_1(vtc[0]), .vtc_2(vtc[1]), .vtc_3(vtc[2]), .vtc_4(vtc[3]),
        .vtc_5(vtc[4]), .vtc_6(vtc[5]), .vtc_7(vtc[6]),
        .ctv_1(ctv[0]), .ctv_2(ctv[1]), .ctv_3(ctv[2]), .ctv_4(ctv[3]),
        .ctv_5(ctv[4]), .ctv_6(ctv[5]), .ctv_7(ctv[6]),
        .app_1(app_1), .app_2(app_2), .app_3(app_3), .app_4(app_4),
        .app_5(app_5), .app_6(app_6), .app_7(app_7)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("tb_ctv_app_calc.vcd");
        $dumpvars(0, tb_ctv_app_calc);
    end

    initial begin
        $monitor("Time = %0t | vtc1 = %h | ctv1 = %h | app1 = %h | app2 = %h | app3 = %h | app4 = %h",
                 $time, vtc[0], ctv[0], app_1, app_2, app_3, app_4);
    end

    initial begin
        // Case 1: Cộng số dương
        vtc = '{8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7};
        ctv = '{8'd10, 8'd10, 8'd10, 8'd10, 8'd10, 8'd10, 8'd10}; #10;
        // Case 2: vtc = 0
        vtc = '{8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0};
        ctv = '{8'd5, 8'd15, 8'd25, 8'd35, 8'd45, 8'd55, 8'd65}; #10;
        // Case 3: ctv = 0
        vtc = '{8'd8, 8'd18, 8'd28, 8'd38, 8'd48, 8'd58, 8'd68};
        ctv = '{8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0}; #10;
        // Case 4: Tràn số có dấu
        vtc = '{8'd120, 8'd121, 8'd122, 8'd123, 8'd124, 8'd125, 8'd126};
        ctv = '{8'd10, 8'd10, 8'd10, 8'd10, 8'd10, 8'd10, 8'd10}; #10;
        // Case 5: Cộng với số âm
        vtc = '{8'd50, 8'd50, 8'd50, 8'd50, 8'd50, 8'd50, 8'd50};
        ctv = '{8'hFF, 8'hFE, 8'hFD, 8'hFC, 8'hFB, 8'hFA, 8'hF9}; #10;
        // Case 6: Tràn số không dấu
        vtc = '{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF};
        ctv = '{8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7}; #10;
        // Case 7: Cả hai âm
        vtc = '{8'hFE, 8'hFE, 8'hFE, 8'hFE, 8'hFE, 8'hFE, 8'hFE};
        ctv = '{8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF}; #10;
        // Case 8: Ngẫu nhiên
        vtc = '{8'd23, 8'd45, 8'hE1, 8'd0, 8'd99, 8'h80, 8'h7F};
        ctv = '{8'h12, 8'd11, 8'h05, 8'd88, 8'd1, 8'hFF, 8'h01}; #10;

        $finish;
    end
endmodule