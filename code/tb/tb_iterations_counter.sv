`timescale 1ns / 1ns

module tb_iterations_counter();
    parameter MAX = 5;

    logic clk;
    logic rst_n;
    logic iter_done;
    logic max_iter_reached;

    // Instantiate DUT
    iterations_counter #(
        .MAX(MAX)
    ) dut (
        .clk(clk), 
        .rst_n(rst_n), 
        .iter_done(iter_done),
        .max_iter_reached(max_iter_reached)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_iterations_counter.vcd");
        $dumpvars(0, tb_iterations_counter);
        
        clk = 0;
        rst_n = 0;
        iter_done = 0;

        #15 rst_n = 1;

        $display("=== TEST ITERATIONS COUNTER ===");
        
        // Mô phỏng phát xung iter_done vượt quá MAX
        repeat (MAX + 2) begin
            #10;
            iter_done = 1;
            #10;
            iter_done = 0;
            $display("Time: %0t | Count Reached Max: %b", $time, max_iter_reached);
        end

        // Kiểm tra Reset
        #10 rst_n = 0;
        #10 rst_n = 1;
        $display("After Reset | Reached Max: %b (Expected: 0)", max_iter_reached);

        $finish;
    end
endmodule