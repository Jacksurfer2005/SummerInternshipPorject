//============================================================================
//  tb_ctrl.sv -- Kiem tra Iterations counter va Operating mode selection
//  Bao phu iter_counter:
//   1. Dem den max_iter voi moi max_iter = 1..16
//   2. Dung som khi converged = 1
//   3. clear giua chung dat lai bo dem va done
//   4. reset bat dong bo
//  Bao phu mode_select:
//   5. VET CAN quyet dinh cung cho moi gia tri APP (Lambda > 0 -> 0)
//   6. Gating cua READY / out_valid theo mode_out va blk_valid
//============================================================================
`timescale 1ns/1ps
import ldpc_pkg::*;

module tb_ctrl;

  logic clk = 0, rst_n;
  always #5 clk = ~clk;

  logic clear, iter_done, converged;
  logic [ITER_W-1:0] max_iter, iter_cnt;
  logic done;
  int errors = 0;

  iter_counter #(.EARLY_TERM(1)) u_ic (
    .clk(clk), .rst_n(rst_n), .clear(clear), .iter_done(iter_done),
    .converged(converged), .max_iter(max_iter), .iter_cnt(iter_cnt), .done(done));

  logic                mode_out, blk_valid, ready, out_valid;
  logic [Z*DW-1:0]     app_word;
  logic [Z-1:0]        out_bits;

  mode_select #(.LANES(Z)) u_ms (
    .mode_out(mode_out), .blk_valid(blk_valid), .app_word(app_word),
    .ready(ready), .out_valid(out_valid), .out_bits(out_bits));

  task automatic pulse_iter(input logic conv);
    begin
      converged = conv;
      @(negedge clk); iter_done = 1;
      @(negedge clk); iter_done = 0;
    end
  endtask

  int exp_bit;

  initial begin
    rst_n = 0; clear = 0; iter_done = 0; converged = 0; max_iter = 5;
    mode_out = 0; blk_valid = 0; app_word = '0;
    @(negedge clk);
    // 4. reset
    if (iter_cnt !== 0 || done !== 0) begin $display("FAIL reset"); errors++; end
    rst_n = 1;
    @(negedge clk);

    // 1. dem den max_iter (khong hoi tu)
    for (int mi = 1; mi <= 16; mi++) begin
      clear = 1; @(negedge clk); clear = 0;
      max_iter = mi[ITER_W-1:0];
      for (int k = 1; k <= mi; k++) begin
        pulse_iter(1'b0);
        if (k < mi && done !== 1'b0) begin
          $display("FAIL done som: max=%0d k=%0d", mi, k); errors++;
        end
        if (iter_cnt !== k[ITER_W-1:0]) begin
          $display("FAIL iter_cnt: max=%0d k=%0d got %0d", mi, k, iter_cnt); errors++;
        end
      end
      if (done !== 1'b1) begin $display("FAIL khong done tai max=%0d", mi); errors++; end
    end

    // 2. dung som
    clear = 1; @(negedge clk); clear = 0;
    max_iter = 10;
    pulse_iter(1'b1);
    if (done !== 1'b1) begin $display("FAIL khong dung som khi converged"); errors++; end
    if (iter_cnt !== 1) begin $display("FAIL iter_cnt khi dung som"); errors++; end

    // 3. clear dat lai
    clear = 1; @(negedge clk); clear = 0; @(negedge clk);
    if (done !== 1'b0 || iter_cnt !== 0) begin $display("FAIL clear"); errors++; end

    //------------------------------------------------------------------
    // 5. quyet dinh cung: vet can gia tri APP tren lane 0
    //------------------------------------------------------------------
    mode_out = 1; blk_valid = 1;
    for (int v = DMIN_I; v <= DMAX_I; v++) begin
      app_word = '0;
      app_word[0 +: DW] = v[DW-1:0];
      #1;
      exp_bit = (v > 0) ? 0 : 1;
      if (out_bits[0] !== exp_bit[0]) begin
        $display("FAIL hard bit: APP=%0d got %b exp %b", v, out_bits[0], exp_bit[0]); errors++;
      end
      if (out_bits[1] !== 1'b1) begin // lane khac = 0 -> bit 1
        $display("FAIL hard bit lane 0-value"); errors++;
      end
    end

    // 6. gating
    mode_out = 0; blk_valid = 1; #1;
    if (ready !== 0 || out_valid !== 0) begin $display("FAIL gating mode_out=0"); errors++; end
    mode_out = 1; blk_valid = 0; #1;
    if (ready !== 1 || out_valid !== 0) begin $display("FAIL gating blk_valid=0"); errors++; end
    mode_out = 1; blk_valid = 1; #1;
    if (ready !== 1 || out_valid !== 1) begin $display("FAIL gating ca hai = 1"); errors++; end

    if (errors == 0) $display("[tb_ctrl] PASS - iter_counter + mode_select");
    else             $display("[tb_ctrl] FAIL - %0d loi", errors);
    $finish;
  end
endmodule
