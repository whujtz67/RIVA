package vlsu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters
import protocols.AXI.spec.RFlit

class SeqBufBundle(implicit p: Parameters) extends VLSUBundle {
  val hb = UInt(4.W)
  val en = Bool() // Not the hbe committing to the lane, haven't considered mask.
}

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

  // The data saved in the seqBuf is the last set of data of the riva req, Use for metaBuf.deq.
  private val seqBufIsFinal = RegInit(0.U.asTypeOf(Vec(2, Bool())))

  // shuffle buffer
  private val shfBuf = RegInit(0.U.asTypeOf(Vec(NrLanes, Valid(new TxLane()))))
  private val shfBufEmpty = !shfBuf.map(_.valid).reduce(_ || _)

// ------------------------------------------ give the Outputs default value ------------------------------------------------- //
  vaddr_nxt      := vaddr_r
  busHbPtr_nxt   := busHbPtr_r
  seqHbPtr_nxt   := seqHbPtr_r
  r.ready        := false.B
  txnInfo.ready  := false.B
  maskReady      := false.B
  busData        := 0.U.asTypeOf(busData)
  busHbe         := 0.U.asTypeOf(busHbe)

// ------------------------------------------ AXI bus -> seqBuf ------------------------------------------------- //
  // FSM Outputs
  when (idle) {
    // initialize Pointers and vaddr
    when(metaBuf.io.deq.valid) {
      busHbPtr_nxt := 0.U
      seqHbPtr_nxt := (meta.vstart << meta.eew)(log2Ceil(hbNum)-1, 0)
      vaddr_nxt.init(meta)

      assert(txnInfo.valid)
    }
  }.elsewhen(serial_cmt) {
    val lowerHb = Mux(
      txn.isHead,
      (txn.addr(busSize-1, 0) << 1).asUInt + txn.illuHead.asUInt, // txnInfo.bits.addr has already taken vstart into consideration
      0.U
    )
    val upperHb = Mux(
      txn.isLastBeat,
      lowerHb + (txn.lbB << 1).asUInt - txn.illuTail.asUInt - (txn.isHead && txn.illuHead).asUInt,
      (busBytes.U << 1).asUInt - 1.U
    )

    // Won't consume data of the R Channel when seqBuf is full.
    when (r.valid && !seqBufFull) {
      val busValidHb    = upperHb - lowerHb + 1.U - busHbPtr_r // The amount of valid data on the bus
      val seqBufValidHb = (NrLanes * SLEN / 4).U - seqHbPtr_r  // The amount of free space available in seqBuf

      val cmtHbNum = WireInit(0.U.asTypeOf(UInt((busSize + 1).W)))


      when (busValidHb > seqBufValidHb) {
        // The amount of valid data on the bus is greater than the amount of free space available in seqBuf.
        cmtHbNum       := seqBufValidHb
        busHbPtr_nxt   := busHbPtr_r + cmtHbNum
        seqHbPtr_nxt   := 0.U
        enqPtr         := enqPtr + 1.U // Current slice of seqBuf is full, add the enqPtr.
      }.otherwise {
        // seqBuf still has enough space for the next r beat.
        cmtHbNum       := busValidHb
        busHbPtr_nxt   := 0.U
        seqHbPtr_nxt   := seqHbPtr_r + cmtHbNum
        r.ready        := true.B
        txnInfo.ready  := true.B

        when (txnInfo.bits.isFinalBeat) {
          seqBufIsFinal(enqPtr.value) := true.B
          enqPtr := enqPtr + 1.U
        }
      }

      val start = lowerHb + busHbPtr_r
      val end   = upperHb

      busData := VecInit(Seq.tabulate(128)(i => r.bits.data(4 * (i + 1) - 1, 4 * i)))

      // connect busData with seqBuf
//      busData.zipWithIndex.foreach {
//        case (busHb, busIdx) =>
//          when (busIdx.U >= start && busIdx.U <= end) {
//            val seqIdx = busIdx.U - start + seqHbPtr_r
//
//            seqBuf(enqPtr.value)(seqIdx).hb := busHb
//            seqBuf(enqPtr.value)(seqIdx).en := true.B
//          }
//      }

      /* 
       * WHY we choose to iterate over result_queue half bytes:
       *
       * Although it's intuitive to 'iterate over AXI half bytes' and decide where each should go in the result_queue,
       * this approach is NOT optimal in hardware.
       *
       * A more fundamental and efficient method is to 'iterate over each half byte in the result_queue' and determine if any AXI half byte should be written into it.
       * This matches the nature of hardware synthesis, where each register (half byte in result_queue) needs to explicitly define
       * its input source and write condition.
       *
       * In our design, each AXI beat contains multiple half bytes, and each half byte may or may not be valid depending on the transfer boundaries and shuffle logic.
       * However, each result_queue half byte can only be written by at most one AXI half byte per cycle. Therefore, by iterating over result_queue half bytes,
       * we only need to perform one matching check per half byte, instead of checking all result_queue positions for every AXI half byte.
       *
       * Moreover, iterating over the result_queue generates only about 1/4 as much Verilog
       * compared to iterating over all AXI half-bytes.
       */
      seqBuf(enqPtr.value).zipWithIndex.foreach {
        case (seqHb_r, seqIdx) =>
          when ((seqIdx.U >= seqHbPtr_r) && (seqIdx.U <= (seqHbPtr_r + cmtHbNum))) {
            val idx = seqIdx.U - seqHbPtr_r + start // 'start' is needed, because 'idx' is the index of busHb.
            seqHb_r.hb := busData(idx)
            seqHb_r.en := true.B
          }
      }

    }
  }.elsewhen(gather_cmt) {
    assert(false.B, "We don't support gather mode now!")
  }.otherwise {
    // Do nothing because default value has been given already.
  }

