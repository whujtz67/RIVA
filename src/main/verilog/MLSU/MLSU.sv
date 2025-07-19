// ============================================================================
// MLSU.sv
// Matrix Load Store Unit - Top Level Module
// ============================================================================

module MLSU import riva_pkg::*; import vlsu_pkg::*; #(
    parameter  int   unsigned  NrExits      = 0,
    parameter  int   unsigned  VLEN         = 0,
    parameter  int   unsigned  MLEN         = 0,
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
    localparam type            strb_t       = logic [DLEN/4-1:0],
    localparam type            vlen_t       = logic [$clog2(VLEN+1)-1:0],
    localparam type            mlen_t       = logic [$clog2(MLEN+1)-1:0]
) (
    // Clock and Reset
    input  logic          clk_i,
    input  logic          rst_ni,
    
    // VLSU Request Interface
    input  logic          pe_req_valid_i,
    output logic          pe_req_ready_o,
    input  pe_req_t       pe_req_i,
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
    output logic        [NrExits-1:0]              txs_valid_o,
    input  logic        [NrExits-1:0]              txs_ready_i,
    // tx_lane_t fields expanded
    output vid_t        [NrExits-1:0]              txs_reqId_o,
    output maddr_set_t  [NrExits-1:0]              txs_maddr_set_o,
    output maddr_bank_t [NrExits-1:0]              txs_maddr_bank_o,
    output logic        [NrExits-1:0][DLEN-1   :0] txs_data_o,
    output logic        [NrExits-1:0][DLEN/4 -1:0] txs_nbe_o,
    
    // Receive lanes (lanes to VLSU) - expanded
    input  logic        [NrExits-1:0]              rxs_valid_i,
    output logic        [NrExits-1:0]              rxs_ready_o,
    // rx_lane_t fields expanded
    input  logic        [NrExits-1:0][DLEN-1   :0] rxs_data_i,

    // Mask Interface
    input  logic        [NrExits-1:0]              mask_valid_i,
    input  strb_t       [NrExits-1:0]              mask_bits_i,
    output logic                                   load_mask_ready_o,
    output logic                                   store_mask_ready_o,

    // pe resp load and store
    output pe_resp_t pe_resp_load_o,
    output pe_resp_t pe_resp_store_o
);


    // TODO: maybe do not need to multiply ELEN here
    typedef logic [$clog2(MLEN*ELEN/DLEN)     -1 :0] cmt_cnt_t; // 0 ~ (MLEN*ELEN*NrExits/DLEN*NrExits)-1
    
    typedef logic [$clog2(MLEN*ELEN/(8*4096)) -1 :0] txn_num_t; // 0 ~ (MLEN*ELEN/8*4096)-1

    typedef logic [$clog2(8*4096/AxiDataWidth)-1 :0] rmn_beat_t; // 0 ~ (4096/AxiDataWidth)-1 
    typedef logic [$clog2(AxiDataWidth/4)        :0] lbn_t; // 1 ~ AxiDataWidth/4

    // Include type definitions
    `include "mlsu/mlsu_typedef.svh"

    // ================= Internal Signals ================= //
    // IQ (Instruction Queue) signals
    logic             iq_enq_valid, iq_enq_ready;
    mlsu_init_req_t   iq_enq_bits;
    logic             iq_deq_valid, iq_deq_ready;
    mlsu_init_req_t   iq_deq_bits;

    logic             meta_ctrl_valid, meta_ctrl_ready;
    meta_glb_t        meta_glb;
    meta_seglv_t      meta_seglv;
     
    logic             txn_ctrl_valid, txn_ctrl_ready;
    txn_ctrl_t        txn_ctrl;
     
    logic             aw_valid, aw_ready;
    axi_aw_t          aw_flit;
     
    logic             ar_valid, ar_ready;
    axi_ar_t          ar_flit;
     
    logic             b_valid, b_ready;
    axi_b_t           b_flit;
     
    logic             update_cm;
    
    // Load/Store Unit control signals
    logic             load_meta_ctrl_valid , load_meta_ctrl_ready;
    logic             store_meta_ctrl_valid, store_meta_ctrl_ready;
    logic             load_txn_ctrl_valid  , load_txn_ctrl_ready;
    logic             store_txn_ctrl_valid , store_txn_ctrl_ready;
    
    // Internal lane signals for submodule connections
    tx_lane_t    [NrExits-1:0] txs_internal;
    rx_lane_t    [NrExits-1:0] rxs_internal;

    // ================= pe_req to vlsu_req Conversion ================= //
    // Convert pe_req_t to mlsu_init_req_t (equivalent to init function in Chisel)
    always_comb begin: pe_req_to_vlsu_req
      // Map pe_req fields to mlsu_init_req fields
      iq_enq_bits.reqId    = pe_req_i.reqId;
      iq_enq_bits.mop      = pe_req_i.mop;
      iq_enq_bits.baseAddr = pe_req_i.baseAddr;
      iq_enq_bits.sew      = pe_req_i.sew;
      iq_enq_bits.md       = pe_req_i.vd;
      iq_enq_bits.stride   = pe_req_i.stride;
      // len equals mlen when requesting matrix operations
      iq_enq_bits.vl       = pe_req_i.vl;
      iq_enq_bits.tile     = pe_req_i.tile;
      iq_enq_bits.isLoad   = pe_req_i.isLoad;
      iq_enq_bits.vm       = pe_req_i.vm;
    end: pe_req_to_vlsu_req

    // Connect pe_req interface to IQ
    assign iq_enq_valid   = pe_req_valid_i;
    assign pe_req_ready_o = iq_enq_ready;

    // ================= IQ (Instruction Queue) Instance ================= //
    QueueFlow #(
      .T      (mlsu_init_req_t),
      .DEPTH  (reqBufDep)
    ) i_iq (
      .clk_i        (clk_i        ),
      .rst_ni       (rst_ni       ),
      .enq_valid_i  (iq_enq_valid ),
      .enq_ready_o  (iq_enq_ready ),
      .enq_bits_i   (iq_enq_bits  ),
      .deq_valid_o  (iq_deq_valid ),
      .deq_ready_i  (iq_deq_ready ),
      .deq_bits_o   (iq_deq_bits  )
    );

    

    // ================= Control Machine Instance ================= //
    MControlMachine #(
      .NrExits           (NrExits           ),
      .VLEN              (VLEN              ),
      .MLEN              (MLEN              ),
      .AxiDataWidth      (AxiDataWidth      ),
      .axi_aw_t          (axi_aw_t          ),
      .axi_ar_t          (axi_ar_t          ),
      .mlsu_init_req_t   (mlsu_init_req_t   ),
      .mlsu_predec_req_t (mlsu_predec_req_t ),
      .meta_glb_t        (meta_glb_t        ),
      .meta_seglv_t      (meta_seglv_t      ),
      .txn_ctrl_t        (txn_ctrl_t        ),
      .pe_resp_t         (pe_resp_t         )
    ) i_cm (
      .clk_i             (clk_i            ),
      .rst_ni            (rst_ni           ),
      .mlsu_req_valid_i  (iq_deq_valid     ),
      .mlsu_req_ready_o  (iq_deq_ready     ),
      .mlsu_req_i        (iq_deq_bits      ),
      .core_st_pending_i (core_st_pending_i),
      .meta_ctrl_valid_o (meta_ctrl_valid  ),
      .meta_ctrl_ready_i (meta_ctrl_ready  ),
      .meta_glb_o        (meta_glb         ),
      .meta_seglv_o      (meta_seglv       ),
      .txn_ctrl_valid_o  (txn_ctrl_valid   ),
      .txn_ctrl_o        (txn_ctrl         ),
      .update_i          (update_cm        ),
      .aw_valid_o        (aw_valid         ),
      .aw_ready_i        (aw_ready         ),
      .aw_o              (aw_flit          ),
      .ar_valid_o        (ar_valid         ),
      .ar_ready_i        (ar_ready         ),
      .ar_o              (ar_flit          ),
      .b_valid_i         (b_valid          ),
      .b_ready_o         (b_ready          ),
      .pe_resp_store_o   (pe_resp_store_o  )
    );
    
    // ================= Load Unit Instance ================= //
    MLoadUnit #(
      .NrExits        (NrExits        ),
      .VLEN           (VLEN           ),
      .MLEN           (MLEN           ),
      .AxiDataWidth   (AxiDataWidth   ),
      .AxiAddrWidth   (AxiAddrWidth   ),
      .axi_r_t        (axi_r_t        ),
      .txn_ctrl_t     (txn_ctrl_t     ),
      .meta_glb_t     (meta_glb_t     ),
      .tx_lane_t      (tx_lane_t      ),
      .pe_resp_t      (pe_resp_t      )
    ) i_ldu (
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
      .mask_ready_o         (load_mask_ready_o    ),
      .pe_resp_load_o       (pe_resp_load_o       )
    );
    
    // ================= Store Unit Instance ================= //
    MStoreUnit #(
      .NrExits        (NrExits        ),
      .VLEN           (VLEN           ),
      .MLEN           (MLEN           ),
      .AxiDataWidth   (AxiDataWidth   ),
      .AxiAddrWidth   (AxiAddrWidth   ),
      .AxiUserWidth   (AxiUserWidth   ),
      .axi_w_t        (axi_w_t        ),
      .txn_ctrl_t     (txn_ctrl_t     ),
      .meta_glb_t     (meta_glb_t     ),
      .rx_lane_t      (rx_lane_t      )
    ) i_stu (
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
    genvar lane;
    generate
      for (lane = 0; lane < NrExits; lane++) begin : lane_connections
        // Connect txs_internal to expanded txs outputs
        assign txs_reqId_o     [lane]  = txs_internal[lane].reqId;
        assign txs_maddr_set_o [lane]  = txs_internal[lane].maddr_set;
        assign txs_maddr_bank_o[lane]  = txs_internal[lane].maddr_bank;
        assign txs_data_o      [lane]  = txs_internal[lane].data;
        assign txs_nbe_o       [lane]  = txs_internal[lane].nbe;
        
        // Connect expanded rxs inputs to rxs_internal
        assign rxs_internal[lane].data = rxs_data_i[lane];
      end
    endgenerate

endmodule : MLSU
