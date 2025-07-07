package vlsu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters
import protocols.AXI.spec.WFlit
import xs.utils.CircularQueuePtr

class SequentialStore(implicit p: Parameters) extends VLSUModule with SequentialDataCtrl {
  def isLoad: Boolean = false

// ------------------------------------------ Private Classes ------------------------------------------------- //
  class CirQWBufPtr extends CircularQueuePtr[CirQWBufPtr](wBufDep)

  class WBufBundle(implicit p: Parameters) extends VLSUBundle {
    val nbs  = Vec(busNibbles, UInt(4.W))
    val nbes = Vec(busNibbles, Bool())
    val last = Bool()
    val user = UInt(axi4Params.userBits.W)

    def strb: UInt = {
      require((busBytes * 2) == busNibbles)

      // A byte is valid if any of its 4-bit nibbles are valid.
      VecInit(Seq.tabulate(busBytes) { i => this.nbes(2 * i) || this.nbes(2 * i + 1) }).asUInt
    }
  }

// ------------------------------------------ IO Declaration ------------------------------------------------- //
  // Input from DeShuffleUnit
  val rxDeshfu = IO(Flipped(Decoupled(new SeqBufBundle()))).suggestName("io_rx_deshfu")

  // W Channel Output
  val w = IO(Decoupled(new WFlit(axi4Params))).suggestName("io_w")

// ------------------------------------------ Wire/Reg Declaration ------------------------------------------------- //
  val wBuf = RegInit(0.U.asTypeOf(Vec(wBufDep, new WBufBundle())))

  val w_enqPtr  = RegInit(0.U.asTypeOf(new CirQWBufPtr()))
  val w_deqPtr  = RegInit(0.U.asTypeOf(new CirQWBufPtr()))
  val wBufFull  = isFull(w_enqPtr, w_deqPtr)
  val wBufEmpty = isEmpty(w_enqPtr, w_deqPtr)

// ------------------------------------------ seqBuf -> wBuf logic ------------------------------------------------- //
  // Override the default assignments from CommonDataCtrl
  busNbCnt_nxt := busNbCnt_r
  seqNbPtr_nxt := seqNbPtr_r
  w.valid := false.B
  txnInfo.ready := false.B
  enqPtr_nxt := enqPtr
  rxDeshfu.ready := false.B
  seqInfoBuf.io.deq.ready := false.B

