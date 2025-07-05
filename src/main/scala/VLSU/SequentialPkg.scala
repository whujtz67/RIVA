package vlsu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters
import xs.utils.{CircularQueuePtr, HasCircularQueuePtrHelper}

/** The essential meta info related to DataController saved in MetaBuf.
 *
 * 1. Problem Description
 * Due to the advanced iteration of MetaCtrlInfo by the Control Machine compared to the processing pace of the DataController,
 * the following issues may arise:
 *
 * (1) Request Mismatch: While the DataController is handling request A, the Control Machine might have already progressed to MetaCtrlInfo corresponding to request B.
 * (2) State Inconsistency: This could lead the DataController to use outdated or incorrect meta information, resulting in logical errors or data corruption.
 *
 * 2. Solution: Using MetaBuf
 * To prevent these problems, it is necessary to cache some meta information related to the DataController within the MetaBuf.
 * This ensures a one-to-one correspondence between meta information and requests through physical queue binding.
 *
 * 3. At which stage is the data in the MetaBuf used?
 * Load: seqBuf commit to shfBuf
 * Store: shfBuf commit to seqBuf
 * TODO: maybe rename it as s2sBuf?
 *
 * 4. Enq
 * In the 's_seg_lv_init' state of the ReqFragmenter, the enq.valid signal is asserted.
 * If the MetaBuf is full at this time, it will cause the ReqFragmenter to enter a stalled state,
 * thereby preventing the loss of requests.
 *
 * 5. Deq
 * Deq when the final transaction of the riva req is committed to the seqBuf.
 *
 * @param p
 */
class MetaBufBundle(isLoad: Boolean)(implicit p: Parameters) extends VLSUBundle {
  val reqId  = UInt(reqIdBits.W)
  val mode   = new VecMopOH()
  val eew    = UInt(2.W)
  val vd     = UInt(5.W)
  val vstart = UInt(vlenBits.W)
  val vm     = Bool()
  val cmtCnt = UInt(log2Ceil(VLEN*EWs.max/SLEN).W)
  val vaddr  = if (isLoad) Some(new VAddrBundle()) else None

  def init(meta: MetaCtrlInfo): Unit = {
    this.reqId  := meta.glb.reqId
    this.mode   := meta.glb.mode
    this.eew    := meta.glb.eew
    this.vd     := meta.glb.vd
    this.vstart := meta.glb.vstart
    this.vm     := meta.glb.vm
    this.cmtCnt := meta.glb.cmtCnt

    // vaddr is only used in seqBuf2shfBuf stage, so it should be put into metaBuf, instead of being initialized in idle state.
    if (this.vaddr.isDefined) {
      this.vaddr.get.init(meta.glb.vd, meta.glb.vstart, meta.glb.eew)
    }
  }
}

class SeqBufBundle(implicit p: Parameters) extends VLSUBundle {
    val nb = Vec(NrLanes*SLEN/4, UInt(4.W))
    val en = Vec(NrLanes*SLEN/4, Bool()) // Not the nbe committing to the lane, haven't considered mask.
  }

trait SequentialDataCtrl extends HasCircularQueuePtrHelper {
  self: VLSUModule =>

  def isLoad: Boolean

// ------------------------------------------ Parameters ------------------------------------------------- //
  val nbNum: Int = (SLEN / 4) * NrLanes // halfByte number in SLEN * NrLanes

// -------------------------------------------------- trait classes -------------------------------------------------- //
  class CirQSeqBufPtr extends CircularQueuePtr[CirQSeqBufPtr](2)

