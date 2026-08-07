`timescale 1ns / 1ns

module tb_ctv_app_calc;

    // Parameters
    parameter W = 8;
    parameter DEG = 8;

    // Inputs
    logic [3:0]          row_weight;
    logic [W-2:0]        min1;
    logic [W-2:0]        min2;
    logic [2:0]          min1_idx;
    logic                signs_xor;
    logic                vtc_signs [0:DEG-1];
    logic signed [W-1:0] vtc_in    [0:DEG-1];

    // Outputs
    logic signed [W-1:0] ctv_new   [0:DEG-1];
    logic signed [W-1:0] app_new   [0:DEG-1];

    // Instantiate the Unit Under Test (UUT)
    ctv_app_calc #(
        .W(W),
        .DEG(DEG)
    ) dut (
        .row_weight(row_weight),
        .min1(min1),
        .min2(min2),
        .min1_idx(min1_idx),
        .signs_xor(signs_xor),
        .vtc_signs(vtc_signs),
        .vtc_in(vtc_in),
        .ctv_new(ctv_new),
        .app_new(app_new)
    );

    // Test procedure
    initial begin
        $dumpfile("tb_ctv_app_calc.vcd");
        $dumpvars(0, tb_ctv_app_calc);

        $display("=== BẮT ĐẦU TESTBENCH CTV APP CALC ===");

        // ---------------------------------------------------------
        // CASE 1: Test chức năng cơ bản (Không tràn số)
        // ---------------------------------------------------------
        row_weight = 8; 
        min1 = 7'd5;
        min2 = 7'd12;
        min1_idx = 3'd2; // Nhánh 2 sẽ nhận min2, các nhánh khác nhận min1
        signs_xor = 1'b1;
        vtc_signs = '{1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0};
        vtc_in    = '{8'd10, -8'd15, 8'd20, -8'd5, 8'd8, 8'd8, 8'd8, 8'd8};
        
        #10;
        $display("\n[TEST 1] Hoạt động bình thường:");
        $display("CTV[2] (nhận min2): %d", ctv_new[2]);
        $display("CTV[0] (nhận min1): %d", ctv_new[0]);
        $display("APP[0] (vtc_in[0] + CTV[0]): %d", app_new[0]);

        // ---------------------------------------------------------
        // CASE 2: Test tràn số trên (Overflow Saturation)
        // Max value của 8-bit signed là 127
        // ---------------------------------------------------------
        min1 = 7'd10; 
        signs_xor = 1'b0;
        vtc_signs[0] = 1'b0;  // Dấu dương
        vtc_in[0] = 8'd125;   // 125 + 10 = 135 -> Tràn số, kỳ vọng bão hòa ở 127
        
        #10;
        $display("\n[TEST 2] Overflow Saturation:");
        $display("Input: %d, CTV: %d", vtc_in[0], ctv_new[0]);
        $display("APP Expected: 127 | APP Actual: %d", app_new[0]);

        // ---------------------------------------------------------
        // CASE 3: Test tràn số dưới (Underflow Saturation)
        // Min value của 8-bit signed là -128
        // ---------------------------------------------------------
        min1 = 7'd20;
        signs_xor = 1'b1;
        vtc_signs[1] = 1'b0;  // Dấu âm (vì xor = 1)
        vtc_in[1] = -8'd120;  // -120 + (-20) = -140 -> Tràn số, kỳ vọng bão hòa ở -128
        
        #10;
        $display("\n[TEST 3] Underflow Saturation:");
        $display("Input: %d, CTV: %d", vtc_in[1], ctv_new[1]);
        $display("APP Expected: -128 | APP Actual: %d", app_new[1]);

        // ---------------------------------------------------------
        // CASE 4: Test ngắt Row Weight (row_weight < DEG)
        // ---------------------------------------------------------
        row_weight = 4;       // Chỉ tính toán từ nhánh 0 đến 3
        vtc_in[5] = 8'd45;    // Nhánh 5 nằm ngoài vùng tính toán
        
        #10;
        $display("\n[TEST 4] Test Row Weight (Masking):");
        $display("Với i = 5 (>= row_weight=4):");
        $display("CTV[5] Expected: 0 | Actual: %d", ctv_new[5]);
        $display("APP[5] Expected: 45 | Actual: %d", app_new[5]);

        row_weight = 4'd8;
        min1       = 7'd3;   // Min1 độ lớn = 3
        min2       = 7'd8;   // Min2 độ lớn = 8
        min1_idx   = 3'd1;   // Min1 nằm ở vị trí index 1
        signs_xor  = 1'b1;   // Tổng tích dấu = Âm (1)

        vtc_signs  = '{ 1'b0,  1'b1,  1'b0,  1'b1,  1'b0,  1'b1,  1'b0,  1'b1 };
        vtc_in     = '{ 8'd15, -8'd3,  8'd45, -8'd8,  8'd22, -8'd12, 8'd50, -8'd18 };
        
        #10;
        $display("\n[TEST 4] Test Row Weight (Masking):");
        $display("Với i = 5 (>= row_weight=4):");
        $display("CTV[5] Expected: 0 | Actual: %d", ctv_new[5]);
        $display("APP[5] Expected: 45 | Actual: %d", app_new[5]);

        #10;
        $display("\n=== HOÀN THÀNH MÔ PHỎNG ===");
        $finish;
    end
endmodule