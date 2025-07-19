// ============================================================================
// VLoadUnit.sv
// Vector Load Unit - Handles vector load operations
// ============================================================================



module VLoadUnit import riva_pkg::*; import vlsu_pkg::*; #(
  parameter  int   unsigned  NrExits          = 0,
  parameter  int   unsigned  VLEN             = 0,
  parameter  int   unsigned  ALEN             = 0,
  parameter  int   unsigned  MaxLEN           = 0,
  parameter  int   unsigned  AxiDataWidth     = 0,
  parameter  int   unsigned  AxiAddrWidth     = 0,
  
  // Type parameters from VLSU typedef
  // TODO: Define these types in vlsu_typedef.svh or create local definitions
  parameter  type            axi_r_t          = logic,
  parameter  type            txn_ctrl_t       = logic,
  parameter  type            meta_glb_t       = logic,
  parameter  type            tx_lane_t        = logic,  
  parameter  type            pe_resp_t        = logic,


  // Dependant parameters. DO NOT CHANGE!
  localparam int   unsigned  NrLaneEntriesNbs = (riva_pkg::DLEN / 4) * NrExits,
  localparam int   unsigned  busNibbles       = AxiDataWidth / 4,
  localparam int   unsigned  busNSize         = $clog2(busNibbles),
  localparam type            strb_t           = logic [riva_pkg::DLEN/4-1:0]
) (
  input  logic                       clk_i, 
  input  logic                       rst_ni,
  
  // AXI R Channel Input
  input  logic                       axi_r_valid_i,
  output logic                       axi_r_ready_o,
  input  axi_r_t                     axi_r_i,
  
  // Transaction Control Interface
  input  logic                       txn_ctrl_valid_i,
  output logic                       txn_ctrl_ready_o,
  input  txn_ctrl_t                  txn_ctrl_i,
  
  // Meta Control Interface - Global
  input  logic                       meta_glb_valid_i,
  output logic                       meta_glb_ready_o,
  input  meta_glb_t                  meta_glb_i,
  
  // Output to Lane Entries
  output logic      [NrExits-1:0]    txs_valid_o,
  input  logic      [NrExits-1:0]    txs_ready_i,
  output tx_lane_t  [NrExits-1:0]    txs_o,
  
  // Mask from mask unit
  input  logic      [NrExits-1:0]    mask_valid_i,
  input  strb_t     [NrExits-1:0]    mask_bits_i,
  output logic                       mask_ready_o,

  // pe resp load
  output pe_resp_t pe_resp_load_o
);

  `include "vlsu/vlsu_dc_typedef.svh"

  // ================= Internal Signals ================= //
  // Connection between SequentialLoad and ShuffleUnit
  logic       tx_shfu_valid;
  logic       tx_shfu_ready;
  seq_buf_t   tx_shfu_data;

  // MetaInfoBroadcast internal signals
  logic       meta_bc_seq_valid;
  logic       meta_bc_seq_ready;
  meta_glb_t  meta_bc_seq_glb;
  logic       meta_bc_shf_valid;
  logic       meta_bc_shf_ready;
  meta_glb_t  meta_bc_shf_glb;

  // ================= MetaInfoBroadcast Instantiation ================= //
  VMetaInfoBroadcast #(
    .meta_glb_t  (meta_glb_t  )
  ) i_meta_broadcast (
    .clk_i                (clk_i                ),
    .rst_ni               (rst_ni               ),
    .meta_info_valid_i    (meta_glb_valid_i     ),
    .meta_info_ready_o    (meta_glb_ready_o     ),
    .meta_info_i          (meta_glb_i           ),
    .seq_valid_o          (meta_bc_seq_valid    ),
    .seq_ready_i          (meta_bc_seq_ready    ),
    .seq_o                (meta_bc_seq_glb      ),
    .shf_valid_o          (meta_bc_shf_valid    ),
    .shf_ready_i          (meta_bc_shf_ready    ),
    .shf_o                (meta_bc_shf_glb      )
  );

  // ================= SequentialLoad Instantiation ================= //
  VSequentialLoad #(
    .NrExits      (NrExits      ),
    .AxiDataWidth (AxiDataWidth ),
    .AxiAddrWidth (AxiAddrWidth ),
    .axi_r_t      (axi_r_t      ),
    .txn_ctrl_t   (txn_ctrl_t   ),
    .meta_glb_t   (meta_glb_t   ),
    .seq_info_t   (seq_info_t   ),
    .seq_buf_t    (seq_buf_t    )
  ) i_sequential_load (
    .clk_i              (clk_i              ),
    .rst_ni             (rst_ni             ),
    .axi_r_valid_i      (axi_r_valid_i      ),
    .axi_r_ready_o      (axi_r_ready_o      ),
    .axi_r_i            (axi_r_i            ),
    .txn_ctrl_valid_i   (txn_ctrl_valid_i   ),
    .txn_ctrl_ready_o   (txn_ctrl_ready_o   ),
    .txn_ctrl_i         (txn_ctrl_i         ),
    .meta_glb_valid_i   (meta_bc_seq_valid  ),
    .meta_glb_ready_o   (meta_bc_seq_ready  ),
    .meta_glb_i         (meta_bc_seq_glb    ),
    .tx_shfu_valid_o    (tx_shfu_valid      ),
    .tx_shfu_ready_i    (tx_shfu_ready      ),
    .tx_shfu_o          (tx_shfu_data       )
  );

  // ================= ShuffleUnit Instantiation ================= //
  VShuffleUnit #(
    .NrExits        (NrExits        ),
    .VLEN           (VLEN           ),
    .ALEN           (ALEN           ),
    .meta_glb_t     (meta_glb_t     ),
    .seq_buf_t      (seq_buf_t      ),
    .tx_lane_t      (tx_lane_t      ),
    .shf_info_t     (shf_info_t     ),
    .pe_resp_t      (pe_resp_t      )
  ) i_shuffle_unit (
    .clk_i                    (clk_i                    ),
    .rst_ni                   (rst_ni                   ),
    .rx_seq_load_valid_i      (tx_shfu_valid            ),
    .rx_seq_load_ready_o      (tx_shfu_ready            ),
    .rx_seq_load_i            (tx_shfu_data             ),
    .txs_valid_o              (txs_valid_o              ),
    .txs_ready_i              (txs_ready_i              ),
    .txs_o                    (txs_o                    ),
    .meta_info_valid_i        (meta_bc_shf_valid        ),
    .meta_info_ready_o        (meta_bc_shf_ready        ),
    .meta_info_i              (meta_bc_shf_glb          ),
    .mask_valid_i             (mask_valid_i             ),
    .mask_bits_i              (mask_bits_i              ),
    .mask_ready_o             (mask_ready_o             ),
    .pe_resp_load_o           (pe_resp_load_o           )
  );

  // ================= Assertions ================= //
  // TODO: Add assertions for data integrity and timing requirements

endmodule : VLoadUnit 