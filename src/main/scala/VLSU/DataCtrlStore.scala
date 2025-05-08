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
    val hbs  = Vec(busBytes * 2, UInt(4.W))
    val hbes = Vec(busBytes * 2, Bool())
    val last = Bool()
    val user = UInt(axi4Params.userBits.W)
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
  busHbCnt_nxt   := busHbCnt_r
  seqHbPtr_nxt   := seqHbPtr_r
  w.valid        := false.B
  txnInfo.ready  := false.B
  maskReady      := false.B
  busData        := 0.U.asTypeOf(busData)
  busHbe         := 0.U.asTypeOf(busHbe)


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

  when (do_cmt_shf_to_seq) {
    val seqBuf_hb = seqBuf(enqPtr.value).hb
    val seqBuf_en = seqBuf(enqPtr.value).en

    val shfBuf_hb = VecInit(shfBuf.map(_.bits.hbs))

    hw_deshuffle(meta.mode, meta.eew, seqBuf_hb, Some(shfBuf_hb))
    hw_deshuffle(meta.mode, meta.eew, seqBuf_en, None, Some(VecInit(mask.map(_.bits))), Some(meta.vm))

    maskReady := !meta.vm // mask has been consumed

    // do enq of seqBuf
    enqPtr := enqPtr + 1.U

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
      busHbCnt_nxt := 0.U
      seqHbPtr_nxt := (meta.vstart << meta.eew)(log2Ceil(hbNum)-1, 0)
    }
  }.elsewhen(serial_cmt) {
    val lowerHb = Mux(
      txn.isHead,
      (txn.addr(busSize-1, 0) << 1).asUInt + txn.illuHead.asUInt, // txnInfo.bits.addr has already taken vstart into consideration
      0.U
    )
    val upperHb = Mux(
      txn.isLastBeat,
      (txn.lbB << 1).asUInt - txn.illuTail.asUInt, // busOff has already been accounted for in txn.lbB, so we don't need to add lowerHb (which is busOff)!
      (busBytes * 2).U
    )

    // Commit when:
    // 1. There are valid data in seqBuf
    // 2. wBuf is not full
    when (!seqBufEmpty && !wBufFull) {
      val busValidHb    = upperHb - lowerHb + 1.U - busHbCnt_r // The amount of valid data on the bus
      val seqBufValidHb = (NrLanes * SLEN / 4).U - seqHbPtr_r  // The amount of free space available in seqBuf

      val cmtHbNum = WireInit(0.U.asTypeOf(UInt((busSize + 1).W)))

      //
      // Update control information
      //
      when (busValidHb > seqBufValidHb) {
        // The free data in the busBuffer is greater than the amount of valid data in seqBuf.
        cmtHbNum     := seqBufValidHb
        busHbCnt_nxt := busHbCnt_r + cmtHbNum
        seqHbPtr_nxt := 0.U

        deqPtr := deqPtr + 1.U // do seqBuf deq
      }.otherwise {
        // The free data in the busBuffer is less than the amount of valid data in seqBuf.
        cmtHbNum      := busValidHb
        busHbCnt_nxt  := 0.U
        seqHbPtr_nxt  := seqHbPtr_r + cmtHbNum // will be 0.U when busValidHb = seqBufValidHb
        txnInfo.ready := true.B                // a beat is issued

        // Still need to do deq for the seqBuf is busValidHb = seqBufValidHb
        when (busValidHb === seqBufValidHb) {
          deqPtr := deqPtr + 1.U
        }

        // do enq for wBuf
        w_enqPtr := w_enqPtr + 1.U

        // Haven't occupied all valid hbs in the seqBuf,
        // but the current beat is already the final beat of the whole riva request.
        when (txnInfo.bits.isFinalBeat) {
          deqPtr := deqPtr + 1.U
        }
      }

      //
      // commit data from seqBuf to wBuf
      //
      val start = lowerHb + busHbCnt_r
      val end   = upperHb

      wBuf(w_enqPtr.value).hbs.zip(wBuf(w_enqPtr.value).hbes).zipWithIndex.foreach {
        case ((hb, hbe), busIdx) =>
          when ((busIdx.U >= start) && (busIdx.U < end)) { // should be '< end' because we don't do '-1' when calculating upperHb.
            val idx = busIdx.U - start + seqHbPtr_r
            hb  := seqBuf(deqPtr.value).hb(idx)
            // The hbes that are outside the start-end range are always zero,
            // so the case for the final beat (lbB) has already been taken into consideration here.
            hbe := seqBuf(deqPtr.value).en(idx)
          }
      }
      wBuf(w_enqPtr.value).last := txnInfo.bits.isLastBeat
      wBuf(w_enqPtr.value).user := 0.U

    }
  }.elsewhen(gather_cmt) {
    assert(false.B, "We don't support gather mode now!")
  }

// ------------------------------------------ wBuf -> AXI W Channel ------------------------------------------------- //
  w.bits.data := wBuf(w_deqPtr.value).hbs.asUInt
  w.bits.strb := wBuf(w_deqPtr.value).hbes.asUInt
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