// ============================================================================
// DeShuffleUnit.sv
// SystemVerilog implementation of DeShuffle Unit for VLSU
// 
// This module handles the deshuffle operation from shuffle buffer to sequential buffer
// using the query_shf_idx function from vlsu_shuffle_pkg.sv
// ============================================================================

module DeShuffleUnit import vlsu_pkg::*; import vlsu_shuffle_pkg::*; #(
  parameter  int  unsigned  NrLanes       = 0,
  parameter  int  unsigned  VLEN          = 0,
  parameter  int  unsigned  ALEN          = 0,
  parameter  int  unsigned  MaxLEN        = 0,
  parameter  type           meta_glb_t    = logic,
  parameter  type           seq_buf_t     = logic,
  parameter  type           rx_lane_t     = logic,
  parameter  type           shf_info_t    = logic,

  // Dependant parameters. DO NOT CHANGE!
  parameter  int  unsigned  laneIdBits    = $clog2(NrLanes),
  parameter  int  unsigned  nbIdxBits     = $clog2((riva_pkg::DLEN/4) * NrLanes),
  localparam type           strb_t        = logic [riva_pkg::DLEN/4-1:0]
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
  rx_lane_t [NrLanes-1:0] shf_buf;
  logic                   shf_buf_full;

  // ShfInfo buffer using CircularQueuePtrTemplate
  shf_info_t                        shf_info_buf [shfInfoBufDep-1:0];
  logic                             shf_info_enq_ptr_flag, shf_info_deq_ptr_flag;
  logic [$clog2(shfInfoBufDep)-1:0] shf_info_enq_ptr_value, shf_info_deq_ptr_value;
  logic                             shf_info_buf_empty, shf_info_buf_full;
  logic                             shf_info_buf_enq, shf_info_buf_deq;

  // Current shuffle info
  shf_info_t              shfInfo;

  // Control signals
  logic                   do_cmt_shf_to_seq;

  // Intermediate signals for meta info calculation
  shf_info_t              shf_info_enq_bits;

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
  // Shuffle Info initialization and enqueue Logic
  // -------------------------------------------
  always_comb begin: meta_info_calc
    // Default assignments
    shf_info_enq_bits = '0;
    shf_info_buf_enq = 1'b0;
    
    if (meta_info_valid_i && meta_info_ready_o) begin
      // Hardware signals
      automatic vaddr_t            vaddr_calc;
      automatic vaddr_set_t        vd_base_set;
      automatic riva_pkg::elen_t   start_elem_in_vd = meta_info_i.vstart >> $clog2(NrLanes);
      
      // Calculate vd_base_set based on vd register type
      vd_base_set = meta_info_i.vd[vlsu_pkg::vdMsb]
        ? (AregBaseSet + (meta_info_i.vd[vlsu_pkg::vdMsb-1:0] * NrSetPerAreg))
        : (meta_info_i.vd[vlsu_pkg::vdMsb-1:0] * NrSetPerVreg);
      
      // Calculate virtual address
      vaddr_calc     = vd_base_set + (start_elem_in_vd >> (3 - meta_info_i.sew));
      
      // Assign meta info to intermediate signal
      shf_info_enq_bits.reqId      = meta_info_i.reqId;
      shf_info_enq_bits.mode       = meta_info_i.mode;
      shf_info_enq_bits.sew        = meta_info_i.sew;
      shf_info_enq_bits.vd         = meta_info_i.vd;
      shf_info_enq_bits.vstart     = meta_info_i.vstart;
      shf_info_enq_bits.vm         = meta_info_i.vm;
      shf_info_enq_bits.cmtCnt     = meta_info_i.cmtCnt;
      shf_info_enq_bits.vaddr_set  = vaddr_calc[VAddrBits-1:VAddrBankBits];
      shf_info_enq_bits.vaddr_bank = vaddr_calc[VAddrBankBits-1:0];
      
      // Set enqueue signal
      shf_info_buf_enq = 1'b1;
    end
  end: meta_info_calc

  // -------------------------------------------
  // Buffer Control Logic
  // -------------------------------------------
  assign shf_info_buf_deq = do_cmt_shf_to_seq && (shfInfo.cmtCnt == 0);

  assign meta_info_ready_o = !shf_info_buf_full;

  // -------------------------------------------
  // rx lane -> shfBuf
  // -------------------------------------------
  always_comb begin: rx_lane_to_shfbuf_logic
    for (int lane = 0; lane < NrLanes; lane++) begin
      rxs_ready_o[lane] = !shf_buf_valid[lane];
    end
  end: rx_lane_to_shfbuf_logic

  assign shf_buf_full = &shf_buf_valid;
  
  // -------------------------------------------
  // shfBuf -> seqBuf
  // -------------------------------------------
  assign tx_seq_store_valid_o = shf_buf_full && !shf_info_buf_empty && (shfInfo.vm || |mask_valid_i);
  assign do_cmt_shf_to_seq = tx_seq_store_valid_o && tx_seq_store_ready_i;

  // ================= tx_seq_store Logic ================= //
  always_comb begin: shfbuf_to_seqbuf_logic
    // Default assignments
    tx_seq_store_o = '0;

    if (do_cmt_shf_to_seq) begin
      // Deshuffle data using query_shf_idx function
      for (int seq_idx = 0; seq_idx < NrLanes*riva_pkg::DLEN/4; seq_idx++) begin
        // Get shuffle index for this sequential index (purely software calculation)
        automatic int unsigned shf_idx = ControlMachinePkg::isCln2D(shfInfo.mode)
            ? query_shf_idx_2d_cln(NrLanes, seq_idx, shfInfo.sew)
            : query_shf_idx       (NrLanes, seq_idx, shfInfo.sew);
        automatic int unsigned lane    = shf_idx / (riva_pkg::DLEN/4);
        automatic int unsigned off     = shf_idx % (riva_pkg::DLEN/4);
        
        // Assign data and nbe
        tx_seq_store_o.nb[seq_idx*4 +: 4] = shf_buf[lane].data[off*4 +: 4];
        tx_seq_store_o.en[seq_idx]        = shfInfo.vm || mask_bits_i[lane][off];
      end
    end
  end: shfbuf_to_seqbuf_logic

  // -------------------------------------------
  // ShfInfo Buffer Logic + Shuffle Buffer UpdateLogic
  // -------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      shf_buf_valid <= '0;
    end 
    else begin
      // Enqueue meta info
      if (shf_info_buf_enq) begin
        shf_info_buf[shf_info_enq_ptr_value] <= shf_info_enq_bits;
      end

      // rx lane -> shfBuf
      for (int lane = 0; lane < NrLanes; lane++) begin
        if (rxs_valid_i[lane] && rxs_ready_o[lane]) begin
          shf_buf      [lane] <= rxs_i[lane];
          shf_buf_valid[lane] <= 1'b1;
        end
      end

      // shfBuf -> seqBuf
      if (do_cmt_shf_to_seq) begin
        // Clear shuffle buffer
        shf_buf_valid <= '0;

        // Update commit counter
        if (!(shfInfo.cmtCnt == 0)) begin
          shf_info_buf[shf_info_deq_ptr_value].cmtCnt <= shfInfo.cmtCnt - 1;
        end
      end
    end
  end

  // ================= Assertions ================= //

endmodule : DeShuffleUnit 