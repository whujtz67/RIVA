// ============================================================================
// vlsu_pkg.sv
// VLSU package definitions
// ============================================================================

`ifndef VLSU_PKG_SV
`define VLSU_PKG_SV

package vlsu_pkg;

  // ================= Mode One-Hot Encoding ================= //
  typedef enum logic [3:0] {
    MODE_INCR  = 4'b0001,  // Incremental mode
    MODE_STRD  = 4'b0010,  // Strided mode  
    MODE_ROW2D = 4'b0100,  // Row-major 2D mode
    MODE_CLN2D = 4'b1000   // Column-major 2D mode
  } mode_oh_t;

endpackage : vlsu_pkg

`endif // VLSU_PKG_SV


