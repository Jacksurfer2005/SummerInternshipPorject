`timescale 1ns / 1ns

module ldpc_top #(
    parameter W = 8,
    parameter DEG = 8,
    parameter Z = 96,
    parameter N = 2304,
    parameter K = N / Z
)(
    input  logic clk,
    input  logic rst_n,
    
    input  logic load_data_en,
    input  logic [(Z*W)-1:0] rx_data_in,
    input  logic [$clog2(K)-1:0] load_addr,
    
    output logic ready,
    output logic decoded_out [0:DEG-1]
);

    logic [$clog2(K)-1:0] app_read_addr, app_write_addr;
    logic [$clog2(K)-1:0] ctv_read_addr, ctv_write_addr;
    logic [6:0]           matrix_rom_addr;
    
    logic app_we, ctv_we;
    logic iter_done_tick;
    
    logic [(Z*W)-1:0] app_dout_flat;
    logic [(Z*W)-1:0] ctv_dout_flat;
    
    logic [(Z*W)-1:0] app_din_flat;
    logic [(Z*W)-1:0] ctv_din_flat;
    
    logic signed [W-1:0] app_core_in  [0:DEG-1];
    logic signed [W-1:0] ctv_core_in  [0:DEG-1];
    logic signed [W-1:0] app_core_out [0:DEG-1];
    logic signed [W-1:0] ctv_core_out [0:DEG-1];

    genvar i;
    generate
        for (i = 0; i < DEG; i++) begin : gen_pack_unpack
            assign app_core_in[i] = app_dout_flat[(i*W) +: W];
            assign ctv_core_in[i] = ctv_dout_flat[(i*W) +: W];
            
            assign app_din_flat[(i*W) +: W] = app_core_out[i];
            assign ctv_din_flat[(i*W) +: W] = ctv_core_out[i];
        end
    endgenerate

    bram_app #(
        .Z(Z), .W(W), .N(N), .K(K)
    ) u_bram_app (
        .clk(clk),
        .we_a(load_data_en), 
	.we_b(app_we),
        .addr_a(load_addr), 
	.addr_b(app_we ? app_write_addr : app_read_addr),
        .din_a(rx_data_in), 
	.din_b(app_din_flat),
        .dout_a(), 
	.dout_b(app_dout_flat)
    );

    bram_app #(
        .Z(Z), .W(W), .N(N), .K(K) 
    ) u_bram_ctv (
        .clk(clk),
        .we_a(1'b0),  
	.we_b(ctv_we),
       	.addr_a('0),
	.addr_b(ctv_we ? ctv_write_addr : ctv_read_addr),
       	.din_a('0),
	.din_b(ctv_din_flat),
       	.dout_a(), 
        .dout_b(ctv_dout_flat)
    );

    check_matrix_rom #(
        .ROM_DEPTH(128), .ADDR_WIDTH(7)
    ) u_matrix_rom (
        .clk(clk),
        .read_addr(matrix_rom_addr),
        .element_size(), 
        .pos_out()      
    );

    ldpc_decoder #(
        .W(W), .DEG(DEG)
    ) u_core (
        .clk(clk),
        .rst_n(rst_n),
        .iter_done(iter_done_tick),
        .app_in(app_core_in),
        .ctv_in(ctv_core_in),
        .ready(ready),
        .decoded_out(decoded_out),
        .app_new(app_core_out),
        .ctv_new(ctv_core_out)
    );

    assign app_we = 1'b0;
    assign ctv_we = 1'b0;
    assign iter_done_tick = 1'b0;

endmodule