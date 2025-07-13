// ============================================================================
// ShuffleUnit.sv
// SystemVerilog implementation of Shuffle Unit for VLSU
// 
// This module handles the shuffle operation from sequential buffer to shuffle buffer
// using the query_seq_idx function from vlsu_shuffle_pkg.sv
// ============================================================================

module ShuffleUnit import vlsu_pkg::*; #(
  parameter  int  unsigned  NrLanes       = 0,
  parameter  int  unsigned  VLEN          = 0,
  parameter  int  unsigned  ALEN          = 0,
  
  // Type parameters
  parameter  type           meta_ctrl_t    = logic,
  parameter  type           seq_buf_t     = logic,
  parameter  type           tx_lane_t     = logic,
  parameter  type           shf_info_t    = logic,
  
  // Dependent parameters, DO NOT OVERRIDE!
  parameter  int  unsigned  laneIdBits    = $clog2(NrLanes),
  parameter  int  unsigned  laneOffBits   = $clog2(DLEN/4),
  parameter  int  unsigned  nbIdxBits     = $clog2((DLEN/4) * NrLanes),

  // Dependant parameters. DO NOT CHANGE!
  localparam type           strb_t        = logic [DLEN/4-1:0]

) (
  input  logic                       clk_i,
  input  logic                       rst_ni,

  // Input from LoadUnit
  input  logic                       rx_seq_load_valid_i,
  output logic                       rx_seq_load_ready_o,
  input  seq_buf_t                   rx_seq_load_i,

  // Output to Lane Entries
  output logic      [NrLanes-1:0]    txs_valid_o,
  input  logic      [NrLanes-1:0]    txs_ready_i,
  output tx_lane_t  [NrLanes-1:0]    txs_o,

  // MetaInfo from broadcast module
  input  logic                       meta_info_valid_i,
  output logic                       meta_info_ready_o,
  input  meta_ctrl_t                 meta_info_i,

  // Mask from mask unit
  input  logic      [NrLanes-1:0]    mask_valid_i,
  input  strb_t     [NrLanes-1:0]    mask_bits_i,
  output logic                       mask_ready_o
);

  // ================= Internal Signals ================= //
  // Shuffle buffer using registers (like Chisel implementation)
  logic     [NrLanes-1:0] shf_buf_valid;
  tx_lane_t [NrLanes-1:0] shf_buf_bits ;
  logic                   shf_buf_empty;

  // ShfInfo buffer using CircularQueuePtrTemplate
  shf_info_t                        shf_info_buf [shfInfoBufDep-1:0];
  logic                             shf_info_enq_ptr_flag , shf_info_deq_ptr_flag ;
  logic [$clog2(shfInfoBufDep)-1:0] shf_info_enq_ptr_value, shf_info_deq_ptr_value;
  logic                             shf_info_buf_enq  , shf_info_buf_deq;
  logic                             shf_info_buf_empty, shf_info_buf_full;

  // Current shuffle info
  shf_info_t              shfInfo;

  // Control signals
  logic                   do_cmt_seq_to_shf;

  // ================= Circular Queue Pointer Instantiations ================= //
  CircularQueuePtrTemplate #(
    .ENTRIES(shfInfoBufDep)
  ) i_shf_info_enq_ptr (
    .clk_i      (clk_i                    ),
    .rst_ni     (rst_ni                   ),
    .ptr_inc_i  (shf_info_buf_enq        ),
    .ptr_flag_o (shf_info_enq_ptr_flag   ),
    .ptr_value_o(shf_info_enq_ptr_value  )
  );

  CircularQueuePtrTemplate #(
    .ENTRIES(shfInfoBufDep)
  ) i_shf_info_deq_ptr (
    .clk_i      (clk_i                    ),
    .rst_ni     (rst_ni                   ),
    .ptr_inc_i  (shf_info_buf_deq        ),
    .ptr_flag_o (shf_info_deq_ptr_flag   ),
    .ptr_value_o(shf_info_deq_ptr_value  )
  );

  // ================= Buffer Logic ================= //
  assign shf_info_buf_empty = (shf_info_enq_ptr_value == shf_info_deq_ptr_value) && 
                              (shf_info_enq_ptr_flag  == shf_info_deq_ptr_flag );
  assign shf_info_buf_full  = (shf_info_enq_ptr_value == shf_info_deq_ptr_value) && 
                              (shf_info_enq_ptr_flag  != shf_info_deq_ptr_flag );

  // Get current shuffle info
  assign shfInfo = shf_info_buf[shf_info_deq_ptr_value];

  // -------------------------------------------
  // ShfInfo Buffer Logic
  // -------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      shf_info_buf_enq <= 1'b0;
      shf_info_buf_deq <= 1'b0;
    end else begin
      shf_info_buf_enq <= 1'b0;
      shf_info_buf_deq <= 1'b0;

      // Enqueue meta info
      if (meta_info_valid_i && meta_info_ready_o) begin
        // Software calculations (same as VAddrBundle.init)
        automatic int unsigned vd_msb = $clog2(NrVregs);
        
        // Hardware signals
        automatic vaddr_t     vaddr_calc;
        automatic vaddr_set_t vd_base_set;
        automatic elen_t      start_elem_in_vd;
        
        // Calculate vd_base_set
        vd_base_set = meta_info_i.glb.vd[vd_msb] 
            ? (AregBaseSet + (meta_info_i.glb.vd[vd_msb-1:0] * NrSetPerAreg))
            : (meta_info_i.glb.vd[vd_msb-1:0] * NrSetPerVreg);
        
        // Calculate start_elem_in_vd
        start_elem_in_vd = meta_info_i.glb.vstart >> $clog2(NrLanes);
        
        // Calculate final vaddr (same as VAddrBundle.init)
        vaddr_calc     = vd_base_set + (start_elem_in_vd >> (3 - meta_info_i.glb.eew));
        
        shf_info_buf[shf_info_enq_ptr_value].req_id    <= meta_info_i.glb.req_id;
        shf_info_buf[shf_info_enq_ptr_value].mode      <= meta_info_i.glb.mode;
        shf_info_buf[shf_info_enq_ptr_value].eew       <= meta_info_i.glb.eew;
        shf_info_buf[shf_info_enq_ptr_value].vd        <= meta_info_i.glb.vd;
        shf_info_buf[shf_info_enq_ptr_value].vstart    <= meta_info_i.glb.vstart;
        shf_info_buf[shf_info_enq_ptr_value].vm        <= meta_info_i.glb.vm;
        shf_info_buf[shf_info_enq_ptr_value].cmt_cnt   <= meta_info_i.glb.cmt_cnt;
        shf_info_buf[shf_info_enq_ptr_value].vaddr_set <= vaddr_calc[VAddrBits-1:VAddrOffBits];
        shf_info_buf[shf_info_enq_ptr_value].vaddr_off <= vaddr_calc[VAddrOffBits-1:0];
        shf_info_buf_enq <= 1'b1;
      end

      // Dequeue meta info when commit is done
      if (do_cmt_seq_to_shf && !shfInfo.cmt_cnt.orR) begin
        shf_info_buf_deq <= 1'b1;
      end
    end
  end

  assign meta_info_ready_o = !shf_info_buf_full;

  // -------------------------------------------
  // seqBuf -> shfBuf
  // -------------------------------------------
  assign rx_seq_load_ready_o = shf_buf_empty && !shf_info_buf_empty && (shfInfo.vm || |mask_valid_i);
  assign do_cmt_seq_to_shf = rx_seq_load_valid_i && rx_seq_load_ready_o;

  // Shuffle and commit data and nbe in seqBuf to shfBuf
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (int i = 0; i < NrLanes; i++) begin
        shf_buf_valid[i] <= 1'b0;
        shf_buf_bits [i] <= '0;
      end
    end else if (do_cmt_seq_to_shf) begin
      // Shuffle data using query_seq_idx function
      for (int lane = 0; lane < NrLanes; lane++) begin
        for (int off = 0; off < DLEN/4; off++) begin
		      automatic int unsigned shf_idx = lane * NrLanes + off;
          // Get sequential index for this lane/offset combination
          automatic int unsigned seq_idx = ControlMachinePkg::isCln2D(shfInfo.mode)
              ? query_seq_idx_2d_cln(NrLanes, shf_idx, shfInfo.eew)
              : query_seq_idx       (NrLanes, shf_idx, shfInfo.eew);
          
          // Assign data and nbe
          shf_buf_bits[lane].data[off*4+3:off*4] <= rx_seq_load_i.nb[seq_idx];
          shf_buf_bits[lane].nbe[off] <= rx_seq_load_i.en[seq_idx] && 
                                         (shfInfo.vm || mask_bits_i[lane][off]);
        end
      end

        // Make all shuffle buffer valid
        for (int i = 0; i < NrLanes; i++) begin
          shf_buf_valid[i]           <= 1'b1;
          shf_buf_bits [i].req_id    <= shfInfo.req_id;
          shf_buf_bits [i].vaddr_set <= shfInfo.vaddr_set;
          shf_buf_bits [i].vaddr_off <= shfInfo.vaddr_off;
        end

        // Update vaddr
        shfInfo.vaddr_set <= shfInfo.vaddr_set + 1;

        // Update commit counter
        if (!shfInfo.cmt_cnt.orR) begin
          // Final transaction, dequeue shfInfo
          shf_info_buf_deq <= 1'b1;
        end else begin
          shfInfo.cmt_cnt <= shfInfo.cmt_cnt - 1;
        end
    end
  end

  assign mask_ready_o = do_cmt_seq_to_shf && !shfInfo.vm;

  // -------------------------------------------
  // shfBuf -> lane
  // -------------------------------------------
  always_comb begin
    for (int lane = 0; lane < NrLanes; lane++) begin
      txs_valid_o[lane] = shf_buf_valid[lane];
      txs_o[lane] = shf_buf_bits[lane];
    end
  end

  // Clear shuffle buffer when transaction is accepted
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      shf_buf_empty <= 1'b1;
      for (int i = 0; i < NrLanes; i++) begin
        shf_buf_valid[i] <= 1'b0;
        shf_buf_bits[i] <= '0;
      end
    end else begin
      for (int lane = 0; lane < NrLanes; lane++) begin
        if (txs_valid_o[lane] && txs_ready_i[lane]) begin
          shf_buf_valid[lane] <= 1'b0;
        end
      end
      shf_buf_empty <= !(|shf_buf_valid);
    end
  end

  // ================= Assertions ================= //
  // Check that there is at least one valid shfInfo info when seqBuf is not empty
  assert property (@(posedge clk_i) 
    rx_seq_load_valid_i |-> !shf_info_buf_empty)
    else $error("[ShuffleUnit] There should be at least one valid shfInfo info in shfInfo Buffer when seqBuf is not Empty!");

  // Check vaddr_set bounds
  assert property (@(posedge clk_i) 
    txs_valid_o[0] |-> txs_o[0].vaddr_set < NrVRFSets)
    else $error("[ShuffleUnit] vaddr_set should < NrVRFSets = %d. However, got %d", NrVRFSets, txs_o[0].vaddr_set);

endmodule : ShuffleUnit 