  // FSM Outputs for seqBuf -> wBuf
  when (idle) {
    // initialize Pointers and vaddr
    when(txnInfo.valid) {
      busNbCnt_nxt := 0.U
      seqNbPtr_nxt := seqInfoBuf.io.deq.bits.seqNbPtr
      seqInfoBuf.io.deq.ready := true.B
    }
  }.elsewhen(serial_cmt) {
    val lower_nibble = Mux(
      txnInfo.bits.isHead,
      txnInfo.bits.addr(busNSize-1, 0), // txnInfo.bits.addr has already taken vstart into consideration
      0.U
    )
    val upper_nibble = Mux(
      txnInfo.bits.isLastBeat,
      // busOff has already been accounted for in txn.lbN, so we don't need to add lower_nibble (which is busOff)!
      txnInfo.bits.lbN,
      busNibbles.U
    )

    // Commit when:
    // 1. There are valid data in seqBuf;
    // 2. Target wBuf is not full;
    // 3. TxnInfo is valid. Otherwise the txnInfo should be wrong.
    when (!seqBufEmpty && !wBufFull && txnInfo.valid) {
      val busValidNb    = upper_nibble - lower_nibble - busNbCnt_r // The amount of valid data on the bus
      val seqBufValidNb = (NrLanes * SLEN / 4).U - seqNbPtr_r  // The amount of free space available in seqBuf

      val cmtNbNum = WireInit(0.U.asTypeOf(UInt((busSize + 1).W)))

      //
      // Update control information
      //
      when (busValidNb > seqBufValidNb) {
        // The free data in the busBuffer is greater than the amount of valid data in seqBuf.
        cmtNbNum     := seqBufValidNb
        busNbCnt_nxt := busNbCnt_r + cmtNbNum
        seqNbPtr_nxt := 0.U

        deqPtr := deqPtr + 1.U // do seqBuf deq
      }.otherwise {
        // The free data in the busBuffer is less than the amount of valid data in seqBuf.
        cmtNbNum      := busValidNb
        busNbCnt_nxt  := 0.U
        seqNbPtr_nxt  := seqNbPtr_r + cmtNbNum // will be 0.U when busValidNb = seqBufValidNb
        txnInfo.ready := true.B                // a beat is issued

        // Still need to do deq for the seqBuf is busValidNb = seqBufValidNb
        when (busValidNb === seqBufValidNb) {
          deqPtr := deqPtr + 1.U
          seqNbPtr_nxt := 0.U
        }

        // do enq for wBuf
        w_enqPtr := w_enqPtr + 1.U

        // Haven't occupied all valid nbs in the seqBuf,
        // but the current beat is already the final beat of the whole riva request.
        when (txnInfo.bits.isFinalBeat) {
          deqPtr := deqPtr + 1.U
          seqNbPtr_nxt := 0.U
        }
      }

      //
      // commit data from seqBuf to wBuf
      //
      val start = lower_nibble + busNbCnt_r
      val end   = upper_nibble

      wBuf(w_enqPtr.value).nbs.zip(wBuf(w_enqPtr.value).nbes).zipWithIndex.foreach {
        case ((nb, nbe), busIdx) =>
          when ((busIdx.U >= start) && (busIdx.U < end)) { // should be '< end' because we don't do '-1' when calculating upperNb.
            // TODO: vstart should be considered!
            val idx = busIdx.U - start + seqNbPtr_r
            nb  := seqBuf(deqPtr.value).nb(idx)
            // The nbes that are outside the start-end range are always zero,
            // so the case for the final beat (lbB) has already been taken into consideration here.
            nbe := seqBuf(deqPtr.value).en(idx)
          }
      }
      wBuf(w_enqPtr.value).last := txnInfo.bits.isLastBeat
      wBuf(w_enqPtr.value).user := 0.U.asTypeOf(wBuf(w_enqPtr.value).user)

      dontTouch(upper_nibble)
      dontTouch(lower_nibble)
      dontTouch(busValidNb)
      dontTouch(seqBufValidNb)
    }
  }.elsewhen(gather_cmt) {
    assert(false.B, "We don't support gather mode now!")
  }
  
// ------------------------------------------ seqBuf input from DeShuffleUnit ------------------------------------------------- //
  // Accept seqBuf data from DeShuffleUnit when available
  rxDeshfu.ready := !seqBufFull
  when (rxDeshfu.fire) {
    seqBuf(enqPtr.value) := rxDeshfu.bits
    enqPtr_nxt := enqPtr + 1.U
  }

// ------------------------------------------ wBuf -> AXI W Channel ------------------------------------------------- //
  w.bits.data := wBuf(w_deqPtr.value).nbs.asUInt
  w.bits.strb := wBuf(w_deqPtr.value).strb
  w.bits.last := wBuf(w_deqPtr.value).last
  w.bits.user := wBuf(w_deqPtr.value).user
  w.valid     := !wBufEmpty

  // do deq when w fire
  when (w.fire) {
    wBuf(w_deqPtr.value) := 0.U.asTypeOf(wBuf(w_deqPtr.value))
    w_deqPtr := w_deqPtr + 1.U
  }

// ------------------------------------------ Don't Touch ------------------------------------------------- //
  dontTouch(idle)
  dontTouch(seqNbPtr_nxt)
  dontTouch(enqPtr_nxt)
  dontTouch(seqBufEmpty)
  dontTouch(seqBufFull)
  dontTouch(serial_cmt)
  dontTouch(gather_cmt)
} 