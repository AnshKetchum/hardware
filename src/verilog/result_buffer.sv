/*
* Module describing a 64-bit result buffer and the mux for controlling where
* in the buffer an adder's result is placed.
* 
* synchronous active high reset on posedge clk
* This module can and should be modified but the interface should not be changed.
*/
module result_buffer import calculator_pkg::*; (
    // DO NOT CHANGE ANY OF THESE PORTS
    input logic     clk_i,                          //clock signal
    input logic     rst_i,                          //reset signal
    input logic     [DATA_W-1 : 0] result_i,        //result from ALU
    input logic     loc_sel,                        //mux control signal
    output logic    [MEM_WORD_SIZE-1 : 0] buffer_o //64-bit output of buffer
);
    // You can make any modifications inside the module
    // MEM_WORD_SIZE >= 2 * DATA_WIDTH
    logic [MEM_WORD_SIZE-1 : 0] internal_buffer;

    // loc_sel is 1, slot the top 32 bits into the buffer
    // loc_sel is 0, slot the bottom 32 bits
    always_ff @(posedge clk_i) begin
        if(rst_i) begin 
            internal_buffer <= 0;
        end else begin 
            if(loc_sel == 1) begin 
                internal_buffer[MEM_WORD_SIZE-1:DATA_W] <= result_i;
            end else begin 
                internal_buffer[DATA_W-1:0] <= result_i;
            end 
        end 
    end

    // output buffer 
    assign buffer_o = internal_buffer;
endmodule