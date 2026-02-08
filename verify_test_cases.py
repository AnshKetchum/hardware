def read_binary_file(filename):
    """Read a binary memory file and return list of 32-bit integers"""
    values = []
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            # Skip empty lines and comments
            if line and not line.startswith('//'):
                # Convert binary string to integer
                values.append(int(line, 2))
    return values

def verify_results():
    """Verify simulation results against expected values"""
    
    print("="*70)
    print("Verifying Simulation Results")
    print("="*70)
    
    # Read pre-state files (inputs)
    print("\nReading input files...")
    pre_lower = read_binary_file('memory_pre_state_lower.txt')
    pre_upper = read_binary_file('memory_pre_state_upper.txt')
    
    # Read expected post-state files
    print("Reading expected output files...")
    expected_lower = read_binary_file('memory_post_state_lower.txt')
    expected_upper = read_binary_file('memory_post_state_upper.txt')
    
    # Read simulation results
    print("Reading simulation output files...")
    try:
        sim_lower = read_binary_file('sim_memory_post_state_lower.txt')
        sim_upper = read_binary_file('sim_memory_post_state_upper.txt')
    except FileNotFoundError as e:
        print(f"\nERROR: Simulation output file not found: {e}")
        print("Make sure you've run the simulation first!")
        return False
    
    print(f"  Pre-state lower: {len(pre_lower)} words")
    print(f"  Pre-state upper: {len(pre_upper)} words")
    print(f"  Expected lower: {len(expected_lower)} words")
    print(f"  Expected upper: {len(expected_upper)} words")
    print(f"  Simulated lower: {len(sim_lower)} words")
    print(f"  Simulated upper: {len(sim_upper)} words")
    
    # Verify lengths
    min_len = min(len(sim_lower), len(sim_upper), len(expected_lower), len(expected_upper))
    
    if len(sim_lower) != len(expected_lower):
        print(f"\nWARNING: Length mismatch in lower memory!")
        print(f"  Expected: {len(expected_lower)} words")
        print(f"  Simulated: {len(sim_lower)} words")
    
    if len(sim_upper) != len(expected_upper):
        print(f"\nWARNING: Length mismatch in upper memory!")
        print(f"  Expected: {len(expected_upper)} words")
        print(f"  Simulated: {len(sim_upper)} words")
    
    # Check results in the write region (addresses 768-1023)
    WRITE_START = 768
    NUM_RESULTS = min(256, min_len - WRITE_START)
    
    print(f"\nVerifying results at addresses {WRITE_START}-{WRITE_START + NUM_RESULTS - 1}...")
    
    errors = []
    matches = 0
    
    for i in range(NUM_RESULTS):
        addr = WRITE_START + i
        
        if addr >= len(sim_lower) or addr >= len(sim_upper):
            print(f"\nERROR: Address {addr} out of range in simulation output")
            break
        
        if addr >= len(expected_lower) or addr >= len(expected_upper):
            print(f"\nERROR: Address {addr} out of range in expected output")
            break
        
        # Get 64-bit values
        expected_64 = (expected_upper[addr] << 32) | expected_lower[addr]
        sim_64 = (sim_upper[addr] << 32) | sim_lower[addr]
        
        if expected_64 == sim_64:
            matches += 1
        else:
            errors.append({
                'addr': addr,
                'input_addr': i,  # Offset in operand arrays
                'expected': expected_64,
                'simulated': sim_64
            })
    
    # Print results
    print("\n" + "="*70)
    print("VERIFICATION RESULTS")
    print("="*70)
    print(f"Total test cases: {NUM_RESULTS}")
    print(f"Passed: {matches}")
    print(f"Failed: {len(errors)}")
    
    if len(errors) == 0:
        print("\n✓ ALL TESTS PASSED! Your calculator works correctly!")
    else:
        print(f"\n✗ {len(errors)} ERRORS FOUND")
        print("\nShowing first 10 errors:")
        
        for idx, err in enumerate(errors[:10]):
            addr = err['addr']
            input_addr = err['input_addr']
            
            # Reconstruct the inputs (check bounds first)
            if input_addr < len(pre_lower) and (input_addr + 256) < len(pre_lower):
                operand_a = (pre_upper[input_addr] << 32) | pre_lower[input_addr]
                operand_b = (pre_upper[input_addr + 256] << 32) | pre_lower[input_addr + 256]
                expected_sum = (operand_a + operand_b) & 0xFFFFFFFFFFFFFFFF
                
                print(f"\n  Error #{idx + 1} at address {addr}:")
                print(f"    Operand A: 0x{operand_a:016X}")
                print(f"    Operand B: 0x{operand_b:016X}")
                print(f"    A + B:     0x{expected_sum:016X}")
                print(f"    Expected:  0x{err['expected']:016X}")
                print(f"    Simulated: 0x{err['simulated']:016X}")
                
                if err['simulated'] == 0:
                    print(f"    ** Simulated value is zero - memory not written? **")
                elif err['simulated'] == operand_a:
                    print(f"    ** Simulated equals operand A - only copied? **")
                elif err['simulated'] == operand_b:
                    print(f"    ** Simulated equals operand B - only copied? **")
        
        if len(errors) > 10:
            print(f"\n  ... and {len(errors) - 10} more errors")
    
    # Verify that input memory wasn't corrupted (if it exists)
    print("\n" + "="*70)
    print("Checking input memory integrity...")
    print("="*70)
    
    input_corrupted = False
    corruption_count = 0
    for i in range(min(512, len(pre_lower), len(sim_lower))):  # Check addresses 0-511 (inputs)
        if (sim_lower[i] != pre_lower[i]) or (sim_upper[i] != pre_upper[i]):
            if not input_corrupted:
                print(f"\nWARNING: Input memory was modified!")
                input_corrupted = True
            corruption_count += 1
            if corruption_count <= 5:  # Show first few corruptions
                print(f"  Address {i}: expected 0x{(pre_upper[i] << 32) | pre_lower[i]:016X}, got 0x{(sim_upper[i] << 32) | sim_lower[i]:016X}")
    
    if not input_corrupted:
        print("✓ Input memory unchanged (good!)")
    else:
        print(f"✗ Total corrupted addresses: {corruption_count}")
    
    print("\n" + "="*70)
    
    return len(errors) == 0

if __name__ == "__main__":
    success = verify_results()
    exit(0 if success else 1)