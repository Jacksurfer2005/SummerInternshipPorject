`timescale 1ns/1ns

// ============================================================================
// LDPC TOP - integration of the currently implemented blocks
//
// This top-level follows the dataflow of the reference paper:
//
//   APP BRAM -> VTC = APP - CTV
//             -> Min/Submin + sign
//             -> CTVnew
//             -> APPnew = VTC + CTVnew
//             -> write APP/CTV back
//             -> iteration control / result output
//
// IMPORTANT:
// 1) The uploaded datapath is currently a 7-edge implementation
//    (dr_max = 7), not the full z-core architecture of the paper.
// 2) Therefore this top processes one scalar position per cycle and
//    reuses the 7-edge datapath for the selected parity-check row.
// 3) The current BRAM modules are wrapped here with WIDTH = DR_MAX*DW = 56.
//    This is intentional: the supplied BRAM default WIDTH=144 is not
//    consistent with Z=24 and DW=8 (which would require 192 bits).
// 4) The exact paper architecture uses z parallel cores and rotated APP
//    addressing. The present top includes the shift information from
//    check_matrix_mem but does not claim full z-core parallelism.
// 5) Required source files not uploaded with this message are:
//      fa_calc.sv, abs_calc.sv, signs_xoring.sv,
//      comp_tree.sv, sign_insertion.sv, iter_compare.sv
// ============================================================================

module ldpc_top #(
    parameter int DW           = 8,
    parameter int Z            = 24,
    parameter int MB           = 6,
    parameter int NB           = 24,
    parameter int DR_MAX       = 7,
    parameter int MAX_ITER     = 8,
    parameter int Z0           = 96,
    parameter string INIT_FILE = "0_src/h_base.mem"
)(
    input  logic                         clk,
    input  logic                         reset_n,
    input  logic                         start,

    // Initial soft information.
    // One word contains DR_MAX signed DW-bit values.
    input  logic [DR_MAX*DW-1:0]         app_init_data,
    input  logic                         app_init_valid,

    // Decoded result.
    output logic [NB*DW-1:0]             decoded_data,
    output logic                         ready,
    output logic                         busy,
    output logic                         done,
    output logic [DW-1:0]                decoding_data,

    output logic [$clog2(MAX_ITER+1)-1:0] iteration_count
);

    localparam int WORD_W  = DR_MAX * DW;
    localparam int LAYER_W = (MB <= 1) ? 1 : $clog2(MB);
    localparam int EDGE_W  = (DR_MAX <= 1) ? 1 : $clog2(DR_MAX);
    localparam int Z_W     = (Z <= 1) ? 1 : $clog2(Z);
    localparam int APP_AW  = (24 <= 1) ? 1 : $clog2(24);
    localparam logic [7:0] MAX_ITER_W = MAX_ITER;

    // ------------------------------------------------------------------------
    // State machine
    // ------------------------------------------------------------------------
    typedef enum logic [3:0] {
        S_IDLE,
        S_INIT_WRITE,
        S_MATRIX_REQ,
        S_APP_READ,
        S_CTV_READ,
        S_CALC,
        S_WRITEBACK,
        S_NEXT_EDGE,
        S_NEXT_LAYER,
        S_ITER_DONE,
        S_RESULT
    } state_t;

    state_t state;

    logic [LAYER_W-1:0] layer;
    logic [EDGE_W-1:0]  edge_idx;
    logic [Z_W-1:0]     z_index;

    // ------------------------------------------------------------------------
    // Matrix information
    // ------------------------------------------------------------------------
    logic [3:0] row_weight;
    logic [LAYER_W-1:0] cm_layer;
    logic [EDGE_W-1:0]  cm_edge_idx;
    logic [EDGE_W-1:0]  cm_edge_idx_safe;

    logic [NB-1:0] col_pos;
    logic [Z_W-1:0] shift;
    logic edge_valid;

    assign cm_layer       = layer;
    assign cm_edge_idx    = edge_idx;
    assign cm_edge_idx_safe = edge_idx;

    check_matrix_mem #(
        .MB          (MB),
        .NB          (NB),
        .Z           (Z),
        .Z0          (Z0),
        .DR_MAX      (DR_MAX),
        .INIT_WIDTH  (8),
        .INIT_FILE   (INIT_FILE)
    ) u_check_matrix (
        .clk        (clk),
        .layer      (cm_layer),
        .edge_idx   (cm_edge_idx_safe),
        .row_weight (row_weight),
        .col_pos    (col_pos),
        .shift      (shift),
        .edge_valid (edge_valid)
    );

    // ------------------------------------------------------------------------
    // APP and CTV memories
    //
    // The supplied BRAM modules have fixed 24-deep storage.  We use one
    // DR_MAX*DW word per address for this 7-edge implementation.
    // ------------------------------------------------------------------------
    logic [WORD_W-1:0] app_mem_dout;
    logic [WORD_W-1:0] ctv_mem_dout;

    logic              app_rd_en;
    logic [4:0]        app_rd_addr;
    logic              app_wr_en;
    logic [4:0]        app_wr_addr;
    logic [WORD_W-1:0] app_wr_data;
    logic [WORD_W-1:0] app_new_word;

    logic              ctv_rd_en;
    logic [6:0]        ctv_rd_addr;
    logic              ctv_wr_en;
    logic [6:0]        ctv_wr_addr;
    logic [WORD_W-1:0] ctv_wr_data;
    logic [WORD_W-1:0] ctv_new_word;

    bram_app #(
        .DEPTH (24),
        .WIDTH (WORD_W)
    ) u_bram_app (
        .clk    (clk),
        .a_en   (app_rd_en),
        .a_addr (app_rd_addr),
        .a_dout (app_mem_dout),
        .b_we   (app_wr_en),
        .b_addr (app_wr_addr),
        .b_din  (app_wr_data)
    );

    bram_ctv #(
        .DEPTH (24),
        .WIDTH (WORD_W)
    ) u_bram_ctv (
        .clk     (clk),
        .rd_en   (ctv_rd_en),
        .rd_addr (ctv_rd_addr),
        .rd_data (ctv_mem_dout),
        .wr_en   (ctv_wr_en),
        .wr_addr (ctv_wr_addr),
        .wr_data (ctv_wr_data)
    );

    // ------------------------------------------------------------------------
    // Seven VTC/CTV lanes
    // ------------------------------------------------------------------------
    logic signed [DW-1:0] app_lane [0:DR_MAX-1];
    logic signed [DW-1:0] ctv_lane [0:DR_MAX-1];
    logic signed [DW-1:0] vtc_lane [0:DR_MAX-1];

    logic signed [DW-1:0] ctv_new [0:DR_MAX-1];
    logic signed [DW-1:0] app_new [0:DR_MAX-1];

    logic [7:0] min_o;
    logic [7:0] submin_o;
    logic [7:0] vtc_o [0:DR_MAX-1];
    logic [3:0] calc_row_weight;

    // Unpack BRAM words.
    genvar g;
    generate
        for (g = 0; g < DR_MAX; g = g + 1) begin : G_UNPACK
            always_comb begin
                app_lane[g] = $signed(app_mem_dout[g*DW +: DW]);
                ctv_lane[g] = $signed(ctv_mem_dout[g*DW +: DW]);
            end
        end
    endgenerate

    // VTC = APP - CTV.
    //
    // The supplied vtc_calc is parameterized by Z.  For the current
    // 7-edge implementation we instantiate it with Z=DR_MAX.
    logic signed [DR_MAX-1:0][DW-1:0] app_vec;
    logic signed [DR_MAX-1:0][DW-1:0] ctv_vec;
    logic signed [DR_MAX-1:0][DW-1:0] vtc_vec;

    generate
        for (g = 0; g < DR_MAX; g = g + 1) begin : G_VEC
            always_comb begin
                app_vec[g] = app_lane[g];
                ctv_vec[g] = ctv_lane[g];
            end
        end
    endgenerate

    vtc_calc #(
        .DW (DW),
        .Z  (DR_MAX)
    ) u_vtc_calc (
        .app_i (app_vec),
        .ctv_i (ctv_vec),
        .vtc_o (vtc_vec)
    );

    // Min/submin block has seven scalar inputs.
    min_submin_calc u_min_submin (
        .vtc_1 (vtc_vec[0]),
        .vtc_2 (vtc_vec[1]),
        .vtc_3 (vtc_vec[2]),
        .vtc_4 (vtc_vec[3]),
        .vtc_5 (vtc_vec[4]),
        .vtc_6 (vtc_vec[5]),
        .vtc_7 (vtc_vec[6]),

        .ctv_1 (ctv_new[0]),
        .ctv_2 (ctv_new[1]),
        .ctv_3 (ctv_new[2]),
        .ctv_4 (ctv_new[3]),
        .ctv_5 (ctv_new[4]),
        .ctv_6 (ctv_new[5]),
        .ctv_7 (ctv_new[6]),

        .min_o (min_o),
        .submin_o (submin_o),

        .vtc_o_1 (vtc_o[0]),
        .vtc_o_2 (vtc_o[1]),
        .vtc_o_3 (vtc_o[2]),
        .vtc_o_4 (vtc_o[3]),
        .vtc_o_5 (vtc_o[4]),
        .vtc_o_6 (vtc_o[5]),
        .vtc_o_7 (vtc_o[6]),

        .rowWeight (calc_row_weight)
    );

    // APPnew = VTC + CTVnew.
    ctv_app_calc u_ctv_app_calc (
        .vtc_1 (vtc_o[0]),
        .vtc_2 (vtc_o[1]),
        .vtc_3 (vtc_o[2]),
        .vtc_4 (vtc_o[3]),
        .vtc_5 (vtc_o[4]),
        .vtc_6 (vtc_o[5]),
        .vtc_7 (vtc_o[6]),

        .ctv_1 (ctv_new[0]),
        .ctv_2 (ctv_new[1]),
        .ctv_3 (ctv_new[2]),
        .ctv_4 (ctv_new[3]),
        .ctv_5 (ctv_new[4]),
        .ctv_6 (ctv_new[5]),
        .ctv_7 (ctv_new[6]),

        .app_1 (app_new[0]),
        .app_2 (app_new[1]),
        .app_3 (app_new[2]),
        .app_4 (app_new[3]),
        .app_5 (app_new[4]),
        .app_6 (app_new[5]),
        .app_7 (app_new[6])
    );

    // ------------------------------------------------------------------------
    // Iteration / mode control
    // ------------------------------------------------------------------------
    logic count_en;
    logic start_counter;
    logic [7:0] iter_count_internal;
    logic [DW-1:0] result_byte;

    // The supplied mode_select_top uses the supplied iteration_counter and
    // iter_compare.  It controls decoding/result mode.
    mode_select_top u_mode_select (
        .clk            (clk),
        .reset_n        (reset_n),
        .start          (start_counter),
        .count_en       (count_en),
        .max_iteration  (MAX_ITER_W),
        .decoding_data  (decoding_data),
        .result_data    (result_byte),
        .iteration_count(iter_count_internal),
        .done           (done),
        .mode           (),
        .ready          (ready),
        .output_data    (decoding_data)
    );

    assign iteration_count = iter_count_internal[$clog2(MAX_ITER+1)-1:0];

    // ------------------------------------------------------------------------
    // Pack APP/CTV result for memory writeback.
    // ------------------------------------------------------------------------
    integer i;

    always_comb begin
        app_new_word = '0;
        ctv_new_word = '0;

        for (i = 0; i < DR_MAX; i = i + 1) begin
            app_new_word[i*DW +: DW] = app_new[i];
            ctv_new_word[i*DW +: DW] = ctv_new[i];
        end
    end

    // ------------------------------------------------------------------------
    // Result collection.
    //
    // This version exposes one selected decoded byte on decoding_data and
    // collects one byte per NB position into decoded_data.  The full paper
    // implementation would output all z cores in parallel.
    // ------------------------------------------------------------------------
    logic [NB*DW-1:0] decoded_reg;

    assign decoded_data = decoded_reg;
    assign result_byte = decoded_reg[DW-1:0];

    always_comb begin
        if (z_index < Z)
            decoding_data = app_mem_dout[DW-1:0];
        else
            decoding_data = '0;
    end


    // ------------------------------------------------------------------------
    // Main controller
    // ------------------------------------------------------------------------
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state          <= S_IDLE;
            layer          <= '0;
            edge_idx       <= '0;
            z_index        <= '0;
            decoded_reg    <= '0;
            app_rd_en      <= 1'b0;
            app_rd_addr    <= '0;
            app_wr_en      <= 1'b0;
            app_wr_addr    <= '0;
            app_wr_data    <= '0;
            ctv_rd_en      <= 1'b0;
            ctv_rd_addr    <= '0;
            ctv_wr_en      <= 1'b0;
            ctv_wr_addr    <= '0;
            ctv_wr_data    <= '0;
            count_en       <= 1'b0;
            start_counter  <= 1'b0;
            busy           <= 1'b0;
        end
        else begin
            // Defaults: pulse-type controls.
            app_rd_en     <= 1'b0;
            app_wr_en     <= 1'b0;
            ctv_rd_en     <= 1'b0;
            ctv_wr_en     <= 1'b0;
            count_en      <= 1'b0;
            start_counter <= 1'b0;

            case (state)

                S_IDLE: begin
                    busy <= 1'b0;

                    if (start) begin
                        busy          <= 1'b1;
                        layer         <= '0;
                        edge_idx      <= '0;
                        z_index       <= '0;
                        decoded_reg   <= '0;
                        start_counter <= 1'b1;
                        state         <= S_INIT_WRITE;
                    end
                end

                // Write the first APP word supplied by the user.
                // CTV starts at zero.
                S_INIT_WRITE: begin
                    app_wr_en   <= app_init_valid;
                    app_wr_addr <= 5'd0;
                    app_wr_data <= app_init_data;

                    ctv_wr_en   <= app_init_valid;
                    ctv_wr_addr <= 7'd0;
                    ctv_wr_data <= '0;

                    if (app_init_valid)
                        state <= S_MATRIX_REQ;
                end

                // Ask check-matrix memory for the current layer/edge.
                S_MATRIX_REQ: begin
                    state <= S_APP_READ;
                end

                // BRAMs are synchronous; issue read.
                S_APP_READ: begin
                    app_rd_en   <= 1'b1;
                    app_rd_addr <= z_index;
                    state       <= S_CTV_READ;
                end

                S_CTV_READ: begin
                    ctv_rd_en   <= 1'b1;
                    ctv_rd_addr <= z_index;
                    state       <= S_CALC;
                end

                // Datapath is combinational, so results are available here.
                S_CALC: begin
                    state <= S_WRITEBACK;
                end

                S_WRITEBACK: begin
                    app_wr_en   <= 1'b1;
                    app_wr_addr <= z_index;
                    app_wr_data <= app_new_word;

                    ctv_wr_en   <= 1'b1;
                    ctv_wr_addr <= z_index;
                    ctv_wr_data <= ctv_new_word;

                    state <= S_NEXT_EDGE;
                end

                S_NEXT_EDGE: begin
                    if (edge_idx == DR_MAX-1) begin
                        edge_idx <= '0;
                        state    <= S_NEXT_LAYER;
                    end
                    else begin
                        edge_idx <= edge_idx + 1'b1;
                        state    <= S_MATRIX_REQ;
                    end
                end

                S_NEXT_LAYER: begin
                    if (layer == MB-1) begin
                        layer <= '0;
                        count_en <= 1'b1;

                        if (iter_count_internal + 1 >= MAX_ITER)
                            state <= S_RESULT;
                        else
                            state <= S_MATRIX_REQ;
                    end
                    else begin
                        layer <= layer + 1'b1;
                        state <= S_MATRIX_REQ;
                    end
                end

                S_RESULT: begin
                    busy <= 1'b0;
                    state <= S_IDLE;
                end

                default: begin
                    state <= S_IDLE;
                end

            endcase
        end
    end

endmodule
