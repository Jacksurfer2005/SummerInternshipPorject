`timescale 1ns / 1ns

module bram_app #(
    parameter Z= 96,       
    parameter W= 8,    
    parameter N= 2304,   
    parameter K= N/ Z
)(
    input  logic clk, we_a, we_b,
    input  logic [$clog2(K)-1:0] addr_a, addr_b,
    input  logic [(Z*W)-1:0] din_a, din_b,
    output logic [(Z*W)-1:0] dout_a, dout_b
);

    logic [(Z*W)-1:0] ram_blocks [0:K-1];
    
    always_ff @(posedge clk) begin
        if (we_a) begin
            ram_blocks[addr_a] <= din_a;
        end
        dout_a <= ram_blocks[addr_a];
    end

    always_ff @(posedge clk) begin
        if (we_b) begin
            ram_blocks[addr_b] <= din_b;
        end
	dout_b <= ram_blocks[addr_b];
    end

endmodule