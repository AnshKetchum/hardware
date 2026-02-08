import random

# Configuration
NUM_WORDS = 512  # Number of 64-bit values to add (addresses 0-511)
WRITE_START = 768  # 0b110000000 = 768
READ_END = 511      # 0b011111111 = 511

def generate_test_files():
    """Generate pre-state and expected post-state memory files"""
    
    # Generate random 64-bit operands
    operand_a = []
    operand_b = []
    
    for i in range(NUM_WORDS):
        # Generate random 64-bit values (split into upper and lower 32-bit parts)
        a_val = random.randint(0, 2**64 - 1)
        b_val = random.randint(0, 2**64 - 1)
        operand_a.append(a_val)
        operand_b.append(b_val)
    
    # Calculate expected results (64-bit addition with wraparound)
    results = []
    for a, b in zip(operand_a, operand_b):
        result = (a + b) & 0xFFFFFFFFFFFFFFFF  # 64-bit wraparound
        results.append(result)
    
    # Write pre-state files (memory layout)
    # Addresses 0-255: operand_a values
    # Addresses 256-511: operand_b values
    # Addresses 512-767: unused
    # Addresses 768-1023: results will be written here
    
    with open('memory_pre_state_lower.txt', 'w') as f:
        # Write operand_a lower 32 bits (addresses 0-255)
        for val in operand_a[:256]:
            f.write(f"{val & 0xFFFFFFFF:032b}\n")
        # Write operand_b lower 32 bits (addresses 256-511)
        for val in operand_b[:256]:
            f.write(f"{val & 0xFFFFFFFF:032b}\n")
        # Unused space (addresses 512-767)
        for _ in range(256):
            f.write("00000000000000000000000000000000\n")
        # Result space (addresses 768-1023) - initially zeros
        for _ in range(256):
            f.write("00000000000000000000000000000000\n")
    
    with open('memory_pre_state_upper.txt', 'w') as f:
        # Write operand_a upper 32 bits (addresses 0-255)
        for val in operand_a[:256]:
            f.write(f"{(val >> 32) & 0xFFFFFFFF:032b}\n")
        # Write operand_b upper 32 bits (addresses 256-511)
        for val in operand_b[:256]:
            f.write(f"{(val >> 32) & 0xFFFFFFFF:032b}\n")
        # Unused space (addresses 512-767)
        for _ in range(256):
            f.write("00000000000000000000000000000000\n")
        # Result space (addresses 768-1023) - initially zeros
        for _ in range(256):
            f.write("00000000000000000000000000000000\n")
    
    # Write expected post-state files (what results should be)
    with open('memory_post_state_lower.txt', 'w') as f:
        # First 768 addresses should match pre-state
        for val in operand_a[:256]:
            f.write(f"{val & 0xFFFFFFFF:032b}\n")
        for val in operand_b[:256]:
            f.write(f"{val & 0xFFFFFFFF:032b}\n")
        for _ in range(256):
            f.write("00000000000000000000000000000000\n")
        # Addresses 768-1023: expected results (lower 32 bits)
        for val in results[:256]:
            f.write(f"{val & 0xFFFFFFFF:032b}\n")
    
    with open('memory_post_state_upper.txt', 'w') as f:
        # First 768 addresses should match pre-state
        for val in operand_a[:256]:
            f.write(f"{(val >> 32) & 0xFFFFFFFF:032b}\n")
        for val in operand_b[:256]:
            f.write(f"{(val >> 32) & 0xFFFFFFFF:032b}\n")
        for _ in range(256):
            f.write("00000000000000000000000000000000\n")
        # Addresses 768-1023: expected results (upper 32 bits)
        for val in results[:256]:
            f.write(f"{(val >> 32) & 0xFFFFFFFF:032b}\n")
    
    # Print some test cases for verification
    print("Generated test files successfully!")
    print("\nSample test cases (first 5):")
    for i in range(5):
        print(f"  [{i}] 0x{operand_a[i]:016X} + 0x{operand_b[i]:016X} = 0x{results[i]:016X}")

if __name__ == "__main__":
    generate_test_files()