`timescale 1ns/1ns

module tb_signs_xoring();

    // 1. Signals
    logic [6:0] sign_i;
    logic       sign_o;

    // 2. DUT Instantiation
    signs_xoring dut (
        .sign_i(sign_i),
        .sign_o(sign_o)
    );

    // 4. Test Stimulus
    initial begin
        // Số bit 1 chẵn -> ngõ ra 0
        sign_i = 7'b0000000; #10;
        $display("sign_i=%b | sign_o=%b (Expect: 0)", sign_i, sign_o);
        
        // Số bit 1 lẻ -> ngõ ra 1
        sign_i = 7'b0000001; #10;
        $display("sign_i=%b | sign_o=%b (Expect: 1)", sign_i, sign_o);
        
        sign_i = 7'b0101010; #10;
        $display("sign_i=%b | sign_o=%b (Expect: 1)", sign_i, sign_o);
        
        sign_i = 7'b1111111; #10;
        $display("sign_i=%b | sign_o=%b (Expect: 1)", sign_i, sign_o);

        #10 $finish;
    end

endmodule