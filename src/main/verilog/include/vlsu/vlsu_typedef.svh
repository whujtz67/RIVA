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

  // ================= VLSU Request Structure ================= //

  // VLSU request structure (based on RivaReqPtl)
  // This structure contains all the information needed to initiate a vector load/store operation
  typedef struct packed {
    vid_t               reqId;        // Request ID for tracking and debugging
    logic [1:0]         mop;          // Memory operation mode (0: unit-stride, 1: strided, 2: indexed)
    elen_t              baseAddr;     // Base address for the vector operation
    riscv_mv_pkg::vew_e sew;          // Element width encoding (00: 4b, 01: 8b, 10: 16b, 11: 32b)
    logic [4:0]         vd;           // Vector destination register index
    elen_t              stride;       // Stride value for strided access mode
    maxlen_t            len;          // Total number of elements to process
    elen_t              vstart;       // Starting element index (for partial vector operations)
    logic               isLoad;       // 1: load operation, 0: store operation
    logic               vm;           // Vector mask enable (1: masked, 0: unmasked)
  } vlsu_req_t;
    
  // ------------------------------------------------------------------------
  // Control Machine Type Definitions
  // ------------------------------------------------------------------------
    
  // Global metadata structure
  // Contains global information decoded from the VLSU request
  // Most fields remain unchanged throughout the request processing
  typedef struct packed {
    vid_t               reqId;        // Request ID for tracking and debugging
    vlsu_pkg::mode_oh_e mode;         // Memory operation mode (one-hot encoded)
    elen_t              baseAddr;     // Base address for the vector operation
    logic [4:0]         vd;           // Vector destination register index
    riscv_mv_pkg::vew_e sew;          // Element width encoding (00: 4b, 01: 8b, 10: 16b, 11: 32b)
    maxlen_t            nrEffElems;   // Number of elements to process (len - vstart)
    elen_t              stride;       // Stride value for strided access mode
    logic               vm;           // Vector mask enable (1: masked, 0: unmasked)
    elen_t              vstart;       // Starting element index for partial vector operations
    rmn_grp_t           rmnGrp;       // Remaining groups (for 2D column-major mode)
    maxlen_t            rmnSeg;       // Remaining segments within current group
    logic               isLoad;       // 1: load operation, 0: store operation
    cmt_cnt_t           cmtCnt;       // Commit counter (used to determine when to dequeue meta buffer)
  } meta_glb_t;
    
  // Segment-level metadata structure
  // Contains segment-level information for the current memory segment
  // This information is updated as transactions are issued within the segment
  typedef struct packed {
    elen_t             segBaseAddr;       // Base address of the current segment
    txn_num_t          txnNum;            // Total number of transactions needed for this segment
    txn_num_t          txnCnt;            // Current transaction count within this segment
    logic [13:0]       ltN;               // Number of nibbles in the last transaction (1 ~ 4096 * 2)
  } meta_seglv_t;
    
  // Transaction control info structure (based on TxnCtrlInfo)
  // Contains transaction-level control information for AXI bus transactions
  // This structure is derived from MetaCtrlInfo.segLevel information
  typedef struct packed {
    vid_t              reqId;             // Request ID (not always needed, defined for debug convenience)
    elen_t             addr;              // Transaction address
    axi_pkg::size_t    size;              // AXI transaction size
    rmn_beat_t         rmnBeat;           // Remaining beats in current transaction
    lbn_t              lbN;               // Number of nibbles in the last beat
    logic              isHead;            // 1: first transaction in segment, 0: subsequent transactions
    logic              isLoad;            // 1: load operation, 0: store operation
    logic              isFinalTxn;        // 1: final transaction of the entire request
  } txn_ctrl_t;

  // ================= Lane Data Structures ================= //
  
  // TxLane structure (based on Chisel TxLane)
  // Contains data to be sent from VLSU to lane units
  // Note: reqId and vaddr are the same for all lanes, but included for simplicity
  typedef struct packed {
    vid_t              reqId;             // Request ID for tracking and debugging
    vaddr_set_t        vaddr_set;         // VRF set address
    vaddr_bank_t       vaddr_bank;        // VRF bank address
    logic [DLEN-1:0]   data;              // Data bits (DLEN = 128 bits)
    logic [DLEN/4-1:0] nbe;               // Nibble byte enable (half byte enable)
  } tx_lane_t;
  
  // RxLane structure (based on Chisel RxLane)
  // Contains data received from lane units to VLSU
  typedef struct packed {
    logic [DLEN-1:0]   data;              // Data bits (DLEN = 128 bits)
  } rx_lane_t;
  
  // LaneSide structure (based on Chisel LaneSide)
  // Contains arrays of TxLane and RxLane for all lanes
  typedef struct packed {
    tx_lane_t [NrExits-1:0] txs;          // Transmit lanes (VLSU to lanes)
    rx_lane_t [NrExits-1:0] rxs;          // Receive lanes (lanes to VLSU)
  } lane_side_t;