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

  function automatic logic is2D(input logic [3:0] mode);
    return mode[3] || mode[2];
  endfunction

endpackage : ControlMachinePkg

`endif // CONTROL_MACHINE_PKG_SV
