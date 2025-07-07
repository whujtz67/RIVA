// ============================================================================
// vlsu_typedef.svh
// VLSU type definitions as macro definitions
// ============================================================================
//
// PURPOSE:
// This file contains type definitions for VLSU (Vector Load Store Unit) that are
// used as type parameters passed to submodules. It is designed to be included
// only in the top-level VLSU.sv file.
//
// DESIGN RATIONALE:
// - Centralized type definitions to avoid code duplication
// - Type parameters are passed to submodules rather than redefined in each module
// - Separated into a dedicated file to keep VLSU.sv clean and focused on logic
//
// USAGE:
// 1. Include this file only in VLSU.sv (top-level module)
// 2. Use the defined types as type parameters when instantiating submodules
// 3. Submodules receive these types as parameters and use them directly
// 4. No need to redefine these types in individual submodules
//
// ============================================================================

`ifndef VLSU_TYPEDEF_SVH
`define VLSU_TYPEDEF_SVH

// ================= VLSU Request Structure ================= //

// VLSU request structure (based on RivaReqPtl)
typedef struct packed {
  vid_t              reqId;
  logic [1:0]        mop;
  elen_t             baseAddr;
  rvmv_pkg::vew_e    sew;
  logic [4:0]        vd;
  elen_t             stride;
  vlen_t             len;
  vlen_t             vstart;
  logic              isLoad;
  logic              vm;
} vlsu_req_t;

// ================= Typedef Macros ================= //

// Global metadata structure
`define VLSU_TYPEDEF_META_GLB_T(meta_glb_t, rmn_grp_t, rmn_seg_t, cmt_t) \
  typedef struct packed {                                       \
    vid_t               reqId;                                   \
    vlsu_pkg::mode_oh_t mode;                                   \
    elen_t              baseAddr;                                \
    logic [4:0]         vd;                                      \
    rvmv_pkg::vew_e     sew;                                     \
    vlen_t              nrElem;                                  \
    elen_t              stride;                                  \
    logic               vm;                                      \
    vlen_t              vstart;                                  \
    rmn_grp_t           rmnGrp;                                  \
    rmn_seg_t           rmnSeg;                                  \
    logic               isLoad;                                  \
    cmt_t               cmtCnt;                                  \
  } meta_glb_t

// Segment-level metadata structure
`define VLSU_TYPEDEF_META_SEGLV_T(meta_seglv_t, txn_num_t, ltn_t) \
  typedef struct packed {                                       \
    elen_t             segBaseAddr;                             \
    txn_num_t          txnNum;                                  \
    txn_num_t          txnCnt;                                  \
    ltn_t              ltN;                                     \
  } meta_seglv_t

// Transaction control info structure (based on TxnCtrlInfo)
`define VLSU_TYPEDEF_TXN_CTRL_T(txn_ctrl_t, rmn_beat_t, lbn_t) \
  typedef struct packed {                                       \
    vid_t              reqId;                                   /* Not always needed, defined for debug convenience */ \
    elen_t             addr;                                    \
    axi_pkg::size_t    size;                                    \
    rmn_beat_t         rmnBeat;                                 \
    lbn_t              lbN;                                     \
    logic              isHead;                                  \
    logic              isLoad;                                  \
    logic              isFinalTxn;                              \
  } txn_ctrl_t

`endif // VLSU_TYPEDEF_SVH
