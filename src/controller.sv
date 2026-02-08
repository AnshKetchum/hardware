/* 
 *	Controller module for DD onboarding.
 *	Manages reading from memory, performing additions, and writing results back to memory.
 *
 *	This module can and should be modified but do not change the interface.
*/
module controller import calculator_pkg::*;(
	// DO NOT MODIFY THESE PORTS
  	input  logic              clk_i,
    input  logic              rst_i,
  
  	// Memory Access
    input  logic [ADDR_W-1:0] read_start_addr,
    input  logic [ADDR_W-1:0] read_end_addr,
    input  logic [ADDR_W-1:0] write_start_addr,
    input  logic [ADDR_W-1:0] write_end_addr,
  
  	// Memory Controls
    output logic 						write,
	output logic 						read,
    output logic [ADDR_W-1:0]			w_addr,
    output logic [MEM_WORD_SIZE-1:0]	w_data,
    output logic [ADDR_W-1:0]			r_addr,
    input  logic [MEM_WORD_SIZE-1:0]	r_data,
  	// Buffer Control (1 = upper, 0, = lower)
    output logic buffer_control,
  
  	// These go into adder
  	output logic [DATA_W-1:0] op_a,
    output logic [DATA_W-1:0] op_b,
	// Carry input for adder
	output logic carry_in,	// Carry input to adder
	input  logic carry_out, // Carry output from adder
	
	// What is being stored in the buffer
    input  logic [MEM_WORD_SIZE-1:0] buff_result
  
); 
	// DO NOT MODIFY THIS BLOCK: Count how many cycles the controller has been active
	logic [31:0] cycle_count;
	always_ff @(posedge clk_i) begin
		if (rst_i)
			cycle_count <= 32'd0;
		else
			cycle_count <= cycle_count + 1'b1;
	end
	//=========================================================================
	// You can change anything below this line. There is a skeleton but feel
	// free to modify as much as you want.
	//=========================================================================
	// Declare state machine states
    state_t state, next;
	
	// Registers to hold read data and address pointers
	logic [ADDR_W-1:0] op_a_addr, op_b_addr, w_ptr;
  	logic [MEM_WORD_SIZE-1:0] op_a_reg;
	logic [MEM_WORD_SIZE-1:0] op_b_reg; 
	logic carry_reg;
	
	// Intermediate wires for bit slicing (avoids iverilog warning)
	logic [DATA_W-1:0] op_a_lower, op_a_upper;
	logic [DATA_W-1:0] op_b_lower, op_b_upper;
	
	assign op_a_lower = op_a_reg[31:0];
	assign op_a_upper = op_a_reg[63:32];
	assign op_b_lower = op_b_reg[31:0];
	assign op_b_upper = op_b_reg[63:32];

	// Helper for r_data slicing
	logic [DATA_W-1:0] r_data_lower, r_data_upper;
	assign r_data_lower = r_data[31:0];
	assign r_data_upper = r_data[63:32];
	
	// Calculate midpoint between read_start and read_end
	// Operand A is in first half, Operand B is in second half
	logic [ADDR_W-1:0] read_mid_addr;
	assign read_mid_addr = read_start_addr + ((read_end_addr - read_start_addr + 1) >> 1);
	
	//Next state logic
	always_comb begin
		case (state)
			S_IDLE:      next = S_READ;   
			S_READ:      next = S_READ2;   
			S_READ2:     next = S_ADD; 
			S_ADD:		 next = S_ADD2;
			S_ADD2:		 next = S_WRITE;
			S_WRITE: begin
				// Check if we've processed all operand A values
				if (op_a_addr >= read_mid_addr - 1)
					next = S_END;
				else
					next = S_READ;
				end
			S_END: next = S_END;
			default: next = S_IDLE;
		endcase
	end
	
	// Sequential part of state machine implementation
	always_ff @(posedge clk_i) begin
		if (rst_i) begin
			op_a_addr <= read_start_addr;
			op_b_addr <= read_mid_addr;
			w_ptr <= write_start_addr;
			op_a_reg <= '0;
			op_b_reg <= '0;
			carry_reg <= '0;
			state <= S_IDLE;
		end
		else begin
			state <= next;
			
			// CRITICAL: Account for 1-cycle SRAM read latency
			// r_data has the data from the PREVIOUS cycle's read request
			case (state)
				S_READ2: begin
					// r_data now contains operand A (requested in S_READ)
					op_a_reg <= r_data;
				end
				S_ADD: begin
					// r_data now contains operand B (requested in S_READ2)
					op_b_reg <= r_data;
				end
				S_ADD2: begin
					// Capture carry out from lower addition (performed in S_ADD)
					carry_reg <= carry_out;
				end
				S_WRITE: begin
					// Move to next pair of operands and next write location
  					op_a_addr <= op_a_addr + 1'b1;
					op_b_addr <= op_b_addr + 1'b1;
					w_ptr <= w_ptr + 1'b1;
					// Reset carry for next addition
					carry_reg <= 1'b0;
				end
			endcase
		end
	end
	
	// Combinational output logic
	always_comb begin
        // Default values
       	write = 1'b0;
		read  = 1'b0;
    	r_addr = op_a_addr;  // Default to reading op_a address
    	w_addr = w_ptr;
		w_data = buff_result;
    	op_a   = '0;
    	op_b   = '0;
    	carry_in = 1'b0;
		buffer_control = LOWER;  
		
        case (state)  
            S_IDLE: begin
                // Do nothing
            end
			S_READ: begin
				// Request read of operand A
				// Data will be available next cycle in r_data
 				read = 1'b1;
				r_addr = op_a_addr;
			end
			S_READ2: begin
				// Request read of operand B
				// Data will be available next cycle in r_data
				// NOTE: r_data currently has operand A from previous cycle
				read = 1'b1;
				r_addr = op_b_addr;
			end			
			S_ADD: begin
				// Perform lower 32-bit addition
				// NOTE: op_b_reg is updated at the END of this cycle
				// So we use r_data directly for op_b
				op_a = op_a_reg[31:0];
				op_b = r_data[31:0];
				carry_in = 1'b0;
				buffer_control = LOWER;
			end
			S_ADD2: begin
				// Perform upper 32-bit addition with carry
				op_a = op_a_reg[63:32];
				op_b = op_b_reg[63:32];
				carry_in = carry_reg; 
				buffer_control = UPPER;
			end
			S_WRITE: begin
				// Write result to memory
				write = 1'b1;
				w_data = buff_result;
				w_addr = w_ptr;
			end
            S_END: begin
                // Defaults
            end
        endcase
    end
	
endmodule
