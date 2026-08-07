`timescale 1ns / 1ns
//bổ sung thêm cách đọc file hex từ rom matrix
module tb_check_matrix_rom();
    parameter ROM_DEPTH = 128;
    parameter ADDR_WIDTH = 7;

    logic clk;
    logic [ADDR_WIDTH-1:0] read_addr;
    logic [7:0] element_size;
    logic [9:0] pos_out;

    check_matrix_rom #(
        .ROM_DEPTH(ROM_DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (.*);

    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_check_matrix_rom.vcd");
        $dumpvars(0, tb_check_matrix_rom);
        
        clk = 0; read_addr = 0;
        #15;
        $display("=== TEST CHECK MATRIX ROM ===");

        read_addr = 7'd0; #10;
        $display("Addr 0 -> Element Size: %d, Pos: %d", element_size, pos_out);

        read_addr = 7'd1; #10;
        $display("Addr 1 -> Element Size: %d, Pos: %d", element_size, pos_out);

        $finish;
    end
endmodule