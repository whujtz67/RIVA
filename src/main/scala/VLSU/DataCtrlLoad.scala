package vlsu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters
import protocols.AXI.spec.RFlit

class DataCtrlLoad(implicit p: Parameters) extends VLSUModule with CommonDataCtrl {
// ------------------------------------------ IO Declaration ------------------------------------------------- //
  // R Channel Input
  val r = IO(Flipped(Decoupled(new RFlit(axi4Params)))).suggestName("io_r")

  // Output to Lane Entries
  val txs = IO(Vec(NrLanes, Decoupled(new TxLane()))).suggestName("io_txs") // to Lane

// ------------------------------------------ Module Declaration ------------------------------------------------- //


// ------------------------------------------ Wire/Reg Declaration ------------------------------------------------- //
  // vaddr
  private val vaddr_nxt    = Wire(new VAddrBundle())
  private val vaddr_r      = RegNext(vaddr_nxt)

  // shuffle buffer
  private val shfBuf = RegInit(0.U.asTypeOf(Vec(NrLanes, Valid(new TxLane()))))
  private val shfBufEmpty = !shfBuf.map(_.valid).reduce(_ || _)

// ------------------------------------------ give the Outputs default value ------------------------------------------------- //
  vaddr_nxt      := vaddr_r
  busNbCnt_nxt   := busNbCnt_r
  seqNbPtr_nxt   := seqNbPtr_r
  r.ready        := false.B
  txnInfo.ready  := false.B
  maskReady      := false.B
  enqPtr_nxt     := enqPtr

// ------------------------------------------ AXI R bus -> seqBuf ------------------------------------------------- //
  // FSM Outputs
  when (idle) {
    // initialize Pointers and vaddr
    when(!metaBufEmpty) {
      busNbCnt_nxt := 0.U // busNbCnt is the counter of valid nbs from the bus that has already been committed, so it should be initialized as 0.
      seqNbPtr_nxt := (meta.vstart << meta.eew)(log2Ceil(nbNum)-1, 0) // Only the initialization of seqNbPtr_nxt needs to consider vstart.
      vaddr_nxt.init(meta)

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
      // busOff has already been accounted for in txn.lbN, so we don't need to add lower_nibble (which is busOff)!
      txn.lbN,
      busNibbles.U
    )

    val do_serial_cmt = r.valid && !seqBufFull
    // Won't consume data of the R Channel when seqBuf is full.
    when (do_serial_cmt) {
      val busValidNb    = upper_nibble - lower_nibble - busNbCnt_r // The amount of valid data on the bus. Don't need to '+1' because we didn't do '-1' when calculating upperNb.
      val seqBufValidNb = (NrLanes * SLEN / 4).U - seqNbPtr_r  // The amount of free space available in seqBuf

      val cmtNbNum = WireInit(0.U.asTypeOf(UInt((busSize + 1).W)))

      // Update control information
      when (busValidNb > seqBufValidNb) {
        // The amount of valid data on the bus is greater than the amount of free space available in seqBuf.
        cmtNbNum       := seqBufValidNb
        busNbCnt_nxt   := busNbCnt_r + cmtNbNum
        seqNbPtr_nxt   := 0.U
        enqPtr_nxt     := enqPtr + 1.U // Current slice of seqBuf is full, add the enqPtr.
      }.otherwise {
        // seqBuf still has enough space for the next r beat.
        cmtNbNum       := busValidNb
        busNbCnt_nxt   := 0.U
        seqNbPtr_nxt   := seqNbPtr_r + cmtNbNum // will be 0.U when busValidNb = seqBufValidNb
        r.ready        := true.B
        txnInfo.ready  := true.B                // a beat is issued

        // Still need to do enq for the seqBuf is busValidNb = seqBufValidNb
        // TODO: is there better way to achieve this?
        when (busValidNb === seqBufValidNb) {
          enqPtr_nxt := enqPtr + 1.U
          seqNbPtr_nxt := 0.U
        }

        // Haven't occupied all valid nbs in the seqBuf,
        // but the current beat is already the final beat of the whole riva request.
        when (txnInfo.bits.isFinalBeat) {
          enqPtr_nxt := enqPtr + 1.U
          seqNbPtr_nxt := 0.U
        }
      }

      val start = lower_nibble + busNbCnt_r
      val end   = upper_nibble

      val busNibbleVec = r.bits.data.asTypeOf(Vec(busNibbles, UInt(4.W)))

      // connect busNibbleVec with seqBuf
//      busNibbleVec.zipWithIndex.foreach {
//        case (busNb, busIdx) =>
//          when (busIdx.U >= start && busIdx.U <= end) {
//            val seqIdx = busIdx.U - start + seqNbPtr_r
//
//            seqBuf(enqPtr.value)(seqIdx).nb := busNb
//            seqBuf(enqPtr.value)(seqIdx).en := true.B
//          }
//      }

      /* 
       * WHY we choose to iterate over seqBuf half bytes:
       *
       * Although it's intuitive to 'iterate over AXI half bytes' and decide where each should go in the seqBuf,
       * this approach is NOT optimal in hardware.
       *
       * A more fundamental and efficient method is to 'iterate over each half byte in the seqBuf' and determine if any AXI half byte should be written into it.
       * This matches the nature of hardware synthesis, where each register (half byte in seqBuf) needs to explicitly define
       * its input source and write condition.
       *
       * In our design, each AXI beat contains multiple half bytes, and each half byte may or may not be valid depending on the transfer boundaries and shuffle logic.
       * However, each seqBuf half byte can only be written by at most one AXI half byte per cycle. Therefore, by iterating over seqBuf half bytes,
       * we only need to perform one matching check per half byte, instead of checking all seqBuf positions for every AXI half byte.
       *
       * Moreover, iterating over the seqBuf generates only about 1/4 as much Verilog
       * compared to iterating over all AXI half-bytes.
       */
      seqBuf(enqPtr.value).nb.zip(seqBuf(enqPtr.value).en).zipWithIndex.foreach {
        case ((nb, en), seqIdx) =>
          when ((seqIdx.U >= seqNbPtr_r) && (seqIdx.U <= (seqNbPtr_r + cmtNbNum))) {
            val idx = seqIdx.U - seqNbPtr_r + start // 'start' is needed, because 'idx' is the index of busNb.
            nb := busNibbleVec(idx)
            en := true.B // Don't consider mask of mask Unit in this stage.
          }
      }

      dontTouch(busValidNb)
      dontTouch(seqBufValidNb)
      dontTouch(do_serial_cmt)
      dontTouch(lower_nibble)
      dontTouch(upper_nibble)
    }
  }.elsewhen(gather_cmt) {
    assert(false.B, "We don't support gather mode now!")
  }

// ------------------------------------------ seqBuf -> shfBuf ------------------------------------------------- //
  private val do_cmt_seq_to_shf = shfBufEmpty && !seqBufEmpty && !metaBufEmpty && (meta.vm || mask.map(_.valid).reduce(_ || _))

