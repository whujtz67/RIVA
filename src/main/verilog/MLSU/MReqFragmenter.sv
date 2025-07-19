// ============================================================================
// MReqFragmenter.sv
// Matrix Request Fragmenter - Fragments matrix requests into smaller transactions
// ============================================================================




module MReqFragmenter import riva_pkg::*; import mlsu_pkg::*; import MControlMachinePkg::*; #(
  parameter int   unsigned  NrExits           = 0,
  parameter int   unsigned  VLEN              = 0,
  parameter int   unsigned  MLEN              = 0,
  parameter type            mlsu_predec_req_t = logic,
  parameter type            meta_glb_t        = logic,
  parameter type            meta_seglv_t      = logic
) (
  input  logic                  clk_i,
  input  logic                  rst_ni,

  // MLSU pre-decoded request input
  input  logic                  mlsu_req_valid_i,
  output logic                  mlsu_req_ready_o,
  input  mlsu_predec_req_t      mlsu_req_i,

  // Core store pending
  input  logic                  core_st_pending_i,

  // Meta output
  output logic                  meta_valid_o,
  input  logic                  meta_ready_i,
  output meta_glb_t             meta_glb_o,
  output meta_seglv_t           meta_seglv_o,

  // Meta buffer full indicator
  input  logic                  meta_buf_full_i,
  output logic                  meta_buf_enq_valid_o
);

  // ------------------- Helper Functions ------------------- //
  function automatic logic isLastSeg(input meta_glb_t g); // TODO: meta_glb_t cannot reach here?
    return (g.rmnSeg == 0);
  endfunction

  function automatic logic isLastGrp(input meta_glb_t g);
    return (g.rmnGrp == 0);
  endfunction

  function automatic logic isLastTxn(input meta_seglv_t s);
    return (s.txnCnt == s.txnNum);
  endfunction

  function automatic logic isFinalTxn(input meta_glb_t glb, input meta_seglv_t seg);
    return isLastGrp(glb) && isLastSeg(glb) && isLastTxn(seg);
  endfunction

  // FSM States
  typedef enum logic [1:0] {
    S_IDLE         = 2'd0, // Wait for new request
    S_SEG_LV_INIT  = 2'd1, // Initialize segment-level info for new segment
    S_FRAGMENTING  = 2'd2, // Fragmenting: issue transactions for current segment
    S_STALL        = 2'd3  // Stall: wait for resources to become available
  } state_e;

  state_e state_r, state_nxt;

  // Registers for meta info
  meta_glb_t   meta_glb_r, meta_glb_nxt, seglv_init_common_glb_i;
  meta_seglv_t meta_seglv_r, meta_seglv_nxt, seglv_init_common_o;

  // Indicates the first cycle of fragmenting state.
  // This register is used to generate a one-cycle pulse (meta_buf_enq_valid_o)
  // at the start of the S_FRAGMENTING state, ensuring that meta information is only enqueued once per request.
  logic start_fragmenting_r, start_fragmenting_nxt;

  // doUpdate signal
  logic do_update;
  assign do_update = meta_ready_i;

  // seglv_init_common module input signals
  riva_pkg::elen_t           seglv_next_addr;
  logic                      seglv_init_en;

  riva_pkg::elen_t mlsu_req_i.vl;

  // FSM state transition
  always_comb begin
    // Default: hold current state
    state_nxt = state_r;
    case (state_r)
      S_IDLE:         // Wait for new request
        state_nxt = mlsu_req_valid_i ? S_SEG_LV_INIT : S_IDLE;
      S_SEG_LV_INIT:  // Initialize segment-level info, then go to fragmenting or stall
        state_nxt = (core_st_pending_i || meta_buf_full_i) ? S_STALL : S_FRAGMENTING;
      S_FRAGMENTING:  // Issue transactions, return to idle when done
        state_nxt = (isFinalTxn(meta_glb_r, meta_seglv_r) && do_update) ? S_IDLE : S_FRAGMENTING;
      S_STALL:        // Wait for resources, return to fragmenting when ready
        state_nxt = (core_st_pending_i || meta_buf_full_i) ? S_STALL : S_FRAGMENTING;
      default:
        state_nxt = state_r;
    endcase
  end

  // Next meta logic
  always_comb begin
    meta_glb_nxt     = meta_glb_r;
    meta_seglv_nxt   = meta_seglv_r;
    meta_valid_o     = 1'b0;
    mlsu_req_ready_o = 1'b0;

    seglv_init_common_glb_i = meta_glb_r;
    seglv_next_addr  = '0;
    seglv_init_en    = 1'b0;

    case (state_r)
      // Initialize global info from new request
      S_IDLE: begin
        if (mlsu_req_valid_i) begin
          meta_glb_nxt.reqId      = mlsu_req_i.reqId;
          meta_glb_nxt.mode       = mlsu_req_i.mode;     // Has been pre-decoded in MReqPreDecoder
          meta_glb_nxt.baseAddr   = mlsu_req_i.baseAddr; // Has been shifted by 1 in MReqPreDecoder
          meta_glb_nxt.md         = mlsu_req_i.md;
          meta_glb_nxt.sew        = mlsu_req_i.sew;
          meta_glb_nxt.nrEffElems = mlsu_req_i.vl;
          meta_glb_nxt.vm         = mlsu_req_i.vm;
          meta_glb_nxt.stride     = mlsu_req_i.stride;
          meta_glb_nxt.rmnSeg     = isRowMajor(mlsu_req_i.mode) ? mlsu_req_i.vl - 1 : 0;
          meta_glb_nxt.isLoad     = mlsu_req_i.isLoad;
          meta_glb_nxt.cmtCnt     = ((mlsu_req_i.vl << mlsu_req_i.sew) - 1) >> $clog2(NrExits * DLEN / 4);
        end
        // Ready to accept new request in IDLE
        mlsu_req_ready_o = 1'b1;
      end
      // Initialize segment level info for new segment
      S_SEG_LV_INIT: begin
        seglv_next_addr = meta_glb_r.baseAddr;
        seglv_init_en   = 1'b1;
        meta_seglv_nxt  = seglv_init_common_o;
      end
      // Fragmenting: update meta info as transactions are issued
      S_FRAGMENTING: begin
        if (do_update && !isFinalTxn(meta_glb_r, meta_seglv_r)) begin
          if (isLastTxn(meta_seglv_r)) begin
            // Current transaction is the last transaction of the segment, but not the last segment: switch SEG.
            if (!isLastSeg(meta_glb_r)) begin
              // Update global info
              meta_glb_nxt.rmnSeg = meta_glb_r.rmnSeg - 1;

              // Update segment level info
              seglv_next_addr = meta_seglv_r.segBaseAddr + meta_glb_r.stride;
              seglv_init_en   = 1'b1;
              meta_seglv_nxt  = seglv_init_common_o;
            end
          end 
          else begin
            // Current transaction is not the last transaction of the segment: update transaction count.
            meta_seglv_nxt.txnCnt = meta_seglv_r.txnCnt + 1;
          end
        end
        meta_valid_o = 1'b1;
      end
    endcase
  end

  // Generate start_fragmenting_nxt:
  // - Set to 1 when entering S_FRAGMENTING from S_SEG_LV_INIT or S_STALL and resources are available
  // - Cleared after the first cycle of S_FRAGMENTING
  always_comb begin
    start_fragmenting_nxt = start_fragmenting_r;
    if (state_r == S_SEG_LV_INIT || state_r == S_STALL)
      start_fragmenting_nxt = !(core_st_pending_i || meta_buf_full_i);
    else if (state_r == S_FRAGMENTING)
      start_fragmenting_nxt = 1'b0;
  end

  // meta_buf_enq_valid_o is asserted only for one cycle at the start of S_FRAGMENTING,
  // ensuring meta information is enqueued exactly once per request.
  assign meta_buf_enq_valid_o = start_fragmenting_r;

  // Output assignments
  assign meta_glb_o   = meta_glb_r;
  assign meta_seglv_o = meta_seglv_r;

  // seglv_init_common module instantiation
  SegLvInitCommon #(
    .NrExits        (NrExits     ),
    .VLEN           (VLEN        ),
    .MLEN           (MLEN        ),
    .meta_glb_t     (meta_glb_t  ),
    .meta_seglv_t   (meta_seglv_t)
  ) i_seglv_init_common (
    .en_i           (seglv_init_en          ),
    .next_addr_i    (seglv_next_addr        ),
    .glb_i          (seglv_init_common_glb_i),
    .seg_r_i        (meta_seglv_r           ),
    .seg_nxt_o      (seglv_init_common_o    )
  );

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_r             <= S_IDLE;
      meta_glb_r          <= '0;
      meta_seglv_r        <= '0;
      start_fragmenting_r <= 1'b0;
    end else begin
      state_r             <= state_nxt;
      meta_glb_r          <= meta_glb_nxt;
      meta_seglv_r        <= meta_seglv_nxt;
      start_fragmenting_r <= start_fragmenting_nxt;
    end
  end
