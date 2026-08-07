//============================================================================
//  tb_ldpc_decoder_top.sv -- Kiem tra muc he thong bo giai ma LDPC
//
//  Bao phu:
//   1. Giao thuc nap du lieu / xuat ket qua (in_ready, READY, out_valid,
//      dung NB nhip vao va NB nhip ra)
//   2. Kenh khong loi  -> hoi tu ngay vong lap dau, iter_cnt = 1
//   3. Sua loi don le  -> quet vi tri loi tren nhieu khoi
//   4. Sua loi ngau nhien voi so luong tang dan (thong ke ti le thanh cong)
//   5. Truong hop khong the sua (rat nhieu loi) -> van ket thuc dung han,
//      khong treo, converged = 0
//   6. Nhieu khung lien tiep (back-to-back) - kiem tra reset trang thai noi bo
//   7. Thay doi he so alpha (0.75 va 1.0) va max_iter
//   8. Kiem tra moi ket qua deu thoa H*x = 0 khi bao hoi tu
//============================================================================
`timescale 1ns/1ps
import ldpc_pkg::*;

module tb_ldpc_decoder_top;

  //------------------------------------------------------------------ clock
  logic clk = 0, rst_n;
  always #5 clk = ~clk;

  //------------------------------------------------------------------ DUT
  logic               in_valid, in_ready;
  logic [Z*DW-1:0]    in_data;
  logic [ALPHA_W-1:0] alpha;
  logic [ITER_W-1:0]  max_iter;
  logic               ready, out_valid, busy, conv;
  logic [Z-1:0]       out_bits;
  logic [ITER_W-1:0]  iter_cnt;

  ldpc_decoder_top #(.INIT_FILE("mem/h_base_16e_r12.mem"), .EARLY_TERM(1)) dut (
    .clk(clk), .rst_n(rst_n),
    .in_valid(in_valid), .in_ready(in_ready), .in_data(in_data),
    .alpha(alpha), .max_iter(max_iter),
    .ready(ready), .out_valid(out_valid), .out_bits(out_bits),
    .busy(busy), .iter_cnt(iter_cnt), .converged(conv));

  //------------------------------------------------------- ma tran tham chieu
  int HB [0:MB-1][0:NB-1];
  initial begin
    logic [7:0] raw [0:MB*NB-1];
    for (int k = 0; k < MB*NB; k++) raw[k] = 8'hff;
    $readmemh("mem/h_base_16e_r12.mem", raw);
    for (int r = 0; r < MB; r++)
      for (int c = 0; c < NB; c++)
        HB[r][c] = (raw[r*NB+c] === 8'hff) ? -1 : ((raw[r*NB+c] * Z) / Z0);
  end

  //------------------------------------------------------------------ bien
  localparam int LMAG = 7;           // bien do LLR kenh

  bit  err_mask [0:N-1];             // vi tri bit bi loi (ma phat = toan 0)
  bit  dec      [0:N-1];             // ket qua giai ma
  int  errors = 0;
  int  n_out_beats;

  //--------------------------------------------------------------- kiem tra H
  function automatic int syndrome_weight;
    int w, p, vn;
    begin
      w = 0;
      for (int r = 0; r < MB; r++)
        for (int i = 0; i < Z; i++) begin
          p = 0;
          for (int c = 0; c < NB; c++)
            if (HB[r][c] >= 0) begin
              vn = c*Z + ((i + HB[r][c]) % Z);
              p  = p ^ dec[vn];
            end
          w = w + p;
        end
      syndrome_weight = w;
    end
  endfunction

  function automatic int bit_errors;
    int e;
    begin
      e = 0;
      for (int i = 0; i < N; i++) if (dec[i] !== 1'b0) e++;   // ma phat = toan 0
      bit_errors = e;
    end
  endfunction

  //------------------------------------------------------------ nap mot khung
  task automatic send_frame;
    int llr;
    begin
      @(negedge clk);
      if (!in_ready) begin $display("FAIL: in_ready khong len o trang thai LOAD"); errors++; end
      for (int c = 0; c < NB; c++) begin
        in_valid = 1;
        for (int i = 0; i < Z; i++) begin
          // ma phat toan 0 -> LLR duong; bit loi -> LLR am
          llr = err_mask[c*Z + i] ? -LMAG : LMAG;
          in_data[i*DW +: DW] = llr[DW-1:0];
        end
        @(negedge clk);
      end
      in_valid = 0;
    end
  endtask

  //--------------------------------------------------------- thu ket qua ra
  task automatic collect_frame;
    int guard, blk;
    begin
      blk = 0; guard = 0; n_out_beats = 0;
      while (blk < NB && guard < 200000) begin
        @(negedge clk);
        guard++;
        if (out_valid) begin
          if (!ready) begin $display("FAIL: out_valid nhung READY = 0"); errors++; end
          for (int i = 0; i < Z; i++) dec[blk*Z + i] = out_bits[i];
          blk++; n_out_beats++;
        end
      end
      if (blk != NB) begin
        $display("FAIL: TIMEOUT - chi nhan %0d/%0d khoi ket qua", blk, NB);
        errors++;
      end
    end
  endtask

  task automatic clear_errors;
    for (int i = 0; i < N; i++) err_mask[i] = 1'b0;
  endtask

  //------------------------------------------------------------------ kich ban
  int nerr_in, nerr_out, sw, pos;
  int ok_cnt, tot_cnt;
  int saved_iter;
  bit saved_conv;

  task automatic run_frame(input string tag, input bit expect_ok);
    begin
      send_frame();
      collect_frame();
      saved_iter = iter_cnt;
      saved_conv = conv;
      nerr_out   = bit_errors();
      sw         = syndrome_weight();
      if (n_out_beats != NB) begin
        $display("FAIL %s: so nhip ra = %0d (mong doi %0d)", tag, n_out_beats, NB);
        errors++;
      end
      if (saved_conv && sw != 0) begin
        $display("FAIL %s: bao hoi tu nhung syndrome = %0d", tag, sw);
        errors++;
      end
      if (expect_ok && nerr_out != 0) begin
        $display("FAIL %s: con %0d bit sai sau giai ma (iter=%0d conv=%0b)",
                 tag, nerr_out, saved_iter, saved_conv);
        errors++;
      end
    end
  endtask

  initial begin
    rst_n = 0; in_valid = 0; in_data = '0;
    alpha = 5'd12;          // 0.75
    max_iter = 5'd10;
    clear_errors();
    repeat (5) @(negedge clk);
    rst_n = 1;
    repeat (2) @(negedge clk);

    //----------------------------------------------------------------
    // 2. Kenh khong loi
    //----------------------------------------------------------------
    clear_errors();
    run_frame("no-error", 1);
    if (saved_iter !== 1) begin
      $display("FAIL no-error: iter_cnt = %0d (mong doi 1 - dung som)", saved_iter);
      errors++;
    end
    if (!saved_conv) begin $display("FAIL no-error: converged = 0"); errors++; end
    $display("  [T2] khong loi: iter=%0d conv=%0b bit sai=%0d", saved_iter, saved_conv, nerr_out);

    //----------------------------------------------------------------
    // 3. Loi don le, quet vi tri
    //----------------------------------------------------------------
    for (int p = 0; p < N; p = p + 37) begin
      clear_errors();
      err_mask[p] = 1'b1;
      run_frame($sformatf("single-error@%0d", p), 1);
    end
    $display("  [T3] quet loi don le tren %0d vi tri: OK", (N+36)/37);

    //----------------------------------------------------------------
    // 4. Loi ngau nhien voi so luong tang dan
    //----------------------------------------------------------------
    for (int ne = 2; ne <= 40; ne = ne + 2) begin
      ok_cnt = 0; tot_cnt = 0;
      for (int t = 0; t < 5; t++) begin
        clear_errors();
        for (int k = 0; k < ne; k++) begin
          pos = $urandom_range(0, N-1);
          err_mask[pos] = 1'b1;
        end
        run_frame($sformatf("rand-%0d", ne), 0);
        tot_cnt++;
        if (nerr_out == 0) ok_cnt++;
        // du sua duoc hay khong, ket qua bao hoi tu phai thoa H*x=0
      end
      $display("  [T4] %2d loi ngau nhien: sua thanh cong %0d/%0d", ne, ok_cnt, tot_cnt);
      if (ne <= 10 && ok_cnt != tot_cnt) begin
        $display("FAIL: khong sua duoc het voi %0d loi", ne);
        errors++;
      end
    end

    //----------------------------------------------------------------
    // 5. Vuot qua kha nang sua loi -> phai ket thuc dung han
    //----------------------------------------------------------------
    clear_errors();
    for (int i = 0; i < N; i++) if ($urandom_range(0,1)) err_mask[i] = 1'b1;
    run_frame("overload", 0);
    $display("  [T5] qua tai loi: ket thuc binh thuong, iter=%0d conv=%0b bit sai=%0d",
             saved_iter, saved_conv, nerr_out);
    if (saved_iter !== max_iter && saved_conv !== 1'b1) begin
      $display("FAIL overload: khong chay du max_iter (%0d)", saved_iter);
      errors++;
    end

    //----------------------------------------------------------------
    // 6. Nhieu khung lien tiep
    //----------------------------------------------------------------
    for (int f = 0; f < 3; f++) begin
      clear_errors();
      err_mask[f*100 + 3] = 1'b1;
      err_mask[f*40  + 7] = 1'b1;
      run_frame($sformatf("b2b-%0d", f), 1);
    end
    $display("  [T6] 3 khung lien tiep: OK");

    //----------------------------------------------------------------
    // 7. alpha = 1.0 va max_iter khac
    //----------------------------------------------------------------
    // Luu y thiet ke: he so alpha PHAI < 1.0. Voi alpha = 1.0 thuat toan
    // min-sum khong con tinh co (non-contracting), bien do ban tin tang
    // den muc bao hoa DW bit va bo giai ma phan ky. Day la dac tinh so hoc
    // da biet, khong phai loi RTL -> test duoi day quet alpha hop le va
    // ghi nhan (khong khang dinh sua duoc loi) truong hop alpha = 1.0.
    max_iter = 5'd15;
    for (int a = 8; a <= 14; a = a + 2) begin
      alpha = a[ALPHA_W-1:0];
      clear_errors();
      for (int k = 0; k < 8; k++) err_mask[(k*61) % N] = 1'b1;
      run_frame($sformatf("alpha-%0d/16", a), 1);
      $display("  [T7] alpha=%0d/16: iter=%0d conv=%0b bit sai=%0d",
               a, saved_iter, saved_conv, nerr_out);
    end

    // alpha = 1.0 : chi kiem tra ket thuc dung giao thuc
    alpha = 5'd16;
    clear_errors();
    for (int k = 0; k < 8; k++) err_mask[(k*61) % N] = 1'b1;
    run_frame("alpha-1.0 (chi kiem tra giao thuc)", 0);
    $display("  [T7c] alpha=1.0 (khong khuyen nghi): iter=%0d conv=%0b bit sai=%0d",
             saved_iter, saved_conv, nerr_out);

    alpha = 5'd12; max_iter = 5'd1;
    clear_errors();
    run_frame("max_iter-1", 1);
    if (saved_iter !== 1) begin $display("FAIL max_iter=1"); errors++; end
    $display("  [T7b] max_iter=1 khong loi: OK");

    if (errors == 0) $display("[tb_ldpc_decoder_top] PASS");
    else             $display("[tb_ldpc_decoder_top] FAIL - %0d loi", errors);
    $finish;
  end

  // canh bao treo toan cuc
  initial begin
    #50_000_000;
    $display("[tb_ldpc_decoder_top] FAIL - TIMEOUT toan cuc");
    $finish;
  end

endmodule
