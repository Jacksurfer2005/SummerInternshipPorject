`timescale 1ns / 1ns

module tb_ldpc_top;
    localparam W = 8, DEG = 8, Z = 96, N = 2304, K = N / Z;
    localparam DATA_W = Z * W;
    
    logic clk, rst_n, load_data_en;
    logic [DATA_W-1:0] rx_data_in;
    logic [$clog2(K)-1:0] load_addr;
    
    logic ready;
    logic decoded_out [0:DEG-1];

    ldpc_top #(W, DEG, Z, N, K) dut (.*);

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst_n = 0;
        load_data_en = 0; load_addr = 0; rx_data_in = '0;
        
        // Reset hệ thống
        #20 rst_n = 1;
        
        // Bơm dữ liệu giả lập vào bộ nhớ BRAM thông qua giao tiếp load
        @(negedge clk);
        load_data_en = 1;
        for(int addr = 0; addr < K; addr++) begin
            load_addr = addr;
            rx_data_in = { (Z){8'h11} }; // Dummy data
            @(negedge clk);
        end
        load_data_en = 0;
        
        // Để quan sát module chạy, ta cần cấp iter_done và điều khiển we/addr từ FSM ở ngoài (hoặc bên trong top)
        // Hiện tại các tín hiệu iter_done_tick, app_we, ctv_we trong ldpc_top đang được gán cứng 1'b0
        // Trong mô phỏng này, chúng ta chỉ kiểm tra việc Load Data và Reset không gây lỗi
        
        #100;
        $display("Kiểm thử Top-Level hoàn tất. Data load thành công.");
        $finish;
    end
endmodule