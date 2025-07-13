// ============================================================================
// ControlMachine.sv
// SystemVerilog translation of Chisel ControlMachineNC
// Top-level control machine: connects ReqFragmenter and TxnCtrlUnit
// ============================================================================

`timescale 1ns/1ps

import ControlMachinePkg::*;
import axi_pkg::*;

module ControlMachine import vlsu_pkg::*; #(
    parameter  int   unsigned  NrLanes      = 0,
    parameter  int   unsigned  VLEN         = 0,
    parameter  int   unsigned  ALEN         = 0,
    parameter  int   unsigned  AxiDataWidth = 0,  // AXI data width in bits
    parameter  type            axi_aw_t     = logic,
    parameter  type            axi_ar_t     = logic,
    parameter  type            vlsu_req_t   = logic,
    parameter  type            meta_glb_t   = logic,
    parameter  type            meta_seglv_t = logic,
    parameter  type            txn_ctrl_t   = logic
) (
    // requester side
    input  logic          clk_i,
    input  logic          rst_ni,

    input  logic          vlsu_req_valid_i,
    output logic          vlsu_req_ready_o,
    input  vlsu_req_t     vlsu_req_i,

    input  logic          core_st_pending_i,

    // data controller side
    output logic          meta_ctrl_valid_o,
    input  logic          meta_ctrl_ready_i,
    output meta_glb_t     meta_glb_o,
    output meta_seglv_t   meta_seglv_o,

    output logic          txn_ctrl_valid_o,
    output txn_ctrl_t     txn_ctrl_o,

    input  logic          update_i,

    output logic          aw_valid_o,
    input  logic          aw_ready_i,
    output axi_aw_t       aw_o,

    output logic          ar_valid_o,
    input  logic          ar_ready_i,
    output axi_ar_t       ar_o,

    input  logic          b_valid_i,
    output logic          b_ready_o
);
    // --------------------- Internal Connection Signals --------------------- //
    logic meta_valid, meta_ready;
    meta_glb_t   meta_glb;
    meta_seglv_t meta_seglv;
    logic meta_buf_enq_valid, meta_buf_full;

    // --------------------- Submodule Instantiation --------------------- //
    ReqFragmenter #(
      .NrLanes      (NrLanes      ),
      .VLEN         (VLEN         ),
      .ALEN         (ALEN         ),
      .vlsu_req_t   (vlsu_req_t   ),
      .meta_glb_t   (meta_glb_t   ),
      .meta_seglv_t (meta_seglv_t )
    ) i_rf (
      .clk_i                (clk_i               ),
      .rst_ni               (rst_ni              ),
      .vlsu_req_valid_i     (vlsu_req_valid_i    ),
      .vlsu_req_ready_o     (vlsu_req_ready_o    ),
      .vlsu_req_i           (vlsu_req_i          ),
      .core_st_pending_i    (core_st_pending_i   ),
      .meta_valid_o         (meta_valid          ),
      .meta_ready_i         (meta_ready          ),
      .meta_glb_o           (meta_glb            ),
      .meta_seglv_o         (meta_seglv          ),
      .meta_buf_full_i      (meta_buf_full       ),
      .meta_buf_enq_valid_o (meta_buf_enq_valid  )
    );

    TxnCtrlUnit #(
      .NrLanes      (NrLanes      ),
      .VLEN         (VLEN         ),
      .ALEN         (ALEN         ),
      .AxiDataWidth (AxiDataWidth ),
      .txn_ctrl_t   (txn_ctrl_t   ),
      .axi_aw_t     (axi_aw_t     ),
      .axi_ar_t     (axi_ar_t     ),
      .meta_glb_t   (meta_glb_t   ),
      .meta_seglv_t (meta_seglv_t )
    ) i_tc (
      .clk_i            (clk_i           ),
      .rst_ni           (rst_ni          ),
      .meta_valid_i     (meta_valid      ),
      .meta_ready_o     (meta_ready      ),
      .meta_glb_i       (meta_glb        ),
      .meta_seglv_i     (meta_seglv      ),
      .txn_ctrl_valid_o (txn_ctrl_valid_o),
      .txn_ctrl_o       (txn_ctrl_o      ),
      .update_i         (update_i        ),
      .aw_valid_o       (aw_valid_o      ),
      .aw_ready_i       (aw_ready_i      ),
      .aw_o             (aw_o            ),
      .ar_valid_o       (ar_valid_o      ),
      .ar_ready_i       (ar_ready_i      ),
      .ar_o             (ar_o            ),
      .b_valid_i        (b_valid_i       ),
      .b_ready_o        (b_ready_o       )
    );

    // --------------------- Meta Buffer Full Signal --------------------- //
    assign meta_buf_full      = !meta_ctrl_ready_i;
    assign meta_ctrl_valid_o  = meta_buf_enq_valid;
    assign meta_glb_o         = meta_glb;
    assign meta_seglv_o       = meta_seglv;
    assign meta_ready         = meta_ctrl_ready_i;

endmodule 