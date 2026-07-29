`timescale 1ns / 1ns

module tb_vtc_calc;
    localparam W = 8;
    logic signed [W-1:0] app_in;
    logic signed [W-1:0] ctv_in;
    logic signed [W-1:0] vtc_out;

    vtc_calc #(W) dut (
        .app_in(app_in),
        .ctv_in(ctv_in),
        .vtc_out(vtc_out)
    );

    initial begin
        $dumpfile("tb_vtc_calc.vcd");
        $dumpvars(0, tb_vtc_calc);

        $display("Bắt đầu test vtc_calc...");
        // Test case 1: Số dương
        app_in = 8'd20; ctv_in = 8'd5; #10;
        $display("app_in=%d, ctv_in=%d -> vtc_out=%d", app_in, ctv_in, vtc_out);
        
        // Test case 2: Số âm
        app_in = -8'd15; ctv_in = 8'd10; #10;
        $display("app_in=%d, ctv_in=%d -> vtc_out=%d", app_in, ctv_in, vtc_out);
        
        // Test case 3: Tràn số (Overflow/Underflow kiểm tra logic cắt)
        app_in = -8'd128; ctv_in = 8'd5; #10;
        $display("app_in=%d, ctv_in=%d -> vtc_out=%d (Lưu ý: Có thể bị tràn nếu không bão hòa)", app_in, ctv_in, vtc_out);
        
        $finish;
    end
endmodule