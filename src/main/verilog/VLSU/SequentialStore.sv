// ============================================================================
// SequentialStore.sv
// Sequential Store Data Controller
// ============================================================================

`timescale 1ns/1ps

module SequentialStore import vlsu_pkg::*; import axi_pkg::*; #(
  parameter  int   unsigned  NrLanes          = 0,
  parameter  int   unsigned  AxiDataWidth     = 0,
  parameter  int   unsigned  AxiAddrWidth     = 0,
  parameter  int   unsigned  AxiUserWidth     = 1, // TODO: pass from top level

  parameter  type            axi_w_t          = logic,
  parameter  type            txn_ctrl_t       = logic,
  parameter  type            meta_glb_t       = logic,
  parameter  type            seq_info_t       = logic,
  parameter  type            seq_buf_t        = logic,

  // Dependant parameters. DO NOT CHANGE!
  localparam int   unsigned  NrLaneEntriesNbs = (DLEN / 4) * NrLanes,
  localparam int   unsigned  busNibbles       = AxiDataWidth / 4,
  localparam int   unsigned  busNSize         = $clog2(busNibbles)
) (
  input  logic          clk_i,
  input  logic          rst_ni,

  // Input from DeShuffleUnit
  input  logic          rx_deshfu_valid_i,
  output logic          rx_deshfu_ready_o,
  input  seq_buf_t      rx_deshfu_i,

  // AXI W Channel Output
  output logic          axi_w_valid_o,
  input  logic          axi_w_ready_i,
  output axi_w_t        axi_w_o,

  // Transaction Control Interface
  input  logic          txn_ctrl_valid_i,
  output logic          txn_ctrl_ready_o,
  input  txn_ctrl_t     txn_ctrl_i,

  // Meta Control Interface
  input  logic          meta_glb_valid_i,
  output logic          meta_glb_ready_o,
  input  meta_glb_t     meta_glb_i
);
  // Write buffer
  typedef struct packed {
    logic [busNibbles-1:0][3:0] nbs;    // nibbles
    logic [busNibbles-1:0]      nbes;   // nibble enables
    logic                       last;
    logic [AxiUserWidth-1:0]    user;
  } w_buf_t;

  // ================= Internal Signals ================= //
  // FSM states
  typedef enum logic [1:0] {
    S_IDLE,
    S_SERIAL_CMT,
    S_GATHER_CMT
  } state_e;

  state_e state_r, state_nxt;

  // Sequential buffer (ping-pong)
  seq_buf_t   seq_buf [1:0];
  logic       seq_buf_empty, seq_buf_full;
  // Circular queue pointers for seq_buf
  logic       seq_enq_ptr_flag, seq_deq_ptr_flag;
  logic       seq_enq_ptr_value, seq_deq_ptr_value;
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

  

  w_buf_t w_buf [wBufDep-1:0];
  logic w_buf_full, w_buf_empty;
  // Circular queue pointers for w_buf
  logic w_enq_ptr_flag, w_deq_ptr_flag;
  logic [$clog2(wBufDep)-1:0] w_enq_ptr_value, w_deq_ptr_value;
  logic w_buf_enq, w_buf_deq;

  CircularQueuePtrTemplate #(
    .ENTRIES(wBufDep)
  ) i_w_enq_ptr (
    .clk_i      (clk_i            ),
    .rst_ni     (rst_ni           ),
    .ptr_inc_i  (w_buf_enq        ),
    .ptr_flag_o (w_enq_ptr_flag   ),
    .ptr_value_o(w_enq_ptr_value  )
  );

  CircularQueuePtrTemplate #(
    .ENTRIES(wBufDep)
  ) i_w_deq_ptr (
    .clk_i      (clk_i            ),
    .rst_ni     (rst_ni           ),
    .ptr_inc_i  (w_buf_deq        ),
    .ptr_flag_o (w_deq_ptr_flag   ),
    .ptr_value_o(w_deq_ptr_value  )
  );

  // Bus nibble counter
  logic [busNSize-1:0] bus_nb_cnt_r, bus_nb_cnt_nxt;

  // Sequential buffer nibble pointer
  logic [$clog2(NrLaneEntriesNbs)-1:0] seq_nb_ptr_r, seq_nb_ptr_nxt;

  // seq_info queue (use Queue module instead of reg)
  logic      seq_info_enq_valid, seq_info_enq_ready;
  seq_info_t seq_info_enq_bits;
  logic      seq_info_deq_valid, seq_info_deq_ready;
  seq_info_t seq_info_deq_bits;

  Queue #(
    .T     (seq_info_t),
    .DEPTH (1),
    .FLOW  (1)
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
  logic [$min(busNSize, $clog2(NrLaneEntriesNbs)): 0] nr_nbs_committed;
  logic [busNSize-1                              : 0] start;

  // ================= FSM State Transition Logic ================= //
  always_comb begin
    state_nxt = state_r;

    case (state_r)
      S_IDLE: begin
        if (txn_ctrl_valid_i) begin
          state_nxt = S_SERIAL_CMT;
        end
      end
      S_SERIAL_CMT: begin
        if (txn_ctrl_i.isFinalBeat && txn_ctrl_ready_o) begin
          state_nxt = S_IDLE;
        end
      end
      S_GATHER_CMT: begin
        if (txn_ctrl_i.isFinalBeat && txn_ctrl_ready_o) begin
          state_nxt = S_IDLE;
        end
      end
      default: begin
        state_nxt = S_IDLE;
      end
    endcase
  end

  // ================= Buffer Logic ================= //
  assign seq_buf_empty = (seq_enq_ptr_value == seq_deq_ptr_value) && (seq_enq_ptr_flag == seq_deq_ptr_flag);
  assign seq_buf_full  = (seq_enq_ptr_value == seq_deq_ptr_value) && (seq_enq_ptr_flag != seq_deq_ptr_flag);
  assign w_buf_empty   = (w_enq_ptr_value == w_deq_ptr_value) && (w_enq_ptr_flag == w_deq_ptr_flag);
  assign w_buf_full    = (w_enq_ptr_value == w_deq_ptr_value) && (w_enq_ptr_flag != w_deq_ptr_flag);

  // ================= seqBuf -> wBuf Logic ================= //
  always_comb begin
    // Default assignments
    bus_nb_cnt_nxt      = bus_nb_cnt_r;
    seq_nb_ptr_nxt      = seq_nb_ptr_r;
    axi_w_valid_o       = 1'b0;
    txn_ctrl_ready_o    = 1'b0;
    rx_deshfu_ready_o   = 1'b0;
    seq_buf_enq         = 1'b0;
    seq_buf_deq         = 1'b0;
    w_buf_enq           = 1'b0;
    w_buf_deq           = 1'b0;
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

    case (state_r)
      S_IDLE: begin
        // Initialize pointers and vaddr
        if (txn_ctrl_valid_i) begin
          bus_nb_cnt_nxt      = '0;
          seq_nb_ptr_nxt      = seq_info_deq_bits.seq_nb_ptr;
          seq_info_deq_ready  = 1'b1;
        end
      end
      S_SERIAL_CMT: begin
        // Calculate lower and upper nibble boundaries
        lower_nibble = txn_ctrl_i.isHead       ? txn_ctrl_i.addr[busNSize-1:0] : '0;
        upper_nibble = txn_ctrl_i.rmnBeat == 0 ? txn_ctrl_i.lbN                : busNibbles;

        // Commit when:
        // 1. There are valid data in seqBuf;
        // 2. Target wBuf is not full;
        // 3. TxnInfo is valid
        if (!seq_buf_empty && !w_buf_full && txn_ctrl_valid_i) begin
          bus_valid_nb     = upper_nibble - lower_nibble - bus_nb_cnt_r;
          seq_buf_valid_nb = NrLaneEntriesNbs - seq_nb_ptr_r;

          if (bus_valid_nb > seq_buf_valid_nb) begin
            // The amount of valid data on the bus is greater than the amount of free space available in seqBuf
            nr_nbs_committed = seq_buf_valid_nb;
            bus_nb_cnt_nxt   = bus_nb_cnt_r + nr_nbs_committed;
            seq_nb_ptr_nxt   = '0;
            seq_buf_deq      = 1'b1;
          end else begin
            // seqBuf still has enough space for the next r beat
            nr_nbs_committed = bus_valid_nb;
            bus_nb_cnt_nxt   = '0;
            seq_nb_ptr_nxt   = seq_nb_ptr_r + nr_nbs_committed;
            txn_ctrl_ready_o = 1'b1;

            // Still need to do deq for the seqBuf if bus_valid_nb = seq_buf_valid_nb
            if (bus_valid_nb == seq_buf_valid_nb) begin
              seq_buf_deq    = 1'b1;
              seq_nb_ptr_nxt = '0;
            end

            // do enq for wBuf
            w_buf_enq = 1'b1;

            // Haven't occupied all valid nbs in the seqBuf,
            // but the current beat is already the final beat of the whole riva request
            if (txn_ctrl_i.isFinalBeat) begin
              seq_buf_deq    = 1'b1;
              seq_nb_ptr_nxt = '0;
            end
          end

          start = lower_nibble + bus_nb_cnt_r;

          // Commit data from seqBuf to wBuf
          for (int i = 0; i < busNibbles; i++) begin
            if ((i >= start) && (i < upper_nibble)) begin
              int idx = i - start + seq_nb_ptr_r;
              w_buf[w_enq_ptr_value].nbs [i] = seq_buf[seq_deq_ptr_value].nb[idx];
              w_buf[w_enq_ptr_value].nbes[i] = seq_buf[seq_deq_ptr_value].en[idx];
            end else begin
              w_buf[w_enq_ptr_value].nbs [i] = '0; // TODO: Only clear nbes[i] is enough.
              w_buf[w_enq_ptr_value].nbes[i] = 1'b0;
            end
          end
          w_buf[w_enq_ptr_value].last = txn_ctrl_i.rmnBeat == 0;
          w_buf[w_enq_ptr_value].user = '0;
        end
      end
      S_GATHER_CMT: begin
        // Not supported yet
        $fatal("Gather mode not supported!");
      end
    endcase
  end

  // ================= seqBuf Input from DeShuffleUnit ================= //
  assign rx_deshfu_ready_o = !seq_buf_full;

  // seq buf enqueue from deshuffle unit.
  always_ff @(posedge clk_i) begin
    if (rx_deshfu_valid_i && rx_deshfu_ready_o) begin
      seq_buf[seq_enq_ptr_value] <= rx_deshfu_i;
      seq_buf_enq <= 1'b1;
    end else begin
      seq_buf_enq <= 1'b0;
    end
  end

  // ================= wBuf -> AXI W Channel ================= //
  always_comb begin
    axi_w_o.data = w_buf[w_deq_ptr_value].nbs;
    axi_w_o.strb = '0;
    for (int i = 0; i < busNibbles; i++) begin
      axi_w_o.strb[i] = w_buf[w_deq_ptr_value].nbes[2*i] || w_buf[w_deq_ptr_value].nbes[2*i+1];
    end
    axi_w_o.last  = w_buf[w_deq_ptr_value].last;
    axi_w_o.user  = w_buf[w_deq_ptr_value].user;
    axi_w_valid_o = !w_buf_empty;
  end

  // w buf dequeue to AXI W Channel.
  always_ff @(posedge clk_i) begin
    if (axi_w_valid_o && axi_w_ready_i) begin
      w_buf[w_deq_ptr_value] <= '0;
      w_buf_deq              <= 1'b1;
    end else begin
      w_buf_deq <= 1'b0;
    end
  end

  // ================= Meta Control Interface Logic ================= //
  assign seq_info_enq_valid         = meta_glb_valid_i;
  assign seq_info_enq_bits.seqNbPtr = (meta_glb_i.vstart << meta_glb_i.sew)[$clog2(NrLaneEntriesNbs)-1:0];
  assign meta_glb_ready_o          = seq_info_enq_ready;

  // ================= Sequential Logic ================= //
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_r      <= S_IDLE;
      bus_nb_cnt_r <= '0;
      seq_nb_ptr_r <= '0;
    end else begin
      state_r      <= state_nxt;
      bus_nb_cnt_r <= bus_nb_cnt_nxt;
      seq_nb_ptr_r <= seq_nb_ptr_nxt;
    end
  end

endmodule : SequentialStore 