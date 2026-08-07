`timescale 1ns / 1ns

module tb_min_submin_calc();

    // 1. Khai báo các tham số tương ứng với DUT
    parameter W = 8;
    localparam M = 8; // Số lượng phần tử tối đa (Max row weight)

    // 2. Khai báo các tín hiệu kết nối
    logic [3:0]         row_weight;
    logic signed [W-1:0] vtc_in [0:M-1];
    
    logic [W-2:0]       min1;
    logic [W-2:0]       min2;
    logic [2:0]         min1_idx;
    logic               signs_xor;
    logic               vtc_signs [0:M-1];

    // 3. Khởi tạo (Instantiate) Module DUT
    min_submin_calc #(
        .W(W)
    ) dut (
        .row_weight(row_weight),
        .vtc_in(vtc_in),
        .min1(min1),
        .min2(min2),
        .min1_idx(min1_idx),
        .signs_xor(signs_xor),
        .vtc_signs(vtc_signs)
    );

    // Biến phụ để hiển thị trạng thái Pass/Fail
    int test_pass = 0;
    int test_fail = 0;

    // 4. Khối tạo kích thích (Stimulus)
    initial begin
        $dumpfile("tb_min_submin_calc.vcd");
        $dumpvars(0, tb_min_submin_calc);

        $display("===============================================================");
        $display("   BAT DAU MO PHONG KHOI MIN/SUBMIN (TOURNAMENT TREE) ");
        $display("===============================================================");

        // ---------------------------------------------------------
        // TEST CASE 1: Mảng đầy đủ (row_weight = 8)
        // Đầu vào:  15, -10, 22, 5, -3, 30, 18, -12
        // Trị tuyệt đối: 15, 10, 22, 5, 3, 30, 18, 12
        // Kì vọng: min1 = 3 (index 4), min2 = 5
        // Dấu: 0, 1, 0, 0, 1, 0, 0, 1 -> XOR = 1
        // ---------------------------------------------------------
        $display("\n--- TEST CASE 1: Full Array (row_weight = 8) ---");
        row_weight = 4'd8;
        vtc_in[0] =  8'sd15; 
        vtc_in[1] = -8'sd10; 
        vtc_in[2] =  8'sd22; 
        vtc_in[3] =  8'sd5;  
        vtc_in[4] = -8'sd3;  // MIN
        vtc_in[5] =  8'sd30; 
        vtc_in[6] =  8'sd18; 
        vtc_in[7] = -8'sd12; 
        //or can be write like this vtc_in = '{ 8'd15, -8'd3, 8'd45, -8'd8, 8'd22, -8'd1, 8'd50, -8'd12 };
        #10; 
        $display("Ket qua: Min1 = %0d, Min2 = %0d, Index = %0d, Signs_XOR = %b", min1, min2, min1_idx, signs_xor);
        if (min1 == 3 && min2 == 5 && min1_idx == 4 && signs_xor == 1'b1) begin
            $display("-> [PASS] Test Case 1"); test_pass++;
        end else begin
            $display("-> [FAIL] Test Case 1"); test_fail++;
        end

        // ---------------------------------------------------------
        // TEST CASE 2: Mảng bị cắt ngắn (row_weight = 4)
        // Chỉ lấy 4 phần tử đầu: 15, -10, 22, 5
        // Trị tuyệt đối: 15, 10, 22, 5 (các phần tử sau bị ép thành MAX)
        // Kì vọng: min1 = 5 (index 3), min2 = 10
        // Dấu (4 node đầu): 0, 1, 0, 0 -> XOR = 1
        // ---------------------------------------------------------
        $display("\n--- TEST CASE 2: Partial Array (row_weight = 4) ---");
        row_weight = 4'd4; 
        // Giữ nguyên dữ liệu của Test Case 1 ở vtc_in
        
        #10; 
        $display("Ket qua: Min1 = %0d, Min2 = %0d, Index = %0d, Signs_XOR = %b", min1, min2, min1_idx, signs_xor);
        if (min1 == 5 && min2 == 10 && min1_idx == 3 && signs_xor == 1'b1) begin
            $display("-> [PASS] Test Case 2"); test_pass++;
        end else begin
            $display("-> [FAIL] Test Case 2"); test_fail++;
        end

        // ---------------------------------------------------------
        // TEST CASE 3: Trùng lặp giá trị MIN (Duplicate Minimums)
        // Đầu vào:  -7, -2, 8, 2, 10, 11, 12, 13
        // Trị tuyệt đối: 7, 2, 8, 2, 10, 11, 12, 13
        // Kì vọng: min1 = 2 (index 1), min2 = 2
        // Dấu: 1, 1, 0, 0, 0, 0, 0, 0 -> XOR = 0
        // ---------------------------------------------------------
        $display("\n--- TEST CASE 3: Duplicates (row_weight = 8) ---");
        row_weight = 4'd8;
        vtc_in[0] = -8'sd7;  
        vtc_in[1] = -8'sd2;  // MIN 1
        vtc_in[2] =  8'sd8; 
        vtc_in[3] =  8'sd2;  // MIN 2 (Submin)
        vtc_in[4] =  8'sd10; 
        vtc_in[5] =  8'sd11; 
        vtc_in[6] =  8'sd12; 
        vtc_in[7] =  8'sd13; 
        
        #10; 
        $display("Ket qua: Min1 = %0d, Min2 = %0d, Index = %0d, Signs_XOR = %b", min1, min2, min1_idx, signs_xor);
        if (min1 == 2 && min2 == 2 && min1_idx == 1 && signs_xor == 1'b0) begin
            $display("-> [PASS] Test Case 3"); test_pass++;
        end else begin
            $display("-> [FAIL] Test Case 3"); test_fail++;
        end

        // ---------------------------------------------------------
        // TEST CASE 4: Kiểm tra giới hạn bù 2 (Saturation Test)
        // Đầu vào chứa MIN_VAL = -128 (8'b10000000). 
        // DUT phải ép thành -127 để lấy trị tuyệt đối là 127, tránh lỗi logic.
        // Đầu vào: -128, 55, 66, 77, 88, 99, 100, 101
        // Trị tuyệt đối dự kiến: 127, 55, 66, 77, 88, 99, 100, 101
        // Kì vọng: min1 = 55 (index 1), min2 = 66
        // ---------------------------------------------------------
        $display("\n--- TEST CASE 4: Saturation Test (row_weight = 8) ---");
        row_weight = 4'd8;
        vtc_in[0] = -8'sd128; // Giá trị âm nhỏ nhất
        vtc_in[1] =  8'sd55;  // MIN 1
        vtc_in[2] =  8'sd66;  // MIN 2
        vtc_in[3] =  8'sd77; 
        vtc_in[4] =  8'sd88; 
        vtc_in[5] =  8'sd99; 
        vtc_in[6] =  8'sd100; 
        vtc_in[7] =  8'sd101; 
        
        #10; 
        $display("Ket qua: Min1 = %0d, Min2 = %0d, Index = %0d", min1, min2, min1_idx);
        if (min1 == 55 && min2 == 66 && min1_idx == 1) begin
            $display("-> [PASS] Test Case 4"); test_pass++;
        end else begin
            $display("-> [FAIL] Test Case 4"); test_fail++;
        end

        // ---------------------------------------------------------
        // TEST CASE 5: Tất cả các giá trị đều bằng nhau (Identical Values)
        // Mục đích: Kiểm tra xem mạch có bị loạn index khi tất cả đều là Min không.
        // Đầu vào: 15, -15, 15, -15, 15, -15, 15, -15
        // Trị tuyệt đối: Toàn bộ là 15.
        // Kì vọng: min1 = 15 (index 0), min2 = 15.
        // Dấu: 0, 1, 0, 1, 0, 1, 0, 1 -> XOR = 0
        // ---------------------------------------------------------
        $display("\n--- TEST CASE 5: All Identical Values ---");
        row_weight = 4'd8;
        for (int i = 0; i < M; i++) begin
            vtc_in[i] = (i % 2 == 0) ? 8'sd15 : -8'sd15;
        end
        
        #10; 
        $display("Ket qua: Min1 = %0d, Min2 = %0d, Index = %0d, Signs_XOR = %b", min1, min2, min1_idx, signs_xor);
        if (min1 == 15 && min2 == 15 && min1_idx == 0 && signs_xor == 1'b0) begin
            $display("-> [PASS] Test Case 5"); test_pass++;
        end else begin
            $display("-> [FAIL] Test Case 5"); test_fail++;
        end

        // ---------------------------------------------------------
        // TEST CASE 6: Min và Submin nằm cùng 1 cặp đấu đầu tiên (Same Bracket)
        // Mục đích: Ép Submin phải là kẻ thua cuộc ngay từ Tầng 1 (los1).
        // Đầu vào: 50, 60, 70, 80, 90, 100, -2, 5
        // Trị tuyệt đối: 50, 60, 70, 80, 90, 100, 2, 5
        // Kì vọng: min1 = 2 (index 6), min2 = 5 (index 7).
        // ---------------------------------------------------------
        $display("\n--- TEST CASE 6: Min & Submin in Same T1 Bracket ---");
        row_weight = 4'd8;
        vtc_in[0] = 8'sd50; vtc_in[1] = 8'sd60;
        vtc_in[2] = 8'sd70; vtc_in[3] = 8'sd80;
        vtc_in[4] = 8'sd90; vtc_in[5] = 8'sd100;
        vtc_in[6] = -8'sd2; // MIN1
        vtc_in[7] = 8'sd5;  // MIN2 (Thua ngay từ vòng gửi xe)
        
        #10; 
        $display("Ket qua: Min1 = %0d, Min2 = %0d, Index = %0d", min1, min2, min1_idx);
        if (min1 == 2 && min2 == 5 && min1_idx == 6) begin
            $display("-> [PASS] Test Case 6"); test_pass++;
        end else begin
            $display("-> [FAIL] Test Case 6"); test_fail++;
        end

        // ---------------------------------------------------------
        // TEST CASE 7: Min và Submin nằm ở 2 đầu thái cực (Opposite Ends)
        // Mục đích: Ép Submin phải là kẻ trụ lại đến tận Tầng 3 (los3_final).
        // Đầu vào: 2, 60, 70, 80, 90, 100, 110, -5
        // Trị tuyệt đối: 2, 60, 70, 80, 90, 100, 110, 5
        // Kì vọng: min1 = 2 (index 0), min2 = 5 (index 7).
        // ---------------------------------------------------------
        $display("\n--- TEST CASE 7: Min & Submin at Opposite Ends ---");
        row_weight = 4'd8;
        vtc_in[0] =  8'sd2;  // MIN1
        vtc_in[1] =  8'sd60;
        vtc_in[2] =  8'sd70; 
        vtc_in[3] =  8'sd80;
        vtc_in[4] =  8'sd90; 
        vtc_in[5] =  8'sd100;
        vtc_in[6] =  8'sd110; 
        vtc_in[7] = -8'sd5;  // MIN2 (Vào đến chung kết mới thua)
        
        #10; 
        $display("Ket qua: Min1 = %0d, Min2 = %0d, Index = %0d", min1, min2, min1_idx);
        if (min1 == 2 && min2 == 5 && min1_idx == 0) begin
            $display("-> [PASS] Test Case 7"); test_pass++;
        end else begin
            $display("-> [FAIL] Test Case 7"); test_fail++;
        end

        // ---------------------------------------------------------
        // TEST CASE 8: Row Weight cực nhỏ (row_weight = 1)
        // Mục đích: Kiểm tra xem mạch có xuất ra Min đúng và Submin là MAX không.
        // Kì vọng: min1 là phần tử duy nhất, min2 = 127 (MAX của 7-bit).
        // ---------------------------------------------------------
        $display("\n--- TEST CASE 8: Extreme Row Weight (row_weight = 1) ---");
        row_weight = 4'd1;
        vtc_in[0] = 8'sd42; // Phần tử duy nhất hợp lệ
        vtc_in[1] = 8'sd10; // Bị bỏ qua
        vtc_in[2] = 8'sd5;  // Bị bỏ qua
        vtc_in[3] = 8'sd1;  // Bị bỏ qua (dù nhỏ nhất)
        vtc_in[4] = 8'sd10; vtc_in[5] = 8'sd10; vtc_in[6] = 8'sd10; vtc_in[7] = 8'sd10;
        
        #10; 
        $display("Ket qua: Min1 = %0d, Min2 = %0d, Index = %0d", min1, min2, min1_idx);
        if (min1 == 42 && min2 == 127 && min1_idx == 0) begin
            $display("-> [PASS] Test Case 8"); test_pass++;
        end else begin
            $display("-> [FAIL] Test Case 8"); test_fail++;
        end

        // ---------------------------------------------------------
        // TEST CASE 9: Toàn bộ là số âm (All Negative)
        // Mục đích: Kiểm tra khả năng xử lý dấu XOR và logic chuyển đổi trị tuyệt đối.
        // Đầu vào: -10, -20, -30, -40, -50, -60, -70, -80
        // Trị tuyệt đối: 10, 20, 30, 40, 50, 60, 70, 80
        // Kì vọng: min1 = 10 (index 0), min2 = 20 (index 1).
        // Dấu: 8 số âm -> XOR = 0
        // ---------------------------------------------------------
        $display("\n--- TEST CASE 9: All Negative Values ---");
        row_weight = 4'd8;
        vtc_in[0] = -8'sd10; vtc_in[1] = -8'sd20;
        vtc_in[2] = -8'sd30; vtc_in[3] = -8'sd40;
        vtc_in[4] = -8'sd50; vtc_in[5] = -8'sd60;
        vtc_in[6] = -8'sd70; vtc_in[7] = -8'sd80;
        
        #10; 
        $display("Ket qua: Min1 = %0d, Min2 = %0d, Index = %0d, Signs_XOR = %b", min1, min2, min1_idx, signs_xor);
        if (min1 == 10 && min2 == 20 && min1_idx == 0 && signs_xor == 1'b0) begin
            $display("-> [PASS] Test Case 9"); test_pass++;
        end else begin
            $display("-> [FAIL] Test Case 9"); test_fail++;
        end

        // ---------------------------------------------------------
        // TỔNG KẾT
        // ---------------------------------------------------------
        $display("\n===============================================================");
        $display(" TONG KET MO PHONG: %0d PASS, %0d FAIL", test_pass, test_fail);
        $display("===============================================================");
        
        $finish;
    end

endmodule