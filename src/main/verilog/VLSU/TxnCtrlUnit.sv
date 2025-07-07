// ============================================================================
// TxnCtrlUnitNC.sv
// SystemVerilog translation of Chisel TxnControlUnitNC
// Non-concurrent Transaction Control Unit
// ============================================================================

`timescale 1ns/1ps

import ControlMachinePkg::*;
import axi_pkg::*;

// Add a typedef for TxnCtrlInfo_t as a type parameter, to be passed in from outside
// (In SystemVerilog, you can use typedef as a parameter, or require the user to import it before instantiating this module)

module TxnCtrlUnit #(
  parameter int  TXN_CTRL_NUM = 4,           // Example value, should match your design
  parameter type txn_ctrl_t   = logic,       // <-- User must typedef txn_ctrl_t before instantiating this module
  parameter type aw_flit_t    = logic,       // <-- User must typedef aw_flit_t before instantiating this module
  parameter type ar_flit_t    = logic,       // <-- User must typedef ar_flit_t before instantiating this module
  parameter type meta_glb_t   = logic,       // <-- User must typedef meta_glb_t before instantiating this module
  parameter type meta_seglv_t = logic,       // <-- User must typedef meta_seglv_t before instantiating this module
  parameter int  PTR_WIDTH    = $clog2(TXN_CTRL_NUM)
) (
  input  logic                  clk_i,
  input  logic                  rst_ni,

  // Meta input
  input  logic                  meta_valid_i,
  output logic                  meta_ready_o,
  input  meta_glb_t             meta_glb_i,
  input  meta_seglv_t           meta_seglv_i,

  // TxnCtrl output
  output logic                  txn_ctrl_valid_o,
  output txn_ctrl_t             txn_ctrl_o,

  // Update signal
  input  logic                  update_i,

  // AXI4 AW/AR/B channels
  output logic                  aw_valid_o,
  input  logic                  aw_ready_i,
  output aw_flit_t              aw_o,

  output logic                  ar_valid_o,
  input  logic                  ar_ready_i,
  output ar_flit_t              ar_o,

  input  logic                  b_valid_i,
  output logic                  b_ready_o
);
  // --------------------- Internal Signals --------------------- //
  // Pointers
  logic enq_ptr_flag, deq_ptr_flag, txn_ptr_flag, data_ptr_flag;
  logic [PTR_WIDTH-1:0] enq_ptr_value, deq_ptr_value, txn_ptr_value, data_ptr_value;

  // Registers for TxnCtrlInfo
  txn_ctrl_t tcs_r   [TXN_CTRL_NUM];
  txn_ctrl_t tcs_nxt [TXN_CTRL_NUM];

  // Empty/Full Flags
  logic empty, full;

  // Pointer update logic
  logic data_ptr_add;
  logic do_enq;
  logic do_deq;
  
  // Handshake logic
  logic ax_valid;

  // --------------------- Main Logic --------------------------------- //
  // Default: hold values
  always_comb begin
    tcs_nxt = tcs_r;
    // Direct assignment for enqueue
    if (!full && meta_valid_i) begin
      tcs_nxt[enq_ptr_value].addr       = meta_seglv_i.segBaseAddr;
      tcs_nxt[enq_ptr_value].size       = 3'b100; // Example: 128 bits (should match bus size)
      tcs_nxt[enq_ptr_value].rmnBeat    = meta_seglv_i.txnNum;
      tcs_nxt[enq_ptr_value].lbN        = meta_seglv_i.ltN;
      tcs_nxt[enq_ptr_value].isHead     = 1'b1;
      tcs_nxt[enq_ptr_value].isLoad     = meta_glb_i.isLoad;
      tcs_nxt[enq_ptr_value].isFinalTxn = isFinalTxn(meta_seglv_i);
    end
    // Direct assignment for update
    if (update_i && !(tcs_r[data_ptr_value].rmnBeat == 0)) begin
      tcs_nxt[data_ptr_value].rmnBeat = tcs_r[data_ptr_value].rmnBeat - 1;
      tcs_nxt[data_ptr_value].isHead  = 1'b0;
    end
  end

  // --------------------- Pointer Update Logic ----------------------- //
  assign data_ptr_add = (tcs_r[data_ptr_value].rmnBeat == 0) && update_i;
  assign do_enq = meta_valid_i && meta_ready_o;
  assign do_deq = tcs_r[deq_ptr_value].isLoad ? data_ptr_add : (b_valid_i && b_ready_o);

  // --------------------- Handshake Logic ---------------------------- //
  assign ax_valid         = (txn_ptr_flag == deq_ptr_flag) && (txn_ptr_value == deq_ptr_value) && !empty;
  assign meta_ready_o     = !full;
  assign txn_ctrl_valid_o = !((enq_ptr_flag == data_ptr_flag) && (enq_ptr_value == data_ptr_value));
  assign aw_valid_o       = ax_valid && !tcs_r[txn_ptr_value].isLoad;
  assign ar_valid_o       = ax_valid &&  tcs_r[txn_ptr_value].isLoad;
  assign b_ready_o        = !empty;

  // --------------------- Output Logic ------------------------------- //
  always_comb begin
    aw_o = '0;
    ar_o = '0;
    
    if (aw_valid_o && aw_ready_i) begin
      aw_o.id    = '0;
      aw_o.addr  = tcs_r[txn_ptr_value].addr >> 1;
      aw_o.len   = tcs_r[txn_ptr_value].rmnBeat;
      aw_o.size  = tcs_r[txn_ptr_value].size;
      aw_o.burst = BURST_INCR;
      aw_o.cache = CACHE_MODIFIABLE;
    end
    
    if (ar_valid_o && ar_ready_i) begin
      ar_o.id    = '0;
      ar_o.addr  = tcs_r[txn_ptr_value].addr >> 1;
      ar_o.len   = tcs_r[txn_ptr_value].rmnBeat;
      ar_o.size  = tcs_r[txn_ptr_value].size;
      ar_o.burst = BURST_INCR;
      ar_o.cache = CACHE_MODIFIABLE;
    end
  end

  assign txn_ctrl_o = tcs_r[data_ptr_value];

  // -------- Instantiate 4 CircularQueuePtrTemplate modules for each pointer -------- //
  CircularQueuePtrTemplate #(
    .ENTRIES(TXN_CTRL_NUM)
  ) enq_ptr_inst (
    .clk_i        (clk_i),
    .rst_ni       (rst_ni),
    .ptr_inc_i    (do_enq),
    .ptr_flag_o   (enq_ptr_flag),
    .ptr_value_o  (enq_ptr_value)
  );

  CircularQueuePtrTemplate #(
    .ENTRIES(TXN_CTRL_NUM)
  ) deq_ptr_inst (
    .clk_i        (clk_i),
    .rst_ni       (rst_ni),
    .ptr_inc_i    (do_deq),
    .ptr_flag_o   (deq_ptr_flag),
    .ptr_value_o  (deq_ptr_value)
  );

  CircularQueuePtrTemplate #(
    .ENTRIES(TXN_CTRL_NUM)
  ) txn_ptr_inst (
    .clk_i        (clk_i),
    .rst_ni       (rst_ni),
    .ptr_inc_i    ((aw_valid_o && aw_ready_i) || (ar_valid_o && ar_ready_i)),
    .ptr_flag_o   (txn_ptr_flag),
    .ptr_value_o  (txn_ptr_value)
  );

  CircularQueuePtrTemplate #(
    .ENTRIES(TXN_CTRL_NUM)
  ) data_ptr_inst (
    .clk_i        (clk_i),
    .rst_ni       (rst_ni),
    .ptr_inc_i    (data_ptr_add),
    .ptr_flag_o   (data_ptr_flag),
    .ptr_value_o  (data_ptr_value)
  );

  // --------------------- Registers ---------------------------------- //
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      tcs_r <= '0;
    end else begin
      tcs_r <= tcs_nxt;
    end
  end

  // --------------------- Assertions ---------------------------------
  always_ff @(posedge clk_i) begin
    if (update_i) assert(!empty);
    if (b_valid_i) assert(!empty);
    assert((txn_ptr_flag == enq_ptr_flag && txn_ptr_value <= enq_ptr_value) || full);
    assert((data_ptr_flag == enq_ptr_flag && data_ptr_value <= enq_ptr_value) || full);
    assert((deq_ptr_flag == data_ptr_flag && deq_ptr_value <= data_ptr_value) || full);
  end

endmodule