//============================================================================
//  ldpc_pkg.sv
//  Goi tham so toan cuc cho bo giai ma QC-LDPC (min-sum, layered)
//  Tham chieu: R. Goriushkin et al., "FPGA Implementation of LDPC Decoder
//              Architecture for Wireless Communication Standards", MOCAST 2021
//
//  Thiet ke duoc tham so hoa: doi Z / MB / NB / DW + file .mem cua ma tran
//  co so la co the tai su dung cho mot cau hinh WiMAX / WiFi khac.
//============================================================================
`ifndef LDPC_PKG_SV
`define LDPC_PKG_SV

package ldpc_pkg;

  //--------------------------------------------------------------------------
  // Tham so cau hinh ma
  //--------------------------------------------------------------------------
  parameter int Z       = 24;   // kich thuoc circulant z (802.16e: 24..96)
  parameter int Z0      = 96;   // circulant goc cua bang ma tran co so
  parameter int NB      = 24;   // so cot khoi cua Hb
  parameter int MB      = 12;   // so hang khoi cua Hb (rate 1/2)
  parameter int DW      = 6;    // do rong du lieu mem (LLR / APP / CTV / VTC)
  parameter int DR_MAX  = 8;    // so dau vao khoi min/submin (Fig.2 = 8)
  parameter int ALPHA_W = 5;    // alpha bieu dien dang Q1.4  (alpha = A/16)
  parameter int ITER_W  = 5;    // do rong bo dem so vong lap

  //--------------------------------------------------------------------------
  // Tham so dan xuat
  //--------------------------------------------------------------------------
  localparam int N     = Z * NB;              // do dai tu ma
  localparam int M     = Z * MB;              // so nut kiem tra
  localparam int KINFO = N - M;               // so bit tin (rate 1/2)

  localparam int NB_W  = (NB > 1) ? $clog2(NB) : 1;
  localparam int MB_W  = (MB > 1) ? $clog2(MB) : 1;
  localparam int Z_W   = (Z  > 1) ? $clog2(Z)  : 1;
  localparam int DRW   = $clog2(DR_MAX + 1);  // do rong rowWeight (0..DR_MAX)
  localparam int IDXW  = $clog2(DR_MAX);      // chi so dau vao min
  localparam int MAGW  = DW - 1;              // do rong modulo (|x|)

  localparam int CTV_DEPTH = MB * DR_MAX;     // so o nho CTV cho moi lane z
  localparam int CTV_AW    = $clog2(CTV_DEPTH);

  //--------------------------------------------------------------------------
  // Hang so bao hoa
  //--------------------------------------------------------------------------
  localparam int DMAX_I = (2 ** (DW - 1)) - 1;
  localparam int DMIN_I = -(2 ** (DW - 1));
  localparam int MAGMAX_I = (2 ** MAGW) - 1;

  localparam logic signed [DW-1:0]  DMAX   = DMAX_I[DW-1:0];
  localparam logic signed [DW-1:0]  DMIN   = DMIN_I[DW-1:0];
  localparam logic        [MAGW-1:0] MAGMAX = MAGMAX_I[MAGW-1:0];

  // Ma hoa "-1" trong file .mem cua ma tran co so
  localparam logic [7:0] HB_NEG = 8'hFF;

  //--------------------------------------------------------------------------
  // Ham cong / tru bao hoa (saturating)
  //--------------------------------------------------------------------------
  function automatic logic signed [DW-1:0] sat_add
    (input logic signed [DW-1:0] a, input logic signed [DW-1:0] b);
    int s;
    begin
      s = $signed(a) + $signed(b);
      if (s > DMAX_I)      sat_add = DMAX;
      else if (s < DMIN_I) sat_add = DMIN;
      else                 sat_add = s[DW-1:0];
    end
  endfunction

  function automatic logic signed [DW-1:0] sat_sub
    (input logic signed [DW-1:0] a, input logic signed [DW-1:0] b);
    int s;
    begin
      s = $signed(a) - $signed(b);
      if (s > DMAX_I)      sat_sub = DMAX;
      else if (s < DMIN_I) sat_sub = DMIN;
      else                 sat_sub = s[DW-1:0];
    end
  endfunction

  // |x| co bao hoa (tranh tran khi x = -2^(DW-1))
  function automatic logic [MAGW-1:0] sat_abs (input logic signed [DW-1:0] a);
    int t;
    begin
      t = ($signed(a) < 0) ? -$signed(a) : $signed(a);
      if (t > MAGMAX_I) sat_abs = MAGMAX;
      else              sat_abs = t[MAGW-1:0];
    end
  endfunction

  // Quyet dinh cung theo (3): x_n = 0 khi Lambda_n > 0, nguoc lai x_n = 1
  function automatic logic hard_bit (input logic signed [DW-1:0] a);
    hard_bit = ($signed(a) > 0) ? 1'b0 : 1'b1;
  endfunction

endpackage : ldpc_pkg

`endif
