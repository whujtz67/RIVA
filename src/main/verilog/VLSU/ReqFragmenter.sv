// ============================================================================
// ReqFragmenter.sv
// SystemVerilog translation of Chisel ReqFragmenter
// All logic is directly expanded, no non-synthesizable task.
// ============================================================================

`timescale 1ns/1ps

import ControlMachinePkg::*;

module ReqFragmenter #(
  parameter REQ_ID_BITS       = 8,
  parameter VLSU_ADDR_BITS    = 32,
  parameter VLEN_BITS         = 8,
  parameter AXI4_ADDR_BITS    = 32,
  parameter type vlsu_req_t   = logic,
  parameter type meta_glb_t   = logic,
  parameter type meta_seglv_t = logic
) (
  input  logic                  clk_i,
  input  logic                  rst_ni,

  // Riva request input
  input  logic                  riva_req_valid_i,
  output logic                  riva_req_ready_o,
  input  vlsu_req_t             riva_req_i,

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
  // Parameters for update_global
  localparam int SLEN = 128;
  localparam int NrLanes = 4;

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
  logic [VLSU_ADDR_BITS-1:0] seglv_next_addr;
  meta_glb_t                 seglv_glb;
  logic                      seglv_en;
  meta_seglv_t               seglv_init_common_out;

  // FSM state transition
  always_comb begin
    // Default: hold current state
    state_nxt = state_r;
    case (state_r)
      S_IDLE:         // Wait for new request
        state_nxt = riva_req_valid_i ? S_SEG_LV_INIT : S_IDLE;
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
    riva_req_ready_o = 1'b0;

    seglv_next_addr  = '0;
    seglv_glb        = '0;
    seglv_en         = 1'b0;

    case (state_r)
      // Initialize global info from new request
      S_IDLE: begin
        if (riva_req_valid_i) begin
          meta_glb_nxt.reqId    = riva_req_i.reqId;
          meta_glb_nxt.mode     = 1 << riva_req_i.mop;
          meta_glb_nxt.baseAddr = riva_req_i.baseAddr << 1;
          meta_glb_nxt.vd       = riva_req_i.vd;
          meta_glb_nxt.sew      = riva_req_i.sew;
          meta_glb_nxt.EW       = 1 << (riva_req_i.sew + 2);
          meta_glb_nxt.nrElem   = riva_req_i.len - riva_req_i.vstart;
          meta_glb_nxt.vm       = riva_req_i.vm;
          meta_glb_nxt.stride   = riva_req_i.stride;
          meta_glb_nxt.vstart   = riva_req_i.vstart;
          meta_glb_nxt.rmnGrp   = isCln2D(meta_glb_nxt.mode) ? ((riva_req_i.len << riva_req_i.sew) - 1) >> $clog2(SLEN/4) : 0;
          meta_glb_nxt.rmnSeg   = isIncr(meta_glb_nxt.mode) ? 0 :
                                isStrd(meta_glb_nxt.mode) ? (riva_req_i.len - riva_req_i.vstart) - 1 :
                                isRow2D(meta_glb_nxt.mode) ? riva_req_i.len - 1 :
                                isCln2D(meta_glb_nxt.mode) ? (NrLanes - 1) : 0;
          meta_glb_nxt.isLoad   = riva_req_i.isLoad;
          meta_glb_nxt.cmtCnt   = (((isRow2D(meta_glb_nxt.mode) | isCln2D(meta_glb_nxt.mode)) ?
                                (riva_req_i.len << riva_req_i.sew << $clog2(NrLanes)) :
                                ((riva_req_i.len - riva_req_i.vstart) << riva_req_i.sew) +
                                ((riva_req_i.vstart << riva_req_i.sew) & ((1 << $clog2(NrLanes * SLEN / 4)) - 1))) - 1) >> $clog2(NrLanes * SLEN / 4);
        end
        // Ready to accept new request in IDLE
        riva_req_ready_o = 1'b1;
      end
      // Initialize segment level info for new segment
      S_SEG_LV_INIT: begin
        seglv_next_addr = meta_seglv_r.segBaseAddr + meta_glb_r.stride;
        seglv_glb       = meta_glb_r;
        seglv_en        = 1'b1;
      end
      // Fragmenting: update meta info as transactions are issued
      S_FRAGMENTING: begin
        if (do_update && !(isLastGrp(meta_glb_r) && isLastSeg(meta_glb_r) && isLastTxn(meta_seglv_r))) begin
          if (isLastTxn(meta_seglv_r)) begin
            if (isLastSeg(meta_glb_r)) begin
              if (isCln2D(meta_glb_r.mode)) begin
                meta_glb_nxt.baseAddr = meta_glb_r.baseAddr + SLEN/4;
                meta_glb_nxt.rmnSeg   = NrLanes - 1;
                meta_glb_nxt.rmnGrp   = meta_glb_r.rmnGrp - 1;
              end
            end else begin
              meta_glb_nxt.rmnSeg = meta_glb_r.rmnSeg - 1;
            end
            if (isLastSeg(meta_glb_r)) begin
              seglv_next_addr = meta_glb_nxt.baseAddr;
              seglv_glb       = meta_glb_nxt;
              seglv_en        = 1'b1;
            end else begin
              seglv_next_addr = meta_seglv_r.segBaseAddr + meta_glb_nxt.stride;
              seglv_glb       = meta_glb_nxt;
              seglv_en        = 1'b1;
            end
          end else begin
            meta_seglv_nxt = meta_seglv_r;
            meta_seglv_nxt.txnCnt = meta_seglv_r.txnCnt + 1;
          end
        end
        meta_valid_o = 1'b1;
      end
    endcase
    // sample seglv_init_common module output
    if (seglv_en) begin
      meta_seglv_nxt = seglv_init_common_out;
    end
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
    .VLSU_ADDR_BITS(VLSU_ADDR_BITS),
    .VLEN_BITS(VLEN_BITS),
    .SLEN(SLEN),
    .NR_LANES(NrLanes),
    .vlsu_req_t(vlsu_req_t),
    .meta_glb_t(meta_glb_t),
    .meta_seglv_t(meta_seglv_t)
  ) seglv_init_common_mod_inst (
    .next_addr_i(seglv_next_addr),
    .glb_i(seglv_glb),
    .seg_o(seglv_init_common_out)
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
module SegLvInitCommon #(
  parameter VLSU_ADDR_BITS = 32,
  parameter VLEN_BITS = 8,
  parameter SLEN = 128,
  parameter NR_LANES = 4,
  parameter type vlsu_req_t = logic,
  parameter type meta_glb_t = logic,
  parameter type meta_seglv_t = logic
) (
  input  logic [VLSU_ADDR_BITS-1:0] next_addr_i,
  input  meta_glb_t                   glb_i,
  output meta_seglv_t                 seg_o
);
  // Mode decode wires
  wire is_incr   = isIncr(glb_i.mode);
  wire is_strd   = isStrd(glb_i.mode);
  wire is_row2d  = isRow2D(glb_i.mode);
  wire is_cln2d  = isCln2D(glb_i.mode);

  // Calculate number of nibbles in the segment for row-major modes
  wire [VLEN_BITS-1:0] nr_seg_nbs_row_major = is_incr  ? glb_i.nrElem :
                                              is_strd  ? 1 :
                                              is_row2d ? NR_LANES : 0;
  wire [VLEN_BITS-1:0] nr_seg_nbs_row_major_shifted = nr_seg_nbs_row_major << glb_i.sew;

  // Calculate number of nibbles in the segment for column-major (cln2D) mode
  wire [VLEN_BITS-1:0] nr_seg_nbs_cln_major = (is_cln2d && (glb_i.rmnGrp == 0)) ?
    (((glb_i.nrElem << glb_i.sew) & ((SLEN/4)-1)) == 0 ? (SLEN/4) : ((glb_i.nrElem << glb_i.sew) & ((SLEN/4)-1))) :
    (SLEN/4);

  // Select row-major or column-major segment nibbles
  wire [VLEN_BITS-1:0] nr_seg_nbs = is_cln2d ? nr_seg_nbs_cln_major : nr_seg_nbs_row_major_shifted;

  // Set segment base address
  assign seg_o.segBaseAddr = next_addr_i;
  // Calculate page offset within the segment
  wire [$clog2(SLEN/4)-1:0] page_off = next_addr_i[$clog2(SLEN/4)-1:0];
  // Total nibbles in this segment including page offset
  wire [VLEN_BITS-1:0] seg_nibbles_with_pageOff = page_off + nr_seg_nbs;
  // Number of transactions needed for this segment
  assign seg_o.txnNum = (seg_nibbles_with_pageOff - 1) >> $clog2(SLEN/4);
  // Transaction count starts at 0
  assign seg_o.txnCnt = 0;
  // Last transaction nibbles (with page offset), or SLEN/4 if aligned
  assign seg_o.ltN = (seg_nibbles_with_pageOff[$clog2(SLEN/4)-1:0] != 0) ?
    seg_nibbles_with_pageOff[$clog2(SLEN/4)-1:0] : SLEN/4;

endmodule
