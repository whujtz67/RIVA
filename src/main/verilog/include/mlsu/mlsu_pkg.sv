// ============================================================================
// mlsu_pkg.sv
// MLSU package definitions
// ============================================================================

`ifndef MLSU_PKG_SV
`define MLSU_PKG_SV

package mlsu_pkg;

  import riva_pkg::*;
  
  typedef enum logic [1:0] {
    ROW_MAJOR  = 2'b00,
    COL_MAJOR  = 2'b01,
    TRANSPOSE  = 2'b10,
    RESHAPE    = 2'b11
  } m_mop_e;

  // ================= Mode One-Hot Encoding ================= //
  typedef enum logic [3:0] {
    ROW_MAJOR  = 4'b0001,  // Row-major mode
    COL_MAJOR  = 4'b0010,  // Column-major mode
    TRANSPOSE  = 4'b0100,  // Transpose mode
    RESHAPE    = 4'b1000   // Reshape mode
  } m_mode_oh_t;

  // TODO: Temporary parameters
  localparam int unsigned NrExits = 4;
  localparam int unsigned VLEN = 8192;
  localparam int unsigned ALEN = 16384;


  // ================= Data Width Parameters ================= //
  parameter int unsigned busBits       = 512;            // Data bus width
  parameter int unsigned addrBits      = 32;            // Address bus width
  parameter int unsigned idBits        = 1;             // AXI ID width
  
  // ================= Buffer and Cache Parameters ================= //
  // The Buffer/Queue depth should be power of 2 because Queue and CircularQueuePtr do not support non-power-of-2 depth currently!
  parameter int unsigned reqBufDep     = 4;           // Instruction Queue depth
  parameter int unsigned metaBufDepth  = 4;           // Meta buffer depth
  parameter int unsigned txnCtrlNum    = 4;           // Number of transaction controllers
  parameter int unsigned wBufDep       = 2;           // Write buffer depth for SequentialStore
  parameter int unsigned seqInfoBufDep = 2;           // Sequential info buffer depth. Should be power of 2!
  parameter int unsigned shfInfoBufDep = 2;           // Shuffle info buffer depth. Should be power of 2!

  // ================= VAddr Parameters ================= //
  parameter int unsigned NrVregs      = 16;
  parameter int unsigned NrAregs      = 16;
  parameter int unsigned NrSetPerVreg = VLEN / NrExits / DLEN / NrVRFBanksPerLane;
  parameter int unsigned NrSetPerAreg = ALEN / NrExits / DLEN / NrVRFBanksPerLane;
  parameter int unsigned NrVRFSets    = NrVregs * NrSetPerVreg + NrAregs * NrSetPerAreg;
  parameter int unsigned AregBaseSet  = NrVregs * NrSetPerVreg;

  // vdMsb: used for part-select of vd field (e.g. vd[vdMsb-1:0])
  parameter int unsigned vdMsb = $clog2(NrVregs);

  parameter int unsigned VAddrSetBits  = $clog2(NrVRFSets);
  parameter int unsigned VAddrBankBits = $clog2(NrVRFBanksPerLane);
  parameter int unsigned VAddrBits     = VAddrSetBits + VAddrBankBits;

  typedef logic [VAddrSetBits -1:0] vaddr_set_t;
  typedef logic [VAddrBankBits-1:0] vaddr_bank_t;
  typedef logic [VAddrBits    -1:0] vaddr_t;
  
  // ================= Derived Parameters ================= //
  parameter int unsigned busBytes      = busBits / 8;
  parameter int unsigned busNibbles    = busBits / 4;

endpackage : mlsu_pkg

`endif // MLSU_PKG_SV


