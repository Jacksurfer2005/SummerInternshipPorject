`timescale 1ns/1ns

module tb_min_submin();

    // 1. Signals
    logic [7:0] vtc_1, vtc_2, vtc_3, vtc_4, vtc_5, vtc_6, vtc_7;
    logic [7:0] ctv_1, ctv_2, ctv_3, ctv_4, ctv_5, ctv_6, ctv_7;
    logic [7:0] min_o, submin_o;
    logic [7:0] vtc_o_1, vtc_o_2, vtc_o_3, vtc_o_4, vtc_o_5, vtc_o_6, vtc_o_7;
    logic [3:0] rowWeight;

    // 2. DUT Instantiation
    min_submin_calc dut (.*);

    // 4. Test Stimulus
    initial begin
        // Khởi tạo vector ngẫu nhiên hoặc biên
        vtc_1 = 8'd12; vtc_2 = -8'd5;  vtc_3 = 8'd18; vtc_4 = -8'd22;
        vtc_5 = 8'd2;  vtc_6 = 8'd100; vtc_7 = 8'd45;
        
        #10;
        $display("min: %d, submin: %d", min_o, submin_o);
        
        // Đổi test vector
        vtc_1 = 8'd33; vtc_2 = 8'd33;  vtc_3 = 8'd1; vtc_4 = -8'd120;
        vtc_5 = -8'd4; vtc_6 = 8'd8;   vtc_7 = 8'd9;
        
        #10;
        $display("min: %d, submin: %d", min_o, submin_o);

        #10 $finish;
    end

endmodule