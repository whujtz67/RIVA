// ============================================================================
// MTxnCtrlUnit.sv
// Matrix Transaction Control Unit - Handles matrix transaction control
// ============================================================================



module MTxnCtrlUnit import riva_pkg::*; import mlsu_pkg::*; #(
  parameter int   unsigned AxiDataWidth = 0,  // AXI data width in bits
  parameter type           txn_ctrl_t   = logic,       // <-- User must typedef txn_ctrl_t before instantiating this module
  parameter type           axi_aw_t     = logic,       // <-- User must typedef axi_aw_t before instantiating this module
  parameter type           axi_ar_t     = logic,       // <-- User must typedef axi_ar_t before instantiating this module
  parameter type           meta_glb_t   = logic,       // <-- User must typedef meta_glb_t before instantiating this module
  parameter type           meta_seglv_t = logic,       // <-- User must typedef meta_seglv_t before instantiating this module
  parameter type           pe_resp_t    = logic,       // <-- User must typedef pe_resp_t before instantiating this module
  
  // Dependant parameters. DO NOT CHANGE!
  localparam int   unsigned  busNibbles       = AxiDataWidth / 4,
  localparam int   unsigned  busNSize         = $clog2(busNibbles)
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
  output axi_aw_t               aw_o,

  output logic                  ar_valid_o,
  input  logic                  ar_ready_i,
  output axi_ar_t               ar_o,

  input  logic                  b_valid_i,
  output logic                  b_ready_o,

  // pe resp store
  output pe_resp_t              pe_resp_store_o
);

  // ------------------- Helper Functions ------------------- //
  function automatic logic isLastSeg(input meta_glb_t g); // TODO: meta_glb_t cannot reach here?
    return (g.rmnSeg == 0);
  endfunction

  function automatic logic isHeadTxn(input meta_seglv_t s);
    return (s.txnCnt == 0);
  endfunction

  function automatic logic isLastTxn(input meta_seglv_t s);
    return (s.txnCnt == s.txnNum);
  endfunction

  function automatic logic isFinalTxn(input meta_glb_t glb, input meta_seglv_t seg);
    return isLastSeg(glb) && isLastTxn(seg);
  endfunction

  // --------------------- Pointer Signals --------------------- //
  // Pointers
  logic                          enq_ptr_flag , deq_ptr_flag , txn_ptr_flag , data_ptr_flag ;
  logic [$clog2(txnCtrlNum)-1:0] enq_ptr_value, deq_ptr_value, txn_ptr_value, data_ptr_value;

  // Registers for TxnCtrlInfo
  txn_ctrl_t tcs_r   [txnCtrlNum];
  txn_ctrl_t tcs_nxt [txnCtrlNum];

  // Empty/Full Flags
  wire empty = (enq_ptr_flag == deq_ptr_flag) && (enq_ptr_value == deq_ptr_value);
  wire full  = (enq_ptr_flag != deq_ptr_flag) && (enq_ptr_value == deq_ptr_value);

  // Pointer update logic
  logic data_ptr_add;
  logic do_enq;
  logic do_deq;
  
  // Handshake logic
  logic ax_valid;

  // --------------------- Internal Signals --------------------- //
  wire [riva_pkg::ELEN-1:0] txn_addr_nxt = isHeadTxn(meta_seglv_i) ?
        meta_seglv_i.segBaseAddr :
        ((meta_seglv_i.segBaseAddr >> 13) + meta_seglv_i.txnCnt) << 13;

  wire [12:0] page_off   = txn_addr_nxt[12:0];
  wire [12:0] busOffMask = ((1 << 13) - 1) - ((1 << busNSize) - 1);

  wire [12:0] pageOff_without_busOff = page_off & busOffMask;

  wire [13:0] txn_nibbles_with_pageOff = isLastTxn(meta_seglv_i) ?
        meta_seglv_i.ltN : // PageOff is already included in ltN
        8192;
  wire [13:0] txn_nibbles_with_busOff = txn_nibbles_with_pageOff - pageOff_without_busOff;

  // --------------------- Main Logic --------------------------------- //
  // Default: hold values
  always_comb begin: txn_ctrl_update_logic
    tcs_nxt = tcs_r;
    // Direct assignment for enqueue
    if (!full && meta_valid_i) begin

      tcs_nxt[enq_ptr_value].reqId      = meta_glb_i.reqId;
      tcs_nxt[enq_ptr_value].addr       = txn_addr_nxt;
      tcs_nxt[enq_ptr_value].size       = $clog2(AxiDataWidth/8); // AXI size = log2(bytes per transfer)

      tcs_nxt[enq_ptr_value].rmnBeat    = (txn_nibbles_with_busOff - 1) >> busNSize;
      tcs_nxt[enq_ptr_value].lbN        = |(txn_nibbles_with_busOff[busNSize-1:0]) ?
        txn_nibbles_with_busOff[busNSize-1:0] :
        busNibbles;
      tcs_nxt[enq_ptr_value].isHead     = 1'b1;
      tcs_nxt[enq_ptr_value].isLoad     = meta_glb_i.isLoad;
      tcs_nxt[enq_ptr_value].isFinalTxn = isFinalTxn(meta_glb_i, meta_seglv_i);
    end
    // Direct assignment for update
    if (update_i && !(tcs_r[data_ptr_value].rmnBeat == 0)) begin
      tcs_nxt[data_ptr_value].rmnBeat = tcs_r[data_ptr_value].rmnBeat - 1;
      tcs_nxt[data_ptr_value].isHead  = 1'b0;
    end
  end: txn_ctrl_update_logic

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
  always_comb begin: axi_output_logic
    aw_o = '0;
    ar_o = '0;
    
    if (aw_valid_o && aw_ready_i) begin
      aw_o.id    = '0;
      aw_o.addr  = tcs_r[txn_ptr_value].addr >> 1;
      aw_o.len   = tcs_r[txn_ptr_value].rmnBeat;
      aw_o.size  = tcs_r[txn_ptr_value].size;
      aw_o.burst = axi_pkg::BURST_INCR;
      aw_o.cache = axi_pkg::CACHE_MODIFIABLE;
    end
    
    if (ar_valid_o && ar_ready_i) begin
      ar_o.id    = '0;
      ar_o.addr  = tcs_r[txn_ptr_value].addr >> 1;
      ar_o.len   = tcs_r[txn_ptr_value].rmnBeat;
      ar_o.size  = tcs_r[txn_ptr_value].size;
      ar_o.burst = axi_pkg::BURST_INCR;
      ar_o.cache = axi_pkg::CACHE_MODIFIABLE;
    end
  end: axi_output_logic

  assign txn_ctrl_o = tcs_r[data_ptr_value];

  // -------- Instantiate 4 CircularQueuePtrTemplate modules for each pointer -------- //
  CircularQueuePtrTemplate #(
    .ENTRIES(txnCtrlNum)
  ) enq_ptr_inst (
    .clk_i        (clk_i        ),
    .rst_ni       (rst_ni       ),
    .ptr_inc_i    (do_enq       ),
    .ptr_flag_o   (enq_ptr_flag ),
    .ptr_value_o  (enq_ptr_value)
  );

  CircularQueuePtrTemplate #(
    .ENTRIES(txnCtrlNum)
  ) deq_ptr_inst (
    .clk_i        (clk_i        ),
    .rst_ni       (rst_ni       ),
    .ptr_inc_i    (do_deq       ),
    .ptr_flag_o   (deq_ptr_flag ),
    .ptr_value_o  (deq_ptr_value)
  );

  CircularQueuePtrTemplate #(
    .ENTRIES(txnCtrlNum)
  ) txn_ptr_inst (
    .clk_i        (clk_i        ),
    .rst_ni       (rst_ni       ),
    .ptr_inc_i    ((aw_valid_o && aw_ready_i) || (ar_valid_o && ar_ready_i)),
    .ptr_flag_o   (txn_ptr_flag ),
    .ptr_value_o  (txn_ptr_value)
  );

  CircularQueuePtrTemplate #(
    .ENTRIES(txnCtrlNum)
  ) data_ptr_inst (
    .clk_i        (clk_i         ),
    .rst_ni       (rst_ni        ),
    .ptr_inc_i    (data_ptr_add  ),
    .ptr_flag_o   (data_ptr_flag ),
    .ptr_value_o  (data_ptr_value)
  );

  always_comb begin: pe_resp_store_logic
    pe_resp_store_o = '0;
    if (b_valid_i && b_ready_o && tcs_r[deq_ptr_value].isLoad) begin
      pe_resp_store_o.vinsn_done[tcs_r[deq_ptr_value].reqId] = 1'b1;
    end
  end: pe_resp_store_logic

  // --------------------- Registers ---------------------------------- //
  genvar i;
  generate
    for (i = 0; i < txnCtrlNum; i = i + 1) begin : tcs_regs
      always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
          tcs_r[i] <= '0;
        end else begin
          tcs_r[i] <= tcs_nxt[i];
        end
      end
    end
  endgenerate

  // --------------------- Assertions ---------------------------------
  `ifndef SYNTHESIS
    always_ff @(posedge clk_i) begin
      if (update_i ) assert(!empty);
      if (b_valid_i) assert(!empty);
      // Right pointer should be not after left pointer.
      assert(((txn_ptr_flag  ^ enq_ptr_flag ) ^ (txn_ptr_value  <= enq_ptr_value )) || (txn_ptr_flag  != enq_ptr_flag  && txn_ptr_value  == enq_ptr_value ))
        else $fatal("enqPtr should not be after txnPtr");
      assert(((data_ptr_flag ^ enq_ptr_flag ) ^ (data_ptr_value <= enq_ptr_value )) || (data_ptr_flag != enq_ptr_flag  && data_ptr_value == enq_ptr_value ))
        else $fatal("enqPtr should not be after dataPtr");
      assert(((deq_ptr_flag  ^ data_ptr_flag) ^ (deq_ptr_value  <= data_ptr_value)) || (deq_ptr_flag  != data_ptr_flag && deq_ptr_value  == data_ptr_value))
        else $fatal("dataPtr should not be after deqPtr");
        
      assert (txn_nibbles_with_pageOff >= pageOff_without_busOff)
          else $fatal("txn_nibbles_with_pageOff should >= pageOff_without_busOff, got txn_nibbles_with_pageOff = %0d, pageOff_without_busOff = %0d", txn_nibbles_with_pageOff, pageOff_without_busOff);
        assert (txn_nibbles_with_busOff <= 8192)
          else $fatal("txn_nibbles_with_busOff should in range(0, 8192). However, got %0d", txn_nibbles_with_busOff);
    end
  `endif

endmodule : MTxnCtrlUnit