  // Shuffle and commit data and nbe in seqBuf to shfBuf
  when(do_cmt_seq_to_shf) { // NOTE: mask.valid should be || instead of &&. TODO: 还不知道为什么
    val seqBuf_nb = seqBuf(deqPtr.value).nb
    val seqBuf_en = seqBuf(deqPtr.value).en

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
      buf.bits.vaddr := vaddr_r
    }

    // add vaddr when info are committed and saved in shfBuf
    vaddr_nxt := (vaddr_r.asUInt + 1.U).asTypeOf(new VAddrBundle)
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

    // do deq of seqBuf
    seqBuf(deqPtr.value) := 0.U.asTypeOf(seqBuf(deqPtr.value)) // Actually, we only need to clear nbe.
    deqPtr := deqPtr + 1.U
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
  when(!seqBufEmpty) { assert(!metaBufEmpty, "[DataCtrlLoad] There should be at least one valid meta info in meta Buffer when seqBuf is not Empty!") }
// ------------------------------------------ Don't Touch ------------------------------------------------- //
  dontTouch(idle)
  dontTouch(do_cmt_seq_to_shf)
  dontTouch(vaddr_nxt)
  dontTouch(seqNbPtr_nxt)
  dontTouch(enqPtr_nxt)
  dontTouch(shfBufEmpty)
}
