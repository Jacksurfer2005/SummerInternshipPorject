`timescale 1ns / 1ns

module ctv_app_calc #(
    parameter W = 8,
    parameter DEG = 8
)(
    input  logic [3:0]          row_weight, 
    input  logic [W-2:0]        min1,
    input  logic [W-2:0]        min2,
    input  logic [2:0]          min1_idx,
    input  logic                signs_xor,
    input  logic                vtc_signs [0:DEG-1],
    input  logic signed [W-1:0] vtc_in    [0:DEG-1],
    
    output logic signed [W-1:0] ctv_new   [0:DEG-1],
    output logic signed [W-1:0] app_new   [0:DEG-1]
);

    localparam logic signed [W-1:0] MAX_VAL = {1'b0, {(W-1){1'b1}}}; // 8-bit: 127
    localparam logic signed [W-1:0] MIN_VAL = {1'b1, {(W-1){1'b0}}}; // 8-bit: -128

    always_comb begin
        for (int i = 0; i < DEG; i++) begin
            if (i < row_weight) begin
                // Khai báo biến cục bộ bên trong vòng lặp để an toàn khi tổng hợp (Synthesis)
                automatic logic ctv_sign = signs_xor ^ vtc_signs[i]; 
                automatic logic [W-2:0] ctv_mag = (i == min1_idx) ? min2 : min1;
                automatic logic signed [W-1:0] ctv_val = $signed({1'b0, ctv_mag}); // Ép kiểu an toàn
                automatic logic signed [W:0] temp_app;

                // Tính CTV
                ctv_new[i] = ctv_sign ? -ctv_val : ctv_val;
                
                // Tính APP với bão hòa chống tràn
                temp_app = vtc_in[i] + ctv_new[i];
                if (temp_app > MAX_VAL) begin
                    app_new[i] = MAX_VAL;
                end else if (temp_app < MIN_VAL) begin
                    app_new[i] = MIN_VAL;
                end else begin
                    app_new[i] = temp_app[W-1:0];
                end
            end else begin
                // Đệm giá trị 0 cho CTV và giữ nguyên APP với các nhánh ngoài dr
                ctv_new[i] = '0;
                app_new[i] = vtc_in[i];
            end
        end
    end
endmodule