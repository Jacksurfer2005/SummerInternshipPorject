`timescale 1ns / 1ns

module tb_mode_selection;
    localparam W = 8;
    logic max_iter_reached, app_valid;
    logic signed [W-1:0] app_in;
    logic signed [W-1:0] app_to_vtc;
    logic ready, decoded_out;

    mode_selection #(W) dut (
        .max_iter_reached(max_iter_reached), 
        .app_valid(app_valid),
        .app_in(app_in),
        .app_to_vtc(app_to_vtc),
        .ready(ready), 
        .decoded_out(decoded_out)
    );

    initial begin
        $dumpfile("tb_mode_selection.vcd");
        $dumpvars(0, tb_mode_selection);

        // Mode đang tính toán
        max_iter_reached = 0; app_valid = 1; app_in = 8'sd25; #10;
        $display("Iterating Mode: app_to_vtc=%d, ready=%b, decoded=%b", app_to_vtc, ready, decoded_out);
        
        // Mode kết thúc, kiểm tra số dương
        max_iter_reached = 1; app_in = 8'sd15; #10;
        $display("Max Iter (APP>0): app_to_vtc=%d, ready=%b, decoded=%b", app_to_vtc, ready, decoded_out);
        
        // Mode kết thúc, kiểm tra số âm
        max_iter_reached = 1; app_in = -8'sd5; #10;
        $display("Max Iter (APP<0): app_to_vtc=%d, ready=%b, decoded=%b", app_to_vtc, ready, decoded_out);
        
        $finish;
    end
endmodule