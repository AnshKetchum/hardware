module tb_calculator import calculator_pkg::*; ();
    //=============== Generate the clock =================
    localparam CLK_PERIOD = 20; //Set clock period: 20 ns
    localparam DUTY_CYCLE = 0.5;
    //define clock
    logic clk_tb;
    
    initial begin
	forever //run the clock forever
	begin		
		#(CLK_PERIOD*DUTY_CYCLE) clk_tb = 1'b1; //wait duty cycle then set clock high
		#(CLK_PERIOD*DUTY_CYCLE) clk_tb = 1'b0; //wait duty cycle then set clock low
	end
	end 

    //======== Define wires going into your module ========
    logic             rst_tb;   // global
    logic [ADDR_W-1:0] read_start_addr_tb, read_end_addr_tb;  //input read addresses
    logic [ADDR_W-1:0] write_start_addr_tb, write_end_addr_tb;  //input write addresses

    //======== Expected addition result signal ========
    logic [31:0] expected_post_lower [0:1023];
    logic [31:0] expected_post_upper [0:1023];
    logic [63:0] expected_result;
    logic [ADDR_W-1:0] current_write_addr;

    // Track current write address from controller
    assign current_write_addr = DUT.w_addr;

    // Get expected result from post-state files
    assign expected_result = {expected_post_upper[current_write_addr], expected_post_lower[current_write_addr]};

    //========= Instantiate a gcd module ==============
    top_lvl DUT (
        .clk                (clk_tb),
        .rst                (rst_tb),
        .read_start_addr    (read_start_addr_tb),
        .read_end_addr      (read_end_addr_tb),
        .write_start_addr   (write_start_addr_tb),
        .write_end_addr     (write_end_addr_tb)
    ) ;
    
    initial begin
        // Dump waveforms
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_calculator);
        // $shm_open("waves.shm");
        // $shm_probe("AC");
        
        $display("\n--------------Beginning Simulation!--------------\n");
        $display("Time: %t", $time);
        initialize_signals();

        // Wait for SRAM to settle
        #100;
        
        // Wait a few clock cycles with reset high
        repeat(5) @(posedge clk_tb);
        
        $display("--------------Releasing Reset---------------\n");
        $display("Time: %t", $time);
        rst_tb = 1'b0;
        
        // Wait for completion or timeout
        fork 
            begin
                wait(DUT.u_ctrl.state == S_END);
                #100;
            end
            begin
                #100000;
            end
        join_any
        $display("\n-------------Finished Simulation!----------------\n");
        $display("Time: %t", $time);
        $display("Cycle Count: %0d cycles (from S_IDLE to S_END)", DUT.u_ctrl.cycle_count);
        $writememb("sim_memory_post_state_lower.txt", DUT.sram_A.memory_mode_inst.memory);
        $writememb("sim_memory_post_state_upper.txt", DUT.sram_B.memory_mode_inst.memory);
        $finish;
    end

    //Task to set the initial state of the signals. Task is called up above
    // task initialize_signals();
    // begin
    //     $display("--------------Initializing Signals---------------\n");
    //     $display("Time: %t", $time);

    //     // Load memory files AFTER SRAM's initial wipe at 1ns
    //     #2;

    //     // Initialize control signals
    //     rst_tb              = 1'b1;
    //     read_start_addr_tb  = 10'd0;
    //     read_end_addr_tb    = 10'd511;
    //     write_start_addr_tb = 10'd768;
    //     write_end_addr_tb   = 10'd1023;

    //     $readmemb("memory_pre_state_lower.txt", DUT.sram_A.memory_mode_inst.memory);
    //     $readmemb("memory_pre_state_upper.txt", DUT.sram_B.memory_mode_inst.memory);

    //     $readmemb("memory_post_state_lower.txt", expected_post_lower);
    //     $readmemb("memory_post_state_upper.txt", expected_post_upper);
    // end
    // endtask

    task initialize_signals();
    begin
        $display("--------------Initializing Signals---------------\n");
        $display("Time: %t", $time);

        #2;

        rst_tb              = 1'b1;
        read_start_addr_tb  = 10'd0;
        read_end_addr_tb    = 10'd511;
        write_start_addr_tb = 10'd768;
        write_end_addr_tb   = 10'd1023;

        // Fill both SRAMs with all 1's
        for (i = 0; i < 1024; i = i + 1) begin
            DUT.sram_A.memory_mode_inst.memory[i] = 32'hFFFFFFFF;
            DUT.sram_B.memory_mode_inst.memory[i] = 32'hFFFFFFFF;
        end

        // Expected result arrays (optional)
        for (i = 0; i < 1024; i = i + 1) begin
            expected_post_lower[i] = 32'hFFFFFFFE;
            expected_post_upper[i] = 32'h00000001;
        end

    end
    endtask

	
endmodule