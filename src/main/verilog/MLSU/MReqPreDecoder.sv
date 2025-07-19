// ============================================================================
// MReqPreDecoder.sv
// Matrix Load Store Unit - Request Pre-Decoder Module
// Converts mlsu_req to preDec_req for downstream processing
// ============================================================================

module MReqPreDecoder import riva_pkg::*; #(
  parameter  type            mlsu_init_req_t     = logic,
  parameter  type            mlsu_predec_req_t   = logic
) (
  // Clock and Reset
  input  logic                 clk_i,
  input  logic                 rst_ni,
  
  // MLSU Request Interface (Input)
  input  logic                 req_valid_i,
  output logic                 req_ready_o,
  input  mlsu_init_req_t       req_i,
  
  // Pr-decoded Request Interface (Output)
  output logic                 preDec_req_valid_o,
  input  logic                 preDec_req_ready_i,
  output mlsu_predec_req_t     preDec_req_o
);

  // ================= FSM Signals ================= //
  typedef enum logic {
    S_IDLE    = 1'b0, // Wait for new request
    S_PRE_DEC = 1'b1  // Pre-decode request
  } state_e;

  state_e  state_nxt, state_r;

  elen_t iter_addr_nxt, iter_addr_r;
  mlen_t tile_nxt, tile_r;

  // ================= Internal Signals ================= //
  // Pre-decoded request queue signals
  logic              rq_enq_valid, rq_enq_ready;
  logic              rq_deq_valid, rq_deq_ready;
  mlsu_predec_req_t  rq_enq_bits , rq_deq_bits ;

  // ================= FSM State Switch Logic ================= //
  always_comb begin
    state_nxt = state_r;
    case (state_r)
      S_IDLE: begin
        if (req_valid_i) begin
          state_nxt = S_PRE_DEC;
        end
      end
      S_PRE_DEC: begin
        if (tile_r == 1 && rq_enq_ready) begin
          state_nxt = S_IDLE;
        end
      end
    endcase
  end

  // ================= FSM State Update Logic ================= //
  always_comb begin: request_pre_decode_fsm
    rq_enq_bits.reqId    = req_i.reqId;
    rq_enq_bits.mode     = 1 << req_i.mop;
    rq_enq_bits.baseAddr = iter_addr_r;
    rq_enq_bits.sew      = req_i.sew;
    rq_enq_bits.md       = req_i.md;
    rq_enq_bits.stride   = req_i.stride;
    rq_enq_bits.vl       = req_i.vl;
    rq_enq_bits.vstart   = req_i.vstart;
    rq_enq_bits.isLoad   = req_i.isLoad;
    rq_enq_bits.vm       = req_i.vm;

    rq_enq_valid = 1'b0;
    iter_addr_nxt = iter_addr_r;
    tile_nxt      = tile_r;
    req_ready_o   = 1'b0;

    case (state_r)
      S_IDLE: begin
        iter_addr_nxt = req_i.baseAddr << 1;
        tile_nxt      = req_i.tile;
      end
      S_PRE_DEC: begin
        // rq_enq_valid is always asserted when in S_PRE_DEC state
        rq_enq_valid = 1'b1;

        // Update iter_addr_nxt and tile_nxt when the queue is ready to accept it.
        if (rq_enq_ready) begin
          iter_addr_nxt = (req_i.mop == 0) ? 
            iter_addr_r + (1 << req_i.sew) : // row-major
            iter_addr_r + req_i.stride     ; // column-major
          tile_nxt      = tile_r - 1;
        end

        // req_ready_o is asserted when the last tile has been decoded and the queue is ready to accept it.
        req_ready_o = tile_r == 1 && rq_enq_ready;
      end
    endcase
  end: request_pre_decode_fsm
  
  // ================= Pre-decoded Request Queue Instance ================= //
  QueueFlow #(
    .T      (mlsu_predec_req_t),
    .DEPTH  (2)
  ) i_pre_dec_req_queue (
    .clk_i        (clk_i         ),
    .rst_ni       (rst_ni        ),
    .enq_valid_i  (rq_enq_valid  ),
    .enq_ready_o  (rq_enq_ready  ),
    .enq_bits_i   (rq_enq_bits   ),
    .deq_valid_o  (rq_deq_valid  ),
    .deq_ready_i  (rq_deq_ready  ),
    .deq_bits_o   (rq_deq_bits   )
  );
  
  // ================= Handshake Logic ================= //
  // Connect input handshake to pre-decoding logic
  assign req_queue_enq_valid = req_valid_i;
  assign req_ready_o         = req_queue_enq_ready;
  
  // Connect output handshake to queue
  assign preDec_req_valid_o  = req_queue_deq_valid;
  assign preDec_req_o        = req_queue_deq_bits;
  assign req_queue_deq_ready = preDec_req_ready_i;

  // ================= FSM State Update Logic ================= //
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_r     <= S_IDLE;
      iter_addr_r <= '0;
      tile_r      <= '0;
    end else begin
      state_r     <= state_nxt;
      iter_addr_r <= iter_addr_nxt;
      tile_r      <= tile_nxt;
    end
  end

  // ================= Assertions ================= //
  // Ensure mop is only 00 (row-major) or 01 (column-major) as only these modes are supported
  assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    req_valid_i |-> (req_i.mop == 2'b00 || req_i.mop == 2'b01)
  ) else $fatal("MReqPreDecoder: Unsupported mop value %0d, only 00 (row-major) and 01 (column-major) are supported", req_i.mop);

endmodule : MReqPreDecoder
