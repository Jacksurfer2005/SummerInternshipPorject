`timescale 1ns / 1ns

module tb_vtc_calc;
    parameter W = 8;
    
    logic signed [W-1:0] app_in;
    logic signed [W-1:0] ctv_in;
    logic signed [W-1:0] vtc_out;
    
    // Khởi tạo Device Under Test (DUT)
    vtc_calc #(
        .W(W)
    ) dut (
        .app_in(app_in),
        .ctv_in(ctv_in),
        .vtc_out(vtc_out)
    );
    
    initial begin
        $dumpfile("tb_vtc_calc.vcd");
        $dumpvars(0, tb_vtc_calc);

        $display("Bắt đầu kiểm thử vtc_calc...");
        
        // Test 1: Phép trừ thông thường
        app_in = 8'sd10; ctv_in = 8'sd5; #10;
        $display("Test 1: %d - %d = %d", app_in, ctv_in, vtc_out);
        
        // Test 2: Phép trừ số âm
        app_in = -8'sd20; ctv_in = 8'sd15; #10;
        $display("Test 2: %d - %d = %d", app_in, ctv_in, vtc_out);
        
        // Test 3: Tràn số dương (Ghim tại MAX_VAL = 127)
        app_in = 8'sd120; ctv_in = -8'sd20; #10;
        $display("Test 3 (Sat Max): %d - %d = %d", app_in, ctv_in, vtc_out);
        
        // Test 4: Tràn số âm (Ghim tại MIN_VAL = -128)
        app_in = -8'sd120; ctv_in = 8'sd30; #10;
        $display("Test 4 (Sat Min): %d - %d = %d", app_in, ctv_in, vtc_out);

        // 1. Phép tính thông thường
        app_in = 8'd20;  ctv_in = 8'd5;   #10;
        $display("Normal: %d - %d = %d", app_in, ctv_in, vtc_out);

        // 2. Tràn số dương (Saturate to 127)
        app_in = 8'd100; ctv_in = -8'd50; #10;
        $display("Overflow Pos: %d - (%d) = %d (Expected: 127)", app_in, ctv_in, vtc_out);

        // 3. Tràn số âm (Saturate to -128)
        app_in = -8'd100; ctv_in = 8'd50; #10;
        $display("Underflow Neg: %d - %d = %d (Expected: -128)", app_in, ctv_in, vtc_out);
        
        $display("Hoàn thành kiểm thử vtc_calc.");
        $stop;
    end
endmodule