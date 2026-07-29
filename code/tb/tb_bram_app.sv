`timescale 1ns / 1ns

module tb_bram_app;
    localparam Z = 96, W = 8, N = 2304, K = N / Z;
    localparam DATA_W = Z * W;
    
    logic clk, we_a, we_b;
    logic [$clog2(K)-1:0] addr_a, addr_b;
    logic [DATA_W-1:0] din_a, din_b;
    logic [DATA_W-1:0] dout_a, dout_b;

    bram_app #(Z, W, N, K) dut (
        .clk(clk),
        .we_a(we_a),
        .we_b(we_b),
        .addr_a(addr_a), 
        .addr_b(addr_b),
        .din_a(din_a), 
        .din_b(din_b),
        .dout_a(dout_a), 
        .dout_b(dout_b)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("tb_bramp_app.vcd");
        $dumpvars(0, tb_bram_app);

        we_a = 0; we_b = 0; addr_a = 0; addr_b = 0;
        din_a = '0; din_b = '0;
        
        @(negedge clk);
        // Ghi vào cổng A
        we_a = 1; addr_a = 5; din_a = {DATA_W{1'b1}};
        @(negedge clk);
        we_a = 0;
        
        // Ghi vào cổng B
        we_b = 1; addr_b = 10; din_b = {DATA_W{1'b0}} | 8'hAA;
        @(negedge clk);
        we_b = 0;
        
        // Đọc từ cổng A và B
        addr_a = 5; addr_b = 10;
        @(negedge clk);
        $display("Đọc Port A (Addr 5): %h", dout_a);
        $display("Đọc Port B (Addr 10): %h", dout_b);
        
        #10 $finish;
    end
endmodule