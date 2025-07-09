// ============================================================================
// vlsu_pkg.sv
// VLSU package definitions
// ============================================================================

`ifndef VLSU_PKG_SV
`define VLSU_PKG_SV

package vlsu_pkg;

  import riva_pkg::*;
  
  // ================= Mode One-Hot Encoding ================= //
  typedef enum logic [3:0] {
    MODE_INCR  = 4'b0001,  // Incremental mode
    MODE_STRD  = 4'b0010,  // Strided mode  
    MODE_ROW2D = 4'b0100,  // Row-major 2D mode
    MODE_CLN2D = 4'b1000   // Column-major 2D mode
  } mode_oh_t;

  // ================= Data Width Parameters ================= //
  parameter int unsigned busBits      = 512;            // Data bus width
  parameter int unsigned addrBits     = 32;            // Address bus width
  parameter int unsigned idBits       = 1;             // AXI ID width
  
  // ================= Buffer and Cache Parameters ================= //
  parameter int unsigned metaBufDepth = 4;           // Meta buffer depth
  parameter int unsigned txnCtrlNum   = 4;           // Number of transaction controllers
  parameter int unsigned wBufDep      = 2;           // Write buffer depth for SequentialStore
  
  // ================= Derived Parameters ================= //
  parameter int unsigned busBytes   = busBits / 8;
  parameter int unsigned busNibbles = busBits / 4;

endpackage : vlsu_pkg

`endif // VLSU_PKG_SV


