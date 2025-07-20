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
    ROW_MAJOR_OH  = 4'b0001,  // Row-major mode
    COL_MAJOR_OH  = 4'b0010,  // Column-major mode
    TRANSPOSE_OH  = 4'b0100,  // Transpose mode
    RESHAPE_OH    = 4'b1000   // Reshape mode
  } m_mode_oh_e;

  // TODO: Temporary parameters
  localparam int unsigned NrExits = 4;
  localparam int unsigned MLEN    = 8192;


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

  // ================= MAddr Parameters ================= //
  // TODO: Maddr logics might be different.
  parameter int unsigned NrMregs      = 16;
  parameter int unsigned NrSetPerMreg = MLEN / NrExits / DLEN / NrVRFBanksPerLane;
  parameter int unsigned NrMRFSets    = NrMregs * NrSetPerMreg;

  parameter int unsigned MAddrSetBits  = $clog2(NrMRFSets);
  parameter int unsigned MAddrBankBits = $clog2(NrVRFBanksPerLane);
  parameter int unsigned MAddrBits     = MAddrSetBits + MAddrBankBits;

  typedef logic [MAddrSetBits -1:0] maddr_set_t;
  typedef logic [MAddrBankBits-1:0] maddr_bank_t;
  typedef logic [MAddrBits    -1:0] maddr_t;
  
  // ================= Derived Parameters ================= //
  parameter int unsigned busBytes      = busBits / 8;
  parameter int unsigned busNibbles    = busBits / 4;

endpackage : mlsu_pkg

`endif // MLSU_PKG_SV


