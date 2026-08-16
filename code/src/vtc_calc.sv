`timescale 1ns/1ns

module vtc_calc #(
    parameter int DW = 8,
    parameter int Z  = 24
)(
    input  logic signed [Z-1:0][DW-1:0] app_i,
    input  logic signed [Z-1:0][DW-1:0] ctv_i,
    output logic signed [Z-1:0][DW-1:0] vtc_o
);

    localparam int MAX_INT = (1 << (DW-1)) - 1;
    localparam int MIN_INT = -(1 << (DW-1));

    always_comb begin
        for (int i = 0; i < Z; i++) begin
            int diff;

            diff = $signed(app_i[i]) - $signed(ctv_i[i]);

            if (diff > MAX_INT)
                vtc_o[i] = MAX_INT;
            else if (diff < MIN_INT)
                vtc_o[i] = MIN_INT;
            else
                vtc_o[i] = diff;
        end
    end

endmodule
