`timescale 1ns / 1ns

module tb_check_matrix_rom;
    logic clk;
    logic [6:0] read_addr;
    logic [7:0] element_size;
    logic [9:0] pos_out;

    check_matrix_rom #(128, 7) dut (.*);

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        // Ghi chú: Nếu không có file init (readmemh) trong RTL, giá trị trả về sẽ là X.
        read_addr = 0;
        @(negedge clk);
        read_addr = 7'd5;
        @(negedge clk);
        $display("Addr: %d, element_size: %d, pos_out: %d", read_addr, element_size, pos_out);
        #10 $finish;
    end
endmodule