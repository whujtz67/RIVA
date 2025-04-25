package vlsu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters
import protocols.AXI.spec.WFlit

class DataCtrlStore(implicit p: Parameters) extends VLSUModule with ShuffleHelper with CommonDataCtrl {
// ------------------------------------------ IO Declaration ------------------------------------------------- //
  // W Channel Output
  val w = IO(Flipped(Decoupled(new WFlit(axi4Params)))).suggestName("io_w")

  // Input from Lane Exits
  val rxs = IO(Vec(NrLanes, Flipped(Decoupled(new RxLane())))).suggestName("io_rxs") // to Lane
// ------------------------------------------ Wire/Reg Declaration ------------------------------------------------- //
  private val shfBuf      = RegInit(0.U.asTypeOf(Vec(NrLanes, Valid(new RxLane()))))
  private val shfBufFull  = shfBuf.map(_.valid).reduce(_ && _)

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
  private val do_cmt_shfBuf_to_seqBuf = shfBufFull && !seqBufFull && metaInfo.valid && (meta.vm || mask.map(_.valid).reduce(_ || _))
  when (do_cmt_shfBuf_to_seqBuf) {
    val seqBuf_hb = VecInit(seqBuf(enqPtr.value).map(_.hb))
    val seqBuf_en = VecInit(seqBuf(enqPtr.value).map(_.en))
  }
}