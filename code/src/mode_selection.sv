`timescale 1ns / 1ns

module mode_selection #(
    parameter W = 8
)(
    input  logic         max_iter_reached,
    input  logic         app_valid,
    input  logic signed [W-1:0] app_in,
    
    output logic signed [W-1:0] app_to_vtc,
    output logic         ready,
    output logic         decoded_out
);
    always_comb begin
        if (max_iter_reached && app_valid) begin
            ready = 1'b1;
            app_to_vtc = '0; // Chặn luồng dữ liệu tiếp tục tính toán
            // Quyết định cứng: nếu APP > 0 thì bit = 0, ngược lại bit = 1
            decoded_out = (app_in > 0) ? 1'b0 : 1'b1;
        end else begin
            ready = 1'b0;
            app_to_vtc = app_in; // Cho phép dữ liệu đi tiếp
            decoded_out = 1'b0;
        end
    end
endmodule