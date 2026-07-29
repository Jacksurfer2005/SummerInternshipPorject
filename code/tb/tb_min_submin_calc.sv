`timescale 1ns / 1ns

module tb_min_submin_calc;
    localparam W = 8, DEG = 8;
    
    logic signed [W-1:0] vtc_in [0:DEG-1];
    logic [W-2:0] min1, min2;
    logic [2:0] min1_idx;
    logic signs_xor;
    logic vtc_signs [0:DEG-1];

    min_submin_calc #(W, DEG) dut (.*);

    initial begin
        $dumpfile("tb_min_submin_calc.vcd");
        $dumpvars(0, tb_min_submin_calc);
        
        // Khởi tạo mảng các giá trị ngẫu nhiên
        vtc_in = '{ 
            8'sd15,  8'sd_10, 8'sd45, 8'sd_3,
            8'sd120, 8'sd22,  8'sd_8, 8'sd99 
        };
        // Trong mảng trên: |VTC| = {15, 10, 45, 3, 120, 22, 8, 99}
        // Min1 sẽ là 3 (tại index 3), Min2 sẽ là 8 (tại index 6)
        
        #10;
        $display("Min1: %d (Index: %d), Min2: %d", min1, min1_idx, min2);
        $display("XOR Signs: %b", signs_xor);
        
        // Test bão hòa tại biên âm (-128)
        vtc_in[0] = 8'sd_128;
        #10;
        $display("Test Bão hòa - Min1: %d, Min2: %d", min1, min2);
        $finish;
    end
endmodule