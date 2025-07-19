// ============================================================================
// MControlMachinePkg.sv
// Matrix Control Machine Package - Contains matrix control machine constants
// ============================================================================

`ifndef CONTROL_MACHINE_PKG_SV
`define CONTROL_MACHINE_PKG_SV

package MControlMachinePkg;

  // Mode decode helpers
  function automatic logic isRowMajor(input logic [3:0] mode); // TODO: should be mode_oh_t
    return mode[0];
  endfunction

  function automatic logic isColMajor(input logic [3:0] mode);
    return mode[1];
  endfunction

  function automatic logic isTranspose(input logic [3:0] mode);
    return mode[2];
  endfunction

  function automatic logic isReshape(input logic [3:0] mode);
    return mode[3];
  endfunction

endpackage : MControlMachinePkg

`endif // CONTROL_MACHINE_PKG_SV
