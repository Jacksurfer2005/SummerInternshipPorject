//============================================================================
//  ldpc_decoder_top.sv -- Cau truc tong the cua bo giai ma LDPC (Figure 1)
//
//  Kien truc: giai ma min-sum theo lop (layered), z core song song.
//    - BRAM APP                    : bo nho xac suat hau nghiem, K = N/z khoi
//    - Operating mode selection    : chuyen "decoding" <-> "result output"
//    - VTC calculation             : (5) VTC = APP - CTV
//    - Min/submin calculation      : Figure 2
//    - CTV and APP calculation     : (6), (7)
//    - BRAM CTV                    : L = MB*DR_MAX o nho x z lane
//    - Iterations counter          : dieu khien ket thuc
//    - Memory for check matrix     : h_rom (vals / pos / elementSize)
//
//  Giao dien:
//    Nap du lieu : moi nhip nhan mot khoi z LLR mem (z*DW bit), tong NB nhip.
//    Xuat ket qua: moi nhip mot khoi z bit quyet dinh cung, tong NB nhip,
//                  READY giu muc cao trong suot che do xuat ket qua.
//
//  So chu ky mot lop = d_r (doc) + 1 (xa duong ong) + 1 (CNU) + d_r (ghi)
//============================================================================
`timescale 1ns/1ps

import ldpc_pkg::*;

module ldpc_decoder_top
#(
  parameter     INIT_FILE  = "h_base.mem",
  parameter bit EARLY_TERM = 1
)(
  input  logic                clk,
  input  logic                rst_n,

  // --- nap LLR tu bo giai dieu che (DATA) ---
  input  logic                in_valid,
  output logic                in_ready,
  input  logic [Z*DW-1:0]     in_data,     // z gia tri LLR mem, moi cai DW bit

  // --- cau hinh ---
  input  logic [ALPHA_W-1:0]  alpha,       // ALPHA (Q1.4, 12 = 0.75)
  input  logic [ITER_W-1:0]   max_iter,

  // --- ket qua ---
  output logic                ready,       // READY
  output logic                out_valid,
  output logic [Z-1:0]        out_bits,    // OUT
  output logic                busy,
  output logic [ITER_W-1:0]   iter_cnt,
  output logic                converged
);

  //--------------------------------------------------------------------------
  // May trang thai
  //--------------------------------------------------------------------------
  typedef enum logic [2:0] {
    S_LOAD    = 3'd0,
    S_READ    = 3'd1,
    S_CNU     = 3'd2,
    S_WRITE   = 3'd3,
    S_ITER    = 3'd4,
    S_ITERCHK = 3'd5,
    S_OUT     = 3'd6
  } state_e;

  state_e state;

  //--------------------------------------------------------------------------
  // Bo dem / thanh ghi dieu khien
  //--------------------------------------------------------------------------
  logic [NB_W:0]    blk_cnt;      // dem khoi khi nap
  logic [MB_W-1:0]  layer;        // hang khoi hien tai
  logic [DRW-1:0]   j;            // chi so canh trong hang
  logic [DRW-1:0]   cap_cnt;      // so VTC da lay ve
  logic             rd_v;         // co du lieu doc hop le o chu ky sau
  logic [DRW-1:0]   j_d;
  logic [Z_W-1:0]   shift_d;
  logic             first_iter;   // vong lap dau -> CTV = 0
  logic             iter_fail;    // co hang nao sai syndrome trong vong lap
  logic [Z-1:0]     synd_acc;     // syndrome cua lop hien tai
  logic [NB_W:0]    out_issue, out_cap;
  logic             out_v;

  //--------------------------------------------------------------------------
  // ROM ma tran kiem tra
  //--------------------------------------------------------------------------
  logic [DRW-1:0]  rw;
  logic [NB_W-1:0] col_pos;
  logic [Z_W-1:0]  shift_cur;
  logic            edge_valid;

  h_rom #(.INIT_FILE(INIT_FILE)) u_hrom (
    .layer      (layer),
    .idx        (j),
    .row_weight (rw),
    .col_pos    (col_pos),
    .shift      (shift_cur),
    .edge_valid (edge_valid));

  //--------------------------------------------------------------------------
  // BRAM APP  (K = NB khoi, moi khoi z*DW bit)
  //--------------------------------------------------------------------------
  logic               app_a_en, app_b_we;
  logic [NB_W-1:0]    app_a_addr, app_b_addr;
  logic [Z*DW-1:0]    app_a_dout, app_b_din;

  bram_app #(.DEPTH(NB), .WIDTH(Z*DW)) u_bram_app (
    .clk    (clk),
    .a_en   (app_a_en),
    .a_addr (app_a_addr),
    .a_dout (app_a_dout),
    .b_we   (app_b_we),
    .b_addr (app_b_addr),
    .b_din  (app_b_din));

  //--------------------------------------------------------------------------
  // BRAM CTV
  //--------------------------------------------------------------------------
  logic               ctv_rd_en, ctv_wr_en;
  logic [CTV_AW-1:0]  ctv_rd_addr, ctv_wr_addr;
  logic [Z*DW-1:0]    ctv_rd_data, ctv_wr_data;

  bram_ctv #(.DEPTH(CTV_DEPTH), .WIDTH(Z*DW)) u_bram_ctv (
    .clk     (clk),
    .rd_en   (ctv_rd_en),
    .rd_addr (ctv_rd_addr),
    .rd_data (ctv_rd_data),
    .wr_en   (ctv_wr_en),
    .wr_addr (ctv_wr_addr),
    .wr_data (ctv_wr_data));

  //--------------------------------------------------------------------------
  // Duong du lieu doc: dich vong -> VTC = APP - CTV
  //--------------------------------------------------------------------------
  logic [Z*DW-1:0] app_sh, ctv_old, vtc_comb;
  logic [Z-1:0]    hard_sh;

  barrel_shifter #(.LANES(Z), .LW(DW), .SW(Z_W)) u_bs_rd (
    .din(app_a_dout), .shift(shift_d), .dir(1'b0), .dout(app_sh));

  assign ctv_old = first_iter ? {(Z*DW){1'b0}} : ctv_rd_data;

  vtc_calc #(.LANES(Z)) u_vtc (
    .app_i(app_sh), .ctv_i(ctv_old), .vtc_o(vtc_comb));

  always_comb begin
    for (int i = 0; i < Z; i++)
      hard_sh[i] = ldpc_pkg::hard_bit($signed(app_sh[i*DW +: DW]));
  end

  //--------------------------------------------------------------------------
  // Tap thanh ghi VTC / CTV_new cua lop hien tai
  //--------------------------------------------------------------------------
  logic [Z*DW-1:0] vtc_reg     [0:DR_MAX-1];
  logic [Z*DW-1:0] ctv_new_reg [0:DR_MAX-1];
  logic [Z*DW-1:0] ctv_new_cmb [0:DR_MAX-1];

  //--------------------------------------------------------------------------
  // z CORE song song (moi core = 1 check node unit, Figure 3)
  //--------------------------------------------------------------------------
  genvar gi, gj;
  generate
    for (gi = 0; gi < Z; gi++) begin : g_core
      logic [DR_MAX*DW-1:0] vtc_lane;
      logic [DR_MAX*DW-1:0] ctv_lane;

      always_comb begin
        for (int k = 0; k < DR_MAX; k++)
          vtc_lane[k*DW +: DW] = vtc_reg[k][gi*DW +: DW];
      end

      ldpc_core u_core (
        .vtc_i       (vtc_lane),
        .row_weight  (rw),
        .alpha       (alpha),
        .ctv_o       (ctv_lane),
        .min_o       (),
        .submin_o    (),
        .sign_prod_o ());

      for (gj = 0; gj < DR_MAX; gj++) begin : g_scatter
        assign ctv_new_cmb[gj][gi*DW +: DW] = ctv_lane[gj*DW +: DW];
      end
    end
  endgenerate

  //--------------------------------------------------------------------------
  // Duong du lieu ghi: APP_new = VTC + CTV_new -> dich nguoc
  //--------------------------------------------------------------------------
  logic [Z*DW-1:0] app_new, app_new_sh;
  logic [Z*DW-1:0] vtc_sel, ctv_sel;
  logic [CTV_AW-1:0] ctv_addr;

  always_comb begin
    vtc_sel  = vtc_reg[j];
    ctv_sel  = ctv_new_reg[j];
    ctv_addr = (layer * DR_MAX + j);
  end

  app_calc #(.LANES(Z)) u_app (
    .vtc_i(vtc_sel), .ctv_i(ctv_sel), .app_o(app_new));

  barrel_shifter #(.LANES(Z), .LW(DW), .SW(Z_W)) u_bs_wr (
    .din(app_new), .shift(shift_cur), .dir(1'b1), .dout(app_new_sh));

  //--------------------------------------------------------------------------
  // Bo dem vong lap
  //--------------------------------------------------------------------------
  logic iter_clear, iter_pulse, dec_done;

  iter_counter #(.EARLY_TERM(EARLY_TERM)) u_iter (
    .clk       (clk),
    .rst_n     (rst_n),
    .clear     (iter_clear),
    .iter_done (iter_pulse),
    .converged (~iter_fail),
    .max_iter  (max_iter),
    .iter_cnt  (iter_cnt),
    .done      (dec_done));

  assign iter_clear = (state == S_LOAD) && in_valid && (blk_cnt == NB-1);
  assign iter_pulse = (state == S_ITER);
  assign converged  = ~iter_fail;

  //--------------------------------------------------------------------------
  // Operating mode selection
  //--------------------------------------------------------------------------
  mode_select #(.LANES(Z)) u_mode (
    .mode_out  (state == S_OUT),
    .blk_valid (out_v),
    .app_word  (app_a_dout),
    .ready     (ready),
    .out_valid (out_valid),
    .out_bits  (out_bits));

  assign in_ready = (state == S_LOAD);
  assign busy     = (state != S_LOAD);

  //--------------------------------------------------------------------------
  // Dieu khien to hop cho bo nho
  //--------------------------------------------------------------------------
  always_comb begin
    app_a_en    = 1'b0;
    app_a_addr  = '0;
    app_b_we    = 1'b0;
    app_b_addr  = '0;
    app_b_din   = '0;
    ctv_rd_en   = 1'b0;
    ctv_rd_addr = '0;
    ctv_wr_en   = 1'b0;
    ctv_wr_addr = '0;
    ctv_wr_data = '0;

    case (state)
      S_LOAD: begin
        app_b_we   = in_valid;
        app_b_addr = blk_cnt[NB_W-1:0];
        app_b_din  = in_data;
      end
      S_READ: begin
        if (j < rw) begin
          app_a_en    = 1'b1;
          app_a_addr  = col_pos;
          ctv_rd_en   = 1'b1;
          ctv_rd_addr = ctv_addr;
        end
      end
      S_WRITE: begin
        app_b_we    = 1'b1;
        app_b_addr  = col_pos;
        app_b_din   = app_new_sh;
        ctv_wr_en   = 1'b1;
        ctv_wr_addr = ctv_addr;
        ctv_wr_data = ctv_sel;
      end
      S_OUT: begin
        if (out_issue < NB) begin
          app_a_en   = 1'b1;
          app_a_addr = out_issue[NB_W-1:0];
        end
      end
      default: ;
    endcase
  end

  //--------------------------------------------------------------------------
  // May trang thai tuan tu
  //--------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state      <= S_LOAD;
      blk_cnt    <= '0;
      layer      <= '0;
      j          <= '0;
      cap_cnt    <= '0;
      rd_v       <= 1'b0;
      j_d        <= '0;
      shift_d    <= '0;
      first_iter <= 1'b1;
      iter_fail  <= 1'b0;
      synd_acc   <= '0;
      out_issue  <= '0;
      out_cap    <= '0;
      out_v      <= 1'b0;
      for (int k = 0; k < DR_MAX; k++) begin
        vtc_reg[k]     <= '0;
        ctv_new_reg[k] <= '0;
      end
    end else begin
      case (state)
        //--------------------------------------------------------------
        S_LOAD: begin
          out_v <= 1'b0;
          if (in_valid) begin
            if (blk_cnt == NB-1) begin
              blk_cnt    <= '0;
              layer      <= '0;
              j          <= '0;
              cap_cnt    <= '0;
              rd_v       <= 1'b0;
              first_iter <= 1'b1;
              iter_fail  <= 1'b0;
              synd_acc   <= '0;
              state      <= S_READ;
            end else begin
              blk_cnt <= blk_cnt + 1'b1;
            end
          end
        end

        //--------------------------------------------------------------
        // Doc APP + CTV, tinh VTC (mot canh moi chu ky)
        //--------------------------------------------------------------
        S_READ: begin
          if (rd_v) begin
            vtc_reg[j_d] <= vtc_comb;
            synd_acc     <= synd_acc ^ hard_sh;
            cap_cnt      <= cap_cnt + 1'b1;
            if (cap_cnt == rw - 1) state <= S_CNU;
          end
          if (j < rw) begin
            rd_v    <= 1'b1;
            j_d     <= j;
            shift_d <= shift_cur;
            j       <= j + 1'b1;
          end else begin
            rd_v <= 1'b0;
          end
        end

        //--------------------------------------------------------------
        // Tinh CTV moi cho ca lop (z core chay dong thoi)
        //--------------------------------------------------------------
        S_CNU: begin
          for (int k = 0; k < DR_MAX; k++) ctv_new_reg[k] <= ctv_new_cmb[k];
          if (|synd_acc) iter_fail <= 1'b1;
          synd_acc <= '0;
          j        <= '0;
          cap_cnt  <= '0;
          rd_v     <= 1'b0;
          state    <= S_WRITE;
        end

        //--------------------------------------------------------------
        // Ghi nguoc APP_new va CTV_new (mot canh moi chu ky)
        //--------------------------------------------------------------
        S_WRITE: begin
          if (j == rw - 1) begin
            j <= '0;
            if (layer == MB-1) begin
              layer <= '0;
              state <= S_ITER;
            end else begin
              layer <= layer + 1'b1;
              state <= S_READ;
            end
          end else begin
            j <= j + 1'b1;
          end
        end

        //--------------------------------------------------------------
        S_ITER: begin
          state <= S_ITERCHK;
        end

        S_ITERCHK: begin
          if (dec_done) begin
            out_issue <= '0;
            out_cap   <= '0;
            out_v     <= 1'b0;
            state     <= S_OUT;
          end else begin
            first_iter <= 1'b0;
            iter_fail  <= 1'b0;
            layer      <= '0;
            j          <= '0;
            cap_cnt    <= '0;
            rd_v       <= 1'b0;
            synd_acc   <= '0;
            state      <= S_READ;
          end
        end

        //--------------------------------------------------------------
        // Xuat ket qua: NB khoi x z bit
        //--------------------------------------------------------------
        S_OUT: begin
          if (out_issue < NB) begin
            out_issue <= out_issue + 1'b1;
            out_v     <= 1'b1;
          end else begin
            out_v <= 1'b0;
          end
          if (out_v) begin
            out_cap <= out_cap + 1'b1;
            if (out_cap == NB-1) begin
              out_v      <= 1'b0;
              blk_cnt    <= '0;
              first_iter <= 1'b1;
              state      <= S_LOAD;
            end
          end
        end

        default: state <= S_LOAD;
      endcase
    end
  end

endmodule
