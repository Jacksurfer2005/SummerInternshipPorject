`timescale 1ns/1ns

module tb_iter_counter();

    // 1. Parameters and Signals
    parameter bit DONE = 1;
    parameter int ITER_W = 5;

    logic              clk;
    logic              rst_n;
    logic              clear;
    logic              iter_done;
    logic              converged;
    logic [ITER_W-1:0] max_iter;
    logic [ITER_W-1:0] iter_cnt;
    logic              done;

    // 2. DUT Instantiation
    iter_counter #(
        .DONE(DONE),
        .ITER_W(ITER_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),
        .iter_done(iter_done),
        .converged(converged),
        .max_iter(max_iter),
        .iter_cnt(iter_cnt),
        .done(done)
    );

    // 3. Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Chu kỳ 10ns
    end

    // 4. Test Stimulus
    initial begin
        // Khởi tạo
        rst_n = 0;
        clear = 0;
        iter_done = 0;
        converged = 0;
        max_iter = 5'd8;

        #15 rst_n = 1;
        
        // Bắt đầu đếm vòng lặp
        @(posedge clk) clear = 1;
        @(posedge clk) clear = 0;

        // Mô phỏng các vòng lặp chưa hội tụ
        repeat (3) begin
            #10;
            @(posedge clk) iter_done = 1;
            @(posedge clk) iter_done = 0;
        end

        // Mô phỏng hội tụ sớm
        #10;
        @(posedge clk) begin
            iter_done = 1;
            converged = 1;
        end
        @(posedge clk) iter_done = 0;

        #30 $finish;
    end

    // Monitor
    initial begin
        $monitor("Time=%0t | rst_n=%b clear=%b iter_done=%b converged=%b | iter_cnt=%0d done=%b", 
                 $time, rst_n, clear, iter_done, converged, iter_cnt, done);
    end

endmodule