`timescale 1ns / 1ns

module tb_iterations_counter;
    logic clk, rst_n, iter_done;
    logic max_iter_reached;

    iterations_counter #(5) dut (
        .clk(clk), 
        .rst_n(rst_n), 
        .iter_done(iter_done),
        .max_iter_reached(max_iter_reached)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_iterations_counter.vcd");
        $dumpvars(0, tb_iterations_counter);
        
        clk = 0; rst_n = 0; iter_done = 0;
        #15 rst_n = 1;
        
        // Mô phỏng 6 vòng lặp (MAX = 5)
        for(int i=0; i<6; i++) begin
            @(posedge clk);
            iter_done = 1;
            @(posedge clk);
            iter_done = 0;
            $display("Lần lặp %d, max_iter_reached = %b", i+1, max_iter_reached);
        end
        
        #20 $finish;
    end
endmodule