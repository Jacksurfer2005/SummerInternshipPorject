`timescale 1ns / 1ns

module min_submin_calc #(
    parameter W = 8,
    parameter DEG = 8 
)(
    input  logic signed [W-1:0] vtc_in [0:DEG-1],
    output logic        [W-2:0] min1,
    output logic        [W-2:0] min2,
    output logic        [2:0]   min1_idx,
    output logic                signs_xor,
    output logic                vtc_signs [0:DEG-1]
);
    logic [W-2:0] abs_vtc [0:DEG-1];
    logic signed [W-1:0] vtc_sat [0:DEG-1];
    logic temp_sign_xor;
    
    // Tạo hằng số cho giá trị âm lớn nhất dựa trên W
    localparam logic signed [W-1:0] MIN_VAL = {1'b1, {(W-1){1'b0}}}; 
    localparam logic signed [W-1:0] SAT_VAL = {1'b1, {(W-2){1'b0}}, 1'b1};

    always_comb begin
        temp_sign_xor = 1'b0;
        
        for (int i = 0; i < DEG; i++) begin
            // overflow when abs
            vtc_sat[i] = (vtc_in[i] == MIN_VAL) ? SAT_VAL : vtc_in[i];
            
            // sign bit and abs calc
            vtc_signs[i]  = vtc_sat[i][W-1]; 
            abs_vtc[i]    = (vtc_signs[i]) ? -vtc_sat[i] : vtc_sat[i];
            
            // xor all the signs
            temp_sign_xor = temp_sign_xor ^ vtc_signs[i];
        end
        signs_xor = temp_sign_xor;

        // init Min1, Min2 bằng giá trị lớn nhất có thể của độ lớn
        min1 = '{default: 1'b1}; 
        min2 = '{default: 1'b1};
        min1_idx = '0;

        // find Min1 and Min2
        for (int i = 0; i < DEG; i++) begin
            if (abs_vtc[i] < min1) begin
                min2 = min1;
                min1 = abs_vtc[i];
                min1_idx = i[2:0]; // Chỉ hoạt động đúng nếu DEG <= 8
            end else if (abs_vtc[i] < min2) begin
                min2 = abs_vtc[i];
            end
        end
    end
endmodule