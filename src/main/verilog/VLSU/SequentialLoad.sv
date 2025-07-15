// ============================================================================
// SequentialLoad.sv
// Sequential Load Data Controller
// ============================================================================

`timescale 1ns/1ps

module SequentialLoad import vlsu_pkg::*; import axi_pkg::*; #(
  parameter  int   unsigned  NrLanes          = 0,
  parameter  int   unsigned  AxiDataWidth     = 0,
  parameter  int   unsigned  AxiAddrWidth     = 0,
  
  parameter  type            axi_r_t          = logic,
  parameter  type            txn_ctrl_t       = logic,
  parameter  type            meta_glb_t       = logic,
  parameter  type            seq_info_t       = logic,
  parameter  type            seq_buf_t        = logic,

  // Dependant parameters. DO NOT CHANGE!
  localparam int   unsigned  NrLaneEntriesNbs = (riva_pkg::DLEN / 4) * NrLanes,
  localparam int   unsigned  busNibbles       = AxiDataWidth / 4,
  localparam int   unsigned  busNSize         = $clog2(busNibbles)
) (
  input  logic          clk_i,
  input  logic          rst_ni,
  
  // AXI R Channel Input
  input  logic          axi_r_valid_i,
  output logic          axi_r_ready_o,
  input  axi_r_t        axi_r_i,
  
  // Transaction Control Interface
  input  logic          txn_ctrl_valid_i,
  output logic          txn_ctrl_ready_o,
  input  txn_ctrl_t     txn_ctrl_i,
  
  // Meta Control Interface
  input  logic          meta_glb_valid_i,
  output logic          meta_glb_ready_o,
  input  meta_glb_t     meta_glb_i,
  
  // Output to ShuffleUnit
  output logic          tx_shfu_valid_o,
  input  logic          tx_shfu_ready_i,
  output seq_buf_t      tx_shfu_o
);

  // ================= Helper Functions ================= //
  function automatic logic isFinalBeat(input txn_ctrl_t txn_ctrl);
    return txn_ctrl.isFinalTxn && (txn_ctrl.rmnBeat == 0);
  endfunction

  

  // ================= Internal Signals ================= //
  // FSM states
  typedef enum logic [1:0] {
    S_IDLE,
    S_SERIAL_CMT,
    S_GATHER_CMT
  } state_e;
  
  state_e state_r, state_nxt;
  
  // Sequential buffer (ping-pong)
  seq_buf_t   seq_buf     [1:0];
  seq_buf_t   seq_buf_nxt [1:0];
  logic       seq_buf_empty, seq_buf_full;
  // Circular queue pointers for seq_buf
  logic       seq_enq_ptr_flag, seq_deq_ptr_flag;
  logic [0:0] seq_enq_ptr_value, seq_deq_ptr_value;
  logic       seq_buf_enq, seq_buf_deq;

  CircularQueuePtrTemplate #(
    .ENTRIES(2)
  ) i_seq_enq_ptr (
    .clk_i      (clk_i            ),
    .rst_ni     (rst_ni           ),
    .ptr_inc_i  (seq_buf_enq      ),
    .ptr_flag_o (seq_enq_ptr_flag ),
    .ptr_value_o(seq_enq_ptr_value)
  );

  CircularQueuePtrTemplate #(
    .ENTRIES(2)
  ) i_seq_deq_ptr (
    .clk_i      (clk_i            ),
    .rst_ni     (rst_ni           ),
    .ptr_inc_i  (seq_buf_deq      ),
    .ptr_flag_o (seq_deq_ptr_flag ),
    .ptr_value_o(seq_deq_ptr_value)
  );
  
  // Bus nibble counter
  logic [busNSize-2:0] bus_nb_cnt_r, bus_nb_cnt_nxt;
  
  // Sequential buffer nibble pointer
  logic [$clog2(NrLaneEntriesNbs)-1:0] seq_nb_ptr_r, seq_nb_ptr_nxt;
  
  // seq_info queue (use Queue module instead of reg)
  logic      seq_info_enq_valid, seq_info_enq_ready;
  seq_info_t seq_info_enq_bits;
  logic      seq_info_deq_valid, seq_info_deq_ready;
  seq_info_t seq_info_deq_bits;

  QueueFlow #(
    .T     (seq_info_t),
    .DEPTH (1)
  ) u_seq_info_queue (
    .clk_i         (clk_i             ),
    .rst_ni        (rst_ni            ),
    .enq_valid_i   (seq_info_enq_valid),
    .enq_ready_o   (seq_info_enq_ready),
    .enq_bits_i    (seq_info_enq_bits ),
    .deq_valid_o   (seq_info_deq_valid),
    .deq_ready_i   (seq_info_deq_ready),
    .deq_bits_o    (seq_info_deq_bits )
  );
  
  // Intermediate variables for S_SERIAL_CMT state
  logic [busNSize-1                              : 0] lower_nibble;
  logic [busNSize                                : 0] upper_nibble;
  logic [busNSize                                : 0] bus_valid_nb;
  logic [$clog2(NrLaneEntriesNbs)                : 0] seq_buf_valid_nb;

  // Use localparam for min(busNSize, $clog2(NrLaneEntriesNbs)) to ensure integral type
  localparam int unsigned nrNbsCmtBits = (busNSize < $clog2(NrLaneEntriesNbs)) ? busNSize + 1 : $clog2(NrLaneEntriesNbs) + 1;
  logic [nrNbsCmtBits                            : 0] nr_nbs_committed;
  logic [busNSize-1                              : 0] start;
  logic                                               do_serial_cmt;

  wire [$clog2(NrLaneEntriesNbs)-1:0] lower_bound = seq_nb_ptr_r;
  wire [$clog2(NrLaneEntriesNbs)  :0] upper_bound = seq_nb_ptr_r + nr_nbs_committed;
  
  // ================= FSM State Transition Logic ================= //
  always_comb begin: fsm_state_transition
    state_nxt = state_r;
    
    case (state_r)
      S_IDLE: begin
        if (txn_ctrl_valid_i) begin
          state_nxt = S_SERIAL_CMT;
        end
      end
      S_SERIAL_CMT: begin
        if (isFinalBeat(txn_ctrl_i) && txn_ctrl_ready_o) begin
          state_nxt = S_IDLE;
        end
      end
      S_GATHER_CMT: begin
        if (isFinalBeat(txn_ctrl_i) && txn_ctrl_ready_o) begin
          state_nxt = S_IDLE;
        end
      end
      default: begin
        state_nxt = S_IDLE;
      end
    endcase
  end: fsm_state_transition
  
  // ================= Sequential Buffer Logic ================= //
  assign seq_buf_empty = (seq_enq_ptr_value == seq_deq_ptr_value) && (seq_enq_ptr_flag == seq_deq_ptr_flag);
  assign seq_buf_full  = (seq_enq_ptr_value == seq_deq_ptr_value) && (seq_enq_ptr_flag != seq_deq_ptr_flag);
  
  // ================= AXI R Channel -> seqBuf Logic ================= //
  always_comb begin: axi_r_to_seqbuf_logic
    // Default assignments
    bus_nb_cnt_nxt      = bus_nb_cnt_r;
    seq_nb_ptr_nxt      = seq_nb_ptr_r;
    axi_r_ready_o       = 1'b0;
    txn_ctrl_ready_o    = 1'b0;
    seq_buf_enq         = 1'b0;
    seq_info_enq_bits   = '0;
    seq_info_enq_valid  = meta_glb_valid_i;
    seq_info_deq_ready  = 1'b0;
    // Default assignments for intermediate variables
    lower_nibble        = '0;
    upper_nibble        = '0;
    bus_valid_nb        = '0;
    seq_buf_valid_nb    = '0;
    nr_nbs_committed    = '0;
    start               = '0;
    do_serial_cmt       = 1'b0;
    seq_buf_nxt         = seq_buf;
    
    case (state_r)
      S_IDLE: begin
        // Initialize pointers and vaddr
        if (txn_ctrl_valid_i) begin
          bus_nb_cnt_nxt      = '0;
          seq_nb_ptr_nxt      = seq_info_deq_bits.seqNbPtr;
          seq_info_deq_ready  = 1'b1;
        end
      end
      S_SERIAL_CMT: begin
        // Calculate lower and upper nibble boundaries
        lower_nibble = txn_ctrl_i.isHead       ? txn_ctrl_i.addr[busNSize-1:0] : '0        ;
        upper_nibble = txn_ctrl_i.rmnBeat == 0 ? txn_ctrl_i.lbN                : busNibbles;
        
        // Commit when:
        // 1. There are valid data on the R Bus;
        // 2. Target seqBuf is not full;
        // 3. TxnInfo is valid
        do_serial_cmt = axi_r_valid_i && !seq_buf_full && txn_ctrl_valid_i;
        
        if (do_serial_cmt) begin
          bus_valid_nb     = upper_nibble - lower_nibble - bus_nb_cnt_r;
          seq_buf_valid_nb = NrLaneEntriesNbs - seq_nb_ptr_r;
          
          if (bus_valid_nb > seq_buf_valid_nb) begin
            // The amount of valid data on the bus is greater than the amount of free space available in seqBuf
            nr_nbs_committed = seq_buf_valid_nb;
            bus_nb_cnt_nxt   = bus_nb_cnt_r + nr_nbs_committed;
            seq_nb_ptr_nxt   = '0;
            seq_buf_enq      = 1'b1;
          end 
          else begin
            // seqBuf still has enough space for the next r beat
            nr_nbs_committed = bus_valid_nb;
            bus_nb_cnt_nxt   = '0;
            seq_nb_ptr_nxt   = seq_nb_ptr_r + nr_nbs_committed;
            axi_r_ready_o    = 1'b1;
            txn_ctrl_ready_o = 1'b1;
            
            // Still need to do enq for the seqBuf if bus_valid_nb = seq_buf_valid_nb
            if (bus_valid_nb == seq_buf_valid_nb) begin
              seq_buf_enq    = 1'b1;
              seq_nb_ptr_nxt = '0;
            end
            
            // Haven't occupied all valid nbs in the seqBuf,
            // but the current beat is already the final beat of the whole riva request
            if (isFinalBeat(txn_ctrl_i)) begin
              seq_buf_enq    = 1'b1;
              seq_nb_ptr_nxt = '0;
            end
          end
          
          // TODO: Maybe there is a better way.
          start = lower_nibble + bus_nb_cnt_r;
          
          // Commit data from R bus to seqBuf
          for (int unsigned i = 0; i < NrLaneEntriesNbs; i++) begin
            if ((i >= seq_nb_ptr_r) && (i < (seq_nb_ptr_r + nr_nbs_committed))) begin
              automatic int unsigned idx = i - seq_nb_ptr_r + start;
              seq_buf_nxt[seq_enq_ptr_value].nb[i*4 +: 4] = axi_r_i.data[idx*4 +: 4];
              seq_buf_nxt[seq_enq_ptr_value].en[i] = 1'b1;
            end
          end
        end

        if (tx_shfu_valid_o && tx_shfu_ready_i) begin
          seq_buf_nxt[seq_deq_ptr_value] = '0;
        end
      end
      S_GATHER_CMT: begin
        // Not supported yet
        $fatal("Gather mode not supported!");
      end
    endcase
  end: axi_r_to_seqbuf_logic
  
  // ================= seqBuf -> ShuffleUnit Logic ================= //
  assign tx_shfu_valid_o = !seq_buf_empty;
  assign tx_shfu_o       = seq_buf[seq_deq_ptr_value];

  assign seq_buf_deq = tx_shfu_valid_o && tx_shfu_ready_i;
  
  // ================= Meta Control Interface Logic ================= //
  assign meta_glb_ready_o = seq_info_enq_ready;
  
  // ================= Sequential Logic ================= //
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_r      <= S_IDLE;
      bus_nb_cnt_r <= '0;
      seq_nb_ptr_r <= '0;
      for (int i = 0; i < 2; i++) begin
        seq_buf[i] <= '0;
      end
    end else begin
      state_r      <= state_nxt;
      bus_nb_cnt_r <= bus_nb_cnt_nxt;
      seq_nb_ptr_r <= seq_nb_ptr_nxt;
      seq_buf     <= seq_buf_nxt;
    end
  end

  // ================= Assertions ================= //
  assert property (@(posedge clk_i) upper_nibble <= busNibbles)
    else $fatal("upper_nibble exceeds busNibbles: %0d > %0d", upper_nibble, busNibbles);
  assert property (@(posedge clk_i) bus_valid_nb <= busNibbles)
    else $fatal("bus_valid_nb exceeds busNibbles: %0d > %0d", bus_valid_nb, busNibbles);
  assert property (@(posedge clk_i) seq_buf_valid_nb <= NrLaneEntriesNbs)
    else $fatal("seq_buf_valid_nb exceeds NrLaneEntriesNbs: %0d > %0d", seq_buf_valid_nb, NrLaneEntriesNbs);

endmodule : SequentialLoad 