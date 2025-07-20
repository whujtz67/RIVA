// ============================================================================
// VControlMachinePkg.sv
// Vector Control Machine Package - Contains vector control machine constants
// ============================================================================

`ifndef CONTROL_MACHINE_PKG_SV
`define CONTROL_MACHINE_PKG_SV

package VControlMachinePkg;

  // Mode decode helpers
  function automatic logic isIncr(input logic [3:0] mode); // TODO: should be mode_oh_e
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

endpackage : VControlMachinePkg

`endif // CONTROL_MACHINE_PKG_SV
