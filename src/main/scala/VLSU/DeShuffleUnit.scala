package vlsu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters

class DeShuffleUnit(implicit p: Parameters) extends VLSUModule with ShuffleDataCtrl {
  def isLoad: Boolean = false
  
  class SeqBufBundle(implicit p: Parameters) extends VLSUBundle {
    val nb = Vec(NrLanes*SLEN/4, UInt(4.W))
    val en = Vec(NrLanes*SLEN/4, Bool())
  }

// ------------------------------------------ IO Declaration ------------------------------------------------- //
  // Input from Lane Exits
  val rxs = IO(Vec(NrLanes, Flipped(Decoupled(new RxLane())))).suggestName("io_rxs")

  // Output to SequentialStore
  val txSeqStore = IO(Decoupled(new SeqBufBundle())).suggestName("io_tx_seqStore")

// ------------------------------------------ Wire/Reg Declaration ------------------------------------------------- //
  // shfBuf to store data from lanes
  val shfBuf = RegInit(0.U.asTypeOf(Vec(NrLanes, Valid(new RxLane()))))
  val shfBufFull = shfBuf.map(_.valid).reduce(_ && _)

// ------------------------------------------ give the Outputs default value ------------------------------------------------- //
  txSeqStore.valid := false.B
  txSeqStore.bits  := 0.U.asTypeOf(new SeqBufBundle())
  maskReady        := false.B

// ------------------------------------------ rx lane -> shfBuf ------------------------------------------------- //
  shfBuf.zip(rxs).foreach {
    case (entry, rx) =>
      rx.ready := !entry.valid

      when (rx.fire) {
        entry.bits := rx.bits
        entry.valid := true.B
      }
  }

// ------------------------------------------ shfBuf -> seqBuf ------------------------------------------------- //
  txSeqStore.valid := shfBufFull && !shfInfoBufEmpty && (meta.vm || mask.map(_.valid).reduce(_ || _))
  private val do_cmt_shf_to_seq = txSeqStore.fire

  when (do_cmt_shf_to_seq) {
    val seqBuf_nb = txSeqStore.bits.nb
    val seqBuf_en = txSeqStore.bits.en

    val shfBuf_nb = VecInit(shfBuf.map(_.bits.nbs))

    hw_deshuffle(meta.mode, meta.eew, seqBuf_nb, Some(shfBuf_nb))
    hw_deshuffle(meta.mode, meta.eew, seqBuf_en, None, Some(VecInit(mask.map(_.bits))), Some(meta.vm))

    maskReady := !meta.vm // mask has been consumed

    // do deq of shfBuf
    shfBuf.foreach(_.valid := false.B)

    // Consume meta from metaBuf
    when (!meta.cmtCnt.orR) {
      shfInfo_deqPtr := shfInfo_deqPtr + 1.U
    }.otherwise {
      meta.cmtCnt := meta.cmtCnt - 1.U
    }
  }

// ------------------------------------------ Don't Touch ------------------------------------------------- //
  dontTouch(do_cmt_shf_to_seq)
  dontTouch(shfBufFull)
} 