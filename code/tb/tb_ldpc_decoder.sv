`timescale 1ns / 1ns

module tb_ldpc_decoder;
    localparam W = 8, DEG = 8;
    logic clk, rst_n, iter_done_tick;
    logic signed [W-1:0] app_in [0:DEG-1];
    logic signed [W-1:0] ctv_in [0:DEG-1];
    
    logic ready;
    logic decoded_out [0:DEG-1];
    logic signed [W-1:0] app_new [0:DEG-1];
    logic signed [W-1:0] ctv_new [0:DEG-1];

    ldpc_decoder #(W, DEG) dut (.*);

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst_n = 0; iter_done_tick = 0;
        
        // Khởi tạo APP và CTV đầu vào
        for(int i=0; i<DEG; i++) begin
            app_in[i] = 8'sd20 - i*5; 
            ctv_in[i] = 8'sd5;
        end
        
        #15 rst_n = 1;
        
        @(posedge clk);
        $display("Decoder Ready Status: %b", ready);
        
        // Kích hoạt iter_done đủ 10 lần (mặc định MAX=10) để xem bit giải mã
        repeat(11) begin
            @(posedge clk);
            iter_done_tick = 1;
            @(posedge clk);
            iter_done_tick = 0;
        end
        
        #10;
        $display("Sau 10 lần lặp, Ready = %b", ready);
        for(int i=0; i<DEG; i++) begin
             $display("Node %d: Decoded Bit = %b", i, decoded_out[i]);
        end
        
        $finish;
    end
endmodule