`timescale 1ns / 1ns

module iterations_counter #(
    parameter int MAX = 10
)(
    input  logic clk,
    input  logic rst_n,
    input  logic iter_done,
    output logic max_iter_reached
);
    logic [4:0] count;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= '0;
        end else if (iter_done) begin
            if (count < MAX) begin
                count <= count + 1'b1;
            end
        end
    end

    assign max_iter_reached = (count >= MAX);

endmodule				