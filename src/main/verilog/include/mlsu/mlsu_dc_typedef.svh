// ============================================================================
// mlsu_dc_typedef.svh
// MLSU DataCtrl type definitions as macro definitions
// ============================================================================
//
// PURPOSE:
// This file contains type definitions for MLSU DataCtrl modules that are
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



  // ================= DataCtrl Type Definitions ================= //
  // SeqBufBundle equivalent (from SequentialPkg.scala)
  // Contains nibbles and enables for sequential buffer
  typedef struct packed {
    logic [4*(NrLaneEntriesNbs)-1:0] nb;    // nibbles
    logic [NrLaneEntriesNbs    -1:0] en;    // nibble enables
  } seq_buf_t;

  // ShfInfoBufBundle equivalent (from ShufflePkg.scala)
  // Contains essential meta info related to DataController saved in MetaBuf
  typedef struct packed {                                                                  
    vid_t                                reqId;      /* Request ID */                      
    logic [3:0]                          mode;       /* Matrix operation mode (one-hot) */ 
    riscv_mv_pkg::vew_e                  sew;        /* Element width encoding */          
    logic [4:0]                          md;         /* Matrix destination register */    
    logic                                vm;         /* Matrix mask enable */              
    logic [$clog2(MLEN*ELEN/DLEN)-1:0]   cmtCnt;     /* Commit counter */                  
    maddr_set_t                          maddr_set;  /* Matrix address set */             
    maddr_bank_t                         maddr_bank; /* Matrix address bank */            
  } shf_info_t;
