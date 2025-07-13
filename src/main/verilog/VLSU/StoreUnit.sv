// ============================================================================
// StoreUnit.sv
// Store Unit Top-Level Module
// 
// This module connects DeShuffleUnit and SequentialStore to form a complete
// data control pipeline for vector store operations
// ============================================================================

`timescale 1ns/1ps

module StoreUnit import vlsu_pkg::*; import axi_pkg::*; #(
  parameter  int   unsigned  NrLanes          = 0,
  parameter  int   unsigned  VLEN             = 0,
  parameter  int   unsigned  ALEN             = 0,
  parameter  int   unsigned  AxiDataWidth     = 0,
  parameter  int   unsigned  AxiAddrWidth     = 0,
  parameter  int   unsigned  AxiUserWidth     = 1, // TODO: pass from top level

  // Type parameters from VLSU typedef
  // TODO: Define these types in vlsu_typedef.svh or create local definitions
  parameter  type            axi_w_t          = logic,
  parameter  type            txn_ctrl_t       = logic,
  parameter  type            meta_glb_t       = logic,
  parameter  type            rx_lane_t        = logic,

  // Dependant parameters. DO NOT CHANGE!
  localparam int   unsigned  NrLaneEntriesNbs = (DLEN / 4) * NrLanes,
  localparam int   unsigned  busNibbles       = AxiDataWidth / 4,
  localparam int   unsigned  busNSize         = $clog2(busNibbles),
  localparam type            strb_t           = logic [DLEN/4-1:0]
) (
  input  logic                       clk_i,
  input  logic                       rst_ni,

  // Input from Lane Exits
  input  logic      [NrLanes-1:0]    rxs_valid_i,
  output logic      [NrLanes-1:0]    rxs_ready_o,
  input  rx_lane_t  [NrLanes-1:0]    rxs_i,

  // AXI W Channel Output
  output logic                       axi_w_valid_o,
  input  logic                       axi_w_ready_i,
  output axi_w_t                     axi_w_o,

  // Transaction Control Interface
  input  logic                       txn_ctrl_valid_i,
  output logic                       txn_ctrl_ready_o,
  input  txn_ctrl_t                  txn_ctrl_i,

  // Meta Control Interface - Global
  input  logic                       meta_glb_valid_i,
  output logic                       meta_glb_ready_o,
  input  meta_glb_t                  meta_glb_i,

  // Mask from mask unit
  input  logic      [NrLanes-1:0]    mask_valid_i,
  input  strb_t     [NrLanes-1:0]    mask_bits_i,
  output logic                       mask_ready_o 
);

  `include "vlsu/vlsu_dc_typedef.svh"

  // ================= Internal Signals ================= //
  // Connection between DeShuffleUnit and SequentialStore
  logic       tx_seq_store_valid;
  logic       tx_seq_store_ready;
  seq_buf_t   tx_seq_store;

  // MetaInfoBroadcast internal signals
  logic       meta_bc_seq_valid;
  logic       meta_bc_seq_ready;
  meta_glb_t  meta_bc_seq;
  logic       meta_bc_shf_valid;
  logic       meta_bc_shf_ready;
  meta_glb_t  meta_bc_shf;

  // ================= MetaInfoBroadcast Instantiation ================= //
  MetaInfoBroadcast #(
    .meta_glb_t  (meta_glb_t  )
  ) i_meta_broadcast (
    .clk_i                (clk_i                  ),
    .rst_ni               (rst_ni                 ),
    .meta_info_valid_i    (meta_glb_valid_i      ),
    .meta_info_ready_o    (meta_glb_ready_o      ),
    .meta_info_i          (meta_glb_i            ),
    .seq_valid_o          (meta_bc_seq_valid      ),
    .seq_ready_i          (meta_bc_seq_ready      ),
    .seq_o                (meta_bc_seq            ),
    .shf_valid_o          (meta_bc_shf_valid      ),
    .shf_ready_i          (meta_bc_shf_ready      ),
    .shf_o                (meta_bc_shf            )
  );

  // ================= DeShuffleUnit Instantiation ================= //
  DeShuffleUnit #(
    .NrLanes      (NrLanes      ),
    .VLEN         (VLEN         ),
    .ALEN         (ALEN         ),
    .meta_glb_t   (meta_glb_t   ),
    .seq_buf_t    (seq_buf_t    ),
    .rx_lane_t    (rx_lane_t    ),
    .shf_info_t   (shf_info_t   )
  ) i_deshuffle_unit (
    .clk_i                (clk_i                ),
    .rst_ni               (rst_ni               ),
    .rxs_valid_i          (rxs_valid_i          ),
    .rxs_ready_o          (rxs_ready_o          ),
    .rxs_i                (rxs_i                ),
    .tx_seq_store_valid_o (tx_seq_store_valid   ),
    .tx_seq_store_ready_i (tx_seq_store_ready   ),
    .tx_seq_store_o       (tx_seq_store         ),
    .meta_info_valid_i    (meta_bc_shf_valid    ),
    .meta_info_ready_o    (meta_bc_shf_ready    ),
    .meta_info_i          (meta_bc_shf          ),
    .mask_valid_i         (mask_valid_i         ),
    .mask_bits_i          (mask_bits_i          ),
    .mask_ready_o         (mask_ready_o         )
  );

  // ================= SequentialStore Instantiation ================= //
  SequentialStore #(
    .NrLanes        (NrLanes        ),
    .AxiDataWidth   (AxiDataWidth   ),
    .AxiAddrWidth   (AxiAddrWidth   ),
    .AxiUserWidth   (AxiUserWidth   ),
    .axi_w_t        (axi_w_t        ),
    .txn_ctrl_t     (txn_ctrl_t     ),
    .meta_glb_t     (meta_glb_t     ),
    .seq_info_t     (seq_info_t     ),
    .seq_buf_t      (seq_buf_t      )
  ) i_sequential_store (
    .clk_i                (clk_i                ),
    .rst_ni               (rst_ni               ),
    .rx_deshfu_valid_i    (tx_seq_store_valid   ),
    .rx_deshfu_ready_o    (tx_seq_store_ready   ),
    .rx_deshfu_i          (tx_seq_store         ),
    .axi_w_valid_o        (axi_w_valid_o        ),
    .axi_w_ready_i        (axi_w_ready_i        ),
    .axi_w_o              (axi_w_o              ),
    .txn_ctrl_valid_i     (txn_ctrl_valid_i     ),
    .txn_ctrl_ready_o     (txn_ctrl_ready_o     ),
    .txn_ctrl_i           (txn_ctrl_i           ),
    .meta_glb_valid_i     (meta_bc_seq_valid    ),
    .meta_glb_ready_o     (meta_bc_seq_ready    ),
    .meta_glb_i           (meta_bc_seq          )
  );

  // ================= Assertions ================= //
  // TODO: Add assertions for data integrity and timing requirements

endmodule : StoreUnit 