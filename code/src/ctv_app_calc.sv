`timescale 1ns / 1ns

module ctv_app_calc #(
    parameter W = 8,
    parameter DEG = 8
)(
    input  logic        [W-2:0] min1,
    input  logic        [W-2:0] min2,
    input  logic        [2:0]   min1_idx,
    input  logic                signs_xor,
    input  logic                vtc_signs [0:DEG-1],
    input  logic signed [W-1:0] vtc_in    [0:DEG-1],
    
    output logic signed [W-1:0] ctv_new   [0:DEG-1],
    output logic signed [W-1:0] app_new   [0:DEG-1]
);
    logic ctv_sign;
    logic [W-2:0] ctv_mag;

    always_comb begin
        for (int i = 0; i < DEG; i++) begin
            // new sign for ctv
            ctv_sign = signs_xor ^ vtc_signs[i]; 
            // min or submin
            ctv_mag = (i == min1_idx) ? min2 : min1;
            // combine sign and mag
            ctv_new[i] = ctv_sign ? -ctv_mag : ctv_mag;
            // update new app
            app_new[i] = vtc_in[i] + ctv_new[i];
        end
    end
endmodule