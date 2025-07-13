// ============================================================================
// vlsu_dc_typedef.svh
// VLSU DataCtrl type definitions as macro definitions
// ============================================================================
//
// PURPOSE:
// This file contains type definitions for VLSU DataCtrl modules that are
// used internally by LoadUnit and StoreUnit. These types are
// defined based on the corresponding Chisel bundle definitions.
//
// DESIGN RATIONALE:
// - Centralized type definitions to avoid code duplication
// - Types are defined based on Chisel SeqBufBundle, SeqInfoBundle, and ShfInfoBufBundle
// - Separated into a dedicated file to keep DataCtrl modules clean and focused
//
// USAGE:
// 1. Include this file in LoadUnit.sv and StoreUnit.sv
// 2. Use the defined types directly in the modules
// 3. No need to pass these types as parameters since they are internal
//
// ============================================================================

`ifndef VLSU_DC_TYPEDEF_SVH
`define VLSU_DC_TYPEDEF_SVH

  // ================= DataCtrl Type Definitions ================= //
  // SeqBufBundle equivalent (from SequentialPkg.scala)
  // Contains nibbles and enables for sequential buffer
  typedef struct packed {
    logic [$clog2(NrLaneEntriesNbs)-1:0][3:0] nb;    // nibbles
    logic [$clog2(NrLaneEntriesNbs)-1:0]      en;    // nibble enables
  } seq_buf_t;

  // SeqInfoBundle equivalent (from SequentialPkg.scala)
  // Contains sequential nibble pointer for seqInfoBuf
  typedef struct packed {
    logic [$clog2(NrLaneEntriesNbs)-1:0] seqNbPtr;  // sequential nibble pointer
  } seq_info_t;

  // ShfInfoBufBundle equivalent (from ShufflePkg.scala)
  // Contains essential meta info related to DataController saved in MetaBuf
  typedef struct packed {
    vid_t                                req_id;     // Request ID
    logic [3:0]                          mode;       // Vector operation mode (one-hot)
    logic [1:0]                          sew;        // Element width encoding
    logic [4:0]                          vd;         // Vector destination register
    elen_t                               vstart;     // Starting element index
    logic                                vm;         // Vector mask enable
    logic [$clog2(MaxLEN*ELEN/DLEN)-1:0] cmt_cnt;    // Commit counter
    vaddr_set_t                          vaddr_set;  // Virtual address set
    vaddr_off_t                          vaddr_off;  // Virtual address offset
  } shf_info_t;

`endif // VLSU_DC_TYPEDEF_SVH

