// ============================================================================
// VLSU.sv
// Vector Load Store Unit - Top Level Module
// ============================================================================

`timescale 1ns/1ps

import vlsu_pkg::*;
import ControlMachinePkg::*;
import axi_pkg::*;

module VLSU #(
    parameter  int   unsigned  NrLanes      = 0,
    parameter  int   unsigned  VLEN         = 0,
    parameter  int   unsigned  ALEN         = 0,
    parameter  type            vaddr_t      = logic,
    parameter  type            pe_req_t     = logic,
    parameter  type            pe_resp_t    = logic,
    
    // AXI type parameters (from upstream)
    parameter  int   unsigned  AxiDataWidth = 0,
    parameter  int   unsigned  AxiAddrWidth = 0,

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
    input  axi_r_t        m_axi_r_i
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
    logic meta_ctrl_valid, meta_ctrl_ready;
    meta_glb_t meta_glb;
    meta_seglv_t meta_seglv;

    logic txn_ctrl_valid, txn_ctrl_ready;
    txn_ctrl_t txn_ctrl;

    logic aw_valid, aw_ready;
    axi_aw_t aw_flit;

    logic ar_valid, ar_ready;
    axi_ar_t ar_flit;

    logic b_valid, b_ready;
    axi_b_t b_flit;

    logic update_signal;
    
    // ================= Control Machine Instance ================= //
    ControlMachine #(
        .NrLanes      (NrLanes      ),
        .VLEN         (VLEN         ),
        .ALEN         (ALEN         ),
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
        .update_i          (update_signal   ),
        .aw_valid_o        (aw_valid        ),
        .aw_ready_i        (aw_ready        ),
        .aw_o              (aw_flit         ),
        .ar_valid_o        (ar_valid        ),
        .ar_ready_i        (ar_ready        ),
        .ar_o              (ar_flit         ),
        .b_valid_i         (b_valid         ),
        .b_ready_o         (b_ready         )
    );
    
    // ================= AXI Interface Connections ================= //
    assign m_axi_aw_valid_o = aw_valid;
    assign aw_ready = m_axi_aw_ready_i;
    assign m_axi_aw_o = aw_flit;
    
    assign m_axi_ar_valid_o = ar_valid;
    assign ar_ready = m_axi_ar_ready_i;
    assign m_axi_ar_o = ar_flit;
    
    assign b_valid = m_axi_b_valid_i;
    assign m_axi_b_ready_o = b_ready;
    assign b_flit = m_axi_b_i;
    
    // TODO: Connect w and r channels when corresponding modules are ready
    // assign m_axi_w_valid_o = ...;
    // assign m_axi_w_o = ...;
    // assign m_axi_r_ready_o = ...;
    
    // ================= Update Signal Logic ================= //
    assign update_signal = m_axi_b_valid_i && m_axi_b_ready_o;

endmodule : VLSU
