package vlsu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters
import protocols.AXI.spec.{AWFlit, ARFlit}

// Address Generate Unit
class AGU(implicit p: Parameters) extends VLSUModule {
// ------------------------------------------ IO Declaration ---------------------------------------------- //
  val io = IO(new Bundle {
    // TODO: The memory access Req AGU received might has been decoded, not the original Req. The valid should not be the original valid!=
    val req    = Flipped(Decoupled(new AGUReq())) // TODO: is ready needed?
    val resp   = Decoupled(new AGUResp())
  })

// ------------------------------------------ Module Declaration ---------------------------------------------- //
  // address aligning
  private val size = io.req.bits.size

  private val alignMask = (1.U << size - 1.U).asUInt
  private val offset    = io.req.bits.baseAddr & alignMask
  private val isAligned = offset === 0.U
  private val alignAddr = io.req.bits.baseAddr >> size << size

  // FSM vals
  private val IDLE   = 0
  private val INCR   = 1
  private val STRD   = 2
  private val TWODIM = 3

  private val state_nxt = WireInit(0.U(2.W))
  private val state_r   = RegNext(state_nxt) // (1) state transfer, Sequential Logic

  private val idle = state_r === IDLE.U
  private val incr = state_r === INCR.U
  private val strd = state_r === STRD.U
  private val twoD = state_r === TWODIM.U

  // Regs to save information
  private val alnBaseAddr_nxt = Wire(chiselTypeOf(io.req.bits.baseAddr)) // aligned base address
  private val alnBaseAddr_r   = RegNext(alnBaseAddr_nxt)

  private val remainBeat_nxt  = Wire(chiselTypeOf(io.req.bits.totBeat))  // NOTE: actual beat = totBeat + 1
  private val remainBeat_r    = RegNext(remainBeat_nxt)

  // These information are stable during the same request.
  private val size_r          = RegEnable(io.req.bits.size  , 0.U, io.req.fire)
  private val stride_r        = RegEnable(io.req.bits.stride, 0.U, io.req.fire)

  //
  // FSM state switch, using block assignment for combination-logic
  //
  // outputs:
  //        state_nxt
  // TODO: not finished yet!
  when (idle) {
     when (io.req.valid) {
      when (io.req.bits.mopOH.isIncr) {
        state_nxt := Mux(io.req.bits.totBeat.orR, IDLE.U, INCR.U) // When mode is Incr and totBeat = 0.U, we dont need to switch state because only one addr is needed.
      }.elsewhen (io.req.bits.mopOH.isStrd) {
        state_nxt := STRD.U
      }.elsewhen (io.req.bits.mopOH.is2D) {
        state_nxt := TWODIM.U
      }.otherwise {
        state_nxt := state_r
      }
    }.otherwise {
      state_nxt := state_r
    }
  }
  .elsewhen(incr) {
    state_nxt := Mux(io.resp.fire, IDLE.U, state_r)
  }
  .otherwise {
    state_nxt := state_r
  }

  //
  // FSM Main Logics
  //
  // outputs:
  //        io.resp.bits.addr
  //        io.resp.bits.offset
  //        io.resp.bits.last
  //        io.resp.valid
  //        alnBaseAddr_nxt
  //        remainBeat_nxt
  when (idle) {
    // When state is IDLE and maReq is received, we immediately return the base addr and offset as first beat.
    when (io.req.valid) {
      io.resp.bits.addr   := alignAddr
      io.resp.bits.offset := offset
      io.resp.bits.last   := Mux(io.req.bits.mopOH.isIncr && !io.req.bits.totBeat.orR, true.B, false.B)
      io.resp.valid       := true.B
      alnBaseAddr_nxt     := alignAddr
      remainBeat_nxt      := Mux(!io.req.bits.totBeat.orR, 0.U, io.req.bits.totBeat - 1.U)
    }.otherwise {
      io.resp.bits.addr   := 0.U
      io.resp.bits.offset := 0.U
      io.resp.bits.last   := false.B
      io.resp.valid       := false.B
      alnBaseAddr_nxt     := 0.U
      remainBeat_nxt      := 0.U
    }
  }
  .elsewhen (incr) {
    io.resp.bits.addr   := alnBaseAddr_r + (1.U << 12 - 1.U) // Only cross page operation will enter this state, so the next address will be base addr + 0xFFF.
    io.resp.bits.offset := 0.U                               // base Addr has been aligned, so the offset is 0.
    io.resp.bits.last   := true.B
    io.resp.valid       := true.B
    alnBaseAddr_nxt     := 0.U
    remainBeat_nxt      := 0.U
  }
  .otherwise {
    io.resp.bits.addr   := 0.U
    io.resp.bits.offset := 0.U
    io.resp.bits.last   := false.B
    io.resp.valid       := false.B
    alnBaseAddr_nxt     := 0.U
    remainBeat_nxt      := 0.U
  }

  // req ready is only asserted when state is IDLE.
  io.req.ready := idle


// ------------------------------------------  Don't Touch ---------------------------------------------- //
  dontTouch(idle)
  dontTouch(incr)
  dontTouch(strd)
  dontTouch(twoD)

// ------------------------------------------  Assertions ---------------------------------------------- //
  when (io.req.valid) {
    assert(PopCount(io.req.bits.mopOH.asUInt) === 1.U, "mopOH should be OneHot!")
    assert((io.req.bits.mopOH.isStrd || io.req.bits.mopOH.is2D) && (io.req.bits.totBeat === 0.U), "TotBeat should > 0 when mode is not incr!")
    assert(io.req.bits.totBeat < maxTxnPerReq.U, "TotBeat should < maxTxnPerReq") // actual maxBeat = totBeat + 1
  }
}