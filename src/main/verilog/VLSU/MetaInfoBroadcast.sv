// ============================================================================
// MetaInfoBroadcast.sv
// MetaInfo Broadcast Module
// 
// This module broadcasts metaInfo to both sequential and shuffle modules:
// - Sequential modules: receive seqNbPtr for seqInfoBuf
// - Shuffle modules: receive full metaInfo for metaBuf
// ============================================================================



module MetaInfoBroadcast import vlsu_pkg::*; #(
  // Type parameters from VLSU typedef
  // TODO: Define these types in vlsu_typedef.svh or create local definitions
  parameter  type            meta_glb_t      = logic
) (
  input  logic                       clk_i,
  input  logic                       rst_ni,

  // Input from Control Machine
  input  logic                       meta_info_valid_i,
  output logic                       meta_info_ready_o,
  input  meta_glb_t                  meta_info_i,

  // Output to Sequential modules
  output logic                       seq_valid_o,
  input  logic                       seq_ready_i,
  output meta_glb_t                  seq_o,

  // Output to Shuffle modules  
  output logic                       shf_valid_o,
  input  logic                       shf_ready_i,
  output meta_glb_t                  shf_o
);

  // ================= Simple Logic ================= //
  // Broadcast data to both outputs
  assign seq_o = meta_info_i;
  assign shf_o = meta_info_i;
  
  // Only send valid when both outputs are ready
  assign seq_valid_o = meta_info_valid_i && seq_ready_i && shf_ready_i;
  assign shf_valid_o = meta_info_valid_i && seq_ready_i && shf_ready_i;
  
  // Input ready when both outputs are ready
  assign meta_info_ready_o = seq_ready_i && shf_ready_i;

endmodule : MetaInfoBroadcast 