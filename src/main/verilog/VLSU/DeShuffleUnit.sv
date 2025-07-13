// ============================================================================
// DeShuffleUnit.sv
// SystemVerilog implementation of DeShuffle Unit for VLSU
// 
// This module handles the deshuffle operation from shuffle buffer to sequential buffer
// using the query_shf_idx function from vlsu_shuffle_pkg.sv
// ============================================================================

module DeShuffleUnit import vlsu_pkg::*; #(
  parameter  int  unsigned  NrLanes       = 0,
  parameter  int  unsigned  VLEN          = 0,
  parameter  int  unsigned  ALEN          = 0,
  parameter  type           meta_glb_t    = logic,
  parameter  type           seq_buf_t     = logic,
  parameter  type           rx_lane_t     = logic,
  parameter  type           shf_info_t    = logic,

  // Dependant parameters. DO NOT CHANGE!
  parameter  int  unsigned  laneIdBits    = $clog2(NrLanes),
  parameter  int  unsigned  nbIdxBits     = $clog2((DLEN/4) * NrLanes),
  localparam type           strb_t        = logic [DLEN/4-1:0]
) (
  input  logic                       clk_i,
  input  logic                       rst_ni,
  
  // Input from Lane Exits
  input  logic      [NrLanes-1:0]    rxs_valid_i,
  output logic      [NrLanes-1:0]    rxs_ready_o,
  input  rx_lane_t  [NrLanes-1:0]    rxs_i,
  
  // Output to SequentialStore
  output logic                       tx_seq_store_valid_o,
  input  logic                       tx_seq_store_ready_i,
  output seq_buf_t                   tx_seq_store_o,
  
  // Meta Control Interface
  input  logic                       meta_info_valid_i,
  output logic                       meta_info_ready_o,
  input  meta_glb_t                  meta_info_i,
  
  // Mask from mask unit
  input  logic      [NrLanes-1:0]    mask_valid_i,
  input  strb_t     [NrLanes-1:0]    mask_bits_i,
  output logic                       mask_ready_o
);

  // ================= Internal Signals ================= //
  // Shuffle buffer to store data from lanes (using registers like Chisel)
  logic     [NrLanes-1:0] shf_buf_valid;
  rx_lane_t [NrLanes-1:0] shf_buf_bits;
  logic                   shf_buf_full;

  // ShfInfo buffer using CircularQueuePtrTemplate
  shf_info_t              shf_info_buf [shfInfoBufDep-1:0];
  logic                   shf_info_enq_ptr_flag, shf_info_deq_ptr_flag;
  logic [$clog2(shfInfoBufDep)-1:0] shf_info_enq_ptr_value, shf_info_deq_ptr_value;
  logic                   shf_info_buf_enq, shf_info_buf_deq;
  logic                   shf_info_buf_empty, shf_info_buf_full;

  // Current shuffle info
  shf_info_t              shfInfo;

  // Control signals
  logic                   do_cmt_shf_to_seq;

  // ================= Circular Queue Pointer Instantiations ================= //
  CircularQueuePtrTemplate #(
    .ENTRIES(shfInfoBufDep)
  ) i_shf_info_enq_ptr (
    .clk_i      (clk_i                   ),
    .rst_ni     (rst_ni                  ),
    .ptr_inc_i  (shf_info_buf_enq        ),
    .ptr_flag_o (shf_info_enq_ptr_flag   ),
    .ptr_value_o(shf_info_enq_ptr_value  )
  );

  CircularQueuePtrTemplate #(
    .ENTRIES(shfInfoBufDep)
  ) i_shf_info_deq_ptr (
    .clk_i      (clk_i                   ),
    .rst_ni     (rst_ni                  ),
    .ptr_inc_i  (shf_info_buf_deq        ),
    .ptr_flag_o (shf_info_deq_ptr_flag   ),
    .ptr_value_o(shf_info_deq_ptr_value  )
  );

  // ================= Buffer Logic ================= //
  assign shf_info_buf_empty = (shf_info_enq_ptr_value == shf_info_deq_ptr_value) && 
                              (shf_info_enq_ptr_flag == shf_info_deq_ptr_flag);
  assign shf_info_buf_full  = (shf_info_enq_ptr_value == shf_info_deq_ptr_value) && 
                              (shf_info_enq_ptr_flag != shf_info_deq_ptr_flag);

  // Get current shuffle info
  assign shfInfo = shf_info_buf[shf_info_deq_ptr_value];

  // ================= Default Output Assignments ================= //
  assign mask_ready_o = do_cmt_shf_to_seq && !shfInfo.vm;

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
        
        // Calculate vd_base_set based on vd register type
        vd_base_set = meta_info_i.vd[vd_msb]
          ? (AregBaseSet + (meta_info_i.vd[vd_msb-1:0] * NrSetPerAreg))
          : (meta_info_i.vd[vd_msb-1:0] * NrSetPerVreg);
        
        // Calculate start element index in vd
        start_elem_in_vd = meta_info_i.vstart >> $clog2(NrLanes);
        
        // Calculate virtual address
        vaddr_calc     = vd_base_set + (start_elem_in_vd >> (3 - meta_info_i.sew));
        
        // Store meta info in shf_info_buf
        shf_info_buf[shf_info_enq_ptr_value].req_id    <= meta_info_i.req_id;
        shf_info_buf[shf_info_enq_ptr_value].mode      <= meta_info_i.mode;
        shf_info_buf[shf_info_enq_ptr_value].eew       <= meta_info_i.sew;
        shf_info_buf[shf_info_enq_ptr_value].vd        <= meta_info_i.vd;
        shf_info_buf[shf_info_enq_ptr_value].vstart    <= meta_info_i.vstart;
        shf_info_buf[shf_info_enq_ptr_value].vm        <= meta_info_i.vm;
        shf_info_buf[shf_info_enq_ptr_value].cmt_cnt   <= meta_info_i.cmt_cnt;
        shf_info_buf[shf_info_enq_ptr_value].vaddr_set <= vaddr_calc[VAddrBits-1:VAddrOffBits];
        shf_info_buf[shf_info_enq_ptr_value].vaddr_off <= vaddr_calc[VAddrOffBits-1:0];
        shf_info_buf_enq <= 1'b1;
      end

      // Dequeue meta info when commit is done
      if (do_cmt_shf_to_seq && !shfInfo.cmt_cnt.orR) begin
        shf_info_buf_deq <= 1'b1;
      end
    end
  end

  assign meta_info_ready_o = !shf_info_buf_full;

  // -------------------------------------------
  // rx lane -> shfBuf
  // -------------------------------------------
  always_comb begin
    for (int lane = 0; lane < NrLanes; lane++) begin
      rxs_ready_o[lane] = !shf_buf_valid[lane];
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (int i = 0; i < NrLanes; i++) begin
        shf_buf_valid[i] <= 1'b0;
        shf_buf_bits[i] <= '0;
      end
    end else begin
      for (int lane = 0; lane < NrLanes; lane++) begin
        if (rxs_valid_i[lane] && rxs_ready_o[lane]) begin
          shf_buf_bits[lane] <= rxs_i[lane];
          shf_buf_valid[lane] <= 1'b1;
        end
      end
    end
  end

  assign shf_buf_full = &shf_buf_valid;
  
  // -------------------------------------------
  // shfBuf -> seqBuf
  // -------------------------------------------
  assign tx_seq_store_valid_o = shf_buf_full && !shf_info_buf_empty && (shfInfo.vm || |mask_valid_i);
  assign do_cmt_shf_to_seq = tx_seq_store_valid_o && tx_seq_store_ready_i;

  // ================= tx_seq_store Logic ================= //
  always_comb begin
    // Default assignments
    tx_seq_store_o = '0;

    if (do_cmt_shf_to_seq) begin
      // Deshuffle data using query_shf_idx function
      for (int seq_idx = 0; seq_idx < NrLanes*DLEN/4; seq_idx++) begin
        // Get shuffle index for this sequential index (purely software calculation)
        automatic int unsigned shf_idx = ControlMachinePkg::isCln2D(shfInfo.mode)
            ? query_shf_idx_2d_cln(NrLanes, seq_idx, shfInfo.eew)
            : query_shf_idx       (NrLanes, seq_idx, shfInfo.eew);
        automatic int unsigned lane    = shf_idx / NrLanes;
        automatic int unsigned off     = shf_idx % NrLanes;
        
        // Assign data and nbe
        tx_seq_store_o.nb[seq_idx] = shf_buf_bits[lane].data[off*4+3:off*4];
        tx_seq_store_o.en[seq_idx] = shfInfo.vm || mask_bits_i[lane][off];
      end
    end
  end

  // Deshuffle and commit data from shfBuf to seqBuf
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      // Reset
    end else if (do_cmt_shf_to_seq) begin
      // Clear shuffle buffer
      for (int i = 0; i < NrLanes; i++) begin
        shf_buf_valid[i] <= 1'b0;
      end

      // Update commit counter
      if (!shfInfo.cmt_cnt.orR) begin
        // Final transaction, dequeue meta
        shf_info_buf_deq <= 1'b1;
      end else begin
        shfInfo.cmt_cnt <= shfInfo.cmt_cnt - 1;
      end
    end
  end

  // ================= Assertions ================= //
  // Check that there is at least one valid meta info when shfBuf is full
  assert property (@(posedge clk_i) 
    shf_buf_full |-> !shf_info_buf_empty)
    else $error("[DeShuffleUnit] There should be at least one valid meta info in meta Buffer when shfBuf is full!");

endmodule : DeShuffleUnit 