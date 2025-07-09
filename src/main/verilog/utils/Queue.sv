// ============================================================================
// Queue.sv
// Parameterized hardware queue (FIFO) with ready/valid interface
// Inspired by Chisel3 Queue implementation
// ============================================================================

`timescale 1ns/1ps

module Queue #(
  parameter type T = logic,
  parameter int unsigned DEPTH = 2,
  parameter bit PIPE = 0,
  parameter bit FLOW = 0
) (
  input  logic clk_i,
  input  logic rst_ni,
  // Enqueue interface
  input  logic        enq_valid_i,
  output logic        enq_ready_o,
  input  T            enq_bits_i,
  // Dequeue interface
  output logic        deq_valid_o,
  input  logic        deq_ready_i,
  output T            deq_bits_o
);
  // Storage
  T      ram      [DEPTH];
  logic [$clog2(DEPTH)-1:0] enq_ptr, deq_ptr;
  logic                     maybe_full;
  logic                     ptr_match, empty, full;
  logic                     do_enq, do_deq;

  assign ptr_match = (enq_ptr == deq_ptr);
  assign empty     = ptr_match && !maybe_full;
  assign full      = ptr_match && maybe_full;

  assign do_enq = enq_valid_i && enq_ready_o;
  assign do_deq = deq_valid_o && deq_ready_i;

  // Ready/valid logic
  assign enq_ready_o = !full;
  assign deq_valid_o = !empty;

  // Data output
  assign deq_bits_o = ram[deq_ptr];

  // Write
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      enq_ptr    <= '0;
      deq_ptr    <= '0;
      maybe_full <= 1'b0;
    end else begin
      if (do_enq) begin
        ram[enq_ptr] <= enq_bits_i;
        enq_ptr      <= enq_ptr + 1'b1;
      end
      if (do_deq) begin
        deq_ptr      <= deq_ptr + 1'b1;
      end
      if (do_enq != do_deq)
        maybe_full <= do_enq;
    end
  end

  // Flow mode: bypass when empty
  generate if (FLOW) begin
    always_comb begin
      if (enq_valid_i) begin
        deq_valid_o = 1'b1;
        if (empty) begin
          deq_bits_o = enq_bits_i;
        end
      end
    end
  end endgenerate

  // Pipe mode: ready always high when deq_ready_i
  generate if (PIPE) begin
    always_comb begin
      if (deq_ready_i) enq_ready_o = 1'b1;
    end
  end endgenerate

endmodule
