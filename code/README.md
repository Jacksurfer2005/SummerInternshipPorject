# Bộ giải mã QC-LDPC trên FPGA — hiện thực SystemVerilog đầy đủ

Hiện thực RTL hoàn chỉnh, đã kiểm chứng bằng mô phỏng, của kiến trúc mô tả trong:

> R. Goriushkin, P. Nikishkin, E. Likhobabin, V. Vityazev,
> **"FPGA Implementation of LDPC Decoder Architecture for Wireless Communication Standards"**,
> 2021 10th International Conference on Modern Circuits and Systems Technologies (MOCAST),
> Ryazan State Radio Engineering University. DOI: 10.1109/MOCAST52088.2021.9493380

- Thuật toán: **min-sum có hệ số tỉ lệ** (scaled min-sum, MSA)
- Lịch cập nhật: **layered** (theo từng hàng khối của ma trận kiểm tra)
- Song song hoá: **z core** hoạt động đồng thời, đúng như mục III.B của bài báo
- Ma trận: **QC-LDPC IEEE 802.16e (WiMAX)** rate 1/2, dễ đổi sang 802.11n hoặc rate khác

---

## Mục lục

1. [Nền tảng thuật toán](#1-nền-tảng-thuật-toán)
2. [Ánh xạ bài báo → RTL](#2-ánh-xạ-bài-báo--rtl)
3. [Cấu hình và tham số](#3-cấu-hình-và-tham-số)
4. [Cây thư mục](#4-cây-thư-mục)
5. [Kiến trúc tổng thể](#5-kiến-trúc-tổng-thể)
6. [Đặc tả từng khối](#6-đặc-tả-từng-khối)
7. [Máy trạng thái và giản đồ thời gian](#7-máy-trạng-thái-và-giản-đồ-thời-gian)
8. [Giao diện `ldpc_decoder_top`](#8-giao-diện-ldpc_decoder_top)
9. [Tài nguyên và thông lượng](#9-tài-nguyên-và-thông-lượng)
10. [Cách chạy mô phỏng](#10-cách-chạy-mô-phỏng)
11. [Kế hoạch kiểm chứng chi tiết](#11-kế-hoạch-kiểm-chứng-chi-tiết)
12. [Kết quả hồi quy](#12-kết-quả-hồi-quy)
13. [Cách đổi cấu hình](#13-cách-đổi-cấu-hình)
14. [Ghi chú tổng hợp FPGA](#14-ghi-chú-tổng-hợp-fpga)
15. [Hạn chế đã biết và hướng mở rộng](#15-hạn-chế-đã-biết-và-hướng-mở-rộng)

---

## 1. Nền tảng thuật toán

### 1.1 Ký hiệu (theo mục II của bài báo)

| Ký hiệu | Ý nghĩa | Tín hiệu RTL |
|---|---|---|
| `c_n` | bit thứ *n* của từ mã | — |
| `y_n` | giá trị nhận từ kênh | — |
| `p_n` | LLR nội tại (intrinsic) của nút biến *n* | `in_data` |
| `q_mn[k]` | bản tin biến → kiểm tra (VTC) | `vtc_comb`, `vtc_reg` |
| `r_mn[k]` | bản tin kiểm tra → biến (CTV) | `ctv_new_cmb`, BRAM CTV |
| `Λ_n[k]` | xác suất hậu nghiệm APP | BRAM APP |
| `N(m)` | tập nút biến tham gia kiểm tra *m* | một hàng của Hb |
| `d_r` | trọng số hàng (row weight) | `row_weight` từ `h_rom` |
| `α` | hệ số tỉ lệ min-sum | `alpha` (Q1.4) |

### 1.2 Các công thức được hiện thực

**(1) Khởi tạo** — `p_n = log( P(y_n|c_n=0) / P(y_n|c_n=1) )`, `r_mn = 0`.

RTL: LLR được nạp từ ngoài vào BRAM APP; cờ `first_iter = 1` ép toàn bộ CTV đọc ra
về 0, tương đương khởi tạo `r_mn = 0` mà **không tốn chu kỳ xoá bộ nhớ**.

**(5) Bản tin VTC** — `VTC_n = APP_n − CTV_n`, `n = 1..d_r`

Đây là dạng rút gọn của (2): thay vì cộng dồn mọi `r_m'n` với `m' ≠ m`, ta lấy APP
hiện hành trừ đi đúng bản tin của hàng đang xét. Chính điều này làm lịch **layered**
hội tụ nhanh hơn flooding (thường nhanh gấp đôi về số vòng lặp).

**(4)/(6) Bản tin CTV mới**

```
CTV_new_n = [ Π_{n'≠n} sign(VTC_n') ] · α · min_{n'≠n} |VTC_n'|
```

Hiện thực tách thành ba phần độc lập, đúng như Figure 2 và Figure 3:

- **Dấu**: XOR toàn bộ bit dấu (`signs_xoring`) rồi XOR lại với dấu của chính lane đó
  (`sign_insertion`) → thu được tích dấu loại trừ mà chỉ tốn một cây XOR.
- **Biên độ**: tìm `min1` (nhỏ nhất) và `min2` (nhỏ nhì) **một lần** cho cả hàng
  (`min_submin`); lane trùng vị trí `min1` lấy `min2`, các lane còn lại lấy `min1`.
  Mẹo này giảm CNU từ *O(d_r²)* xuống *O(d_r)* phép so sánh.
- **Tỉ lệ**: nhân `α` rồi dịch phải 4 bit (Q1.4) kèm bão hoà.

**(7) Cập nhật APP** — `APP_new_n = VTC_n + CTV_new_n`

**(3) Quyết định cứng** — `x_n = 0` khi `Λ_n > 0`, ngược lại `x_n = 1`
(hàm `hard_bit` trong `ldpc_pkg.sv`; `Λ_n = 0` cho ra bit 1 — đúng đặc tả).

**Điều kiện dừng** — `H·x = 0` hoặc đạt số vòng lặp cực đại. Syndrome được tính
*on-the-fly* ngay trong pha đọc mỗi lớp (XOR bit cứng của APP đã dịch), không tốn thêm chu kỳ.

---

## 2. Ánh xạ bài báo → RTL

| Thành phần trong bài báo | Vị trí | File RTL |
|---|---|---|
| BRAM APP | Figure 1 | `bram_app.sv` |
| Operating mode selection | Figure 1 | `mode_select.sv` |
| VTC calculation, công thức (5) | Figure 1 | `vtc_calc.sv` |
| Min/submin calculation | Figure 1, **Figure 2** | `min_submin.sv`, `min2_merge.sv` |
| ABS | Figure 2 | `abs_sign.sv` |
| Signs XORing | Figure 2, 3 | `signs_xoring.sv` |
| Sign insertion | **Figure 3** | `sign_insertion.sv` |
| Check node unit (CORE) | Figure 3 | `ldpc_core.sv` |
| CTV and APP calculation, (6)(7) | Figure 1 | `sign_insertion.sv` + `app_calc.sv` |
| BRAM CTV | Figure 1 | `bram_ctv.sv` |
| Iterations counter | Figure 1 | `iter_counter.sv` |
| Memory for check matrix (vals/pos/elementSize) | Figure 1, III.B | `h_rom.sv` |
| Prior shift of values (dịch vòng QC) | Abstract, III.B | `barrel_shifter.sv` |
| Cấu trúc tổng thể | **Figure 1** | `ldpc_decoder_top.sv` |
| Công thức thông lượng (8) | mục V | xem §9 |

---

## 3. Cấu hình và tham số

Toàn bộ tham số nằm trong `rtl/ldpc_pkg.sv`.

| Tham số | Mặc định | Ý nghĩa | Ràng buộc |
|---|---|---|---|
| `Z` | 24 | kích thước circulant *z* | 802.16e: 24…96, bội của 4 |
| `Z0` | 96 | circulant gốc của bảng Hb | cố định theo chuẩn |
| `NB` | 24 | số cột khối của Hb | khớp file `.mem` |
| `MB` | 12 | số hàng khối của Hb | khớp file `.mem` |
| `DW` | 6 | độ rộng LLR/APP/VTC/CTV | ≥ 4 |
| `DR_MAX` | 8 | số đầu vào khối min/submin | **phải là 8** (cascade cố định) |
| `ALPHA_W` | 5 | độ rộng α | α = `alpha`/16 |
| `ITER_W` | 5 | độ rộng bộ đếm vòng lặp | `max_iter` ≤ 2^ITER_W − 1 |

Tham số dẫn xuất: `N = Z·NB = 576`, `M = Z·MB = 288`, `K = 288` (rate 1/2),
`MAGW = DW−1 = 5`, `CTV_DEPTH = MB·DR_MAX = 96`.

**α khuyến nghị: `5'd12` (0,75)** — xem §15.1 về lý do α phải < 1.

---

## 4. Cây thư mục

```
ldpc_decoder/
├── Makefile                    chạy toàn bộ hồi quy
├── README.md                   tài liệu này
├── mem/
│   └── h_base_16e_r12.mem      ma trận cơ sở Hb (12×24, 1 byte/phần tử, ff = −1)
├── scripts/
│   └── gen_h_base.py           sinh file .mem cho chuẩn/rate khác
├── rtl/
│   ├── ldpc_pkg.sv             tham số, hàm bão hoà, |x|, quyết định cứng
│   ├── abs_sign.sv             ABS: tách dấu + modulo
│   ├── min2_merge.sv           tế bào Compare(min) giữ (min1, min2, idx)
│   ├── min_submin.sv           cây tìm min/submin 8 đầu vào, 4 tầng
│   ├── signs_xoring.sv         cộng modulo 2 các bit dấu
│   ├── sign_insertion.sv       chèn dấu + nhân α + bão hoà
│   ├── ldpc_core.sv            CORE = CNU hoàn chỉnh (1 hàng kiểm tra)
│   ├── vtc_calc.sv             VTC = APP − CTV (z lane song song)
│   ├── app_calc.sv             APP_new = VTC + CTV_new (z lane)
│   ├── barrel_shifter.sv       dịch vòng z lane, hai chiều
│   ├── h_rom.sv                nén Hb thành vals/pos/elementSize
│   ├── bram_app.sv             bộ nhớ APP, dual-port
│   ├── bram_ctv.sv             bộ nhớ CTV
│   ├── iter_counter.sv         đếm vòng lặp + dừng sớm
│   ├── mode_select.sv          chuyển chế độ, phát READY/OUT
│   └── ldpc_decoder_top.sv     FSM + z core song song
├── tb/                         11 testbench (xem §11)
└── sim/                        sản phẩm mô phỏng (.vvp)
```

---

## 5. Kiến trúc tổng thể

```
                          ┌──────────────────────────────┐
        DATA ──►┌────────┐│      Operating mode          │──► READY
                │ BRAM   ││        selection             │──► OUT
                │ APP    ││   (decoding / result output) │
                │ 1..K   │└──────────────────────────────┘
                └───┬────┘            ▲
                    │ đọc khối cột    │ APP
              ┌─────▼──────┐          │
              │  Barrel    │  dịch trái theo vals[layer][j]
              │  shifter   │
              └─────┬──────┘
                    │ APP đã căn chỉnh
              ┌─────▼──────┐   CTV cũ   ┌──────────┐
              │    VTC     │◄───────────│ BRAM CTV │
              │ calculation│            │  1..L    │
              └─────┬──────┘            └────▲─────┘
                    │ VTC[0..d_r-1]          │ CTV mới
        ┌───────────▼──────────────┐         │
        │  z CORE song song        │         │
        │  ABS → Signs XOR         │         │
        │      → Min/submin        │         │
        │      → Sign insertion    │         │
        │      → × α               │─────────┘
        └───────────┬──────────────┘
                    │ CTV_new
              ┌─────▼──────┐
              │    APP     │  APP_new = VTC + CTV_new
              │ calculation│
              └─────┬──────┘
              ┌─────▼──────┐
              │  Barrel    │  dịch phải (nghịch đảo) → ghi lại BRAM APP
              │  shifter   │
              └────────────┘

     ┌──────────────┐        ┌─────────────────────┐
     │  Iterations  │        │ Memory for check    │  vals / pos / elementSize
     │   counter    │        │ matrix (h_rom)      │
     └──────────────┘        └─────────────────────┘
```

**Nguyên lý song song hoá:** một hàng khối (layer) của Hb tương ứng *z* hàng thật của
ma trận H. Nhờ cấu trúc tựa vòng, *z* hàng này có **cùng trọng số hàng** và chỉ khác
nhau ở lượng dịch vòng. Do đó ta đọc một khối cột (*z* giá trị APP), dịch vòng để căn
chỉnh, rồi cho *z* core CNU giống hệt nhau xử lý đồng thời — đúng câu
*"the number of cores is equal to the codeword circulant size (z)"*.

---

## 6. Đặc tả từng khối

### 6.1 `ldpc_pkg.sv`

- `sat_add(a,b)`, `sat_sub(a,b)` — cộng/trừ **bão hoà** trong miền `DW` bit, ngăn cuộn
  vòng (wrap-around) vốn gây lỗi giải mã nghiêm trọng.
- `sat_abs(a)` — `|a|` có bão hoà; xử lý đúng `a = −2^(DW−1)` (giá trị này không có
  số đối trong `DW` bit, phải kẹp về `MAGMAX`).
- `hard_bit(a)` — quyết định cứng theo (3).
- Hằng số `DMAX`, `DMIN`, `MAGMAX`, `HB_NEG = 8'hFF`.

> **Tương thích công cụ:** các hàm được gọi với tiền tố tường minh
> `ldpc_pkg::sat_add(...)` vì Icarus Verilog không tự đưa hàm của package vào phạm vi
> module qua `import`. Cú pháp này hợp lệ với mọi công cụ.

### 6.2 `abs_sign.sv` — khối ABS (Figure 2)

| Cổng | Hướng | Rộng | Mô tả |
|---|---|---|---|
| `din` | in | `DW` signed | dữ liệu vào (1…8) |
| `sign` | out | 1 | bit dấu, đưa lên bus `signs` |
| `mag` | out | `MAGW` | modulo (1′…8′) |

Dùng `assign` thay vì `always_comb` — xem §14.

### 6.3 `min2_merge.sv` — tế bào Compare(min)

Mỗi nút giữ bộ ba `(min1, min2, idx_of_min1)` của một nhóm đầu vào. Ghép hai nhóm:

```
min1 = min(A.min1, B.min1)
idx  = idx của nhóm thắng
min2 = min( max(A.min1, B.min1), min2 của nhóm thắng )
```

Quy tắc `<=` khiến khi hoà, **chỉ số nhỏ hơn thắng** — hành vi xác định, đã kiểm chứng.

### 6.4 `min_submin.sv` — Min/submin calculation (Figure 2)

- 8 đầu vào modulo; tầng lá + 3 tầng ghép = **4 tầng so sánh**, khớp mô tả
  *"a cascade of 4 consecutive stages of comparators"*.
- Lane có chỉ số ≥ `row_weight` được nạp `MAGMAX`, đúng câu *"the remaining inputs are
  fed with the maximum positive values for the current input bitness"*.
- Trả về `min1`, `min2`, `min_idx`.

### 6.5 `signs_xoring.sv`

`sign_prod = XOR` bit dấu của `d_r` lane hợp lệ. Lane thừa mang giá trị dương (dấu 0)
nên vốn không ảnh hưởng, nhưng vẫn được che tường minh cho an toàn.

### 6.6 `sign_insertion.sv` — Sign insertion (Figure 3)

Với mỗi lane *n*:

```
sel_mag = (n == min_idx) ? min2 : min1
scaled  = (sel_mag * alpha) >> 4        // Q1.4, bão hoà tại MAGMAX
sign_n  = sign_prod XOR signs[n]
CTV_n   = sign_n ? −scaled : +scaled    // lane n ≥ d_r cho ra 0
```

### 6.7 `ldpc_core.sv` — CORE / Check Node Unit

Ghép ABS ×8 → Signs XORing → Min/submin → Sign insertion. Đây là đơn vị được nhân bản
*z* lần trong `ldpc_decoder_top`. Thuần tổ hợp; thanh ghi nằm ở tầng trên.

### 6.8 `vtc_calc.sv` / `app_calc.sv`

Vector hoá trên `LANES = Z` lane, mỗi lane dùng `sat_sub` / `sat_add`.

### 6.9 `barrel_shifter.sv`

```
dir = 0 (trái) : dout[i] = din[(i + shift) mod LANES]
dir = 1 (phải) : dout[i] = din[(i − shift + LANES) mod LANES]
```

Vì `I(s)` là ma trận đơn vị dịch vòng *s*, nút kiểm tra *i* của lớp *r* nối tới nút
biến `c·Z + (i + s) mod Z`. Dịch trái khi đọc đưa nút biến về đúng lane của nút kiểm
tra; dịch phải khi ghi là phép nghịch đảo. Testbench kiểm tra tính nghịch đảo với mọi
lượng dịch.

### 6.10 `h_rom.sv` — Memory for check matrix

Đọc file `.mem` chứa Hb (1 byte/phần tử, `ff` = −1) rồi **tự nén** thành ba vector
theo đúng mục III.B:

| Vector | Nội dung | Kích thước |
|---|---|---|
| `vals` | lượng dịch vòng, đã chia tỉ lệ `⌊p·Z/Z0⌋` | 96 × 5 bit |
| `pos` | chỉ số cột khối của từng phần tử | 96 × 5 bit |
| `elementSize` | trọng số hàng `d_r` | 12 × 4 bit |

Giao diện đọc tổ hợp (distributed memory): cho `layer` và `idx`, trả về `row_weight`,
`col_pos`, `shift`, `edge_valid`.

**Hiệu quả nén:** Hb đầy đủ cần 288 × 8 = 2 304 bit; ba vector chỉ cần
480 + 480 + 48 = **1 008 bit** (giảm 56 %). Đây chính là đóng góp *"the new way of
storing the parity check matrix is proposed… allows to reduce the amount of memory"*.

### 6.11 `bram_app.sv` / `bram_ctv.sv`

- **BRAM APP**: `DEPTH = NB = 24`, `WIDTH = Z·DW = 144` bit. Cổng A đọc (giải mã /
  xuất kết quả), cổng B ghi (nạp LLR / ghi ngược APP_new). Độ trễ đọc 1 chu kỳ.
  Chia khối theo đúng câu *"the block memory is divided into K = N/z blocks"*.
- **BRAM CTV**: `DEPTH = MB·DR_MAX = 96`, `WIDTH = 144` bit, địa chỉ
  `layer·DR_MAX + j`. Tương đương *"z memory instances of size
  (rowWeight × inputDataSize × numberOfRow)"*.

### 6.12 `iter_counter.sv`

Đếm vòng lặp, phát `done` khi `iter_cnt ≥ max_iter` **hoặc** khi `converged = 1`
(nếu `EARLY_TERM = 1`). Có `clear` cho khung mới và reset bất đồng bộ.

### 6.13 `mode_select.sv`

Chuyển giữa "decoding" và "result output": khi ở chế độ xuất, đặt `READY` mức cao,
chuyển APP thành quyết định cứng và phát ra `OUT` cùng `out_valid`.

---

## 7. Máy trạng thái và giản đồ thời gian

### 7.1 Sơ đồ trạng thái

```
            ┌────────┐  nhận đủ NB khối
            │ S_LOAD │────────────────────┐
            └────▲───┘                    ▼
                 │              ┌──────────────────┐
                 │              │      S_READ      │ ◄──────────┐
                 │              │ đọc APP+CTV,     │            │
                 │              │ tính VTC, cộng   │            │
                 │              │ dồn syndrome     │            │
                 │              └────────┬─────────┘            │
                 │                       │ đủ d_r bản tin       │
                 │              ┌────────▼─────────┐            │
                 │              │      S_CNU       │            │
                 │              │ z core tính CTV  │            │
                 │              └────────┬─────────┘            │
                 │              ┌────────▼─────────┐            │
                 │              │     S_WRITE      │  layer++   │
                 │              │ ghi APP_new, CTV │────────────┘
                 │              └────────┬─────────┘
                 │                       │ hết MB lớp
                 │              ┌────────▼─────────┐
                 │              │ S_ITER→S_ITERCHK │──► chưa xong: layer=0 → S_READ
                 │              └────────┬─────────┘
                 │                       │ done
            ┌────┴───┐          ┌────────▼─────────┐
            │        │◄─────────│      S_OUT       │ READY = 1
            └────────┘  xong NB └──────────────────┘
```

### 7.2 Giản đồ thời gian pha đọc (`S_READ`, ví dụ `d_r = 3`)

```
chu kỳ      :   0      1      2      3
issue j     :   0      1      2      –
app_a_addr  : pos[0] pos[1] pos[2]   –
shift_d     :   –    val[0] val[1] val[2]
app_a_dout  :   –    APP[0] APP[1] APP[2]
ctv_rd_data :   –    CTV[0] CTV[1] CTV[2]
capture     :   –    vtc[0] vtc[1] vtc[2]  → chuyển S_CNU
```

Đọc BRAM trễ 1 chu kỳ nên `shift_d` và `j_d` được trễ tương ứng để căn chỉnh lượng
dịch với dữ liệu về. Pha đọc tốn **d_r + 1** chu kỳ.

### 7.3 Giản đồ thời gian pha ghi (`S_WRITE`)

```
chu kỳ      :   0        1        2
j           :   0        1        2
app_b_addr  : pos[0]   pos[1]   pos[2]
app_b_din   : rot_r(vtc[j] + ctv_new[j], val[j])
ctv_wr_addr : layer·8+0  +1       +2
```

Pha ghi tốn đúng **d_r** chu kỳ, không có độ trễ vì `h_rom` đọc tổ hợp.

### 7.4 Số chu kỳ

| Giai đoạn | Công thức | Rate 1/2 (Σd_r = 76, MB = 12) |
|---|---|---|
| Nạp LLR | `NB` | 24 |
| Một lớp | `2·d_r + 2` | 14…16 |
| Một vòng lặp | `Σ(2·d_r + 2) + 2` | **178** |
| Xuất kết quả | `NB + 1` | 25 |
| Tổng, 10 vòng lặp | | ≈ 1 829 |

---

## 8. Giao diện `ldpc_decoder_top`

```systemverilog
module ldpc_decoder_top #(
  parameter     INIT_FILE  = "h_base.mem",
  parameter bit EARLY_TERM = 1
)(
  input  logic                clk,
  input  logic                rst_n,       // reset bất đồng bộ, tích cực thấp

  // nạp LLR (DATA)
  input  logic                in_valid,
  output logic                in_ready,
  input  logic [Z*DW-1:0]     in_data,     // z giá trị LLR mềm, mỗi cái DW bit

  // cấu hình
  input  logic [ALPHA_W-1:0]  alpha,       // Q1.4, khuyến nghị 5'd12 = 0,75
  input  logic [ITER_W-1:0]   max_iter,

  // kết quả
  output logic                ready,       // READY
  output logic                out_valid,
  output logic [Z-1:0]        out_bits,    // OUT, quyết định cứng
  output logic                busy,
  output logic [ITER_W-1:0]   iter_cnt,
  output logic                converged
);
```

### Giao thức

**Nạp:** khi `in_ready = 1`, đưa `in_valid = 1` liên tục **NB nhịp**; nhịp thứ *c*
chứa *z* giá trị LLR của khối cột *c*. LLR **dương ⇒ thiên về bit 0** (theo (1)).
Sau nhịp cuối, bộ giải mã tự khởi động, `in_ready` xuống 0 và `busy` lên 1.

**Xuất:** `ready` giữ mức cao trong suốt chế độ xuất. Mỗi nhịp `out_valid = 1` mang
*z* bit quyết định cứng của một khối cột; tổng **NB nhịp** = N bit (gồm cả bit tin và
bit kiểm tra). Sau đó tự trở về trạng thái nhận khung mới.

**Bit thứ *n* của từ mã** nằm ở nhịp `n / Z`, vị trí `n % Z` của `out_bits`.

### Ví dụ trình tự

```
        ┌── NB=24 nhịp ──┐                              ┌── NB=24 nhịp ──┐
in_valid ▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔________________________________________________
in_ready ▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔________________________________________▔▔▔▔▔▔▔▔
busy     ________________▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔________
ready    ________________________________________________▔▔▔▔▔▔▔▔________
out_valid_______________________________________________▔▔▔▔▔▔▔▔________
                          ◄── giải mã (178 × NOI) ──►
```

---

## 9. Tài nguyên và thông lượng

### 9.1 Bộ nhớ

| Khối | Kích thước |
|---|---|
| BRAM APP | 24 × 144 = 3 456 bit |
| BRAM CTV | 96 × 144 = 13 824 bit |
| h_rom (3 vector) | 1 008 bit (phân tán) |
| Thanh ghi VTC lớp | 8 × 144 = 1 152 FF |
| Thanh ghi CTV_new lớp | 8 × 144 = 1 152 FF |

### 9.2 Logic tổ hợp

24 core, mỗi core gồm 8 khối ABS, 7 tế bào so sánh (4 tầng), 1 cây XOR 8 đầu vào,
8 bộ nhân α 5×5 bit. Bộ nhân α có thể thay bằng cộng-dịch nếu cố định α = 0,75
(`x − x/4`) để tiết kiệm LUT/DSP.

### 9.3 Thông lượng

Theo công thức (8) của bài báo: `T = F_max · BL / (CPI · NOI)`

Với `BL = 576`, `CPI = 178`, `NOI = 10`, `F_max = 240 MHz` (giá trị bài báo báo cáo
cho n = 576):

```
T = 240e6 × 576 / (178 × 10) ≈ 77,7 Mbps
```

Bài báo báo cáo 483 Mbps cho **một vòng lặp** ở n = 576, tương ứng `CPI ≈ 286` cho một
vòng lặp — cùng bậc độ lớn với thiết kế này. Chênh lệch đến từ mức độ ống hoá: thiết
kế hiện tại chưa chồng lấn pha đọc của lớp *L+1* lên pha ghi của lớp *L* (xem §15.2).

---

## 10. Cách chạy mô phỏng

Yêu cầu: **Icarus Verilog ≥ 12** (`-g2012`) và Python 3.

```bash
make all            # toàn bộ 11 testbench (~1 phút)
make lint           # chỉ elaborate RTL, không mô phỏng
make core           # riêng CNU
make top            # riêng testbench hệ thống
make dp             # riêng vtc/app_calc + barrel shifter
make bram hrom ctrl # riêng các khối bộ nhớ / điều khiển
make mem            # sinh lại mem/h_base_16e_r12.mem
make clean
```

Với Verilator / Questa / VCS: nạp `rtl/ldpc_pkg.sv` **trước** các file còn lại
(package phải được biên dịch trước khi dùng).

Cảnh báo `sorry: constant selects in always_* processes ...` là hạn chế của Icarus,
vô hại, đã lọc sẵn trong Makefile.

---

## 11. Kế hoạch kiểm chứng chi tiết

Mỗi testbench tự đếm lỗi và in `PASS` / `FAIL` kèm số vector.

### `tb_abs_sign` — vét cạn
1. Toàn bộ 2^DW giá trị vào
2. Kiểm tra riêng `−2^(DW−1)` (bão hoà modulo)

### `tb_min2_merge` — vét cạn không gian rút gọn
1. Quét mọi `(a_min1 ≤ a_min2, b_min1 ≤ b_min2)` với MAGW = 3
2. Trường hợp hoà (`a_min1 == b_min1`) → chỉ số nhỏ hơn phải thắng

### `tb_min_submin`
1. 2 000 vector ngẫu nhiên cho **mỗi** `d_r` = 1…8
2. Tất cả đầu vào bằng nhau, quét mọi giá trị
3. Hai giá trị nhỏ nhất bằng nhau, quét mọi cặp vị trí
4. Giá trị nhỏ nhất đặt ở từng vị trí
5. Dãy tăng dần và giảm dần

Tổng **16 476** vector, đối chiếu mô hình vàng độc lập.

### `tb_signs_xoring` — vét cạn
Toàn bộ 2⁸ tổ hợp dấu × 9 giá trị `row_weight` (0…8) = 2 304 vector.

### `tb_sign_insertion`
1. 5 000 vector ngẫu nhiên (min1 ≤ min2, idx, sign_prod, signs, d_r, α)
2. Quét toàn bộ α = 0…31, **gồm cả α > 1,0** để kiểm tra bão hoà
3. Lane có chỉ số ≥ `row_weight` phải cho ra 0

### `tb_ldpc_core` — quan trọng nhất
Mô hình vàng tính **trực tiếp từ công thức (4)/(6)** (min loại trừ, không dùng mẹo
min/submin) nên độc lập hoàn toàn với hiện thực:

1. 3 000 vector ngẫu nhiên × 8 giá trị `d_r`
2. Toàn bộ VTC = 0 (suy biến)
3. Toàn bộ VTC = `−2^(DW−1)` (bão hoà modulo)
4. Đúng một VTC âm, quét vị trí (kiểm tra lan truyền dấu)
5. Hai modulo nhỏ nhất bằng nhau, quét mọi cặp vị trí (tie)
6. **Vét cạn** `d_r = 3` trên miền [−3, 3], hai giá trị α

Tổng **24 766** vector.

### `tb_vtc_app_calc`
1. Vét cạn toàn bộ cặp (APP, CTV) = 4 096 tổ hợp — phủ mọi trường hợp tràn dương và
   tràn âm cần bão hoà
2. 500 vector ngẫu nhiên đồng thời trên cả z lane

### `tb_barrel_shifter`
1. Mọi lượng dịch 0…Z−1, cả hai chiều
2. Kiểm tra tính nghịch đảo (dịch trái rồi phải = ban đầu)
3. Dữ liệu biên: toàn 0, toàn 1, mẫu đánh dấu từng lane, ngẫu nhiên

### `tb_h_rom`
1. Đối chiếu `vals` / `pos` / `elementSize` với Hb gốc đọc theo đường độc lập
2. Quét toàn bộ `MB × DR_MAX` cặp (layer, idx)
3. Kiểm tra `edge_valid`, `shift < Z`, tỉ lệ `⌊p·Z/Z0⌋`, `d_r ≤ DR_MAX`

### `tb_bram`
1. Ghi/đọc toàn bộ địa chỉ của cả hai BRAM
2. Ghi cổng B và đọc cổng A đồng thời, khác địa chỉ (dual-port)
3. `we = 0` không được làm thay đổi nội dung
4. Mẫu biên: toàn 0, toàn 1, ngẫu nhiên

### `tb_ctrl`
1. Đếm đủ `max_iter` với mọi `max_iter` = 1…16
2. Dừng sớm khi `converged = 1`
3. `clear` giữa chừng đặt lại bộ đếm và `done`
4. Reset bất đồng bộ
5. Vét cạn quyết định cứng cho mọi giá trị APP (kiểm tra `Λ = 0 → bit 1`)
6. Gating `READY` / `out_valid` theo `mode_out` và `blk_valid`

### `tb_ldpc_decoder_top` — mức hệ thống

Từ mã phát là **từ toàn 0** (luôn hợp lệ với mã tuyến tính, nên không cần bộ mã hoá);
ngoài ra mọi kết quả báo hội tụ đều được kiểm tra thoả `H·x = 0` bằng mô hình ma trận
dựng độc lập trong testbench.

| Test | Nội dung | Tiêu chí |
|---|---|---|
| T1 | Giao thức nạp/xuất | `in_ready` đúng lúc, đủ NB nhịp ra, `READY` cao khi `out_valid` |
| T2 | Kênh không lỗi | hội tụ ở vòng lặp 1, `iter_cnt = 1`, 0 bit sai |
| T3 | Lỗi đơn lẻ, quét 16 vị trí | sửa hết |
| T4 | Lỗi ngẫu nhiên 2…40 bit, 5 lần/mức | bắt buộc sửa hết tới 10 lỗi; thống kê phần còn lại |
| T5 | Quá tải (≈50 % bit lỗi) | không treo, chạy đủ `max_iter`, `converged = 0` |
| T6 | Ba khung liên tiếp | trạng thái nội bộ được đặt lại đúng |
| T7 | Quét α = 0,5 / 0,625 / 0,75 / 0,875 | sửa hết trong 3 vòng lặp |
| T7b | `max_iter = 1` | kết thúc đúng sau 1 vòng lặp |
| T7c | α = 1,0 | chỉ kiểm tra giao thức (xem §15.1) |
| — | Bảo vệ treo | timeout cục bộ mỗi khung + timeout toàn cục |

---

## 12. Kết quả hồi quy

Icarus Verilog 12, toàn bộ **PASS**:

| Testbench | Số vector / khung | Thời gian |
|---|---|---|
| `tb_abs_sign` | 64 | < 1 s |
| `tb_min2_merge` | 1 296 | < 1 s |
| `tb_min_submin` | 16 476 | ~3 s |
| `tb_signs_xoring` | 2 304 | < 1 s |
| `tb_sign_insertion` | 5 040 | ~1 s |
| `tb_ldpc_core` | 24 766 | ~5 s |
| `tb_vtc_app_calc` | 4 596 | ~1 s |
| `tb_barrel_shifter` | 552 | < 1 s |
| `tb_bram` | 127 phép đọc | < 1 s |
| `tb_h_rom` | 96 | < 1 s |
| `tb_ctrl` | — | < 1 s |
| `tb_ldpc_decoder_top` | ~140 khung | ~50 s |

Khả năng sửa lỗi đo được (N = 576, rate 1/2, α = 0,75, `max_iter` = 10):

| Số bit lỗi | 2…14 | 16 | 18…40 |
|---|---|---|---|
| Tỉ lệ sửa thành công | 5/5 | 4/5 | 5/5 |

Tỉ lệ không đơn điệu theo số lỗi vì yếu tố quyết định không phải số lượng mà là **vị
trí** lỗi: các mẫu lỗi rơi vào cùng một chu trình ngắn của đồ thị Tanner mới gây thất bại.

---

## 13. Cách đổi cấu hình

### Đổi kích thước circulant (đổi độ dài từ mã)

Chỉ cần sửa `Z` trong `ldpc_pkg.sv`. `h_rom` tự chia tỉ lệ lượng dịch theo `⌊p·Z/Z0⌋`
đúng đặc tả 802.16e. Ví dụ `Z = 96` → `N = 2304`, đúng cấu hình cho thông lượng cực đại
trong bài báo (1,2 Gbps).

### Đổi rate hoặc chuẩn

1. Thêm ma trận cơ sở vào bảng `MATRICES` trong `scripts/gen_h_base.py`
2. `python3 gen_h_base.py --std 802.11n --rate 2/3 -o ../mem/h_new.mem`
3. Cập nhật `MB`, `NB`, `Z0` trong `ldpc_pkg.sv`
4. Truyền `INIT_FILE` mới cho `ldpc_decoder_top`

Script in ra trọng số hàng để kiểm tra `max d_r ≤ DR_MAX`. Nếu ma trận có `d_r > 8`,
phải mở rộng cây trong `min_submin.sv` (thêm một tầng ghép).

### Đổi độ rộng lượng tử

Sửa `DW`. Mọi hàm bão hoà, `MAGW`, độ rộng BRAM tự điều chỉnh. Độ rộng lớn hơn cải
thiện chất lượng giải mã, đổi lại tốn bộ nhớ và có thể hạ `F_max`.

---

## 14. Ghi chú tổng hợp FPGA

- **Ánh xạ BRAM:** `bram_app` viết theo mẫu true dual-port chuẩn, `bram_ctv` theo mẫu
  simple dual-port; Vivado/Quartus suy luận ra BRAM tự động. Cấu hình mặc định
  (144 bit × 24) khá nông nên có thể bị ánh xạ thành LUTRAM — với `Z = 96` sẽ dùng
  BRAM đúng nghĩa.
- **`h_rom` khởi tạo bằng `initial` + `$readmemh` + vòng lặp nén.** Vivado hằng-số-hoá
  được; nếu công cụ khác không hỗ trợ, dùng `gen_h_base.py` sinh sẵn ba file `.mem`
  (`vals`/`pos`/`elementSize`) và thay bằng ba lệnh `$readmemh` trực tiếp.
- **Không dùng `always_comb` chứa lời gọi hàm cho logic tổ hợp đơn giản.** `abs_sign`
  dùng `assign` — trước đây khi viết bằng `always_comb`, Icarus đưa cả biến cục bộ vào
  danh sách nhạy khiến khối tự kích hoạt lại vô hạn trong cùng bước thời gian
  (testbench CNU từ > 600 s xuống còn 5 s sau khi sửa). Tương tự, biến trung gian trong
  `sign_insertion` và `barrel_shifter` đã được đưa ra phạm vi module.
- **Đường tới hạn** dự kiến: `vtc_calc → z core (4 tầng so sánh + nhân α) → app_calc`.
  Muốn tăng `F_max`, chèn thanh ghi giữa `min_submin` và `sign_insertion`
  (thêm 1 chu kỳ mỗi lớp).
- **Reset:** bất đồng bộ tích cực thấp; nên thêm bộ đồng bộ hoá cạnh nhả ở mức hệ thống.
- Không dùng `initial` cho logic chức năng (chỉ dùng cho ROM); không có cấu trúc không
  tổng hợp được trong `rtl/`.

---

## 15. Hạn chế đã biết và hướng mở rộng

### 15.1 Hệ số α bắt buộc nhỏ hơn 1

Đo được ngưỡng rất sắc (8 bit lỗi đầu vào, `max_iter` = 15):

| α | 0,5 | 0,625 | 0,75 | 0,875 | **1,0** |
|---|---|---|---|---|---|
| Bit sai sau giải mã | 0 | 0 | 0 | 0 | **472** |
| Số vòng lặp | 3 | 3 | 3 | 3 | 15 (không hội tụ) |

Nguyên nhân: với α = 1 thuật toán min-sum **mất tính co** (non-contracting), biên độ
bản tin tăng dần qua các lớp tới mức bão hoà `DW` bit; khi mọi APP đều kẹp ở ±31,
thông tin độ tin cậy biến mất và các lỗi dấu bị "khoá cứng". Đây là đặc tính số học đã
biết của min-sum lượng tử hoá, **không phải lỗi RTL** — testbench ghi nhận rõ ràng
trường hợp này thay vì khẳng định sai.

**Khắc phục nếu bắt buộc dùng α = 1,0:** mở rộng độ rộng bộ nhớ APP thêm 2–3 bit bảo vệ
so với độ rộng bản tin (`APP_W = DW + 2`), giữ CTV/VTC ở `DW` bit và bão hoà khi chuyển
đổi. Cần sửa: độ rộng `bram_app`, `barrel_shifter` phía APP, `vtc_calc` (thu hẹp có bão
hoà), `app_calc` (mở rộng), `mode_select`.

### 15.2 Chưa chồng lấn pha đọc và pha ghi

Hiện mỗi lớp tốn `2·d_r + 2` chu kỳ. Có thể giảm gần một nửa bằng cách chồng lấn pha
ghi của lớp *L* với pha đọc của lớp *L+1*, với điều kiện xử lý xung đột khi hai lớp
liên tiếp cùng chạm một khối cột (khá phổ biến với cấu trúc lưỡng đường chéo của
802.16e). Cần thêm logic forwarding hoặc chèn bong bóng.

### 15.3 Chưa có bộ mã hoá

Testbench dùng từ mã toàn 0 nên không cần bộ mã hoá. Muốn kiểm tra với từ mã ngẫu
nhiên, cần thêm bộ mã hoá khai thác cấu trúc lưỡng đường chéo của Hb 802.16e. Tính đúng
đắn hiện đã được bảo đảm gián tiếp qua kiểm tra `H·x = 0`.

### 15.4 `DR_MAX` cố định bằng 8

Cây min/submin được viết tường minh 3 tầng ghép cho đúng 8 đầu vào (khớp Figure 2). Ma
trận có `d_r > 8` cần thêm tầng — `min2_merge` đã tham số hoá sẵn nên chỉ là việc mở
rộng phần `generate` trong `min_submin.sv`.

### 15.5 Dừng sớm dùng syndrome "on-the-fly"

Syndrome của lớp *L* được tính trên APP đọc trong lớp đó, tức đã chịu ảnh hưởng của các
lớp trước trong cùng vòng lặp. Đây là kỹ thuật chuẩn cho giải mã layered và có thể báo
hội tụ sớm hơn một chút so với kiểm tra syndrome toàn cục trên APP cuối vòng lặp.
Testbench khắc phục bằng cách **luôn kiểm tra lại `H·x = 0` trên kết quả xuất ra**, và
chưa từng phát hiện trường hợp báo hội tụ sai.
