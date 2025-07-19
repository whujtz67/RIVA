// ============================================================================
// MShuffleUnit.sv
// Matrix Shuffle Unit - Handles matrix shuffle operations
// ============================================================================

module MShuffleUnit import riva_pkg::*; import vlsu_pkg::*; #(
  parameter  int  unsigned  NrExits       = 0,
  parameter  int  unsigned  VLEN          = 0,
  parameter  int  unsigned  MLEN          = 0,
  parameter  type           meta_glb_t    = logic,
  parameter  type           seq_buf_t     = logic,
  parameter  type           tx_lane_t     = logic,
  parameter  type           shf_info_t    = logic,
  parameter  type           pe_resp_t     = logic,
  
  // Dependant parameters. DO NOT CHANGE!
  localparam int  unsigned  laneIdBits       = $clog2(NrExits),
  localparam int  unsigned  nbIdxBits        = $clog2((riva_pkg::DLEN/4) * NrExits),
  localparam type           strb_t           = logic [riva_pkg::DLEN/4-1:0]
) (
  input  logic                       clk_i,
  input  logic                       rst_ni,
  
  // Input from SequentialLoad
  input  logic                       rx_seq_load_valid_i,
  output logic                       rx_seq_load_ready_o,
  input  seq_buf_t                   rx_seq_load_i,
  
  // Output to Lane Entries
  output logic      [NrExits-1:0]    txs_valid_o,
  input  logic      [NrExits-1:0]    txs_ready_i,
  output tx_lane_t  [NrExits-1:0]    txs_o,
  
  // Meta Control Interface
  input  logic                       meta_info_valid_i,
  output logic                       meta_info_ready_o,
  input  meta_glb_t                  meta_info_i,
  
  // Mask from mask unit
  input  logic      [NrExits-1:0]    mask_valid_i,
  input  strb_t     [NrExits-1:0]    mask_bits_i,
  output logic                       mask_ready_o,

  // pe resp load
  output pe_resp_t              pe_resp_load_o
);

  // ================= Internal Signals ================= //
  // Shuffle buffer using registers (like Chisel implementation)
  logic     [NrExits-1:0] shf_buf_valid, shf_buf_valid_nxt;
  tx_lane_t [NrExits-1:0] shf_buf, shf_buf_nxt;
  wire                    shf_buf_empty = !(|shf_buf_valid);

  // ShfInfo buffer using CircularQueuePtrTemplate
  shf_info_t                        shf_info_buf [shfInfoBufDep-1:0];
  logic                             shf_info_enq_ptr_flag , shf_info_deq_ptr_flag ;
  logic [$clog2(shfInfoBufDep)-1:0] shf_info_enq_ptr_value, shf_info_deq_ptr_value;
  logic                             shf_info_buf_empty, shf_info_buf_full;
  logic                             shf_info_buf_enq, shf_info_buf_deq;

  // Current shuffle info
  shf_info_t              shfInfo;

  // Control signals
  logic                   do_cmt_seq_to_shf;

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
                              (shf_info_enq_ptr_flag  == shf_info_deq_ptr_flag );
  assign shf_info_buf_full  = (shf_info_enq_ptr_value == shf_info_deq_ptr_value) && 
                              (shf_info_enq_ptr_flag  != shf_info_deq_ptr_flag );

  // Get current shuffle info
  assign shfInfo = shf_info_buf[shf_info_deq_ptr_value];

  // -------------------------------------------
  // Shuffle Info initialization and enqueue Logic
  // -------------------------------------------
  always_comb begin: meta_info_calc
    // Default assignments
    shf_info_enq_bits = '0;
    shf_info_buf_enq = 1'b0;
    
    if (meta_info_valid_i && meta_info_ready_o) begin
      // Hardware signals
      automatic maddr_t            maddr_calc;
      
      // Calculate matrix address
      maddr_calc     = meta_info_i.md * NrSetPerMreg;
      
      // Assign meta info to intermediate signal
      shf_info_enq_bits.reqId      = meta_info_i.reqId;
      shf_info_enq_bits.mode       = meta_info_i.mode;
      shf_info_enq_bits.sew        = meta_info_i.sew;
      shf_info_enq_bits.md         = meta_info_i.md;
      shf_info_enq_bits.vstart     = meta_info_i.vstart;
      shf_info_enq_bits.vm         = meta_info_i.vm;
      shf_info_enq_bits.cmtCnt     = meta_info_i.cmtCnt;
      shf_info_enq_bits.maddr_set  = maddr_calc[MAddrBits-1:MAddrBankBits];
      shf_info_enq_bits.maddr_bank = maddr_calc[MAddrBankBits-1:0];
      
      // Set enqueue signal
      shf_info_buf_enq = 1'b1;
    end
  end: meta_info_calc

  // -------------------------------------------
  // Buffer Control Logic
  // -------------------------------------------
  assign shf_info_buf_deq = do_cmt_seq_to_shf && (shfInfo.cmtCnt == 0);
  assign meta_info_ready_o = !shf_info_buf_full;

  // -------------------------------------------
  // seqBuf -> shfBuf
  // -------------------------------------------
  assign rx_seq_load_ready_o = shf_buf_empty && !shf_info_buf_empty && (shfInfo.vm || |mask_valid_i);
  assign do_cmt_seq_to_shf   = rx_seq_load_valid_i && rx_seq_load_ready_o;

  // -------------------------------------------
  // Shuffle Logic
  // -------------------------------------------
  always_comb begin: shuffle_calc
    // Default assignments
    shf_buf_valid_nxt = shf_buf_valid;
    shf_buf_nxt  = shf_buf;
    
    if (do_cmt_seq_to_shf) begin
      // Shuffle data using query_seq_idx function
      for (int lane = 0; lane < NrExits; lane++) begin
        for (int off = 0; off < riva_pkg::DLEN/4; off++) begin
          automatic int unsigned shf_idx = lane * (riva_pkg::DLEN/4) + off;
          // Get sequential index for this lane/offset combination
          automatic int unsigned seq_idx = query_seq_idx_2d_cln(NrExits, shf_idx, shfInfo.sew); // NOTE: always use query_seq_idx_2d_cln.
          
          // Assign data and nbe
          shf_buf_nxt[lane].data[off*4 +: 4] = rx_seq_load_i.nb[seq_idx*4 +: 4];
          shf_buf_nxt[lane].nbe [off]        = rx_seq_load_i.en[seq_idx] && (shfInfo.vm || mask_bits_i[lane][off]);
        end
      end

      // Make all shuffle buffer valid
      for (int i = 0; i < NrExits; i++) begin
        shf_buf_valid_nxt[i]       = 1'b1;
        shf_buf_nxt [i].reqId      = shfInfo.reqId;
        shf_buf_nxt [i].maddr_set  = shfInfo.maddr_set;
        shf_buf_nxt [i].maddr_bank = shfInfo.maddr_bank;
      end
    end
  end: shuffle_calc

  // -------------------------------------------
  // Shuffle Info Buffer and Shuffle Buffer Update Logic
  // -------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (int i = 0; i < NrExits; i++) begin
        shf_buf_valid[i] <= 1'b0;
      end
    end
    else begin
      if (shf_info_buf_enq) begin
        // Enqueue meta info
        shf_info_buf[shf_info_enq_ptr_value] <= shf_info_enq_bits;
      end

      if (do_cmt_seq_to_shf) begin
        // Update shuffle buffer
        shf_buf_valid <= shf_buf_valid_nxt;
        shf_buf  <= shf_buf_nxt;

        // Update maddr
        shf_info_buf[shf_info_deq_ptr_value].maddr_set <= shfInfo.maddr_set + 1;

        // Update commit counter
        if (!(shfInfo.cmtCnt == 0)) begin
          shf_info_buf[shf_info_deq_ptr_value].cmtCnt <= shfInfo.cmtCnt - 1;
        end
      end

      // Clear shuffle buffer when transaction is accepted
      for (int unsigned lane = 0; lane < NrExits; lane++) begin
        if (txs_valid_o[lane] && txs_ready_i[lane]) begin
          shf_buf_valid[lane] <= 1'b0;
        end
      end
    end
  end

  assign mask_ready_o = do_cmt_seq_to_shf && !shfInfo.vm;

  // -------------------------------------------
  // shfBuf -> lane
  // -------------------------------------------
  always_comb begin: shfbuf_to_lane_logic
    for (int lane = 0; lane < NrExits; lane++) begin
      txs_valid_o[lane] = shf_buf_valid[lane];
      txs_o      [lane] = shf_buf[lane];
    end
  end: shfbuf_to_lane_logic

  // -------------------------------------------
  // pe resp load
  // -------------------------------------------
  always_comb begin: pe_resp_load_logic
    pe_resp_load_o = '0;
    if (shf_info_buf_deq) begin
      pe_resp_load_o.vinsn_done[shfInfo.reqId] = 1'b1;
    end
  end: pe_resp_load_logic

  // ================= Assertions ================= //
  // Check that there is at least one valid shfInfo info when seqBuf is not empty
  assert property (@(posedge clk_i) 
    rx_seq_load_valid_i |-> !shf_info_buf_empty)
    else $error("[ShuffleUnit] There should be at least one valid shfInfo info in shfInfo Buffer when seqBuf is not Empty!");

  // Check vaddr_set bounds
  assert property (@(posedge clk_i) 
    txs_valid_o[0] |-> txs_o[0].vaddr_set < NrVRFSets)
    else $error("[ShuffleUnit] vaddr_set should < NrVRFSets = %d. However, got %d", NrVRFSets, txs_o[0].vaddr_set);

endmodule : MShuffleUnit 