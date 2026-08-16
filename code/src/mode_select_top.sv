`timescale 1ns/1ns

module mode_select_top (
    input  logic        clk,
    input  logic        reset_n,
    input  logic        start,
    input  logic        count_en,

    input  logic [7:0]  max_iteration,

    input  logic [7:0]  decoding_data,
    input  logic [7:0]  result_data,

    output logic [7:0]  iteration_count,
    output logic        done,
    output logic        mode,
    output logic        ready,
    output logic [7:0]  output_data
);

    // ========================================================
    // 1. ITERATION COUNTER
    // ========================================================
    iteration_counter u_iteration_counter (
        .clk     (clk),
        .reset_n (reset_n),
        .start   (start),
        .enable  (count_en),
        .count   (iteration_count)
    );


    // ========================================================
    // 2. ITERATION COMPARATOR
    // ========================================================
    iter_compare u_iter_compare (
        .iteration_count (iteration_count),
        .max_iteration   (max_iteration),
        .done            (done)
    );


    // ========================================================
    // 3. MODE CONTROL
    // ========================================================
    //
    // done = 0:
    //     MODE = DECODING
    //     READY = 0
    //
    // done = 1:
    //     MODE = RESULT
    //     READY = 1
    //
    assign mode  = done;
    assign ready = done;
   
    assign output_data = mode ? result_data : decoding_data;

endmodule