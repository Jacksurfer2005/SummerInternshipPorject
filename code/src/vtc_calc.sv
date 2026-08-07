`timescale 1ns / 1ns

module vtc_calc #(
    parameter W = 8
)(
    input  logic signed [W-1:0] app_in,
    input  logic signed [W-1:0] ctv_in,
    output logic signed [W-1:0] vtc_out
);

    logic signed [W:0] temp_vtc;    //9
    
    localparam logic signed [W-1:0] MAX_VAL = {1'b0, {(W-1){1'b1}}}; 
    localparam logic signed [W-1:0] MIN_VAL = {1'b1, {(W-1){1'b0}}}; 
    
    always_comb begin
        temp_vtc = app_in - ctv_in;        
        if (temp_vtc > MAX_VAL) begin
            vtc_out = MAX_VAL;
        end else if (temp_vtc < MIN_VAL) begin
            vtc_out = MIN_VAL;
        end else begin
            vtc_out = temp_vtc[W-1:0];
        end
    end

endmodule