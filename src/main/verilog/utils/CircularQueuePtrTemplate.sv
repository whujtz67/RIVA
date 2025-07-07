// ============================================================================
// CircularQueuePtrTemplate.sv
// SystemVerilog implementation of circular queue pointer based on Chisel design
// 
// This module implements a single circular queue pointer with parameterized width.
// The pointer consists of a flag bit and a value field, similar to Chisel's 
// CircularQueuePtr implementation. The increment logic is optimized for both
// power-of-2 and non-power-of-2 queue sizes.
// ============================================================================

module CircularQueuePtrTemplate #(
  parameter int ENTRIES = 16,                    // Queue depth (number of entries)
  // Dependent parameters, DO NOT OVERRIDE!
  parameter int unsigned PTR_WIDTH = $clog2(ENTRIES)  // Auto-calculated pointer width
) (
  input  logic                  clk_i,          // Clock input
  input  logic                  rst_ni,         // Active-low reset

  // Pointer increment control
  input  logic                  ptr_inc_i,      // Pointer increment enable

  // Pointer output
  output logic                  ptr_flag_o,     // Flag bit (MSB of combined pointer)
  output logic [PTR_WIDTH-1:0]  ptr_value_o     // Value field (LSB of combined pointer)
);

  // ================= Static Parameters ================= //
  // Check if entries is power of 2 (static calculation at compile time)
  // This determines which increment algorithm to use
  localparam bit IS_POW2 = (ENTRIES & (ENTRIES - 1)) == 0;
  
  // ================= Internal Registers ================= //
  // Current pointer state (registered)
  logic                  ptr_flag_r, ptr_flag_nxt;    // Flag bit register and next state
  logic [PTR_WIDTH-1:0]  ptr_value_r, ptr_value_nxt;  // Value register and next state
  
  // ================= Internal Signals ================= //
  // Temporary signals for pointer increment logic
  logic [PTR_WIDTH:0] combined;    // Combined flag+value for power-of-2 case
  logic [PTR_WIDTH:0] new_val;     // Extended value for overflow detection
  logic overflow;                  // Overflow flag for non-power-of-2 case
  
  // ================= Pointer Increment Logic ================= //
  // Combinational logic for next pointer state
  // Implements the same logic as Chisel's CircularQueuePtr + operator
  always_comb begin
    // Default: hold current state
    ptr_flag_nxt = ptr_flag_r;
    ptr_value_nxt = ptr_value_r;
    
    if (ptr_inc_i) begin
      if (IS_POW2) begin
        // ================= Power-of-2 Optimization ================= //
        // For power-of-2 entries, use hardware-friendly concatenation method
        // This leverages natural overflow behavior of binary addition
        // Algorithm: {flag, value} + 1, then split back to {flag, value}
        combined = {ptr_flag_r, ptr_value_r} + 1;
        ptr_flag_nxt = combined[PTR_WIDTH];           // MSB becomes new flag
        ptr_value_nxt = combined[PTR_WIDTH-1:0];      // LSB becomes new value
      end else begin
        // ================= Non-Power-of-2 Logic ================= //
        // For non-power-of-2 entries, use explicit overflow detection
        // This matches Chisel's implementation exactly
        new_val = ptr_value_r + 1;                    // Increment value
        overflow = new_val > (ENTRIES - 1);           // Check for overflow
        ptr_flag_nxt = overflow ^ ptr_flag_r;         // Toggle flag on overflow
        ptr_value_nxt = overflow ? (new_val - ENTRIES) : new_val;  // Wrap value
      end
    end
  end
  
  // ================= Sequential Logic ================= //
  // Register update logic with synchronous reset
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      // Reset to initial state
      ptr_flag_r  <= 1'b0;
      ptr_value_r <= '0;
    end else begin
      // Update with next state
      ptr_flag_r  <= ptr_flag_nxt;
      ptr_value_r <= ptr_value_nxt;
    end
  end
  
  // ================= Output Assignments ================= //
  // Connect internal registers to output ports
  assign ptr_flag_o  = ptr_flag_r;
  assign ptr_value_o = ptr_value_r;

endmodule : CircularQueuePtrTemplate
