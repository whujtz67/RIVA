package vlsu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters
import protocols.AXI.spec.WFlit
import xs.utils.CircularQueuePtr


class DataCtrlStore(implicit p: Parameters) extends VLSUModule with ShuffleHelper with CommonDataCtrl {
// ------------------------------------------ Private Classes ------------------------------------------------- //
  private class CirQWBufPtr extends CircularQueuePtr[CirQWBufPtr](wBufDep)

  private class WBufBundle(implicit p: Parameters) extends VLSUBundle {
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
  // W Channel Output
  val w = IO(Decoupled(new WFlit(axi4Params))).suggestName("io_w")

  // Input from Lane Exits
  val rxs = IO(Vec(NrLanes, Flipped(Decoupled(new RxLane())))).suggestName("io_rxs") // to Lane

// ------------------------------------------ Wire/Reg Declaration ------------------------------------------------- //
  private val shfBuf      = RegInit(0.U.asTypeOf(Vec(NrLanes, Valid(new RxLane()))))
  private val shfBufFull  = shfBuf.map(_.valid).reduce(_ && _)

  private val wBuf = RegInit(0.U.asTypeOf(Vec(wBufDep, new WBufBundle())))

  private val w_enqPtr  = RegInit(0.U.asTypeOf(new CirQWBufPtr()))
  private val w_deqPtr  = RegInit(0.U.asTypeOf(new CirQWBufPtr()))
  private val wBufFull  = isFull(w_enqPtr, w_deqPtr)
  private val wBufEmpty = isEmpty(w_enqPtr, w_deqPtr)

// ------------------------------------------ give the Outputs default value ------------------------------------------------- //
  busNbCnt_nxt   := busNbCnt_r
  seqNbPtr_nxt   := seqNbPtr_r
  w.valid        := false.B
  txnInfo.ready  := false.B
  maskReady      := false.B

  // ------------------------------------------ rx lane -> shfBuf ------------------------------------------------- //
  shfBuf.zip(rxs).foreach {
    case (entry, rx) =>
      rx.ready := !entry.valid

      when (rx.fire) {
        entry.bits  := rx.bits
        entry.valid := true.B
      }
  }

// ------------------------------------------ shfBuf -> seqBuf ------------------------------------------------- //
  private val do_cmt_shf_to_seq = shfBufFull && !seqBufFull && !metaBufEmpty && (meta.vm || mask.map(_.valid).reduce(_ || _))

  enqPtr_nxt := enqPtr

  when (do_cmt_shf_to_seq) {
    val seqBuf_nb = seqBuf(enqPtr.value).nb
    val seqBuf_en = seqBuf(enqPtr.value).en

    val shfBuf_nb = VecInit(shfBuf.map(_.bits.nbs))

    hw_deshuffle(meta.mode, meta.eew, seqBuf_nb, Some(shfBuf_nb))
    hw_deshuffle(meta.mode, meta.eew, seqBuf_en, None, Some(VecInit(mask.map(_.bits))), Some(meta.vm))

    maskReady := !meta.vm // mask has been consumed

    // do enq of seqBuf
    enqPtr_nxt := enqPtr + 1.U

    // do deq of shfBuf
    shfBuf.foreach { source =>
      source.valid := false.B
      source.bits  := 0.U.asTypeOf(source.bits)  // TODO: not necessary actually
    }

    // Do deq of metaBuf if cmtCnt == 0. Otherwise, do cmtCnt - 1
    when (!meta.cmtCnt.orR) {
      m_deqPtr := m_deqPtr + 1.U
    }.otherwise {
      meta.cmtCnt := meta.cmtCnt - 1.U
    }
  }

// ------------------------------------------ seqBuf -> wBuf ------------------------------------------------- //
  when (idle) {
    when(!metaBufEmpty) {
      busNbCnt_nxt := 0.U
      seqNbPtr_nxt := (meta.vstart << meta.eew)(log2Ceil(nbNum)-1, 0)

      assert(txnInfo.valid, "There should be at least one valid tc!")
    }
  }.elsewhen(serial_cmt) {
    val lower_nibble = Mux(
      txn.isHead,
      txn.addr(busNSize-1, 0), // txnInfo.bits.addr has already taken vstart into consideration
      0.U
    )
    val upper_nibble = Mux(
      txn.isLastBeat,
      // busOff has already been accounted for in txn.lbB, so we don't need to add lowerNb (which is busOff)!
      txn.lbN,
      busNibbles.U
    )

    // Commit when:
    // 1. There are valid data in seqBuf
    // 2. wBuf is not full
    when (!seqBufEmpty && !wBufFull) {
      val busValidNb    = upper_nibble - lower_nibble + 1.U - busNbCnt_r // The amount of valid data on the bus
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
            val idx = busIdx.U - start + seqNbPtr_r
            nb  := seqBuf(deqPtr.value).nb(idx)
            // The nbes that are outside the start-end range are always zero,
            // so the case for the final beat (lbB) has already been taken into consideration here.
            nbe := seqBuf(deqPtr.value).en(idx)
          }
      }
      wBuf(w_enqPtr.value).last := txnInfo.bits.isLastBeat
      wBuf(w_enqPtr.value).user := 0.U

    }
  }.elsewhen(gather_cmt) {
    assert(false.B, "We don't support gather mode now!")
  }

// ------------------------------------------ wBuf -> AXI W Channel ------------------------------------------------- //
  w.bits.data := wBuf(w_deqPtr.value).nbs.asUInt
  w.bits.strb := wBuf(w_deqPtr.value).strb
  w.bits.last := wBuf(w_deqPtr.value).last
  w.bits.user := wBuf(w_deqPtr.value).user
  w.valid     := !wBufEmpty

  // do deq when w fire
  when (w.fire) {
    w_deqPtr := w_deqPtr + 1.U
  }
// ------------------------------------------ Don't Touch ------------------------------------------------- //
  dontTouch(do_cmt_shf_to_seq)
}