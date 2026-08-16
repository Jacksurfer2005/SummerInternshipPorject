`timescale 1ns/1ns

// ============================================================
// Testbench for the complete Mode Selection path
// ============================================================

module tb_mode_select;

    logic       clk;
    logic       reset_n;
    logic       start;
    logic       count_en;

    logic [7:0] max_iteration;

    logic [7:0] decoding_data;
    logic [7:0] result_data;

    logic [7:0] iteration_count;
    logic       done;
    logic       mode;
    logic       ready;
    logic [7:0] output_data;

    mode_select_top dut (
        .clk            (clk),
        .reset_n        (reset_n),
        .start          (start),
        .count_en       (count_en),
        .max_iteration  (max_iteration),
        .decoding_data  (decoding_data),
        .result_data    (result_data),
        .iteration_count(iteration_count),
        .done           (done),
        .mode           (mode),
        .ready          (ready),
        .output_data    (output_data)
    );

    always #5 clk = ~clk;

    initial begin
        clk            = 1'b0;
        reset_n        = 1'b0;
        start          = 1'b0;
        count_en       = 1'b0;
        max_iteration  = 8'd5;

        decoding_data  = 8'h11;
        result_data    = 8'hA5;

        #12;
        reset_n = 1'b1;

        // Start a new decoding operation.
        @(negedge clk);
        start = 1'b1;

        @(negedge clk);
        start = 1'b0;

        // Five decoding iterations.
        repeat (5) begin
            @(negedge clk);
            count_en = 1'b1;

            @(negedge clk);
            count_en = 1'b0;

            #1;
            $display(
                "time=%0t count=%0d done=%b mode=%b ready=%b output=%h",
                $time, iteration_count, done, mode, ready, output_data
            );
        end

        #10;

        if (iteration_count >= max_iteration &&
            done == 1'b1 &&
            mode == 1'b1 &&
            ready == 1'b1 &&
            output_data == result_data) begin

            $display("PASS: RESULT OUTPUT mode reached correctly.");

        end
        else begin

            $display("FAIL: Mode Selection result is incorrect.");

        end

        $finish;
    end

endmodule