// ------------------------------------------ seqBuf -> shfBuf ------------------------------------------------- //
  private val do_cmt_seq_to_shf = shfBufEmpty && !seqBufEmpty && metaInfo.valid && (meta.vm || mask.map(_.valid).reduce(_ || _))

  // Shuffle and commit data and hbe in seqBuf to shfBuf
  when(do_cmt_seq_to_shf) { // NOTE: mask.valid should be || instead of &&. TODO: 还不知道为什么
    val seqBuf_hb = VecInit(seqBuf(deqPtr.value).map(_.hb))
    val seqBuf_en = VecInit(seqBuf(deqPtr.value).map(_.en))

    val shfBuf_hb = VecInit(shfBuf.map(_.bits.hbs))
    val shfBuf_en = VecInit(shfBuf.map(_.bits.hbes))

    hw_shuffle(meta.mode, meta.eew, seqBuf_hb, shfBuf_hb)
    hw_shuffle(meta.mode, meta.eew, seqBuf_en, shfBuf_en, Some(VecInit(mask.map(_.bits))), Some(meta.vm))

    // ShfBuf_hb/en is created using VecInit, assigning values to it does not automatically propagate to shfBuf.
    // Therefore, it is necessary to connect the two and perform the assignment again.
    shfBuf.zip(shfBuf_hb.zip(shfBuf_en)).foreach {
      case (vec_o, (vec_hb_i, vec_en_i)) =>
        val hbs = Wire(chiselTypeOf(vec_hb_i))
        hbs.zip(vec_hb_i).foreach {
          case (hb_o, hb_i) =>
            hb_o := hb_i
        }
        vec_o.bits.data := hbs.asUInt

        val hbes = Wire(chiselTypeOf(vec_en_i))
        hbes.zip(vec_en_i).foreach {
          case (en_o, en_i) =>
            en_o := en_i
        }
        vec_o.bits.hbe := hbes.asUInt
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

    // When current seqBuf is the last set of data of the riva req, do metaReq deq.
    // We SHOULD wait for this stage to deq metaBuf, instead of at 'bus -> seqBuf' stage!!!
    // The reason is we need meta.vm in this stage.
    metaBuf.io.deq.ready := seqBufIsFinal(deqPtr.value)

    // do deq of seqBuf
    seqBuf(deqPtr.value)        := 0.U.asTypeOf(seqBuf(deqPtr.value))
    seqBufIsFinal(deqPtr.value) := false.B
    deqPtr := deqPtr + 1.U
  }.otherwise {
    metaBuf.io.deq.ready := false.B
  }

// ------------------------------------------ shfBuf -> lane ------------------------------------------------- //
  txs.zipWithIndex.foreach {
    case (tx, lane) =>
      tx.bits.reqId := shfBuf(lane).bits.reqId
      tx.bits.vaddr := shfBuf(lane).bits.vaddr
      tx.bits.data  := shfBuf(lane).bits.hbs.asUInt
      tx.bits.hbe   := shfBuf(lane).bits.hbes.asUInt
      tx.valid      := shfBuf(lane).valid

      when (tx.fire) {
        shfBuf(lane).valid := false.B
      }
  }

// ------------------------------------------ Don't Touch ------------------------------------------------- //
  dontTouch(idle)
  dontTouch(do_cmt_seq_to_shf)
}
