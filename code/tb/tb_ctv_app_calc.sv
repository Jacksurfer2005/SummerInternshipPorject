`timescale 1ns / 1ns

module tb_ctv_app_calc;
    localparam W = 8, DEG = 8;
    
    logic [W-2:0] min1 = 7'd3, min2 = 7'd8;
    logic [2:0] min1_idx = 3'd3;
    logic signs_xor = 1'b1; // Dấu tổng hợp giả định là âm
    logic vtc_signs [0:DEG-1];
    logic signed [W-1:0] vtc_in [0:DEG-1];
    logic signed [W-1:0] ctv_new [0:DEG-1];
    logic signed [W-1:0] app_new [0:DEG-1];

    ctv_app_calc #(W, DEG) dut (.*);

    initial begin
        for(int i=0; i<DEG; i++) begin
            vtc_in[i] = 8'sd10 + i;
            vtc_signs[i] = (i%2 == 0) ? 1'b0 : 1'b1;
        end
        
        #10;
        for(int i=0; i<DEG; i++) begin
            $display("Node %d: vtc_in=%d, ctv_new=%d, app_new=%d", i, vtc_in[i], ctv_new[i], app_new[i]);
        end
        $finish;
    end
endmodule