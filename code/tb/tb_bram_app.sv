`timescale 1ns/1ns

module tb_bram_app();
    parameter int DEPTH = 24;
    parameter int WIDTH = 144;

    logic clk;
    logic a_en;
    logic [4:0] a_addr;
    logic [WIDTH-1:0] a_dout;
    logic b_we;
    logic [4:0] b_addr;
    logic [WIDTH-1:0] b_din;

    bram_app #(DEPTH, WIDTH) dut (
        .clk(clk), .a_en(a_en), .a_addr(a_addr), .a_dout(a_dout),
        .b_we(b_we), .b_addr(b_addr), .b_din(b_din)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("tb_bram_app.vcd");
        $dumpvars(0, tb_bram_app);
    end

    initial begin
        $monitor("Time = %0t | a_en = %b | a_addr = %0d | a_dout = %h | b_we = %b | b_addr = %0d | b_din = %h",
                 $time, a_en, a_addr, a_dout, b_we, b_addr, b_din);
    end

    initial begin
        a_en = 0; a_addr = 0; b_we = 0; b_addr = 0; b_din = 0; #10;

        // Case 1: Ghi dữ liệu vào địa chỉ 0
        b_we = 1; b_addr = 5'd0; b_din = 144'hAABB; #10;
        // Case 2: Ghi dữ liệu vào địa chỉ 5
        b_we = 1; b_addr = 5'd5; b_din = 144'hCCDD; #10;
        // Case 3: Ghi dữ liệu vào địa chỉ biên (23)
        b_we = 1; b_addr = 5'd23; b_din = 144'hEEFF; #10;
        // Case 4: Đọc dữ liệu từ địa chỉ 0
        b_we = 0; a_en = 1; a_addr = 5'd0; #10;
        // Case 5: Đọc dữ liệu từ địa chỉ 5
        a_en = 1; a_addr = 5'd5; #10;
        // Case 6: Đọc dữ liệu từ địa chỉ 23
        a_en = 1; a_addr = 5'd23; #10;
        // Case 7: Vừa đọc vừa ghi khác địa chỉ
        b_we = 1; b_addr = 5'd10; b_din = 144'h1234;
        a_en = 1; a_addr = 5'd5; #10;
        // Case 8: Vô hiệu hóa cả đọc và ghi
        b_we = 0; a_en = 0; a_addr = 5'd0; b_addr = 5'd0; #10;

        $finish;
    end
endmodule