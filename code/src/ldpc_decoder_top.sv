`timescale 1ns / 1ns

module ldpc_decoder #(
    parameter W = 8,
    parameter DEG = 8
)(
    input  logic clk,
    input  logic rst_n,
    input  logic iter_done_tick,
    input  logic signed [W-1:0] app_in [0:DEG-1],
    input  logic signed [W-1:0] ctv_in [0:DEG-1],
    
    output logic         ready,
    output logic         decoded_out [0:DEG-1],
    output logic signed [W-1:0] app_new [0:DEG-1],
    output logic signed [W-1:0] ctv_new [0:DEG-1]
);
    // Tín hiệu nội bộ
    logic max_iter_reached;
    logic signed [W-1:0] app_to_vtc [0:DEG-1];
    logic signed [W-1:0] vtc_net    [0:DEG-1];
    
    logic [DEG-1:0] temp;
    assign ready = &temp;
    logic [W-2:0] min1, min2;
    logic [2:0]   min1_idx;
    logic         signs_xor;
    logic         vtc_signs [0:DEG-1];

    // 1. Iterations Counter
    iterations_counter u_iter_count (
        .clk(clk),
        .rst_n(rst_n),
        .iter_done_tick(iter_done_tick),
        .max_iter_reached(max_iter_reached)
    );

    // Xử lý song song cho DEG nút (thường được unroll trong phần cứng thực)
    genvar i;
    generate
        for (i = 0; i < DEG; i++) begin : gen_processing_nodes
            // 2. Operating Mode
            mode_selection #(W) u_op_mode (
                .max_iter_reached(max_iter_reached),
                .app_valid(1'b1),
                .app_in(app_in[i]),
                .app_to_vtc(app_to_vtc[i]),
                .ready(temp[i]),
                .decoded_out(decoded_out[i])
            );

            // 3. VTC Calc
            vtc_calc #(W) u_vtc (
                .app_in(app_to_vtc[i]),
                .ctv_in(ctv_in[i]),
                .vtc_out(vtc_net[i])
            );
        end
    endgenerate

    // 4. Min/Submin
    min_submin_calc #(W, DEG) u_min_submin (
        .vtc_in(vtc_net),
        .min1(min1),
        .min2(min2),
        .min1_idx(min1_idx),
        .signs_xor(signs_xor),
        .vtc_signs(vtc_signs)
    );

    // 5. CTV & APP Calc
    ctv_app_calc #(W, DEG) u_ctv_app (
        .min1(min1),
        .min2(min2),
        .min1_idx(min1_idx),
        .signs_xor(signs_xor),
        .vtc_signs(vtc_signs),
        .vtc_in(vtc_net),
        .ctv_new(ctv_new),
        .app_new(app_new)
    );

endmodule