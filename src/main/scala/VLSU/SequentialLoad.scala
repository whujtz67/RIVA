package vlsu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters
import protocols.AXI.spec.RFlit

class SequentialLoad(implicit p: Parameters) extends VLSUModule with SequentialDataCtrl {
  def isLoad: Boolean = true

// ------------------------------------------ IO Declaration ------------------------------------------------- //
  // R Channel Input
  val r = IO(Flipped(Decoupled(new RFlit(axi4Params)))).suggestName("io_r")

  // Output to ShuffleUnit
  val txShfu = IO(Decoupled(new SeqBufBundle())).suggestName("io_tx_shfu")

// ------------------------------------------ AXI R bus -> seqBuf logic ------------------------------------------------- //
  // Override the default assignments from CommonDataCtrl
  busNbCnt_nxt := busNbCnt_r
  seqNbPtr_nxt := seqNbPtr_r
  r.ready := false.B
  txnInfo.ready := false.B
  enqPtr_nxt := enqPtr
  txShfu.valid := false.B
  seqInfoBuf.io.deq.ready := false.B

  // FSM Outputs for AXI R bus -> seqBuf
  when (idle) {
    // initialize Pointers and vaddr
    when(txnInfo.valid) {
      busNbCnt_nxt := 0.U // busNbCnt is the counter of valid nbs from the bus that has already been committed, so it should be initialized as 0.
      seqNbPtr_nxt := seqInfoBuf.io.deq.bits.seqNbPtr // Only the initialization of seqNbPtr_nxt needs to consider vstart.
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
    // 1. There are valid data on the R Bus;
    // 2. Target seqBuf is not full;
    // 3. TxnInfo is valid. Otherwise the txnInfo should be wrong.
    val do_serial_cmt = r.valid && !seqBufFull && txnInfo.valid
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
          when ((seqIdx.U >= seqNbPtr_r) && (seqIdx.U < (seqNbPtr_r + cmtNbNum))) {
            val idx = seqIdx.U - seqNbPtr_r + start // 'start' is needed, because 'idx' is the index of busNb.
            nb := busNibbleVec(idx)
            en := true.B // Don't consider mask of mask Unit in this stage.
          }
      }

      dontTouch(busValidNb)
      dontTouch(seqBufValidNb)
      dontTouch(cmtNbNum)
      dontTouch(do_serial_cmt)
      dontTouch(lower_nibble)
      dontTouch(upper_nibble)
    }
  }.elsewhen(gather_cmt) {
    assert(false.B, "We don't support gather mode now!")
  }

// ------------------------------------------ seqBuf -> ShuffleUnit ------------------------------------------------- //
  txShfu.valid := !seqBufEmpty
  txShfu.bits  := seqBuf(deqPtr.value)
  // Output seqBuf data to ShuffleUnit when available
  when (txShfu.fire) {
    // Clear the seqBuf entry and advance deqPtr
    seqBuf(deqPtr.value) := 0.U.asTypeOf(seqBuf(deqPtr.value))
    deqPtr := deqPtr + 1.U
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
