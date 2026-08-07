`timescale 1ns / 1ns
//check lại
module ldpc_decoder_top #(
    parameter W = 8,
    parameter DEG = 8,
    parameter MAX_ITER = 10,
    parameter ROM_DEPTH = 128,
    parameter ADDR_WIDTH = 7
)(
    input  logic clk,
    input  logic rst_n,
    
    // Giao tiếp nạp DATA ban đầu từ kênh truyền (Khớp với mũi tên DATA)
    input  logic init_en,
    input  logic [ADDR_WIDTH-1:0] init_addr,
    input  logic [(DEG*W)-1:0] data_in, 
    
    // Hệ số bão hòa ALPHA (Khớp với mũi tên ALPHA từ Figure 1)
    input  logic signed [W-1:0] alpha,

    // Giao tiếp ngõ ra kết quả
    output logic [DEG-1:0]     decoded_out,
    output logic               ready
);

    // =====================================================================
    // TÍN HIỆU ĐIỀU KHIỂN FSM VÀ KHỐI NHỚ
    // =====================================================================
    logic iter_done;
    logic max_iter_reached;
    logic [ADDR_WIDTH-1:0] rom_read_addr;
    logic app_valid;

    // FSM nội bộ tạo địa chỉ quét ma trận và cờ hoàn thành lặp
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rom_read_addr <= '0;
            iter_done <= 1'b0;
            app_valid <= 1'b0;
        end else if (!init_en && !ready) begin // Đã nạp xong data, chưa ready
            app_valid <= 1'b1;
            if (rom_read_addr < ROM_DEPTH - 1) begin
                rom_read_addr <= rom_read_addr + 1'b1;
                iter_done <= 1'b0;
            end else begin
                rom_read_addr <= '0;
                iter_done <= 1'b1; // Quét xong 1 vòng, kích hoạt counter
            end
        end else begin
            iter_done <= 1'b0;
            app_valid <= (ready) ? 1'b1 : 1'b0; // Giữ valid nếu chờ xuất
        end
    end

    // =====================================================================
    // 1. Iterations counter
    // =====================================================================
    iterations_counter #(
        .MAX(MAX_ITER)
    ) iter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .iter_done(iter_done),
        .max_iter_reached(max_iter_reached)
    );

    // =====================================================================
    // 2. Memory for check matrix
    // =====================================================================
    logic [7:0] element_size;
    logic [9:0] pos_out;

    check_matrix_rom #(
        .ROM_DEPTH(ROM_DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) rom_inst (
        .clk(clk),
        .read_addr(rom_read_addr),
        .element_size(element_size),
        .pos_out(pos_out)
    );

    // =====================================================================
    // BỘ NHỚ RAM (BRAM APP & BRAM CTV)
    // =====================================================================
    logic [(DEG*W)-1:0] bram_app_dout;
    logic [(DEG*W)-1:0] bram_ctv_dout;
    logic [(DEG*W)-1:0] bram_app_din;
    logic [(DEG*W)-1:0] bram_ctv_din;

    // Chỉ cho phép ghi vào BRAM thuật toán khi FSM đang chạy và chưa Ready
    logic we_alg;
    assign we_alg = (!init_en && app_valid && !ready);

    // 3. BRAM APP
    // Sử dụng module bram_app của bạn, với Z = DEG để map với logic 1 hàng
    bram_app #(
        .Z(DEG), .W(W), .N(DEG * ROM_DEPTH)
    ) bram_app_inst (
        .clk(clk),
        .we_a(init_en),         // Cổng A nạp dữ liệu mềm (DATA)
        .we_b(we_alg),          // Cổng B nhận APP_new vòng lặp khép kín
        .addr_a(init_addr),
        .addr_b(rom_read_addr),
        .din_a(data_in),
        .din_b(bram_app_din),
        .dout_a(),
        .dout_b(bram_app_dout)
    );

    // 4. BRAM CTV
    bram_app #(
        .Z(DEG), .W(W), .N(DEG * ROM_DEPTH)
    ) bram_ctv_inst (
        .clk(clk),
        .we_a(1'b0),            // CTV không cần khởi tạo ban đầu qua kênh
        .we_b(we_alg),          // Cổng B nhận CTV_new vòng lặp khép kín
        .addr_a('0),
        .addr_b(rom_read_addr),
        .din_a('0),
        .din_b(bram_ctv_din),
        .dout_a(),
        .dout_b(bram_ctv_dout)
    );

    // =====================================================================
    // KHAI BÁO MẢNG TRUNG GIAN NỐI GIỮA CÁC KHỐI TOÁN HỌC
    // =====================================================================
    logic signed [W-1:0] app_in_arr [0:DEG-1];
    logic signed [W-1:0] ctv_in_arr [0:DEG-1];
    logic signed [W-1:0] app_to_vtc_arr [0:DEG-1];
    logic signed [W-1:0] vtc_out_arr [0:DEG-1];
    logic signed [W-1:0] ctv_new_arr [0:DEG-1];
    logic signed [W-1:0] app_new_arr [0:DEG-1];
    
    logic [W-2:0] min1, min2;
    logic [2:0]   min1_idx;
    logic         signs_xor;
    logic         vtc_signs [0:DEG-1];
    logic [DEG-1:0] ready_arr;

    // =====================================================================
    // UNPACK BRAM & KẾT NỐI KHỐI PARALLEL (Operating mode & VTC)
    // =====================================================================
    genvar i;
    generate
        for (i = 0; i < DEG; i++) begin : gen_parallel_units
            // Unpack flat vector từ BRAM thành mảng 2D cho toán học
            assign app_in_arr[i] = bram_app_dout[(i*W) +: W];
            assign ctv_in_arr[i] = bram_ctv_dout[(i*W) +: W];

            // Pack mảng 2D thành flat vector để ghi ngược vào BRAM
            assign bram_app_din[(i*W) +: W] = app_new_arr[i];
            assign bram_ctv_din[(i*W) +: W] = ctv_new_arr[i];

            // 5. Operating mode selection
            mode_selection #(
                .W(W)
            ) mode_sel_inst (
                .max_iter_reached(max_iter_reached),
                .app_valid(app_valid),
                .app_in(app_in_arr[i]),
                .app_to_vtc(app_to_vtc_arr[i]),
                .ready(ready_arr[i]),
                .decoded_out(decoded_out[i])
            );

            // 6. VTC calculation
            vtc_calc #(
                .W(W)
            ) vtc_inst (
                .app_in(app_to_vtc_arr[i]),
                .ctv_in(ctv_in_arr[i]),
                .vtc_out(vtc_out_arr[i])
            );
        end
    endgenerate

    // Cờ ready đồng bộ chung cho toàn lõi
    assign ready = ready_arr[0];

    // =====================================================================
    // 7. Min/submin calculation
    // =====================================================================
    min_submin_calc #(
        .W(W)
    ) min_submin_inst (
        .row_weight(element_size[3:0]),
        .vtc_in(vtc_out_arr),
        .min1(min1),
        .min2(min2),
        .min1_idx(min1_idx),
        .signs_xor(signs_xor),
        .vtc_signs(vtc_signs)
    );

    // =====================================================================
    // 8. CTV and APP calculation
    // =====================================================================
    ctv_app_calc #(
        .W(W),
        .DEG(DEG)
    ) ctv_app_inst (
        .row_weight(element_size[3:0]),
        .min1(min1),
        .min2(min2),
        .min1_idx(min1_idx),
        .signs_xor(signs_xor),
        .vtc_signs(vtc_signs),
        .vtc_in(vtc_out_arr),
        .ctv_new(ctv_new_arr),
        .app_new(app_new_arr)
    );

endmodule