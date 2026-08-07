`timescale 1ns / 1ns

module min_submin_calc #(
    parameter W = 8
)(
    input  logic [3:0]          row_weight,   
    input  logic signed [W-1:0] vtc_in [0:7], 
    
    output logic        [W-2:0] min1,
    output logic        [W-2:0] min2,
    output logic        [2:0]   min1_idx,
    output logic                signs_xor,
    output logic                vtc_signs [0:7]
);

    logic [W-2:0] abs_vtc [0:7];
    logic signed [W-1:0] vtc_sat [0:7];
    
    localparam logic signed [W-1:0] MIN_VAL = {1'b1, {(W-1){1'b0}}}; 
    localparam logic signed [W-1:0] SAT_VAL = {1'b1, {(W-2){1'b0}}, 1'b1};
    localparam logic [W-2:0] MAX_POS_MAG = {(W-1){1'b1}}; // Giá trị dương lớn nhất để đệm

    // =====================================================================
    // KHỐI ABS VÀ ĐỆM DỮ LIỆU
    // =====================================================================
    always_comb begin
        signs_xor = 1'b0;
        for (int i = 0; i < 8; i++) begin
            if (i < row_weight) begin
                // Tính trị tuyệt đối và trích xuất dấu
                vtc_sat[i]    = (vtc_in[i] == MIN_VAL) ? SAT_VAL : vtc_in[i];
                vtc_signs[i]  = vtc_sat[i][W-1];
                abs_vtc[i]    = (vtc_signs[i]) ? -vtc_sat[i] : vtc_sat[i];
                // Cộng Modulo 2 (XOR) tất cả các dấu
                signs_xor     = signs_xor ^ vtc_signs[i];
            end else begin
                // Đệm giá trị tối đa nếu vượt quá trọng số hàng
                vtc_signs[i]  = 1'b0;
                abs_vtc[i]    = MAX_POS_MAG; 
            end
        end
    end

    // =====================================================================
    // 2. KHỐI TÌM MIN/SUBMIN
    // =====================================================================
    // TẦNG 1: So sánh từng cặp (0-1, 2-3, 4-5, 6-7)
    logic [W-2:0] min1_01, min1_23, min1_45, min1_67; // Người thắng (nhỏ hơn)
    logic [W-2:0] max1_01, max1_23, max1_45, max1_67; // Người thua (lớn hơn)
    logic [2:0]   idx1_01, idx1_23, idx1_45, idx1_67; // Index của người thắng
    
    always_comb begin
        {min1_01, max1_01, idx1_01} = (abs_vtc[0] <= abs_vtc[1]) ? {abs_vtc[0], abs_vtc[1], 3'd0} : {abs_vtc[1], abs_vtc[0], 3'd1};
        {min1_23, max1_23, idx1_23} = (abs_vtc[2] <= abs_vtc[3]) ? {abs_vtc[2], abs_vtc[3], 3'd2} : {abs_vtc[3], abs_vtc[2], 3'd3};
        {min1_45, max1_45, idx1_45} = (abs_vtc[4] <= abs_vtc[5]) ? {abs_vtc[4], abs_vtc[5], 3'd4} : {abs_vtc[5], abs_vtc[4], 3'd5};
        {min1_67, max1_67, idx1_67} = (abs_vtc[6] <= abs_vtc[7]) ? {abs_vtc[6], abs_vtc[7], 3'd6} : {abs_vtc[7], abs_vtc[6], 3'd7};
    end

    // TẦNG 2: So sánh những người thắng ở Tầng 1
    logic [W-2:0] min2_03, min2_47;
    logic [W-2:0] max2_03, max2_47;
    logic [2:0]   idx2_03, idx2_47;
    
    always_comb begin
        {min2_03, max2_03, idx2_03} = (min1_01 <= min1_23) ? {min1_01, min1_23, idx1_01} : {min1_23, min1_01, idx1_23};
        {min2_47, max2_47, idx2_47} = (min1_45 <= min1_67) ? {min1_45, min1_67, idx1_45} : {min1_67, min1_45, idx1_67};
    end

    // TẦNG 3: Tìm ra MIN1 (Người chiến thắng cuối cùng)
    logic [W-2:0] min3_final;
    
    always_comb begin
        {min1, min3_final, min1_idx} = (min2_03 <= min2_47) ? {min2_03, min2_47, idx2_03} : {min2_47, min2_03, idx2_47};
    end

    // TẦNG 4: Tìm ra MIN2 (Submin)
    // Giá trị submin chắc chắn là 1 trong 3 phần tử đã trực tiếp để thua MIN1 ở 3 tầng trên.
    logic [W-2:0] submin1, submin2;
    
    always_comb begin
        // Xác định phần tử thua cấp 1 và cấp 2 của nhánh chứa MIN1
        if (min1_idx < 4) begin 
            submin2 = max2_03; // Thua ở tầng 2 nhánh trái
            submin1 = (min1_idx < 2) ? max1_01 : max1_23; // Thua ở tầng 1 nhánh trái
        end else begin
            submin2 = max2_47; // Thua ở tầng 2 nhánh phải
            submin1 = (min1_idx < 6) ? max1_45 : max1_67; // Thua ở tầng 1 nhánh phải
        end
        
        // Tìm min của 3 phần tử thua: submin1, submin2 và min3_final (thua ở tầng 3)
        // Việc này có thể gộp thành logic song song:
        if (submin1 <= submin2 && submin1 <= min3_final)
            min2 = submin1;
        else if (submin2 <= submin1 && submin2 <= min3_final)
            min2 = submin2;
        else
            min2 = min3_final;
    end

endmodule