`timescale 1ns/1ns

module tb_sign_insertion();

    // 1. Signals
    logic [7:0] x_1, x_2, x_3, x_4, x_5, x_6, x_7;
    logic [6:0] sign_i;
    logic       sign_total;
    logic [7:0] y_1, y_2, y_3, y_4, y_5, y_6, y_7;

    // 2. DUT Instantiation
    sign_insertion dut (.*);

    // 4. Test Stimulus
    initial begin
        x_1 = 8'd10; x_2 = 8'd20; x_3 = 8'd30; x_4 = 8'd40;
        x_5 = 8'd50; x_6 = 8'd60; x_7 = 8'd70;
        
        // TH1: sign_total = 0, sign_i = all 0
        sign_i = 7'b0000000;
        sign_total = 0;
        #10;
        $display("TH1: y_1=%d y_2=%d (Expect: 10, 20)", $signed(y_1), $signed(y_2));

        // TH2: sign_total = 1, lật bit của một số vị trí
        sign_i = 7'b0000001; // x_1 bị lật logic XOR
        sign_total = 1;
        #10;
        $display("TH2: y_1=%d y_2=%d (Expect: 10, -20)", $signed(y_1), $signed(y_2));

        #10 $finish;
    end

endmodule