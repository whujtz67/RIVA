package vlsu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters
import xs.utils.{CircularQueuePtr, HasCircularQueuePtrHelper}

class ShuffleUnit(implicit p: Parameters) extends VLSUModule with ShuffleDataCtrl {
  def isLoad: Boolean = true

// ------------------------------------------ IO Declaration ------------------------------------------------- //
  // Input from DataCtrlLoad
  val rxSeqLoad = IO(Flipped(Decoupled(new SeqBufBundle()))).suggestName("io_rx_seqLoad")

  // Output to Lane Entries
  val txs = IO(Vec(NrLanes, Decoupled(new TxLane()))).suggestName("io_txs") // to Lane

// ------------------------------------------ Wire/Reg Declaration ------------------------------------------------- //
  // shuffle buffer
  private val shfBuf = RegInit(0.U.asTypeOf(Vec(NrLanes, Valid(new TxLane()))))
  private val shfBufEmpty = !shfBuf.map(_.valid).reduce(_ || _)

// ------------------------------------------ give the Outputs default value ------------------------------------------------- //
  maskReady      := false.B

// ------------------------------------------ Connections ------------------------------------------------- //
  when (metaInfo.fire) {
    // do metaBuffer enqueue
    metaBuf(m_enqPtr.value).init(metaInfo.bits)
    m_enqPtr := m_enqPtr + 1.U
  }
  metaInfo.ready := !metaBufFull

// ------------------------------------------ seqBuf -> shfBuf ------------------------------------------------- //
  rxSeqLoad.ready := shfBufEmpty && !metaBufEmpty && (meta.vm || mask.map(_.valid).reduce(_ || _))
  private val do_cmt_seq_to_shf = rxSeqLoad.fire

  // Shuffle and commit data and nbe in seqBuf to shfBuf
  when(do_cmt_seq_to_shf) { // NOTE: mask.valid should be || instead of &&. TODO: 还不知道为什么
    val seqBuf_nb = rxSeqLoad.bits.nb
    val seqBuf_en = rxSeqLoad.bits.en

    val shfBuf_nb = VecInit(shfBuf.map(_.bits.nbs))
    val shfBuf_en = VecInit(shfBuf.map(_.bits.nbes))

    hw_shuffle(meta.mode, meta.eew, seqBuf_nb, shfBuf_nb)
    hw_shuffle(meta.mode, meta.eew, seqBuf_en, shfBuf_en, Some(VecInit(mask.map(_.bits))), Some(meta.vm))

    // ShfBuf_nb/en is created using VecInit, assigning values to it does not automatically propagate to shfBuf.
    // Therefore, it is necessary to connect the two and perform the assignment again.
    shfBuf.zip(shfBuf_nb.zip(shfBuf_en)).foreach {
      case (vec_o, (vec_nb_i, vec_en_i)) =>
        val nbs = Wire(chiselTypeOf(vec_nb_i))
        nbs.zip(vec_nb_i).foreach {
          case (nb_o, nb_i) =>
            nb_o := nb_i
        }
        vec_o.bits.data := nbs.asUInt

        val nbes = Wire(chiselTypeOf(vec_en_i))
        nbes.zip(vec_en_i).foreach {
          case (en_o, en_i) =>
            en_o := en_i
        }
        vec_o.bits.nbe := nbes.asUInt
    }

    // Make all shuffle buffer valid
    shfBuf.foreach { buf =>
      buf.valid := true.B
      // TODO: 是否考虑只存一份reqId和vaddr_r
      buf.bits.reqId := meta.reqId
      buf.bits.vaddr := meta.vaddr.get
    }

    // add vaddr when info are committed and saved in shfBuf
    meta.vaddr.get := (meta.vaddr.get.asUInt + 1.U).asTypeOf(new VAddrBundle)
    maskReady := !meta.vm // mask has been consumed

    /* When current seqBuf is the last set of data of the riva req, do metaReq deq.
     * We SHOULD wait for this stage to deq metaBuf, instead of at 'bus -> seqBuf' stage!!!
     * The reason is we need meta.vm in this stage.
     *
     * cmtCnt is pre-calculated in the ControlMachine.
     *
     * cmtCnt is the actually count - 1, so do deq when cmtCnt = 0 and data is committed to shfBuf to seqBuf.
     */
    when (!meta.cmtCnt.orR) {
      m_deqPtr := m_deqPtr + 1.U
    }.otherwise {
      meta.cmtCnt := meta.cmtCnt - 1.U
    }
  }

// ------------------------------------------ shfBuf -> lane ------------------------------------------------- //
  txs.zipWithIndex.foreach {
    case (tx, lane) =>
      tx.bits.reqId := shfBuf(lane).bits.reqId
      tx.bits.vaddr := shfBuf(lane).bits.vaddr
      tx.bits.data  := shfBuf(lane).bits.nbs.asUInt
      tx.bits.nbe   := shfBuf(lane).bits.nbes.asUInt
      tx.valid      := shfBuf(lane).valid

      when (tx.fire) {
        shfBuf(lane).valid := false.B
      }
  }

// ------------------------------------------ Assertions ------------------------------------------------- //
  when(rxSeqLoad.valid) { assert(!metaBufEmpty, "[ShuffleUnit] There should be at least one valid meta info in meta Buffer when seqBuf is not Empty!") }
  assert(txs(0).bits.vaddr.set < vmSramDepth.U, s"[ShuffleUnit] vaddr_set should < vmSramDepth = $vmSramDepth. However, got %d\n", txs(0).bits.vaddr.set)

// ------------------------------------------ Debug signals ------------------------------------------------- //
  if (debug) {
    val current_meta = WireDefault(metaBuf(m_deqPtr.value))
    dontTouch(current_meta)
  }

// ------------------------------------------ Don't Touch ------------------------------------------------- //
  dontTouch(do_cmt_seq_to_shf)
  dontTouch(shfBufEmpty)
  dontTouch(metaBufEmpty)
  dontTouch(metaBufFull)
} 