endmodule : MReqFragmenter

// -----------------------------------------------------------------------------
// SegLvInitCommon: Module version of seglv_init_common
// -----------------------------------------------------------------------------
// This module implements the segment-level initialization logic originally
// written as a function. We use a module instead of a function because the
// logic is relatively complex and we do not want synthesis tools to duplicate
// the hardware three times for each mutually exclusive call site. By using a
// single module instance and multiplexing its inputs, we ensure only one
// hardware implementation is generated and shared.
// -----------------------------------------------------------------------------
module SegLvInitCommon import riva_pkg::*; #(
  parameter  int   unsigned  NrExits        = 0,
  parameter  int   unsigned  VLEN           = 0,
  parameter  int   unsigned  MLEN           = 0,
  parameter  type            meta_glb_t     = logic,       // <-- User must typedef meta_glb_t before instantiating this module
  parameter  type            meta_seglv_t   = logic,       // <-- User must typedef meta_seglv_t before instantiating this module

  // Dependant parameters. DO NOT CHANGE!
  localparam int   unsigned  clog2MaxNbs    = $clog2(MLEN * ELEN / 4)
) (
  input  logic                        en_i,
  input  riva_pkg::elen_t             next_addr_i,
  input  meta_glb_t                   glb_i,
  input  meta_seglv_t                 seg_r_i,

  output meta_seglv_t                 seg_nxt_o
);

  // Mode decode
  wire isRowMajor  = isRowMajor (glb_i.mode);
  wire isColMajor  = isColMajor (glb_i.mode);
  wire isTranspose = isTranspose(glb_i.mode);
  wire isReshape   = isReshape  (glb_i.mode);

  // Calculate number of nibbles in the segment for row-major modes
  logic [clog2MaxNbs   : 0] nr_seg_elems;

  // Select row-major or column-major segment nibbles
  logic [clog2MaxNbs   : 0] nr_seg_nbs;
  logic [12            : 0] page_off;
  logic [clog2MaxNbs   : 0] seg_nibbles_with_pageOff;

  always_comb begin
    // Calculate number of nibbles in the segment for row-major modes - always calculated
    nr_seg_elems             = isRowMajor ? 1 : glb_i.nrEffElems;

    // Select row-major or column-major segment nibbles - always calculated
    nr_seg_nbs               = nr_seg_elems_row_major << glb_i.sew;
    page_off                 = next_addr_i[12:0];
    seg_nibbles_with_pageOff = page_off + nr_seg_nbs;

    // Output assignment based on enable signal
    if (en_i) begin
      seg_nxt_o.segBaseAddr = next_addr_i;
      seg_nxt_o.txnNum      = (seg_nibbles_with_pageOff - 1) >> 13;
      seg_nxt_o.txnCnt      = 0;
      seg_nxt_o.ltN         = (seg_nibbles_with_pageOff[12:0] != 0) ?
        seg_nibbles_with_pageOff[12:0] : 
        8192;
    end else begin
      seg_nxt_o = seg_r_i;
    end
  end

endmodule
