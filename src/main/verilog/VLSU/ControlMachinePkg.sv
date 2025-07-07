// ============================================================================
// ControlMachinePkg.sv
// SystemVerilog package for ControlMachine/ReqFragmenter
// ============================================================================

`ifndef CONTROL_MACHINE_PKG_SV
`define CONTROL_MACHINE_PKG_SV

package ControlMachinePkg;

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

  // Mode decode helpers
  function automatic logic isIncr(input logic [3:0] mode); // TODO: should be mode_oh_t
    return mode[0];
  endfunction

  function automatic logic isStrd(input logic [3:0] mode);
    return mode[1];
  endfunction

  function automatic logic isRow2D(input logic [3:0] mode);
    return mode[2];
  endfunction

  function automatic logic isCln2D(input logic [3:0] mode);
    return mode[3];
  endfunction

  // -----------------------------------------------------------------------------
  // seglv_init_common: Initialize segment-level info for a new segment
  // -----------------------------------------------------------------------------
  // This function computes the segment base address, number of transactions,
  // transaction count, and last transaction nibbles for a new segment, based on
  // the next address and global info. It handles both row-major and column-major
  // (2D) access modes, and takes care of page offset and segment nibbles calculation.
  //
  // Parameters:
  //   next_addr : The base address for the new segment
  //   glb       : The global (request-level) info for this operation
  // Returns:
  //   meta_seglv_t: The initialized segment-level info for the new segment
  // -----------------------------------------------------------------------------
  function automatic meta_seglv_t seglv_init_common (
    input logic [VLSU_ADDR_BITS-1:0] next_addr,
    input meta_glb_t glb
  );
    meta_seglv_t res;

    // Calculate number of nibbles in the segment for row-major modes
    logic [VLEN_BITS-1:0] nr_seg_nbs_row_major;
    nr_seg_nbs_row_major = isIncr(glb.mode)  ? glb.nrElem :
                           isStrd(glb.mode)  ? 1 :
                           isRow2D(glb.mode) ? NR_LANES : 0;
    nr_seg_nbs_row_major = nr_seg_nbs_row_major << glb.sew;

    // Calculate number of nibbles in the segment for column-major (cln2D) mode
    logic [VLEN_BITS-1:0] nr_seg_nbs_cln_major;
    if (isCln2D(glb.mode) && isLastGrp(glb))
      // If last group, check for partial segment
      nr_seg_nbs_cln_major = ((glb.nrElem << glb.sew) & ((SLEN/4)-1)) == 0 ?
        (SLEN/4) : ((glb.nrElem << glb.sew) & ((SLEN/4)-1));
    else
      // Otherwise, full segment
      nr_seg_nbs_cln_major = SLEN/4;

    // Select row-major or column-major segment nibbles
    logic [VLEN_BITS-1:0] nr_seg_nbs = isCln2D(glb.mode) ? nr_seg_nbs_cln_major : nr_seg_nbs_row_major;

    // Set segment base address
    res.segBaseAddr = next_addr;
    // Calculate page offset within the segment
    logic [$clog2(SLEN/4)-1:0] page_off = next_addr[$clog2(SLEN/4)-1:0];
    // Total nibbles in this segment including page offset
    logic [VLEN_BITS-1:0] seg_nibbles_with_pageOff = page_off + nr_seg_nbs;
    // Number of transactions needed for this segment
    res.txnNum = (seg_nibbles_with_pageOff - 1) >> $clog2(SLEN/4);
    // Transaction count starts at 0
    res.txnCnt = 0;
    // Last transaction nibbles (with page offset), or SLEN/4 if aligned
    res.ltN = (seg_nibbles_with_pageOff[$clog2(SLEN/4)-1:0] != 0) ?
      seg_nibbles_with_pageOff[$clog2(SLEN/4)-1:0] : SLEN/4;

    return res;
  endfunction

endpackage : ControlMachinePkg

`endif // CONTROL_MACHINE_PKG_SV
