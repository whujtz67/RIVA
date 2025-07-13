// ============================================================================
// VLSU.sv
// Vector Load Store Unit - Top Level Module
// ============================================================================

`timescale 1ns/1ps

module VLSU import vlsu_pkg::*; #(
    parameter  int   unsigned  NrLanes      = 0,
    parameter  int   unsigned  VLEN         = 0,
    parameter  int   unsigned  ALEN         = 0,
    parameter  type            vaddr_t      = logic,
    parameter  type            pe_req_t     = logic,
    parameter  type            pe_resp_t    = logic,
    
    // AXI type parameters (from upstream)
    parameter  int   unsigned  AxiDataWidth = 0,
    parameter  int   unsigned  AxiAddrWidth = 0,
    parameter  int   unsigned  AxiUserWidth = 1, // TODO: pass from top level

    parameter  type            axi_aw_t     = logic,
    parameter  type            axi_ar_t     = logic,
    parameter  type            axi_w_t      = logic,
    parameter  type            axi_r_t      = logic,
    parameter  type            axi_b_t      = logic,
 
    parameter  type            axi_req_t    = logic,
    parameter  type            axi_resp_t   = logic,
    // Dependant parameters. DO NOT CHANGE!
    localparam int   unsigned  MaxLEN       = $max(VLEN, ALEN),
    localparam int   unsigned  clog2MaxNbs  = $clog2(MaxLEN * ELEN / 4),
    localparam type            strb_t       = logic [DLEN/4-1:0],
    localparam type            vlen_t       = logic [$clog2(VLEN+1)-1:0],
	  localparam type            alen_t       = logic [$clog2(ALEN+1)-1:0]
) (
    // Clock and Reset
    input  logic          clk_i,
    input  logic          rst_ni,
    
    // VLSU Request Interface
    input  logic          vlsu_req_valid_i,
    output logic          vlsu_req_ready_o,
    input  vlsu_req_t     vlsu_req_i,
    input  logic          core_st_pending_i,
    
    // AXI Master Interface
    output logic          m_axi_aw_valid_o,
    input  logic          m_axi_aw_ready_i,
    output axi_aw_t       m_axi_aw_o, 

    output logic          m_axi_w_valid_o,
    input  logic          m_axi_w_ready_i,
    output axi_w_t        m_axi_w_o,

    input  logic          m_axi_b_valid_i,
    output logic          m_axi_b_ready_o,
    input  axi_b_t        m_axi_b_i,

    output logic          m_axi_ar_valid_o,
    input  logic          m_axi_ar_ready_i,
    output axi_ar_t       m_axi_ar_o,
    
    input  logic          m_axi_r_valid_i,
    output logic          m_axi_r_ready_o,
    input  axi_r_t        m_axi_r_i,

    // Lane Interface - Expanded for upstream compatibility
    // Transmit lanes (VLSU to lanes) - expanded
    output logic       [NrLanes-1:0]              txs_valid_o,
    input  logic       [NrLanes-1:0]              txs_ready_i,
    // tx_lane_t fields expanded
    output vid_t       [NrLanes-1:0]              txs_req_id_o,
    output vaddr_set_t [NrLanes-1:0]              txs_vaddr_set_o,
    output vaddr_off_t [NrLanes-1:0]              txs_vaddr_off_o,
    output logic       [DLEN-1   :0][NrLanes-1:0] txs_data_o,
    output logic       [DLEN/4 -1:0][NrLanes-1:0] txs_nbe_o,
    
    // Receive lanes (lanes to VLSU) - expanded
    input  logic       [NrLanes-1:0]              rxs_valid_i,
    output logic       [NrLanes-1:0]              rxs_ready_o,
    // rx_lane_t fields expanded
    input  logic       [DLEN-1   :0][NrLanes-1:0] rxs_data_i,

    // Mask Interface
    input  logic       [NrLanes-1:0]              mask_valid_i,
    input  strb_t      [NrLanes-1:0]              mask_bits_i,
    output logic                                  load_mask_ready_o,
    output logic                                  store_mask_ready_o
);

    // TODO: maybe do not need to multiply ELEN here
    typedef logic [$clog2(MaxLEN*ELEN/DLEN)-1    :0] rmn_grp_t; // 0 ~ (MaxLEN*ELEN/DLEN)-1
    typedef logic [$clog2(MaxLEN*ELEN/DLEN)-1    :0] cmt_cnt_t; // 0 ~ (MaxLEN*ELEN*NrLanes/DLEN*NrLanes)-1
    
    typedef logic [$clog2(MaxLEN*ELEN/(8*4096))-1:0] txn_num_t; // 0 ~ (MaxLEN*ELEN/8*4096)-1

    typedef logic [$clog2(4096/AxiDataWidth)-1   :0] rmn_beat_t; // 0 ~ (4096/AxiDataWidth)-1 
    typedef logic [$clog2(AxiDataWidth/4)        :0] lbn_t; // 1 ~ AxiDataWidth/4

    // Include type definitions
    `include "vlsu/vlsu_typedef.svh"

    // ================= Internal Signals ================= //
    logic        meta_ctrl_valid, meta_ctrl_ready;
    meta_glb_t   meta_glb;
    meta_seglv_t meta_seglv;

    logic        txn_ctrl_valid, txn_ctrl_ready;
    txn_ctrl_t   txn_ctrl;

    logic        aw_valid, aw_ready;
    axi_aw_t     aw_flit;

    logic        ar_valid, ar_ready;
    axi_ar_t     ar_flit;

    logic        b_valid, b_ready;
    axi_b_t      b_flit;

    logic        update_cm;
    
    // Load/Store Unit control signals
    logic        load_meta_ctrl_valid , load_meta_ctrl_ready;
    logic        store_meta_ctrl_valid, store_meta_ctrl_ready;
    logic        load_txn_ctrl_valid  , load_txn_ctrl_ready;
    logic        store_txn_ctrl_valid , store_txn_ctrl_ready;
    
    // Internal lane signals for submodule connections
    tx_lane_t    [NrLanes-1:0] txs_internal;
    rx_lane_t    [NrLanes-1:0] rxs_internal;

    // ================= Control Machine Instance ================= //
    ControlMachine #(
      .NrLanes      (NrLanes      ),
      .VLEN         (VLEN         ),
      .ALEN         (ALEN         ),
      .AxiDataWidth (AxiDataWidth ),
      .axi_aw_t     (axi_aw_t     ),
      .axi_ar_t     (axi_ar_t     ),
      .vlsu_req_t   (vlsu_req_t  ),
      .meta_glb_t   (meta_glb_t  ),
      .meta_seglv_t (meta_seglv_t),
      .txn_ctrl_t   (txn_ctrl_t  )
    ) i_cm (
      .clk_i             (clk_i           ),
      .rst_ni            (rst_ni          ),
      .vlsu_req_valid_i  (vlsu_req_valid_i),
      .vlsu_req_ready_o  (vlsu_req_ready_o),
      .vlsu_req_i        (vlsu_req_i      ),
      .core_st_pending_i (core_st_pending_i),
      .meta_ctrl_valid_o (meta_ctrl_valid ),
      .meta_ctrl_ready_i (meta_ctrl_ready ),
      .meta_glb_o        (meta_glb        ),
      .meta_seglv_o      (meta_seglv      ),
      .txn_ctrl_valid_o  (txn_ctrl_valid  ),
      .txn_ctrl_o        (txn_ctrl        ),
      .update_i          (update_cm       ),
      .aw_valid_o        (aw_valid        ),
      .aw_ready_i        (aw_ready        ),
      .aw_o              (aw_flit         ),
      .ar_valid_o        (ar_valid        ),
      .ar_ready_i        (ar_ready        ),
      .ar_o              (ar_flit         ),
      .b_valid_i         (b_valid         ),
      .b_ready_o         (b_ready         )
    );
    
    // ================= Load Unit Instance ================= //
    LoadUnit #(
      .NrLanes        (NrLanes        ),
      .VLEN           (VLEN           ),
      .ALEN           (ALEN           ),
      .AxiDataWidth   (AxiDataWidth   ),
      .AxiAddrWidth   (AxiAddrWidth   ),
      .axi_r_t        (axi_r_t        ),
      .txn_ctrl_t     (txn_ctrl_t     ),
      .meta_glb_t     (meta_glb_t     ),
      .tx_lane_t      (tx_lane_t      )
    ) i_load_unit (
      .clk_i                (clk_i                ),
      .rst_ni               (rst_ni               ),
      .axi_r_valid_i        (m_axi_r_valid_i      ),
      .axi_r_ready_o        (m_axi_r_ready_o      ),
      .axi_r_i              (m_axi_r_i            ),
      .txn_ctrl_valid_i     (load_txn_ctrl_valid  ),
      .txn_ctrl_ready_o     (load_txn_ctrl_ready  ),
      .txn_ctrl_i           (txn_ctrl             ),
      .meta_glb_valid_i     (load_meta_ctrl_valid ),
      .meta_glb_ready_o     (load_meta_ctrl_ready ),
      .meta_glb_i           (meta_glb             ),
      .txs_valid_o          (txs_valid_o          ),
      .txs_ready_i          (txs_ready_i          ),
      .txs_o                (txs_internal         ),
      .mask_valid_i         (mask_valid_i         ),
      .mask_bits_i          (mask_bits_i          ),
      .mask_ready_o         (load_mask_ready_o    )
    );
    
    // ================= Store Unit Instance ================= //
    StoreUnit #(
      .NrLanes        (NrLanes        ),
      .VLEN           (VLEN           ),
      .ALEN           (ALEN           ),
      .AxiDataWidth   (AxiDataWidth   ),
      .AxiAddrWidth   (AxiAddrWidth   ),
      .AxiUserWidth   (AxiUserWidth   ),
      .axi_w_t        (axi_w_t        ),
      .txn_ctrl_t     (txn_ctrl_t     ),
      .meta_glb_t     (meta_glb_t     ),
      .rx_lane_t      (rx_lane_t      )
    ) i_store_unit (
      .clk_i                (clk_i                ),
      .rst_ni               (rst_ni               ),
      .rxs_valid_i          (rxs_valid_i          ),
      .rxs_ready_o          (rxs_ready_o          ),
      .rxs_i                (rxs_internal         ),
      .axi_w_valid_o        (m_axi_w_valid_o      ),
      .axi_w_ready_i        (m_axi_w_ready_i      ),
      .axi_w_o              (m_axi_w_o            ),
      .txn_ctrl_valid_i     (store_txn_ctrl_valid ),
      .txn_ctrl_ready_o     (store_txn_ctrl_ready ),
      .txn_ctrl_i           (txn_ctrl             ),
      .meta_glb_valid_i     (store_meta_ctrl_valid),
      .meta_glb_ready_o     (store_meta_ctrl_ready),
      .meta_glb_i           (meta_glb             ),
      .mask_valid_i         (mask_valid_i         ),
      .mask_bits_i          (mask_bits_i          ),
      .mask_ready_o         (store_mask_ready_o   )
    );
    
    // ================= AXI Interface Connections ================= //
    assign m_axi_aw_valid_o = aw_valid;
    assign aw_ready         = m_axi_aw_ready_i;
    assign m_axi_aw_o       = aw_flit;
    
    assign m_axi_ar_valid_o = ar_valid;
    assign ar_ready         = m_axi_ar_ready_i;
    assign m_axi_ar_o       = ar_flit;
    
    assign b_valid          = m_axi_b_valid_i;
    assign m_axi_b_ready_o  = b_ready;
    assign b_flit           = m_axi_b_i;
    
    // ================= Control Signal Routing ================= //
    // Route meta control signals based on load/store operation
    assign load_meta_ctrl_valid  = meta_ctrl_valid && meta_glb.isLoad;
    assign store_meta_ctrl_valid = meta_ctrl_valid && !meta_glb.isLoad;
    
    // Route transaction control signals based on load/store operation
    assign load_txn_ctrl_valid   = txn_ctrl_valid && txn_ctrl.isLoad;
    assign store_txn_ctrl_valid  = txn_ctrl_valid && !txn_ctrl.isLoad;
    
    // Combine ready signals from load and store units
    assign meta_ctrl_ready       = load_meta_ctrl_ready && store_meta_ctrl_ready;
    assign txn_ctrl_ready        = load_txn_ctrl_ready  || store_txn_ctrl_ready;
    
    // ================= Update Signal Logic ================= //
    assign update_cm             = load_txn_ctrl_ready || store_txn_ctrl_ready;

    // ================= Lane Interface Connection Logic ================= //
    // Connect expanded txs interface to internal array
    generate
      for (int lane = 0; lane < NrLanes; lane++) begin : lane_connections
        // Connect txs_internal to expanded txs outputs
        assign txs_req_id_o   [lane]  = txs_internal[lane].reqId;
        assign txs_vaddr_set_o[lane]  = txs_internal[lane].vaddr_set;
        assign txs_vaddr_off_o[lane]  = txs_internal[lane].vaddr_off;
        assign txs_data_o     [lane]  = txs_internal[lane].data;
        assign txs_nbe_o      [lane]  = txs_internal[lane].nbe;
        
        // Connect expanded rxs inputs to rxs_internal
        assign rxs_internal[lane].data = rxs_data_i[lane];
      end
    endgenerate

endmodule : VLSU
