`timescale 1ns / 1ns

module check_matrix_rom #(
    parameter ROM_DEPTH = 128,
    parameter ADDR_WIDTH = 7
)(
    input  logic clk,
    input  logic [ADDR_WIDTH-1:0] read_addr,
    
    // Tương ứng với vector vals, pos, elementSize 
    output logic [7:0] element_size, // Trọng số hàng (rowWeight)
    output logic [9:0] pos_out       // Vị trí cột (Column index)
);
    // should use $readmemh for load file txt/hex
    logic [7:0] rom_element_size [0:ROM_DEPTH-1];
    logic [9:0] rom_pos [0:ROM_DEPTH-1];

    always_ff @(posedge clk) begin
        element_size <= rom_element_size[read_addr];
        pos_out      <= rom_pos[read_addr];
    end
endmodule