  class IdleInfoBundle(implicit p: Parameters) extends VLSUBundle {
    val seqNbPtr = UInt(log2Ceil(nbNum).W)
  }

// ------------------------------------------ Common IO Declaration ------------------------------------------------- //
  val txnInfo  = IO(Flipped(Decoupled(new TxnCtrlInfo()))).suggestName("io_txnInfo")   // TxnCtrlInfo from TC. NOTE: txnInfo.ready is the update signal to TC
  val metaInfo = IO(Flipped(Decoupled(new MetaCtrlInfo()))).suggestName("io_metaInfo") // MetaInfo from broadcast module

// ------------------------------------------ Idle Info Queue ------------------------------------------------- //
  // skid buffer for sequential commit
  val idleInfoQueue = Module(new Queue(new IdleInfoBundle(), entries = 1, flow = true))

// ------------------------------------------ Sequential Buffer ------------------------------------------------- //
  val seqBuf: Vec[SeqBufBundle] = RegInit(0.U.asTypeOf(Vec(2, new SeqBufBundle()))) // Ping-pong buffer

//  val enqPtr: CirQSeqBufPtr = RegInit(0.U.asTypeOf(new CirQSeqBufPtr()))
  val deqPtr: CirQSeqBufPtr = RegInit(0.U.asTypeOf(new CirQSeqBufPtr()))

  val enqPtr_nxt: CirQSeqBufPtr = WireInit(0.U.asTypeOf(new CirQSeqBufPtr()))
  val enqPtr: CirQSeqBufPtr = RegNext(enqPtr_nxt)

  val seqBufEmpty: Bool = isEmpty(enqPtr, deqPtr)
  val seqBufFull : Bool = isFull (enqPtr, deqPtr)

// ------------------------------------------ Internal Bundles ------------------------------------------------- //
  val txn : TxnCtrlInfo   = txnInfo.bits

// ------------------------------------------ Wire/Reg Delaration ------------------------------------------------- //
  // Because the remaining space in seqBuf might be less than the amount of valid data on the bus,
  // it may not be possible to commit all valid data from the bus in a single cycle.
  // Therefore, a counter is required to indicate the amount of valid data from the bus that has already been committed.
  val busNbCnt_nxt: UInt = WireInit(0.U.asTypeOf(UInt((busSize-2).W)))
  val busNbCnt_r  : UInt = RegNext(busNbCnt_nxt)

  // seqBuf half byte pointer
  val seqNbPtr_nxt: UInt = WireInit(0.U.asTypeOf(UInt(log2Ceil(nbNum).W)))
  val seqNbPtr_r  : UInt = RegNext(seqNbPtr_nxt)

  val isFinalBeat: Bool = WireDefault(txn.isFinalBeat)

// ------------------------------------------ FSM Logics ------------------------------------------------- //
  val s_idle :: s_serial_cmt :: s_gather_cmt :: Nil = Enum(3)
  val state_nxt  = WireInit(s_idle)
  val state_r    = RegNext(state_nxt)
  val idle       = state_r === s_idle
  val serial_cmt = state_r === s_serial_cmt
  val gather_cmt = state_r === s_gather_cmt

  // FSM State switch
  when (idle) {
    state_nxt := Mux(
      txnInfo.valid,
      // accept a new request
      s_serial_cmt,
      s_idle
    )
  }.elsewhen(serial_cmt) {
    state_nxt := Mux(isFinalBeat && txnInfo.ready, s_idle, s_serial_cmt) // txnInfo.ready is do Update
  }.elsewhen(gather_cmt) {
    state_nxt := Mux(isFinalBeat && txnInfo.ready, s_idle, s_gather_cmt)
  }.otherwise {
    state_nxt := state_r
  }

// ------------------------------------------ Connections ------------------------------------------------- //
  when (metaInfo.fire) {
    // do idleInfoQueue enqueue
    idleInfoQueue.io.enq.bits.seqNbPtr := (metaInfo.bits.glb.vstart << metaInfo.bits.glb.eew)(log2Ceil(nbNum)-1, 0)
    idleInfoQueue.io.enq.valid := true.B
  }.otherwise {
    // do nothing
    idleInfoQueue.io.enq.bits.seqNbPtr := 0.U.asTypeOf(idleInfoQueue.io.enq.bits.seqNbPtr)
    idleInfoQueue.io.enq.valid := false.B
  }
  metaInfo.ready := idleInfoQueue.io.enq.ready

// ------------------------------------------ Don't Touch ------------------------------------------------- //
  dontTouch(seqBufEmpty)
  dontTouch(seqBufFull)
  dontTouch(isFinalBeat)
  dontTouch(idle)
  dontTouch(serial_cmt)
  dontTouch(gather_cmt)

  if (txn.reqId.isDefined) dontTouch(txn.reqId.get)
}

