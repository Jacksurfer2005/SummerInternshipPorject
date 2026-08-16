`timescale 1ns/1ns

module tb_vtc_calc();

    // 1. Parameters and Signals
    parameter int DW = 8;
    parameter int Z  = 24;

    logic signed [Z-1:0][DW-1:0] app_i;
    logic signed [Z-1:0][DW-1:0] ctv_i;
    logic signed [Z-1:0][DW-1:0] vtc_o;

    // 2. DUT Instantiation
    vtc_calc #(
        .DW(DW),
        .Z(Z)
    ) dut (
        .app_i(app_i),
        .ctv_i(ctv_i),
        .vtc_o(vtc_o)
    );

    // 4. Test Stimulus
    initial begin
        app_i = '0;
        ctv_i = '0;

        // Gán các trường hợp toán học
        app_i[0] = 8'd50;  ctv_i[0] = 8'd20;   // Bình thường (50 - 20 = 30)
        app_i[1] = 8'd100; ctv_i[1] = -8'd50;  // Tràn trên (150 > MAX_INT 127) -> Clip về 127
        app_i[2] = -8'd100; ctv_i[2] = 8'd50;  // Tràn dưới (-150 < MIN_INT -128) -> Clip về -128

        #10;
        
        $display("vtc_o[0] = %d (Expect: 30)", vtc_o[0]);
        $display("vtc_o[1] = %d (Expect: 127 - Saturation)", vtc_o[1]);
        $display("vtc_o[2] = %d (Expect: -128 - Saturation)", vtc_o[2]);

        #10 $finish;
    end

endmodule