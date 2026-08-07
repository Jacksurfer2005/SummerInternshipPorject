`timescale 1ns / 1ns

module tb_ldpc_decoder_top();

    parameter W = 8;
    parameter DEG = 8;
    parameter MAX_ITER = 3; 
    parameter ROM_DEPTH = 4; // Cấu hình nhỏ để chạy testbench cho nhanh
    parameter ADDR_WIDTH = $clog2(ROM_DEPTH);

    logic clk;
    logic rst_n;
    
    // Tín hiệu nạp liệu
    logic init_en;
    logic [ADDR_WIDTH-1:0] init_addr;
    logic [(DEG*W)-1:0] data_in;
    logic signed [W-1:0] alpha;
    
    // Tín hiệu ngõ ra
    logic [DEG-1:0] decoded_out;
    logic ready;

    ldpc_decoder_top #(
        .W(W), .DEG(DEG), .MAX_ITER(MAX_ITER), .ROM_DEPTH(ROM_DEPTH), .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .*
    );

    always #10 clk = ~clk;

    initial begin
        $dumpfile("tb_ldpc_decoder_top.vcd");
        $dumpvars(0, tb_ldpc_decoder_top);
        
        clk = 0;
        rst_n = 0;
        init_en = 0;
        init_addr = 0;
        data_in = 0;
        alpha = 8'd1; // Mặc định alpha = 1

        #25 rst_n = 1;

        $display("--- GIAI DOAN 1: NAP DU LIEU (DATA) TU KANH TRUYEN ---");
        // Nạp data mềm giả lập vào các hàng của BRAM APP
        @(posedge clk);
        init_en = 1;
        init_addr = 0;
        // Việc nạp được pack theo dạng vector. 
        // Vd: node 0: 12, node 1: -25... node 7: -30
        data_in = { -8'd30, 8'd50, -8'd10, 8'd18, -8'd5, 8'd40, -8'd25, 8'd12 };
        
        @(posedge clk);
        init_addr = 1;
        data_in = { 8'd10, 8'd20, -8'd15, -8'd35, 8'd22, -8'd18, 8'd42, 8'd5 };

        @(posedge clk);
        init_en = 0; // Tắt tín hiệu nạp, bắt đầu tự động giải mã

        $display("--- GIAI DOAN 2: FSM CHAY VONG LAP GIAI MA THUAT TOAN ---");
        // Đợi FSM bên trong top module kích hoạt vòng lặp đến MAX_ITER và báo Ready
        wait(ready == 1'b1);
        
        $display("--- HOAN THANH GIAI MA ---");
        $display("Time: %0t | Bits cứng ngõ ra: %b", $time, decoded_out);

        #50 $stop;
    end
endmodule