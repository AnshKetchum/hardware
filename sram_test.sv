module sram_test;
    
    // Clock generation
    logic clk = 1'b0;
    always #10 clk = ~clk;
    
    // SRAM signals
    logic [31:0] data_out;
    logic [31:0] data_in;
    logic [9:0]  addr;
    logic        enable;
    logic        read_write_b;  // 1 = read, 0 = write
    
    // Instantiate SRAM
    CF_SRAM_1024x32_macro sram (
        .DO         (data_out),
        .DI         (data_in),
        .AD         (addr),
        .CLKin      (clk),
        .EN         (enable),
        .R_WB       (read_write_b),
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
    
    initial begin
        $display("\n=== SRAM Interaction Test ===\n");
        
        // Initialize
        enable = 1'b0;
        read_write_b = 1'b1;
        addr = 10'd0;
        data_in = 32'd0;
        
        // Wait for SRAM to settle
        repeat(10) @(posedge clk);
        
        // Test 1: Write a value
        $display("Test 1: Writing 0xDEADBEEF to address 5");
        @(posedge clk);
        enable = 1'b1;
        read_write_b = 1'b0;  // Write mode
        addr = 10'd5;
        data_in = 32'hDEADBEEF;
        
        @(posedge clk);
        enable = 1'b0;
        
        // Wait a bit
        repeat(2) @(posedge clk);
        
        // Test 2: Read back the value
        $display("Test 2: Reading from address 5");
        @(posedge clk);
        enable = 1'b1;
        read_write_b = 1'b1;  // Read mode
        addr = 10'd5;
        
        @(posedge clk);
        @(posedge clk);  // Wait for data to be available
        $display("  Read data: 0x%08X (expected 0xDEADBEEF)", data_out);
        
        enable = 1'b0;
        
        // Test 3: Write another value
        $display("\nTest 3: Writing 0x12345678 to address 100");
        @(posedge clk);
        enable = 1'b1;
        read_write_b = 1'b0;
        addr = 10'd100;
        data_in = 32'h12345678;
        
        @(posedge clk);
        enable = 1'b0;
        
        repeat(2) @(posedge clk);
        
        // Test 4: Read it back
        $display("Test 4: Reading from address 100");
        @(posedge clk);
        enable = 1'b1;
        read_write_b = 1'b1;
        addr = 10'd100;
        
        @(posedge clk);
        @(posedge clk);
        $display("  Read data: 0x%08X (expected 0x12345678)", data_out);
        
        enable = 1'b0;
        
        // Test 5: Read from address 5 again to verify first write persisted
        $display("\nTest 5: Re-reading from address 5");
        @(posedge clk);
        enable = 1'b1;
        read_write_b = 1'b1;
        addr = 10'd5;
        
        @(posedge clk);
        @(posedge clk);
        $display("  Read data: 0x%08X (expected 0xDEADBEEF)", data_out);
        
        $display("\n=== Test Complete ===\n");
        $finish;
    end
    
endmodule