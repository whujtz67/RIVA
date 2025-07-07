// ============================================================================
// ReqFragmenter.sv
// SystemVerilog translation of Chisel ReqFragmenter
// All logic is directly expanded, no non-synthesizable task.
// ============================================================================

`timescale 1ns/1ps

import ControlMachinePkg::*;

module ReqFragmenter import riva_pkg::*; #(
  parameter int   unsigned  NrLanes      = 0,
  parameter int   unsigned  VLEN         = 0,
  parameter int   unsigned  ALEN         = 0,
  parameter type            vlsu_req_t   = logic,
  parameter type            meta_glb_t   = logic,
  parameter type            meta_seglv_t = logic
) (
  input  logic                  clk_i,
  input  logic                  rst_ni,

  // VLSU request input
  input  logic                  vlsu_req_valid_i,
  output logic                  vlsu_req_ready_o,
  input  vlsu_req_t             vlsu_req_i,

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

  // FSM States
  typedef enum logic [1:0] {
    S_IDLE         = 2'd0, // Wait for new request
    S_SEG_LV_INIT  = 2'd1, // Initialize segment-level info for new segment
    S_FRAGMENTING  = 2'd2, // Fragmenting: issue transactions for current segment
    S_STALL        = 2'd3  // Stall: wait for resources to become available
  } state_e;

  state_e state_r, state_nxt;

  // Registers for meta info
  meta_glb_t   meta_glb_r, meta_glb_nxt;
  meta_seglv_t meta_seglv_r, meta_seglv_nxt;

  // Indicates the first cycle of fragmenting state.
  // This register is used to generate a one-cycle pulse (meta_buf_enq_valid_o)
  // at the start of the S_FRAGMENTING state, ensuring that meta information is only enqueued once per request.
  logic start_fragmenting_r, start_fragmenting_nxt;

  // doUpdate signal
  logic do_update;
  assign do_update = meta_ready_i;

  // seglv_init_common module input signals
  elen_t seglv_next_addr;
  meta_glb_t                 seglv_glb;
  logic                      seglv_init_en;

  // FSM state transition
  always_comb begin
    // Default: hold current state
    state_nxt = state_r;
    case (state_r)
      S_IDLE:         // Wait for new request
        state_nxt = vlsu_req_valid_i ? S_SEG_LV_INIT : S_IDLE;
      S_SEG_LV_INIT:  // Initialize segment-level info, then go to fragmenting or stall
        state_nxt = (core_st_pending_i || meta_buf_full_i) ? S_STALL : S_FRAGMENTING;
      S_FRAGMENTING:  // Issue transactions, return to idle when done
        state_nxt = (isFinalTxn(meta_glb_r) && do_update) ? S_IDLE : S_FRAGMENTING;
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
    vlsu_req_ready_o = 1'b0;

    seglv_next_addr  = '0;
    seglv_glb        = '0;
    seglv_init_en    = 1'b0;

    case (state_r)
      // Initialize global info from new request
      S_IDLE: begin
        if (vlsu_req_valid_i) begin
          meta_glb_nxt.reqId    = vlsu_req_i.reqId;
          meta_glb_nxt.mode     = 1 << vlsu_req_i.mop;
          meta_glb_nxt.baseAddr = vlsu_req_i.baseAddr << 1;
          meta_glb_nxt.vd       = vlsu_req_i.vd;
          meta_glb_nxt.sew      = vlsu_req_i.sew;
          meta_glb_nxt.EW       = 1 << (vlsu_req_i.sew + 2);
          meta_glb_nxt.nrElem   = vlsu_req_i.len - vlsu_req_i.vstart;
          meta_glb_nxt.vm       = vlsu_req_i.vm;
          meta_glb_nxt.stride   = vlsu_req_i.stride;
          meta_glb_nxt.vstart   = vlsu_req_i.vstart;
          meta_glb_nxt.rmnGrp   = isCln2D(meta_glb_nxt.mode) ? ((vlsu_req_i.len << vlsu_req_i.sew) - 1) >> $clog2(DLEN/4) : 0;
          meta_glb_nxt.rmnSeg   = isIncr(meta_glb_nxt.mode)  ? 0                                        :
                                  isStrd(meta_glb_nxt.mode)  ? (vlsu_req_i.len - vlsu_req_i.vstart) - 1 :
                                  isRow2D(meta_glb_nxt.mode) ? vlsu_req_i.len - 1                       :
                                  isCln2D(meta_glb_nxt.mode) ? (NrLanes - 1)                            : 
                                                               0                                        ;
          meta_glb_nxt.isLoad   = vlsu_req_i.isLoad;
          meta_glb_nxt.cmtCnt   = (
              (is2D(meta_glb_nxt.mode) ?
                (vlsu_req_i.len << vlsu_req_i.sew << $clog2(NrLanes)) :
                ((vlsu_req_i.len - vlsu_req_i.vstart) << vlsu_req_i.sew) + ((vlsu_req_i.vstart << vlsu_req_i.sew) & (1 << $clog2(NrLanes * DLEN / 4) - 1))
              ) - 1
          ) >> $clog2(NrLanes * DLEN / 4);
        end
        // Ready to accept new request in IDLE
        vlsu_req_ready_o = 1'b1;
      end
      // Initialize segment level info for new segment
      S_SEG_LV_INIT: begin
        seglv_next_addr = meta_seglv_r.segBaseAddr + meta_glb_r.stride;
        seglv_glb       = meta_glb_r;
        seglv_init_en   = 1'b1;
      end
      // Fragmenting: update meta info as transactions are issued
      S_FRAGMENTING: begin
        if (do_update && !(isLastGrp(meta_glb_r) && isLastSeg(meta_glb_r) && isLastTxn(meta_seglv_r))) begin
          if (isLastTxn(meta_seglv_r)) begin
            if (isLastSeg(meta_glb_r)) begin
              if (isCln2D(meta_glb_r.mode)) begin
                meta_glb_nxt.baseAddr = meta_glb_r.baseAddr + DLEN/4;
                meta_glb_nxt.rmnSeg   = NrLanes - 1;
                meta_glb_nxt.rmnGrp   = meta_glb_r.rmnGrp - 1;
              end
            end else begin
              meta_glb_nxt.rmnSeg = meta_glb_r.rmnSeg - 1;
            end
            if (isLastSeg(meta_glb_r)) begin
              seglv_next_addr = meta_glb_nxt.baseAddr;
              seglv_glb       = meta_glb_nxt;
              seglv_init_en   = 1'b1;
            end else begin
              seglv_next_addr = meta_seglv_r.segBaseAddr + meta_glb_nxt.stride;
              seglv_glb       = meta_glb_nxt;
              seglv_init_en   = 1'b1;
            end
          end else begin
            meta_seglv_nxt = meta_seglv_r;
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
  assign meta_glb_o = meta_glb_r;
  assign meta_seglv_o = meta_seglv_r;

  // seglv_init_common module instantiation
  SegLvInitCommon #(
      .NrLanes        (NrLanes),
      .VLEN           (VLEN   ),
      .ALEN           (ALEN   )
  ) i_seglv_init_common (
      .en_i           (seglv_init_en  ),
      .next_addr_i    (seglv_next_addr),
      .glb_i          (seglv_glb      ),
      .seg_r_i        (meta_seglv_r   ),
      .seg_nxt_o      (meta_seglv_nxt )
  );

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_r <= S_IDLE;
      meta_glb_r <= '0;
      meta_seglv_r <= '0;
      start_fragmenting_r <= 1'b0;
    end else begin
      state_r <= state_nxt;
      meta_glb_r <= meta_glb_nxt;
      meta_seglv_r <= meta_seglv_nxt;
      start_fragmenting_r <= start_fragmenting_nxt;
    end
  end
endmodule

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
  parameter  int   unsigned  NrLanes        = 0,
  parameter  int   unsigned  VLEN           = 0,
  parameter  int   unsigned  ALEN           = 0

  // Dependant parameters. DO NOT CHANGE!
  localparam int   unsigned  MaxLEN         = $max(VLEN, ALEN),
  localparam int   unsigned  clog2MaxNbs    = $clog2(MaxLEN * ELEN)
) (
  input  logic                        en_i,
  input  elen_t                       next_addr_i,
  input  meta_glb_t                   glb_i,
  input  meta_seglv_t                 seg_r_i,

  output logic meta_seglv_t           seg_nxt_o
);

  // Mode decode
  logic is_incr;
  logic is_strd;
  logic is_row2d;
  logic is_cln2d;

  // Calculate number of nibbles in the segment for row-major modes
  logic [clog2MaxNbs   : 0] nr_seg_elems_row_major;
  logic [clog2MaxNbs   : 0] nr_seg_nbs_row_major;

  // Calculate number of nibbles in the segment for column-major (cln2D) mode
  logic [clog2MaxNbs   : 0] nr_all_grp_nbs;
  logic [$clog2(DLEN/4): 0] nr_last_grp_nbs;
  logic [clog2MaxNbs   : 0] nr_seg_nbs_cln_major;

  // Select row-major or column-major segment nibbles
  logic [clog2MaxNbs          : 0] nr_seg_nbs;
  logic [12                   : 0] page_off;
  logic [$max(clog2MaxNbs, 12): 0] seg_nibbles_with_pageOff;

  always_comb begin
    if (en_i) begin
      is_incr   = isIncr (glb_i.mode);
      is_strd   = isStrd (glb_i.mode);
      is_row2d  = isRow2D(glb_i.mode);
      is_cln2d  = isCln2D(glb_i.mode);

      nr_seg_elems_row_major = is_incr  ? glb_i.nrElem :
                               is_strd  ? 1            :
                               is_row2d ? NrLanes      : 
                                          0            ;
      nr_seg_nbs_row_major = nr_seg_elems_row_major << glb_i.sew;

      nr_all_grp_nbs       = (glb_i.nrElem << glb_i.sew);
      nr_last_grp_nbs      = nr_all_grp_nbs[$clog2(DLEN/4)-1: 0];
      nr_seg_nbs_cln_major = isLastGrp(glb_i) ?
                                (
                                  nr_last_grp_nbs == 0 ? 
                                    (DLEN/4) : 
                                    nr_last_grp_nbs
                                ) : 
                                (DLEN/4);

      nr_seg_nbs               = is_cln2d ? nr_seg_nbs_cln_major : nr_seg_nbs_row_major;
      page_off                 = next_addr_i[12:0];
      seg_nibbles_with_pageOff = page_off + nr_seg_nbs;

      seg_nxt_o.segBaseAddr = next_addr_i;
      seg_nxt_o.txnNum      = (seg_nibbles_with_pageOff - 1) >> 13;
      seg_nxt_o.txnCnt      = 0;
      seg_nxt_o.ltN         = (seg_nibbles_with_pageOff[12:0] != 0) ?
        seg_nibbles_with_pageOff[12:0] : 
        DLEN/4;
        
    end else begin
      seg_nxt_o = seg_r_i;
    end
  end

endmodule
