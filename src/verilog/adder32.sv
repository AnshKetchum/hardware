`timescale 1ns/1ps/*
* Module describing a 32-bit ripple carry adder, with no carry output or input.
*
* You can and should modify this file but do NOT change the interface.
*/
module adder32 #(
    parameter int DATA_W = 32
)(
    // DO NOT MODIFY THE PORTs
    input logic [DATA_W - 1 : 0]    a_i, // First operand
    input logic [DATA_W - 1 : 0]    b_i, // Second operand
    input logic                     c_i, // Carry input
    output logic                    c_o, // Carry output
    output logic [DATA_W - 1 : 0]   sum_o // Sum output
);

    // You can modify anything below this line. You are required to use
    // full_adder.sv to build this module.
    
    //TODO: Declare any internal signals you need here.
    logic [DATA_W:0] carries;

    // Hint: You need an intermediary signal to handle the carry bits between adders.
    assign carries[0] = c_i;
    assign c_o = carries[DATA_W];
    // TODO: use a generate block to chain together 32 full adders.

    // generate block for building the large adder out of smaller, full adders
    // Hint: Think about looping w/ a module declaration
    generate
        genvar i;
		for (i = 0; i < DATA_W; i = i+1) begin
          full_adder fa_inst (
            .a (a_i[i]), 
            .b (b_i[i]), 
            .cin (carries[i]),
            .s (sum_o[i]), 
            .cout (carries[i+1])
            );
		end

    endgenerate
endmodule
