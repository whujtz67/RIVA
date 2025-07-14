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

  // TODO: Temporary parameters
  localparam int unsigned NrLanes = 4;
  localparam int unsigned VLEN = 8192;
  localparam int unsigned ALEN = 16384;


  // ================= Data Width Parameters ================= //
  parameter int unsigned busBits       = 512;            // Data bus width
  parameter int unsigned addrBits      = 32;            // Address bus width
  parameter int unsigned idBits        = 1;             // AXI ID width
  
  // ================= Buffer and Cache Parameters ================= //
  parameter int unsigned reqBufDep     = 4;           // Instruction Queue depth
  parameter int unsigned metaBufDepth  = 4;           // Meta buffer depth
  parameter int unsigned txnCtrlNum    = 4;           // Number of transaction controllers
  parameter int unsigned wBufDep       = 2;           // Write buffer depth for SequentialStore
  parameter int unsigned seqInfoBufDep = 2;           // Sequential info buffer depth
  parameter int unsigned shfInfoBufDep = 2;           // Shuffle info buffer depth

  // ================= VAddr Parameters ================= //
  parameter int unsigned NrVregs      = 16;
  parameter int unsigned NrAregs      = 16;
  parameter int unsigned NrSetPerVreg = VLEN / NrLanes / DLEN / NrVRFBanksPerLane;
  parameter int unsigned NrSetPerAreg = ALEN / NrLanes / DLEN / NrVRFBanksPerLane;
  parameter int unsigned NrVRFSets    = NrVregs * NrSetPerVreg + NrAregs * NrSetPerAreg;
  parameter int unsigned AregBaseSet  = NrVregs * NrSetPerVreg;

  // vdMsb: used for part-select of vd field (e.g. vd[vdMsb-1:0])
  parameter int unsigned vdMsb = $clog2(NrVregs);

  parameter int unsigned VAddrSetBits = $clog2(NrVRFSets);
  parameter int unsigned VAddrOffBits = $clog2(NrVRFBanksPerLane);
  parameter int unsigned VAddrBits    = VAddrSetBits + VAddrOffBits;

  typedef logic [VAddrSetBits-1:0] vaddr_set_t;
  typedef logic [VAddrOffBits-1:0] vaddr_off_t;
  typedef logic [VAddrBits   -1:0] vaddr_t;
  
  // ================= Derived Parameters ================= //
  parameter int unsigned busBytes      = busBits / 8;
  parameter int unsigned busNibbles    = busBits / 4;

endpackage : vlsu_pkg

`endif // VLSU_PKG_SV


