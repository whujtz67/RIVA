package vlsu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters
import protocols.AXI.spec.{AxFlit, BFlit, Burst, Cache}

import xs.utils.{CircularQueuePtr, HasCircularQueuePtrHelper}

class ReqFragmenter(implicit p: Parameters) extends VLSUModule {
  val io = IO(new Bundle {
    val rivaReq        = Flipped(Decoupled(new RivaReqPtl()))
    val coreStPending  = Input(Bool())
    val meta           = Output(new MetaCtrlInfo())
    val txnInjectValid = Output(Bool())
    val txnInjectReady = Input(Bool()) // If target TxnCtrlUnit is ready to be injected.
    val txnDone        = Input(Bool()) // The whole transaction in the TxnCtrl is done, which will cause the ReqFrag to update meta_r.
  })

  private val IDLE = 0
  private val FRAGMENTING = 1
  private val STALL = 2
  private val state_nxt = WireInit(0.U(1.W))
  private val state_r   = RegNext(state_nxt)
  private val idle = state_r === IDLE.U
  val fragmenting: Bool = state_r === FRAGMENTING.U
  private val stall = state_r === STALL.U

  val meta_nxt = Wire(new MetaCtrlInfo())
  val meta_r   = Reg(new MetaCtrlInfo())

  meta_r.sgm := RegNext(meta_nxt.sgm)
  meta_r.txn := RegNext(meta_nxt.txn)

  val txnInjectValid: Bool = WireDefault(!meta_r.isLast)

  // The condition for the Fragmenter to be cleared is that the last transaction is completed, NOT issued.
  // The reason is that the meta information needs to remain stable during the execution of the transaction.
  // TODO: maybe save some important infos in TxnCtrl or outside, and clear the reqFrag when the last Txn is issued. 这个可以提高一些效率，但是需要额外的存储。
  private val allDone = meta_r.isLast && io.txnDone // reqFragmenter should wait the last txn finish

  // FSM state switch
  when(idle) {
    state_nxt := Mux(io.rivaReq.valid, Mux(io.coreStPending, STALL.U, FRAGMENTING.U), IDLE.U)
  }.elsewhen(io.coreStPending) {
    state_nxt := Mux(!io.coreStPending, FRAGMENTING.U, STALL.U) // FSM will enter STALL state only when rivaReq is valid, so the next state can only be fragmenting.
  }.otherwise {
    state_nxt := Mux(allDone, IDLE.U, FRAGMENTING.U)
  }

  // FSM Outputs
  when(idle) {
    meta_nxt := 0.U.asTypeOf(meta_nxt)
    when(io.rivaReq.valid) {
      // save meta info into the regs regardless of coreStPending
      meta_nxt.init(io.rivaReq.bits, true.B)
      meta_r.glb := RegNext(meta_nxt.glb) // glb infos will not change during the req
    }
  }.elsewhen(fragmenting) {
    when(txnInjectValid && io.txnInjectReady) {
      meta_nxt.update(meta_r)
    }.otherwise {
      meta_nxt := meta_r
    }
  }.otherwise {
    meta_nxt := meta_r // Do Nothing when stalling.
  }

  io.meta := meta_r
  io.rivaReq.ready := idle
  io.txnInjectValid := txnInjectValid
// ------------------------------------------ Don't Touch ---------------------------------------------- //
  dontTouch(idle)
  dontTouch(fragmenting)
  dontTouch(stall)
}

class TxnControlUnit(isLoad: Boolean)(implicit p: Parameters) extends VLSUModule {
  val io = IO(new Bundle {
    val meta     = Flipped(Decoupled(new MetaCtrlInfo())) // inward
    val ctrl     = Valid(new AxiCtrlInfo()) // outward
    val update   = Input(Bool())
    val lastDone = Output(Bool()) // This signal tells Control Unit to update dataPtr. For STU, it will help DT assert w last.
    val release  = if (isLoad) None else Some(Input(Bool()))
  })

  // TODO: do we need this FSM?
  private val IDLE  = 0
  private val VALID = 1
//  private val STALL = 2 // wait core store TODO: Stall in Load/StoreCtrl
  private val state_nxt = WireInit(0.U(1.W))
  private val state_r   = RegNext(state_nxt)
  private val idle  = state_r === IDLE.U
  private val valid = state_r === VALID.U

  private val payload_nxt = Wire(chiselTypeOf(io.ctrl.bits))
  private val payload_r   = RegNext(payload_nxt) // TODO: make it Reg?
  
  private val lastDone = WireInit(false.B)
  private val allDone  = WireInit(false.B)

  lastDone := payload_r.isLast && io.update
  if (isLoad) {
    allDone := lastDone
  } else {
    allDone := io.release.get
  }

  // FSM state switch
  when(idle) {
    state_nxt := Mux(io.meta.valid, VALID.U, IDLE.U)
  }.otherwise {
    state_nxt := Mux(allDone, IDLE.U, VALID.U)
  }

  // FSM Outputs
  when(idle) {
    payload_nxt := 0.U.asTypeOf(payload_nxt)
    when(io.meta.valid) {
      payload_nxt.init(io.meta.bits)
    }
  }.otherwise {
    when(io.update) {
      payload_nxt.update(payload_r)
    }.otherwise {
      payload_nxt := payload_r
    }
  }

  io.ctrl.bits  := payload_r
  io.ctrl.valid := valid
  io.meta.ready := idle
  io.lastDone   := lastDone

  dontTouch(idle)
  dontTouch(valid)
}

