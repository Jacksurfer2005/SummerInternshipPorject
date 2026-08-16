`timescale 1ns/1ns

module tb_ldpc_top();

    // 1. Parameters and Signals
    parameter int MB = 6;
    parameter int NB = 24;
    parameter int Z = 24;
    parameter int Z0 = 96;
    parameter int DR_MAX = 7;
    parameter int DW = 8;
    parameter int MAX_ITER = 8;
    parameter int APP_DEPTH = 24;
    parameter int CTV_DEPTH = 96;
    parameter int APP_WIDTH = Z*DW;

    logic clk;
    logic rst_n;
    logic start;
    logic iter_done;
    logic converged;
    logic signed [Z-1:0][DW-1:0] app_init;
    logic signed [Z-1:0][DW-1:0] ctv_word_i;
    logic blk_valid;
    logic [((MB <= 1) ? 1 : $clog2(MB))-1:0] layer_i;
    logic [((DR_MAX <= 1) ? 1 : $clog2(DR_MAX))-1:0] edge_idx_i;
    
    logic [((DR_MAX+1 <= 1) ? 1 : $clog2(DR_MAX+1))-1:0] row_weight_o;
    logic [((NB <= 1) ? 1 : $clog2(NB))-1:0] col_pos_o;
    logic [((Z <= 1) ? 1 : $clog2(Z))-1:0] shift_o;
    logic edge_valid_o;

    logic app_a_en;
    logic [((APP_DEPTH <= 1) ? 1 : $clog2(APP_DEPTH))-1:0] app_a_addr;
    logic [APP_WIDTH-1:0] app_a_dout;
    logic app_b_we;
    logic [((APP_DEPTH <= 1) ? 1 : $clog2(APP_DEPTH))-1:0] app_b_addr;
    logic [APP_WIDTH-1:0] app_b_din;

    logic ctv_rd_en;
    logic [((CTV_DEPTH <= 1) ? 1 : $clog2(CTV_DEPTH))-1:0] ctv_rd_addr;
    logic [APP_WIDTH-1:0] ctv_rd_data;
    logic ctv_wr_en;
    logic [((CTV_DEPTH <= 1) ? 1 : $clog2(CTV_DEPTH))-1:0] ctv_wr_addr;
    logic [APP_WIDTH-1:0] ctv_wr_data;

    logic signed [Z-1:0][DW-1:0] vtc_word_o;
    logic [7:0] min_o;
    logic [7:0] submin_o;
    logic [7:0] ctv_1_o, ctv_2_o, ctv_3_o, ctv_4_o, ctv_5_o, ctv_6_o, ctv_7_o;
    
    logic [((MAX_ITER <= 1) ? 1 : $clog2(MAX_ITER+1))-1:0] iter_cnt_o;
    logic done_o;
    logic ready_o;
    logic out_valid_o;
    logic [Z-1:0] out_bits_o;

    // 2. DUT Instantiation
    ldpc_decoder_top #(
        .MB(MB), .NB(NB), .Z(Z), .Z0(Z0), .DR_MAX(DR_MAX), .DW(DW),
        .MAX_ITER(MAX_ITER), .APP_DEPTH(APP_DEPTH), .CTV_DEPTH(CTV_DEPTH), .APP_WIDTH(APP_WIDTH)
    ) dut (
        .* // Tự động map các tín hiệu cùng tên
    );

    // 3. Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    // 4. Test Stimulus
    initial begin
        rst_n = 0;
        start = 0;
        iter_done = 0;
        converged = 0;
        app_init = '0;
        ctv_word_i = '0;
        blk_valid = 0;
        layer_i = 0;
        edge_idx_i = 0;

        // BRAM signals init
        app_a_en = 0; app_a_addr = 0; app_b_we = 0; app_b_addr = 0; app_b_din = '0;
        ctv_rd_en = 0; ctv_rd_addr = 0; ctv_wr_en = 0; ctv_wr_addr = 0; ctv_wr_data = '0;

        #20 rst_n = 1;
        
        @(posedge clk) start = 1;
        @(posedge clk) start = 0;

        // Dành không gian nạp vector test bổ sung ở đây
        
        #100 $finish;
    end

endmodule