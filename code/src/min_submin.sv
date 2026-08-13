`timescale 1ns/1ns

module min_submin_calc (
    input  logic [7:0] vtc_1,
    input  logic [7:0] vtc_2,
    input  logic [7:0] vtc_3,
    input  logic [7:0] vtc_4,
    input  logic [7:0] vtc_5,
    input  logic [7:0] vtc_6,
    input  logic [7:0] vtc_7,

    output logic [7:0] ctv_1,
    output logic [7:0] ctv_2,
    output logic [7:0] ctv_3,
    output logic [7:0] ctv_4,
    output logic [7:0] ctv_5,
    output logic [7:0] ctv_6,
    output logic [7:0] ctv_7,

    output logic [7:0] min_o,
    output logic [7:0] submin_o,

    output logic [7:0] vtc_o_1,
    output logic [7:0] vtc_o_2,
    output logic [7:0] vtc_o_3,
    output logic [7:0] vtc_o_4,
    output logic [7:0] vtc_o_5,
    output logic [7:0] vtc_o_6,
    output logic [7:0] vtc_o_7,

    output logic [3:0] rowWeight
);
    logic [7:0] abs_0;
    logic [7:0] abs_1;
    logic [7:0] abs_2;
    logic [7:0] abs_3;
    logic [7:0] abs_4;
    logic [7:0] abs_5;
    logic [7:0] abs_6;
    logic [7:0] abs_7;

    logic [6:0] sign_bus;

    logic sign_total;

    logic [7:0] y_1;
    logic [7:0] y_2;
    logic [7:0] y_3;
    logic [7:0] y_4;
    logic [7:0] y_5;
    logic [7:0] y_6;
    logic [7:0] y_7;

    abs_calc dut_abs (
        .x_1(vtc_1),
        .x_2(vtc_2),
        .x_3(vtc_3),
        .x_4(vtc_4),
        .x_5(vtc_5),
        .x_6(vtc_6),
        .x_7(vtc_7),
        .x_8(8'b0),

        .y_1(abs_1),
        .y_2(abs_2),
        .y_3(abs_3),
        .y_4(abs_4),
        .y_5(abs_5),
        .y_6(abs_6),
        .y_7(abs_7),
        .y_8(),

        .sign_o(sign_bus)

    );


    //==================================================
    // SIGNS XORING
    //==================================================

    signs_xoring dut_sign (

        .sign_i(sign_bus),
        .sign_o(sign_total)

    );


    //==================================================
    // MIN / SUBMIN COMPARATOR TREE
    //==================================================

    comp_tree dut_comp (

        .x_1(abs_1),
        .x_2(abs_2),
        .x_3(abs_3),
        .x_4(abs_4),
        .x_5(abs_5),
        .x_6(abs_6),
        .x_7(abs_7),

        .y_1(y_1),
        .y_2(y_2),
        .y_3(y_3),
        .y_4(y_4),
        .y_5(y_5),
        .y_6(y_6),
        .y_7(y_7),

        .min_o(min_o),
        .submin_o(submin_o),

        .vtc_o_1(vtc_o_1),
        .vtc_o_2(vtc_o_2),
        .vtc_o_3(vtc_o_3),
        .vtc_o_4(vtc_o_4),
        .vtc_o_5(vtc_o_5),
        .vtc_o_6(vtc_o_6),
        .vtc_o_7(vtc_o_7),

        .rowWeight(rowWeight)

    );


    //==================================================
    // SIGN INSERTION
    //==================================================

    sign_insertion dut_insert (

        .x_1(y_1),
        .x_2(y_2),
        .x_3(y_3),
        .x_4(y_4),
        .x_5(y_5),
        .x_6(y_6),
        .x_7(y_7),

        .sign_i(sign_bus),
        .sign_total(sign_total),

        .y_1(ctv_1),
        .y_2(ctv_2),
        .y_3(ctv_3),
        .y_4(ctv_4),
        .y_5(ctv_5),
        .y_6(ctv_6),
        .y_7(ctv_7)

    );


endmodule
