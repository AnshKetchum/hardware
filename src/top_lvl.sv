/* 
 * This top_level module integrates the controller, memory, adder, and result buffer to form a complete calculator system.
 * It handles memory reads/writes, arithmetic operations, and result buffering.
 */
module top_lvl import calculator_pkg::*; (
    input  logic                 clk,
    input  logic                 rst,

    // Memory Config
    input  logic [ADDR_W-1:0]    read_start_addr,
    input  logic [ADDR_W-1:0]    read_end_addr,
    input  logic [ADDR_W-1:0]    write_start_addr,
    input  logic [ADDR_W-1:0]    write_end_addr
    
);

    // Controller wires
    logic                       write, read;
	logic [ADDR_W-1:0]          r_addr, w_addr;
    logic [MEM_WORD_SIZE-1:0]   r_data;
    logic [31:0]                op_a,   op_b;
    logic                       carry_in, carry_out;
    logic                       buffer_control;

    // Result buffer wires
    logic [MEM_WORD_SIZE-1:0]   buffer_word;   // 64-bit output of buffer

    // Splitting up read and write data buses
    logic [DATA_W-1:0]          w_data_lower, w_data_upper;
    logic [DATA_W-1:0]          r_data_lower, r_data_upper;



   
	controller u_ctrl (
        .clk_i              (clk),
        .rst_i              (rst),
        .read_start_addr    (read_start_addr ),
        .read_end_addr      (read_end_addr   ),
        .write_start_addr   (write_start_addr),
        .write_end_addr     (write_end_addr  ),
        .write              (write),
        .w_addr             (w_addr),
        .w_data             (w_data),
        .read               (read),
        .r_addr             (r_addr),
        .r_data             (r_data),
        .buffer_control     (buffer_control),
        .op_a               (op_a),
        .op_b               (op_b),
        .carry_in           (carry_in),
        .carry_out          (carry_out),
        .buff_result        (buffer_word)
    );

    // TODO: Instantiate two SRAM A here 
    CF_SRAM_1024x32_macro sram_A (
        .DO         (r_data_lower), // data output
        .DI         (w_data_lower), // data input
        .AD         (write ? w_addr : w_addr), // 10-bit address
        .CLKin      (clk), // Clock input             
        .EN         (1'b1), // Global enable
        .R_WB       (~write), // Read enable

        // DO NOT MODIFY THE FOLLOWING PINS
        .BEN        (32'hFFFF_FFFF),    
        .TM         (1'b0),            
        .SM         (1'b0),            
        .WLBI       (1'b0),            
        .WLOFF      (1'b0),            
        .ScanInCC   (1'b0),
        .ScanInDL   (1'b0),
        .ScanInDR   (1'b0),
        .ScanOutCC  (),                
        .vpwrac     (1'b1),            
        .vpwrpc     (1'b1)
    );
    
    // TODO: Instantiate two SRAM B here
    CF_SRAM_1024x32_macro sram_B (
        .DO         (r_data_upper), // data output
        .DI         (w_data_upper), // data input
        .AD         (write ? w_addr : r_addr), // 10-bit address
        .CLKin      (clk), // Clock input             
        .EN         (1'b1), // Global enable
        .R_WB       (~write), // Read enable

        // DO NOT MODIFY THE FOLLOWING PINS
        .BEN        (32'hFFFF_FFFF),    
        .TM         (1'b0),            
        .SM         (1'b0),            
        .WLBI       (1'b0),            
        .WLOFF      (1'b0),            
        .ScanInCC   (1'b0),
        .ScanInDL   (1'b0),
        .ScanInDR   (1'b0),
        .ScanOutCC  (),                
        .vpwrac     (1'b1),            
        .vpwrpc     (1'b1)
    );

  	// You can but do not need to modify the adder declaration
    logic [DATA_W - 1:0] sum32;
    adder32 u_adder (
        .a_i    (op_a),
        .b_i    (op_b),
        .c_i    (carry_in),
        .c_o    (carry_out),
        .sum_o  (sum32)
    );

   	// You can but do not need to modify the result buffer declaration
    result_buffer u_resbuf (
        .clk_i            (clk),
        .rst_i           (rst),
        .result_i          (sum32),
        .buffer_o  (buffer_word)
    );
endmodule