/** A Control Machine that applies to both Load and Store Process.
 *
 * @param isLoad: this Control Machine served for load or store.
 */
class ControlMachine(isLoad: Boolean)(implicit p: Parameters) extends VLSUModule with HasCircularQueuePtrHelper {
  class CirQTxnCtrlPtr extends CircularQueuePtr[CirQTxnCtrlPtr](txnCtrlNum)

// ------------------------------------------ Parameters ---------------------------------------------- //
  private val addrChnlName = if (isLoad) "ar" else "aw"
  private val dataChnlName = if (isLoad) "r"  else "w"
  override def desiredName: String = if (isLoad) "LoadCtrl" else "StoreCtrl"

// ------------------------------------------ IO Declarations ---------------------------------------------- //
  // LaneSide OUTPUT io, request side IO is defined in ReqFragmenter
  val rivaReq        = IO(Flipped(Decoupled(new RivaReqPtl())))
  val coreStPending  = IO(Input(Bool()))
  val info = IO(Valid(new Bundle {
    val meta = new MetaCtrlInfo()
    val axi  = new AxiCtrlInfo()
  }))
  val update = IO(Input(Bool())) // update is asserted when an Axi Data Beat is committed(R) / sent(W).
  val ax     = IO(Decoupled(new AxFlit(axi4Params))).suggestName(s"$addrChnlName")       // TODO: 看看suggestName有没有起效果
  val b      = if (isLoad) None else Some(IO(Flipped(Decoupled(new BFlit(axi4Params))))) // Only STU has b channel

// ------------------------------------------ Module and Signal Declaration ---------------------------------------------- //
  private val enqPtr  = RegInit(0.U.asTypeOf(new CirQTxnCtrlPtr))
  private val deqPtr  = RegInit(0.U.asTypeOf(new CirQTxnCtrlPtr))  // B Ptr is not needed because deqPtr can serves as B Ptr when storing.
  private val axPtr   = RegInit(0.U.asTypeOf(new CirQTxnCtrlPtr)).suggestName(s"${addrChnlName}Ptr") // Ax Txn with info of which TxnCtrl is sending
  private val dataPtr = RegInit(0.U.asTypeOf(new CirQTxnCtrlPtr)).suggestName(s"${dataChnlName}Ptr") // Pointing to the information of the transaction being processed by the Data Transformer.

  private val reqFrag = Module(new ReqFragmenter())

  private val tcs = for(idx <- 0 until txnCtrlNum) yield {
    val tc = Module(new TxnControlUnit(isLoad))
    tc.suggestName(s"tc_$idx")
    tc.io.meta.bits  := reqFrag.io.meta
    tc.io.meta.valid := reqFrag.io.txnInjectValid
    tc.io.update     := dataPtr.value === idx.U && update
    if (tc.io.release.isDefined) tc.io.release.get := deqPtr.value === idx.U && b.get.fire // TODO: 考虑B的乱序响应

    tc
  }

// ------------------------------------------ Main logic ---------------------------------------------- //
  private val full  = isFull(enqPtr, deqPtr)
  private val empty = isEmpty(enqPtr, deqPtr)

  private val dataPtrAdd = WireDefault(Mux1H(UIntToOH(dataPtr.value), VecInit(tcs.map(_.io.lastDone))))
  private val do_enq     = WireDefault(Mux1H(UIntToOH(enqPtr .value), VecInit(tcs.map(_.io.meta.fire))))
  // What represents the finish of the transaction?
  // For Load: The last beat of R response is committed.
  // For Store: B is received.
  private val do_deq     = WireDefault(if (isLoad) dataPtrAdd else b.get.fire)

  reqFrag.io.rivaReq <> rivaReq
  reqFrag.io.coreStPending <> coreStPending
  //
  // ptr update logics
  //
  // enq
  when(do_enq) { enqPtr := enqPtr + 1.U }
  // deq
  when(do_deq) { deqPtr := deqPtr + 1.U }
  // ax
  when(ax.fire) { axPtr := axPtr + 1.U }
  // data
  when(dataPtrAdd) { dataPtr := dataPtr + 1.U}

  // axPtr === enqPtr means all ax txn in the tcs has been issued.
  when(!(axPtr.asUInt === enqPtr.asUInt)) {
    val info = Mux1H(UIntToOH(enqPtr .value), VecInit(tcs.map(_.io.ctrl.bits)))
    ax.bits.set(
      id = axPtr.value,
      addr = info.addr,
      len = info.rmnBeat,
      size = info.size,
      burst = Burst.Incr,
      cache = Cache.Modifiable
    )

    ax.valid := true.B
    assert(info.isHead, "should always be the head beat before Ax is sent.")
  }.otherwise {
    ax.bits := 0.U.asTypeOf(ax.bits)
    ax.valid := false.B
  }

  info.bits.meta := reqFrag.io.meta
  info.bits.axi  := Mux1H(UIntToOH(dataPtr.value), VecInit(tcs.map(_.io.ctrl.bits)))
  info.valid     := !empty // Don't need to consider whether reqFrag is valid.
  if (b.isDefined) b.get.ready := !empty

  reqFrag.io.txnInjectReady := !full
  reqFrag.io.txnDone := do_deq

// ------------------------------------------ assertion ---------------------------------------------- //
  when(update) { assert(!empty, "should not update when there are no control information in TC")  }

// ------------------------------------------ Don't Touch ---------------------------------------------- //
  dontTouch(full )
  dontTouch(empty)
  dontTouch(do_enq)
  dontTouch(do_deq)
  dontTouch(dataPtrAdd)

}