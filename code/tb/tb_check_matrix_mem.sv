`timescale 1ns/1ns

module tb_check_matrix_mem();
    logic clk;
    logic [2:0] layer;
    logic [2:0] edge_idx;
    logic [2:0] row_weight;
    logic [4:0] col_pos;
    logic [4:0] shift;
    logic edge_valid;

    check_matrix_mem dut (
        .clk(clk), .layer(layer), .edge_idx(edge_idx),
        .row_weight(row_weight), .col_pos(col_pos),
        .shift(shift), .edge_valid(edge_valid)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("tb_check_matrix_mem.vcd");
        $dumpvars(0, tb_check_matrix_mem);
    end

    initial begin
        $monitor("Time = %0t | layer = %0d | edge_idx = %0d | row_weight = %0d | col_pos = %0d | shift = %0d | edge_valid = %b",
                 $time, layer, edge_idx, row_weight, col_pos, shift, edge_valid);
    end

    initial begin
        layer = 0; edge_idx = 0; #10;

        // Case 1: Lớp 0, cạnh 0
        layer = 3'd0; edge_idx = 3'd0; #10;
        // Case 2: Lớp 0, cạnh 1
        layer = 3'd0; edge_idx = 3'd1; #10;
        // Case 3: Lớp 1, cạnh 0
        layer = 3'd1; edge_idx = 3'd0; #10;
        // Case 4: Lớp 1, cạnh 5
        layer = 3'd1; edge_idx = 3'd5; #10;
        // Case 5: Lớp 2, cạnh 3
        layer = 3'd2; edge_idx = 3'd3; #10;
        // Case 6: Cạnh không hợp lệ (ngoài phạm vi, edge_valid = 0)
        layer = 3'd2; edge_idx = 3'd7; #10;
        // Case 7: Lớp 5, cạnh 0
        layer = 3'd5; edge_idx = 3'd0; #10;
        // Case 8: Lớp 5, cạnh 1
        layer = 3'd5; edge_idx = 3'd1; #10;

        $finish;
    end
endmodule