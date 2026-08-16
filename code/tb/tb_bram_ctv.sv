`timescale 1ns/1ns

module tb_bram_ctv();
    parameter int DEPTH = 96;
    parameter int WIDTH = 144;

    logic clk;
    logic rd_en, wr_en;
    logic [6:0] rd_addr, wr_addr;
    logic [WIDTH-1:0] rd_data, wr_data;

    bram_ctv #(DEPTH, WIDTH) dut (
        .clk(clk), .rd_en(rd_en), .rd_addr(rd_addr), .rd_data(rd_data),
        .wr_en(wr_en), .wr_addr(wr_addr), .wr_data(wr_data)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("tb_bram_ctv.vcd");
        $dumpvars(0, tb_bram_ctv);
    end

    initial begin
        $monitor("Time = %0t | rd_en = %b | rd_addr = %0d | rd_data = %h | wr_en = %b | wr_addr = %0d | wr_data = %h",
                 $time, rd_en, rd_addr, rd_data, wr_en, wr_addr, wr_data);
    end

    initial begin
        rd_en = 0; rd_addr = 0; wr_en = 0; wr_addr = 0; wr_data = 0; #10;

        // Case 1: Ghi địa chỉ 10
        wr_en = 1; wr_addr = 7'd10; wr_data = 144'h1111; #10;
        // Case 2: Ghi địa chỉ 20
        wr_en = 1; wr_addr = 7'd20; wr_data = 144'h2222; #10;
        // Case 3: Ghi địa chỉ 95
        wr_en = 1; wr_addr = 7'd95; wr_data = 144'h9595; #10;
        // Case 4: Đọc địa chỉ 10
        wr_en = 0; rd_en = 1; rd_addr = 7'd10; #10;
        // Case 5: Đọc địa chỉ 20
        rd_en = 1; rd_addr = 7'd20; #10;
        // Case 6: Đọc địa chỉ 95
        rd_en = 1; rd_addr = 7'd95; #10;
        // Case 7: Vừa đọc vừa ghi (đọc 10, ghi 30)
        wr_en = 1; wr_addr = 7'd30; wr_data = 144'h3030;
        rd_en = 1; rd_addr = 7'd10; #10;
        // Case 8: Tắt enable
        wr_en = 0; rd_en = 0; #10;

        $finish;
    end
endmodule