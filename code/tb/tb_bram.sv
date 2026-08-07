//============================================================================
//  tb_bram.sv -- Kiem tra BRAM APP va BRAM CTV
//  Bao phu:
//   1. Ghi/doc toan bo dia chi (do tre doc = 1 chu ky)
//   2. Ghi va doc dong thoi tren hai cong khac dia chi (dual-port)
//   3. Kiem tra khong ghi khi we = 0 (giu nguyen noi dung)
//   4. Mau du lieu bien: toan 0, toan 1, ngau nhien
//============================================================================
`timescale 1ns/1ps
import ldpc_pkg::*;

module tb_bram;

  localparam int W = Z*DW;

  logic clk = 0;
  always #5 clk = ~clk;

  // ---- BRAM APP ----
  logic           a_en, b_we;
  logic [NB_W-1:0] a_addr, b_addr;
  logic [W-1:0]   a_dout, b_din;

  bram_app #(.DEPTH(NB), .WIDTH(W)) u_app (
    .clk(clk), .a_en(a_en), .a_addr(a_addr), .a_dout(a_dout),
    .b_we(b_we), .b_addr(b_addr), .b_din(b_din));

  // ---- BRAM CTV ----
  logic              c_rd_en, c_wr_en;
  logic [CTV_AW-1:0] c_rd_addr, c_wr_addr;
  logic [W-1:0]      c_rd_data, c_wr_data;

  bram_ctv #(.DEPTH(CTV_DEPTH), .WIDTH(W)) u_ctv (
    .clk(clk), .rd_en(c_rd_en), .rd_addr(c_rd_addr), .rd_data(c_rd_data),
    .wr_en(c_wr_en), .wr_addr(c_wr_addr), .wr_data(c_wr_data));

  logic [W-1:0] ref_app [0:NB-1];
  logic [W-1:0] ref_ctv [0:CTV_DEPTH-1];
  int errors = 0, nvec = 0;

  task automatic wr_app(input int addr, input logic [W-1:0] d);
    begin
      @(negedge clk); b_we = 1; b_addr = addr[NB_W-1:0]; b_din = d;
      @(negedge clk); b_we = 0;
      ref_app[addr] = d;
    end
  endtask

  task automatic rd_app_chk(input int addr);
    begin
      @(negedge clk); a_en = 1; a_addr = addr[NB_W-1:0];
      @(negedge clk); a_en = 0;
      nvec++;
      if (a_dout !== ref_app[addr]) begin
        $display("FAIL APP addr %0d got %h exp %h", addr, a_dout, ref_app[addr]); errors++;
      end
    end
  endtask

  task automatic wr_ctv(input int addr, input logic [W-1:0] d);
    begin
      @(negedge clk); c_wr_en = 1; c_wr_addr = addr[CTV_AW-1:0]; c_wr_data = d;
      @(negedge clk); c_wr_en = 0;
      ref_ctv[addr] = d;
    end
  endtask

  task automatic rd_ctv_chk(input int addr);
    begin
      @(negedge clk); c_rd_en = 1; c_rd_addr = addr[CTV_AW-1:0];
      @(negedge clk); c_rd_en = 0;
      nvec++;
      if (c_rd_data !== ref_ctv[addr]) begin
        $display("FAIL CTV addr %0d got %h exp %h", addr, c_rd_data, ref_ctv[addr]); errors++;
      end
    end
  endtask

  logic [W-1:0] tmp;

  initial begin
    a_en = 0; b_we = 0; c_rd_en = 0; c_wr_en = 0;
    a_addr = 0; b_addr = 0; b_din = 0;
    c_rd_addr = 0; c_wr_addr = 0; c_wr_data = 0;
    @(negedge clk);

    // 1. ghi/doc toan bo dia chi APP
    for (int i = 0; i < NB; i++) begin
      tmp = '0;
      for (int k = 0; k < Z; k++) tmp[k*DW +: DW] = $urandom_range(0,(2**DW)-1);
      wr_app(i, tmp);
    end
    for (int i = 0; i < NB; i++) rd_app_chk(i);

    // mau bien
    wr_app(0, '0);              rd_app_chk(0);
    wr_app(NB-1, {W{1'b1}});    rd_app_chk(NB-1);

    // 3. we = 0 khong duoc thay doi noi dung
    @(negedge clk); b_we = 0; b_addr = 0; b_din = {W{1'b1}};
    @(negedge clk);
    rd_app_chk(0);

    // 2. ghi cong B va doc cong A dong thoi (khac dia chi)
    @(negedge clk);
    b_we = 1; b_addr = 5; b_din = {W{1'b1}};
    a_en = 1; a_addr = 7;
    @(negedge clk);
    b_we = 0; a_en = 0;
    ref_app[5] = {W{1'b1}};
    nvec++;
    if (a_dout !== ref_app[7]) begin
      $display("FAIL dual-port doc dong thoi"); errors++;
    end
    rd_app_chk(5);

    // 1b. BRAM CTV toan bo dia chi
    for (int i = 0; i < CTV_DEPTH; i++) begin
      tmp = '0;
      for (int k = 0; k < Z; k++) tmp[k*DW +: DW] = $urandom_range(0,(2**DW)-1);
      wr_ctv(i, tmp);
    end
    for (int i = 0; i < CTV_DEPTH; i++) rd_ctv_chk(i);

    // 2b. CTV ghi va doc dong thoi khac dia chi
    @(negedge clk);
    c_wr_en = 1; c_wr_addr = 3; c_wr_data = '0;
    c_rd_en = 1; c_rd_addr = 9;
    @(negedge clk);
    c_wr_en = 0; c_rd_en = 0;
    ref_ctv[3] = '0;
    nvec++;
    if (c_rd_data !== ref_ctv[9]) begin $display("FAIL CTV doc/ghi dong thoi"); errors++; end
    rd_ctv_chk(3);

    if (errors == 0) $display("[tb_bram] PASS - %0d phep doc kiem tra", nvec);
    else             $display("[tb_bram] FAIL - %0d loi", errors);
    $finish;
  end
endmodule
